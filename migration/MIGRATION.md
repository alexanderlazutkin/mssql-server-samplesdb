# Миграция AdventureWorksDW2019 → DuckDB

Конвейер: SQL Server 2022 (docker) → bcp CSV (UTF-8, sep `0x1F`) → DuckDB 1.5.5 → gzip.

## Запуск

```bash
make migrate            # полный конвейер + docker compose stop в конце
# или по фазам:
./migration/bin/migrate.sh restore   # поднятие контейнера + RESTORE из Backups/AdventureWorksDW2019.bak
./migration/bin/migrate.sh export    # экспорт 30 таблиц dbo в CSV
./migration/bin/migrate.sh ddl       # генерация DDL DuckDB из метаданных источника
./migration/bin/migrate.sh load      # загрузка CSV → migration/aw_dw2019.duckdb
./migration/bin/migrate.sh comments-en  # комментарии EN → aw_dw2019.duckdb
./migration/bin/migrate.sh comments-ru  # копия EN-БД + комментарии RU → aw_dw2019_ru.duckdb
./migration/bin/migrate.sh verify    # row counts + агрегаты источник/приёмник
./migration/bin/migrate.sh archive   # gzip -9f CSV (83МБ → 17МБ)

make migrate-verify     # только верификация
```

## Артефакты

| Файл | Назначение |
|---|---|
| `migration/aw_dw2019.duckdb` | результат: 30 таблиц, 354 колонки, 28 PK, комментарии EN |
| `migration/aw_dw2019_ru.duckdb` | то же + комментарии RU (данные идентичны EN-базе) |
| `migration/ddl/aw_dw2019_schema.sql` | генерируемый DDL (коммитится как референс) |
| `migration/ddl/aw_metadata.tsv` | словарь метаданных EN+RU (30 таблиц + 354 колонки) |
| `migration/ddl/aw_dw2019_comments_{en,ru}.sql` | COMMENT ON-скрипты, генерируются из TSV |
| `migration/csv/*.csv.gz` | архив выгрузки (sep `0x1F`, NULL = пустая строка) |
| `migration/logs/rowcounts.tsv` | счётчики строк источника |
| `migration/logs/migrate_*.log` | логи прогонов |
| `migration/.venv` | окружение писателя: **duckdb 1.5.5** |

## Совместимость

Файл `.duckdb` записывается версией **1.5.5** — ровно как в проекте
`~/Git/DE/pocketstack` (uv.lock). Глобальный CLI 2.0.0 для записи не использовать.
Проверка: pocketstack-рантайм открывает файл и читает данные (done).

## Решения конвейера

- `tinyint`/`smallint` → `INTEGER` (унификация < INT)
- `varbinary` → `VARCHAR` с hex-текстом (bcp `-c` выгружает бинарник как hex);
  бинарник восстановим: `SELECT unhex(EmployeePhoto) FROM dbo.DimEmployee`
- `sysdiagrams` исключена (SSMS-метаданные, OLE-блобы)
- `DatabaseLog`: CR/LF внутри TSQL/XmlEvent заменены на пробел до экспорта
- `money` → `DECIMAL(19,4)`, `datetime` → `TIMESTAMP`, `bit` → `BOOLEAN`

## Перезагрузка одной таблицы из архива

```sql
INSERT INTO dbo.DimProduct
SELECT * FROM read_csv('migration/csv/DimProduct.csv.gz', sep = chr(31),
                       header = false, nullstr = '',
                       columns = {'ProductKey': 'INTEGER', ...});
```

(колонки смотрите в `ddl/aw_dw2019_schema.sql`)

## Контейнер

- После `make migrate` контейнер остановлен (`docker compose stop`); образ и данные
  в `local_mountpoint/data` сохранены
- Повторный запуск: `docker compose up -d` — базы подтянутся (attach/restore по sentinel-файлу)

## Проверка целостности

Последний прогон: 30/30 таблиц OK; `SUM(SalesAmount)` FactInternetSales =
`29358677.2207`, `SUM(UnitCost)` FactProductInventory = `128657992.0600` —
совпадение с источником до копейки.
