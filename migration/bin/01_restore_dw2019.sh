#!/bin/bash
set -euo pipefail

SA_PASSWORD="${SA_PASSWORD:-PaSSw0rd}"
CONTAINER="${CONTAINER:-mssql-server-samplesdb}"
DB_NAME="AdventureWorksDW2019"
BAK_PATH="/var/opt/mssql/backup/AdventureWorksDW2019.bak"
DATA_DIR="/var/opt/mssql/data"
SQLCMD=(/opt/mssql-tools18/bin/sqlcmd -No -C -S 127.0.0.1 -U sa -P "$SA_PASSWORD")

exec_sql() {
  docker exec "$CONTAINER" "${SQLCMD[@]}" -W -s "|" "$@"
}

wait_for_sql() {
  local i=0
  until exec_sql -Q "SET NOCOUNT ON; SELECT 1;" -h -1 >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -ge 60 ]; then
      echo "ERROR: SQL Server not ready after 120s" >&2
      exit 1
    fi
    sleep 2
  done
  echo "SQL Server is up"
}

wait_for_setup() {
  local i=0
  until docker logs "$CONTAINER" 2>&1 | grep -q "MSSQL CONFIG COMPLETE"; do
    i=$((i + 1))
    if [ "$i" -ge 90 ]; then
      echo "ERROR: container bootstrap not finished after 450s" >&2
      exit 1
    fi
    sleep 5
  done
  echo "container bootstrap complete"
}

db_row() {
  exec_sql -h -1 -Q "SET NOCOUNT ON; $1" | tr -d ' \r'
}

wait_for_sql
wait_for_setup

if [ "$(db_row "SELECT COUNT(*) FROM sys.databases WHERE name = '${DB_NAME}';")" = "1" ]; then
  echo "${DB_NAME} already exists, restore skipped"
else
  LOGICAL_DATA=$(exec_sql -Q "RESTORE FILELISTONLY FROM DISK = '${BAK_PATH}'" | awk -F'|' '$3 == "D" {print $1; exit}')
  LOGICAL_LOG=$(exec_sql -Q "RESTORE FILELISTONLY FROM DISK = '${BAK_PATH}'" | awk -F'|' '$3 == "L" {print $1; exit}')

  if [ -z "$LOGICAL_DATA" ] || [ -z "$LOGICAL_LOG" ]; then
    echo "ERROR: cannot resolve logical file names from ${BAK_PATH}" >&2
    exit 1
  fi
  echo "logical names: data='${LOGICAL_DATA}' log='${LOGICAL_LOG}'"

  exec_sql -Q "RESTORE DATABASE [${DB_NAME}] FROM DISK = N'${BAK_PATH}' WITH FILE = 1, MOVE N'${LOGICAL_DATA}' TO N'${DATA_DIR}/${DB_NAME}.mdf', MOVE N'${LOGICAL_LOG}' TO N'${DATA_DIR}/${DB_NAME}_log.ldf', REPLACE, NOUNLOAD, STATS = 10" >/dev/null
  echo "${DB_NAME} restored"
fi

TABLES=$(db_row "SELECT COUNT(*) FROM [${DB_NAME}].sys.tables WHERE schema_id = SCHEMA_ID('dbo');")
echo "dbo tables in ${DB_NAME}: ${TABLES}"
