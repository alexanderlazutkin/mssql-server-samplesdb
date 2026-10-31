#!/bin/bash
set -euo pipefail

SA_PASSWORD="${SA_PASSWORD:-PaSSw0rd}"
CONTAINER="${CONTAINER:-mssql-server-samplesdb}"
DB_NAME="AdventureWorksDW2019"
CSV_DIR="migration/csv"
LOGS_DIR="migration/logs"
STAGE_C="/var/opt/mssql/shared_folder/csv"
STAGE_HOST="local_mountpoint/shared_folder/csv"
SEP=$'\x1f'

SQLCMD=(/opt/mssql-tools18/bin/sqlcmd -No -C -S 127.0.0.1 -U sa -P "$SA_PASSWORD")

exec_sql() {
  docker exec "$CONTAINER" "${SQLCMD[@]}" -W -s "|" "$@"
}

query_c() {
  docker exec "$CONTAINER" /opt/mssql-tools18/bin/bcp "$1" queryout "$STAGE_C/$2.csv" \
    -c -C 65001 -t "$SEP" -r '\n' -Yo -u \
    -S 127.0.0.1 -U sa -P "$SA_PASSWORD" >/dev/null
}

mkdir -p "$CSV_DIR" "$LOGS_DIR" "$STAGE_HOST"
chmod 777 "$STAGE_HOST"

echo -e "table\trows" > "$LOGS_DIR/rowcounts.tsv"

TABLES=$(exec_sql -h -1 -Q "SET NOCOUNT ON; SELECT t.name FROM ${DB_NAME}.sys.tables t WHERE t.schema_id = SCHEMA_ID('dbo') EXCEPT SELECT 'sysdiagrams' ORDER BY 1;" | tr -d ' \r')

for T in $TABLES; do
  if [ "$T" = "DatabaseLog" ]; then
    Q="SELECT [DatabaseLogID], [PostTime], [DatabaseUser], [Event], [Schema], [Object], REPLACE(REPLACE(CAST([TSQL] AS NVARCHAR(MAX)), CHAR(13), ''), CHAR(10), ' '), REPLACE(REPLACE(CAST([XmlEvent] AS NVARCHAR(MAX)), CHAR(13), ''), CHAR(10), ' ') FROM ${DB_NAME}.dbo.[${T}]"
  else
    Q="SELECT * FROM ${DB_NAME}.dbo.[${T}]"
  fi

  query_c "$Q" "$T"

  ROWS=$(exec_sql -h -1 -Q "SET NOCOUNT ON; SELECT p.rows FROM ${DB_NAME}.sys.partitions p WHERE p.object_id = OBJECT_ID('${DB_NAME}.dbo.[${T}]') AND p.index_id IN (0, 1);" | tr -d ' \r')
  echo -e "${T}\t${ROWS}" >> "$LOGS_DIR/rowcounts.tsv"
  echo "exported ${T} (${ROWS} rows)"
done

mv "$STAGE_HOST"/*.csv "$CSV_DIR"/

COUNT_CSV=$(ls -1 "$CSV_DIR"/*.csv | wc -l)
COUNT_TBL=$(echo "$TABLES" | wc -l)
echo "csv files: ${COUNT_CSV}, tables: ${COUNT_TBL}"

if [ "$COUNT_CSV" -ne "$COUNT_TBL" ]; then
  echo "ERROR: csv count mismatch" >&2
  exit 1
fi
for F in "$CSV_DIR"/*.csv; do
  if [ ! -s "$F" ]; then
    echo "ERROR: empty file $F" >&2
    exit 1
  fi
done
echo "export complete: ${COUNT_CSV} tables -> ${CSV_DIR}/"
