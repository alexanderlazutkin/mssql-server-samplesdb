# План работ: AdventureWorksDW2019 (SQL Server 2022) → DuckDB

## Цель

Миграция базы **AdventureWorksDW2019** (SQL Server 2022, docker-контейнер) в **DuckDB**
через промежуточные CSV-файлы, с автоматизацией всех этапов скриптами.

## Требования

- SQL Server 2022 в docker-контейнере; после работ **образ не удалять**, контейнер **выключить** (`docker compose stop`)
- База-источник: AdventureWorksDW2019, восстановленная из архива `.bak`
- Перенос: все таблицы схемы `dbo` (структура + данные)
- CSV после загрузки **заархивировать** (gzip) для экономии места
- Всё автоматизировать скриптами; один driver-скрипт запускает весь конвейер

## Ограничение совместимости DuckDB (критично)

Целевой файл `aw_dw2019.duckdb` будет использоваться проектом **pocketstack**
(`/home/lan/Git/DE/pocketstack`), где закреплена версия **duckdb 1.5.5** (uv.lock).

Проверено на этой машине:

| Окружение | Версия |
|---|---|
| Глобальный CLI | v2.0.0 (Cyanoptera) |
| pocketstack (uv.lock + рантайм) | 1.5.5 |
| Системный python | duckdb не установлен |

Формат хранения DuckDB обратно совместим (новая версия читает файл старой),
но **не совместим вперёд**: файл, записанный 2.0.0, НЕ гарантирует чтение в 1.5.5.

**Решение:** запись файла ведём строго duckdb **1.5.5** в отдельном окружении
`migration/.venv` (uv, `duckdb==1.5.5`). Глобальным CLI 2.0.0 файл только читаем
(опционально). Финальная проверка — открытие файла рантаймом pocketstack.

## Не переносим (за рамками)

- Представления, хранимые процедуры, функции, индексы (кроме PRIMARY KEY), триггеры
- Идентичность IDENTITY (в DuckDB не нужна для аналитической копии)

## Архитектура конвейера

```
[AdventureWorksDW2019.bak]  (уже в Backups/, 98M)
        │  RESTORE
        ▼
┌─────────────────────────┐
│ SQL Server 2022         │  docker: mssql-server-samplesdb, port 1433
│ dbo.* (26 таблиц)       │
└───────────┬─────────────┘
            │  bcp queryout: UTF-8, sep 0x1F, header off
            ▼
migration/csv/*.csv  ──►  gzip  ──►  migration/csv/*.csv.gz
            │
            │  DDL из sys.columns (маппинг типов T-SQL → DuckDB)
            ▼
┌─────────────────────────┐
│ aw_dw2019.duckdb        │  read_csv(..., sep='\x1f', nullstr='')
└───────────┬─────────────┘
            │  row counts: SQL Server vs DuckDB
            ▼
       отчёт верификации
```

## Структура артефактов

```
migration/
├── MIGRATION_PLAN.md          # этот план
├── bin/
│   ├── 01_restore_dw2019.sh   # скачивание .bak + RESTORE в контейнере
│   ├── 02_export_csv.sh       # bcp-экспорт всех таблиц dbo → csv/
│   ├── 03_gen_ddl.py          # генерация DDL DuckDB из метаданных источника
│   ├── 04_load_duckdb.py      # создание таблиц + загрузка CSV
│   ├── 05_verify.py           # сверка row counts источник/приёмник
│   └── migrate.sh             # driver: фазы по очереди, логирование
├── ddl/
│   └── aw_dw2019_schema.sql   # генерируется (коммитится как референс)
├── csv/                       # временные CSV → .csv.gz (в .gitignore)
├── logs/
│   └── rowcounts.tsv          # таблица сверки количества строк
└── aw_dw2019.duckdb           # результат (в .gitignore)
```

## Этапы

### Этап 0 — Подготовка (инструменты, структура)

- [x] Проверить: `docker` (есть, 29.9.2), `gzip`, `uv`
- [x] Создать изолированное окружение писателя:
      `uv venv migration/.venv && uv pip install --python migration/.venv 'duckdb==1.5.5'`
      (версия строго = pocketstack, см. «Ограничение совместимости»)
- [x] Создать каталоги `migration/{bin,ddl,csv,logs}`
- [x] Дополнить `.gitignore`: `migration/csv/`, `migration/*.duckdb`, `migration/.venv/`, `*.bak`

### Этап 1 — Развертывание SQL Server 2022 + восстановление БД

- [x] `docker compose up -d` (образ mssql/server:2022-latest уже настроен)
- [x] Дождаться готовности: цикл `sqlcmd -Q "select 1"` (макс. 60 сек)
- [x] `AdventureWorksDW2019.bak` (98M) уже в `Backups/` — скачивание не требуется
- [x] `RESTORE FILELISTONLY` → определить логические имена файлов
- [x] `RESTORE DATABASE [AdventureWorksDW2019]` с MOVE в `/var/opt/mssql/data`
      (отдельный скрипт — не трогаем существующий `setup.restore.sql`)
- [x] Контроль: `SELECT name FROM sys.databases` + список таблиц `dbo`

### Этап 2 — Экспорт таблиц в CSV

- [x] Получить список таблиц: `INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo'`
- [x] Для каждой таблицы — `bcp queryout` внутри контейнера:
      - кодировка UTF-8 (`-C 65001`), разделитель полей `0x1F` (не ломается о запятые в строках),
        без header, окончание строк `\n`
      - вывод в `/var/opt/mssql/shared_folder/csv/<table>.csv` (общий volume с хостом)
- [x] Параллельно снять счётчики строк источника → `logs/rowcounts.tsv`
- [x] Контроль: количество CSV = количество таблиц; размер каждого файла > 0

### Этап 3 — Генерация DDL DuckDB

- [x] Скрипт читает `sys.columns` + `sys.types` из SQL Server
- [x] Маппинг типов:

  | T-SQL                  | DuckDB          |
  |------------------------|-----------------|
  | tinyint / smallint     | INTEGER (все < INT унифицируем в INT) |
  | int                    | INTEGER         |
  | bigint                 | BIGINT          |
  | bit                    | BOOLEAN         |
  | decimal(p,s) / numeric | DECIMAL(p,s)    |
  | money / smallmoney     | DECIMAL(19,4)   |
  | float / real           | DOUBLE / FLOAT  |
  | datetime / datetime2   | TIMESTAMP       |
  | date                   | DATE            |
  | time                   | TIME            |
  | datetimeoffset         | TIMESTAMP WITH TIME ZONE |
  | char/nchar/varchar/nvarchar/text | VARCHAR |
  | uniqueidentifier       | VARCHAR (безопаснее, чем UUID) |
  | varbinary / binary / image | VARCHAR (hex-текст от bcp; бинарник восстановим через `unhex()`) |
  | sql_variant            | VARCHAR         |

- [x] Сгенерировать `ddl/aw_dw2019_schema.sql`: `CREATE SCHEMA dbo;` + `CREATE TABLE dbo.X (...)`
      с PRIMARY KEY из метаданных PK источника
- [x] NULL/NOT NULL переносим как в источнике

### Этап 4 — Загрузка в DuckDB

- [x] Запуск скрипта через `migration/.venv` (duckdb **1.5.5** — как в pocketstack)
- [x] Открыть/создать `migration/aw_dw2019.duckdb`
- [x] Выполнить DDL (этап 3)
- [x] Для каждой таблицы:
      `INSERT INTO dbo.X SELECT * FROM read_csv('csv/X.csv', sep='\x1f', header=false, columns={...}, nullstr='', ignore_errors=false)`
- [x] `CHECKPOINT` после загрузки
- [x] Контроль: загрузка без ошибок; при ошибке — остановка конвейера (fail fast)

### Этап 5 — Верификация

- [x] Row counts по всем таблицам: SQL Server (`SELECT COUNT(*)`) vs DuckDB
- [x] Сверка в `logs/rowcounts.tsv`: таблица | источник | приёмник | статус
- [x] Выборочная проверка агрегатов по ключевой таблице (FactInternetSales:
      SUM(SalesAmount), COUNT(DISTINCT CustomerKey))
- [x] Критерий успеха: 100% совпадение row counts; при расхождении — выход с ошибкой
- [x] Совместимость: открыть `aw_dw2019.duckdb` рантаймом pocketstack
      (`uv run --directory /home/lan/Git/DE/pocketstack python -c "..."`) —
      читается, версия хранилища валидна для 1.5.5

### Этап 6 — Архивация CSV

- [x] `gzip -9` каждый CSV пофайлово (DuckDB умеет читать `.csv.gz` напрямую —
      точечная перезагрузка одной таблицы без распаковки)
- [x] Удалить исходные `.csv`, оставить только `.csv.gz`
- [x] Отчёт: размер до/после

### Этап 7 — Оркестрация

- [x] `bin/migrate.sh` — driver с фазами (по одной или `all`):
      `restore | export | ddl | load | verify | archive | all`
- [x] Логирование в `migration/logs/migrate_<date>.log`
- [x] Makefile-таргеты: `make migrate`, `make migrate-verify`
- [x] В конце конвейера (успех): `docker compose stop` (контейнер выключен, образ остаётся)

### Этап 8 — Документация

- [x] `migration/MIGRATION.md`: как запускать, что получается, как перезагрузить одну таблицу
- [x] Ссылка на план/инструкцию из README.md

## Риски и решения

| Риск | Решение |
|------|---------|
| Запятые/кавычки/переводы строк в данных ломают CSV | разделитель `0x1F`, данные AW-DW не содержат его |
| NULL vs пустая строка | bcp пишет NULL как пустоту → `nullstr=''` в read_csv |
| Логические имена файлов в .bak отличаются | RESTORE FILELISTONLY перед RESTORE |
| Unicode (DimCustomer с не-ASCII) | `-C 65001` + проверка выборочно |
| Тип datetime2(7) точность | TIMESTAMP DuckDB хранит микросекунды; допустимо для AW-DW |
| Образ/контейнер нужны повторно | `docker compose stop` (не `down`), образ не удаляем |
| Файл .duckdb записан версией новее pocketstack | писатель закреплён `duckdb==1.5.5` в `migration/.venv`; верификация открытием в рантайме pocketstack |

## Порядок исполнения

0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 (можно параллельно с 2-6) → 8

Коммит — по явному запросу после завершения работ.

---

# Доработки (задачи после основного конвейера)

> Правило: все новые задачи пользователя фиксируются здесь.

## Этап 9 — Перенос описаний таблиц/колонок в DuckDB (COMMENT ON)

Статус: **выполнен, изменён по факту**: extended properties в AdventureWorksDW2019
отсутствуют (0 `MS_Description`), поэтому описания авторские — словарь метаданных
`ddl/aw_metadata.tsv` (EN+RU).

- [x] Проверка EP источника (пусто) → решение: авторский data dictionary
- [x] Синтаксис `COMMENT ON TABLE` / `COMMENT ON COLUMN` проверен на 1.5.5
- [x] `07_apply_comments.py <db> <sql>` — применение к БД
- [x] Верификация: 30 таблиц + 354 колонки прокомментированы в обеих БД

## Этап 10 — Два варианта метаданных: EN (исходные) и RU (переведённые)

Статус: **выполнен**

Две БД: `aw_dw2019.duckdb` (EN) и `aw_dw2019_ru.duckdb` (RU = копия EN + RU-комментарии),
данные идентичны.

- [x] `ddl/aw_metadata.tsv` — 384 записи (30 таблиц + 354 колонки), колонки EN и RU
- [x] `ddl/aw_dw2019_comments_en.sql` и `ddl/aw_dw2019_comments_ru.sql` (по 384 statement,
      генератор `06_gen_comments.py` с валидацией имён по схеме БД)
- [x] Фазы `migrate.sh`: `comments-en`, `comments-ru`; включены в `all` (после `load`)
- [x] Верификация: EN == RU == 30/354 прокомментировано, row counts идентичны
- [x] Примеры комментариев обоих вариантов показаны пользователю
