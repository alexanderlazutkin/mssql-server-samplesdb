#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."

LOG_DIR="migration/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/migrate_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

stamp() { echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] $1 ==="; }

phase_restore() { stamp "phase 1/6: restore AdventureWorksDW2019"; ./migration/bin/01_restore_dw2019.sh; }
phase_export()  { stamp "phase 2/6: export CSV"; ./migration/bin/02_export_csv.sh; }
phase_ddl()     { stamp "phase 3/6: generate DDL"; python3 migration/bin/03_gen_ddl.py; }
phase_load()    { stamp "phase 4/6: load DuckDB"; ./migration/.venv/bin/python migration/bin/04_load_duckdb.py; }
phase_verify()  { stamp "phase 5/6: verify"; ./migration/.venv/bin/python migration/bin/05_verify.py; }
phase_archive() {
  stamp "phase 6/6: archive CSV"
  local before after
  before=$(du -sb migration/csv | cut -f1)
  gzip -9f migration/csv/*.csv
  after=$(du -sb migration/csv | cut -f1)
  echo "csv size: $((before / 1024 / 1024))MB -> $((after / 1024 / 1024))MB"
}

case "${1:-all}" in
  restore) phase_restore ;;
  export) phase_export ;;
  ddl) phase_ddl ;;
  load) phase_load ;;
  verify) phase_verify ;;
  archive) phase_archive ;;
  all)
    phase_restore
    phase_export
    phase_ddl
    phase_load
    phase_verify
    phase_archive
    stamp "migration complete, stopping container"
    docker compose stop
    ;;
  *)
    echo "usage: $0 {restore|export|ddl|load|verify|archive|all}" >&2
    exit 1
    ;;
esac
stamp "done"
