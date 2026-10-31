#!/usr/bin/env python3
import os
import sys

import duckdb


def main():
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} <db_file> <comments.sql>", file=sys.stderr)
        sys.exit(1)
    db_file, sql_file = sys.argv[1], sys.argv[2]

    with open(sql_file) as f:
        sql = f.read()

    con = duckdb.connect(db_file)
    con.execute(sql)
    con.execute("CHECKPOINT")
    con.close()
    print(f"applied {sql_file} -> {db_file} ({os.path.getsize(db_file)} bytes)")


if __name__ == "__main__":
    main()
