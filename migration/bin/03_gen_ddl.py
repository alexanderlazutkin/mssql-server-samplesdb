#!/usr/bin/env python3
import subprocess
import sys

CONTAINER = "mssql-server-samplesdb"
DB = "AdventureWorksDW2019"
SA_PASSWORD = "PaSSw0rd"
OUT = "migration/ddl/aw_dw2019_schema.sql"
EXCLUDE = {"sysdiagrams"}

COLS_SQL = f"""SET NOCOUNT ON;
SELECT t.name, c.name, ty.name, c.precision, c.scale, c.is_nullable
FROM {DB}.sys.tables t
JOIN {DB}.sys.columns c ON c.object_id = t.object_id
JOIN {DB}.sys.types ty ON ty.system_type_id = c.system_type_id AND ty.user_type_id = ty.system_type_id
WHERE t.schema_id = SCHEMA_ID('dbo')
ORDER BY t.name, c.column_id;"""

PK_SQL = f"""SET NOCOUNT ON;
SELECT t.name, c.name, ic.key_ordinal
FROM {DB}.sys.tables t
JOIN {DB}.sys.indexes i ON i.object_id = t.object_id AND i.is_primary_key = 1
JOIN {DB}.sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN {DB}.sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE t.schema_id = SCHEMA_ID('dbo')
ORDER BY t.name, ic.key_ordinal;"""

TYPE_MAP = {
    "tinyint": "INTEGER",
    "smallint": "INTEGER",
    "int": "INTEGER",
    "bigint": "BIGINT",
    "bit": "BOOLEAN",
    "decimal": "DECIMAL",
    "numeric": "DECIMAL",
    "money": "DECIMAL(19,4)",
    "smallmoney": "DECIMAL(10,4)",
    "float": "DOUBLE",
    "real": "FLOAT",
    "datetime": "TIMESTAMP",
    "datetime2": "TIMESTAMP",
    "smalldatetime": "TIMESTAMP",
    "date": "DATE",
    "time": "TIME",
    "datetimeoffset": "TIMESTAMP WITH TIME ZONE",
    "char": "VARCHAR",
    "varchar": "VARCHAR",
    "nchar": "VARCHAR",
    "nvarchar": "VARCHAR",
    "text": "VARCHAR",
    "ntext": "VARCHAR",
    "sysname": "VARCHAR",
    "uniqueidentifier": "VARCHAR",
    "xml": "VARCHAR",
    "sql_variant": "VARCHAR",
    "binary": "VARCHAR",
    "varbinary": "VARCHAR",
    "image": "VARCHAR",
}


def q(sql):
    res = subprocess.run(
        [
            "docker",
            "exec",
            CONTAINER,
            "/opt/mssql-tools18/bin/sqlcmd",
            "-No",
            "-C",
            "-S",
            "127.0.0.1",
            "-U",
            "sa",
            "-P",
            SA_PASSWORD,
            "-W",
            "-s",
            "|",
            "-h",
            "-1",
            "-Q",
            sql,
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    rows = []
    for line in res.stdout.splitlines():
        line = line.strip()
        if not line or set(line) <= {"-", "|"}:
            continue
        rows.append([f.strip() for f in line.split("|")])
    return rows


def duck_type(base, precision, scale):
    t = TYPE_MAP.get(base)
    if t is None:
        raise ValueError(f"unmapped type: {base}")
    if t == "DECIMAL":
        return f"DECIMAL({precision},{scale})"
    return t


def main():
    col_rows = q(COLS_SQL)
    pk_rows = q(PK_SQL)

    tables = {}
    for table, name, base, prec, scale, nullable in col_rows:
        if table in EXCLUDE:
            continue
        tables.setdefault(table, []).append(
            (name, duck_type(base, prec, scale), nullable)
        )
    pks = {}
    for table, name, ordinal in pk_rows:
        pks.setdefault(table, []).append(name)

    unknown = {r[2] for r in col_rows if r[2] not in TYPE_MAP}
    if unknown:
        print(f"ERROR: unmapped types: {unknown}", file=sys.stderr)
        sys.exit(1)

    lines = ["CREATE SCHEMA IF NOT EXISTS dbo;", ""]
    for table in sorted(tables):
        cols = tables[table]
        defs = [f'    "{n}" {t}{"" if nl == "1" else " NOT NULL"}' for n, t, nl in cols]
        if table in pks:
            defs.append(
                "    PRIMARY KEY (" + ", ".join(f'"{c}"' for c in pks[table]) + ")"
            )
        lines.append(f'CREATE TABLE IF NOT EXISTS dbo."{table}" (')
        lines.append(",\n".join(defs))
        lines.append(");")
        lines.append("")

    with open(OUT, "w") as f:
        f.write("\n".join(lines))
    print(
        f"DDL written: {OUT} ({len(tables)} tables, {sum(len(v) for v in tables.values())} columns, {len(pks)} PKs)"
    )


if __name__ == "__main__":
    main()
