#!/usr/bin/env python3
import csv
import sys

import duckdb

TSV = "migration/ddl/aw_metadata.tsv"
DB_FILE = "migration/aw_dw2019.duckdb"
OUT = {
    "en": "migration/ddl/aw_dw2019_comments_en.sql",
    "ru": "migration/ddl/aw_dw2019_comments_ru.sql",
}


def esc(s):
    return s.replace("'", "''")


def main():
    con = duckdb.connect(DB_FILE, read_only=True)
    tables = {
        r[0]
        for r in con.execute(
            "SELECT table_name FROM information_schema.tables "
            "WHERE table_schema = 'dbo'"
        ).fetchall()
    }
    columns = {
        (r[0], r[1])
        for r in con.execute(
            "SELECT table_name, column_name FROM information_schema.columns "
            "WHERE table_schema = 'dbo'"
        ).fetchall()
    }
    con.close()

    rows = []
    with open(TSV, newline="") as f:
        for line in csv.reader(f, delimiter="\t"):
            if not line or len(line) != 4:
                print(f"ERROR: bad TSV line: {line}", file=sys.stderr)
                sys.exit(1)
            table, col, en, ru = [x.strip() for x in line]
            if table not in tables:
                print(f"ERROR: unknown table {table}", file=sys.stderr)
                sys.exit(1)
            if col != "-" and (table, col) not in columns:
                print(f"ERROR: unknown column {table}.{col}", file=sys.stderr)
                sys.exit(1)
            rows.append((table, col, en, ru))

    covered_t = {t for t, c, *_ in rows if c == "-"}
    covered_c = {(t, c) for t, c, *_ in rows if c != "-"}
    missing_t = tables - covered_t
    missing_c = columns - covered_c
    if missing_t:
        print(f"WARN: tables without comments: {sorted(missing_t)}", file=sys.stderr)
    if missing_c:
        print(
            f"WARN: {len(missing_c)} columns without comments: "
            f"{sorted(missing_c)[:10]}",
            file=sys.stderr,
        )

    for lang, idx in (("en", 0), ("ru", 1)):
        with open(OUT[lang], "w") as f:
            n = 0
            for table, col, *desc in rows:
                text = esc(desc[idx])
                if col == "-":
                    f.write(f"COMMENT ON TABLE dbo.\"{table}\" IS '{text}';\n")
                else:
                    f.write(f'COMMENT ON COLUMN dbo."{table}"."{col}" IS \'{text}\';\n')
                n += 1
        print(f"{OUT[lang]}: {n} statements")

    print(
        f"tables: {len(covered_t)}/{len(tables)}, "
        f"columns: {len(covered_c)}/{len(columns)}"
    )


if __name__ == "__main__":
    main()
