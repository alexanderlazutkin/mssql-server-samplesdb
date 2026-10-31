#!/usr/bin/env python3
import os
import sys

import duckdb

DB_FILE = "migration/aw_dw2019.duckdb"
DDL_FILE = "migration/ddl/aw_dw2019_schema.sql"
CSV_DIR = "migration/csv"


def main():
    if os.path.exists(DB_FILE):
        os.remove(DB_FILE)

    con = duckdb.connect(DB_FILE)
    with open(DDL_FILE) as f:
        con.execute(f.read())

    tables = [
        r[0]
        for r in con.execute(
            "SELECT table_name FROM information_schema.tables "
            "WHERE table_schema = 'dbo' ORDER BY table_name"
        ).fetchall()
    ]

    for t in tables:
        cols = con.execute(
            "SELECT column_name, data_type FROM information_schema.columns "
            "WHERE table_schema = 'dbo' AND table_name = ? "
            "ORDER BY ordinal_position",
            [t],
        ).fetchall()
        colspec = ", ".join(f"'{n}': '{ty}'" for n, ty in cols)
        path = os.path.abspath(os.path.join(CSV_DIR, f"{t}.csv"))

        if not os.path.exists(path):
            print(f"ERROR: missing {path}", file=sys.stderr)
            sys.exit(1)

        con.execute(
            f'INSERT INTO dbo."{t}" SELECT * FROM read_csv(?, '
            f"sep = chr(31), header = false, nullstr = '', "
            f"columns = {{{colspec}}})",
            [path],
        )
        loaded = con.execute(f'SELECT COUNT(*) FROM dbo."{t}"').fetchone()[0]
        print(f"loaded {t}: {loaded}")

    con.execute("CHECKPOINT")
    con.close()
    print(f"DuckDB file: {DB_FILE} ({os.path.getsize(DB_FILE)} bytes)")


if __name__ == "__main__":
    main()
