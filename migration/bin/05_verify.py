#!/usr/bin/env python3
import subprocess
import sys
from decimal import Decimal

import duckdb

CONTAINER = "mssql-server-samplesdb"
DB = "AdventureWorksDW2019"
SA_PASSWORD = "PaSSw0rd"
DUCK_FILE = "migration/aw_dw2019.duckdb"


def sql_source(sql):
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
            f"SET NOCOUNT ON; {sql}",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    line = next(
        l
        for l in res.stdout.splitlines()
        if l.strip() and not set(l.strip()) <= {"-", "|"}
    )
    return [f.strip() for f in line.split("|")]


def main():
    con = duckdb.connect(DUCK_FILE, read_only=True)
    tables = [
        r[0]
        for r in con.execute(
            "SELECT table_name FROM information_schema.tables "
            "WHERE table_schema = 'dbo' ORDER BY table_name"
        ).fetchall()
    ]

    failed = []
    print(f"{'table':<46} {'source':>8} {'duckdb':>8} status")
    for t in tables:
        src = int(sql_source(f"SELECT COUNT(*) FROM {DB}.dbo.[{t}]")[0])
        dst = con.execute(f'SELECT COUNT(*) FROM dbo."{t}"').fetchone()[0]
        ok = "OK" if src == dst else "MISMATCH"
        if src != dst:
            failed.append(t)
        print(f"{t:<46} {src:>8} {dst:>8} {ok}")

    checks = [
        (
            "FactInternetSales",
            "COUNT(*)|SUM(SalesAmount)|COUNT(DISTINCT CustomerKey)",
            f"SELECT COUNT(*), SUM(CAST(SalesAmount AS DECIMAL(19,4))), COUNT(DISTINCT CustomerKey) FROM {DB}.dbo.FactInternetSales",
            "SELECT COUNT(*), SUM(SalesAmount), COUNT(DISTINCT CustomerKey) FROM dbo.FactInternetSales",
        ),
        (
            "FactProductInventory",
            "COUNT(*)|SUM(UnitCost)",
            f"SELECT COUNT(*), SUM(CAST(UnitCost AS DECIMAL(19,4))) FROM {DB}.dbo.FactProductInventory",
            "SELECT COUNT(*), SUM(UnitCost) FROM dbo.FactProductInventory",
        ),
    ]
    print()
    for table, label, src_sql, dst_sql in checks:
        s = sql_source(src_sql)
        d = [str(x) for x in con.execute(dst_sql).fetchone()]
        norm = lambda v: Decimal(v).normalize()
        ok = all(norm(a) == norm(b) for a, b in zip(s, d))
        if not ok:
            failed.append(table)
        print(
            f"aggregate {label} [{table}]: source={s} duckdb={d} -> {'OK' if ok else 'MISMATCH'}"
        )

    con.close()
    if failed:
        print(f"\nVERIFY FAILED: {failed}", file=sys.stderr)
        sys.exit(1)
    print("\nVERIFY PASSED")


if __name__ == "__main__":
    main()
