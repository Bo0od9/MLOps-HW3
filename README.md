# Домашнее задание 3

## 1. Структура репозитория

```text

├─ docker-compose.yaml              # Все необходимые контейнеры
├─ requirements.txt           
├─ README.md
│
├─ src/
│   └─ kafka_producer.py            # Python-скрипт: читает train.csv и шлёт строки в Kafka
│
├─ sql/
│   ├─ create_tables.sql            # DDL: Kafka-таблица, MergeTree-таблица, MATERIALIZED VIEW
│   ├─ create_tables_optimized.sql  # Оптимизированный DDL
│   └─ query_max_tx_by_state.sql    # SQL-запрос
│
├─ data/
│   └─ train.csv                    # Датасет с транзакциями (НУЖНО СКАЧАТЬ С Kaggle!)
│
├─ result/
│   └─ max_tx_by_state.csv          # результат запроса
│
└─ clickhouse_data/                 # (создаётся автоматически) данные ClickHouse
````

### Что делает каждый компонент

* **`docker-compose.yaml`**
  * Поднимает контейнеры:
    * `clickhouse`
    * `zookeeper`
    * `kafka`
    * `akhq` — веб-интерфейс для просмотра топиков Kafka ([http://localhost:8080](http://localhost:8080)).
    * `app` — контейнер с Python 3.12, в котором запускается `kafka_producer.py`.

* **`src/kafka_producer.py`**

  * Читает файл `data/train.csv`.
  * Каждую строку превращает в JSON и отправляет в Kafka-топик `transactions`.
  * Параметры можно переопределить через переменные окружения:

    * `KAFKA_BROKER` (по умолчанию `kafka:29092` внутри контейнеров),
    * `KAFKA_TOPIC` (по умолчанию `transactions`),
    * `CSV_PATH` (по умолчанию `/app/data/train.csv` в контейнере `app`).

* **`sql/create_tables.sql`**

  * Создаёт три объекта в ClickHouse:
    1. `transactions_kafka` — таблица, читает сырые JSON-сообщения из топика.
    2. `transactions` — основная аналитическая таблица.
    3. `transactions_mv` — `MATERIALIZED VIEW`, который:

       * читает записи из `transactions_kafka`,
       * парсит JSON,
       * пишет данные в таблицу `transactions`.
* **`sql/create_tables_optimized.sql`**
  * Изменения по сравнению с `sql/create_tables.sql`:
    * LowCardinality для категориальных строк, должен уменьшить размер таблицы за счет хранения id категории вместо названия.
    * Кодирование ZSTD. DoubleDelta, чтобы хранить не значения, а дельты.
    * Сортировка по us_state, transaction_time, cat_id, amount должна ускорить выполнения запроса.
    * PARTITION BY по месяцу транзакции. Полезно для запросов, где нужно выбрать транзакции за какой-то ограниченный период.

* **`sql/query_max_tx_by_state.sql`**

  * Запрос для получения категории наибольшей транзакции по каждому штату.


* **`data/train.csv`**

  * Исходный датасет

---

## 2. Как всё запустить

### 2.1. Предварительные требования

1. Склонироать репозиторий.
2. Перейти в директорию репозитория: `cd MLOps-HW3`
3. Проверить, еслить ли датасет в `/data`. Если нет, скачать с [Kaggle](https://www.kaggle.com/competitions/teta-ml-1-2025/data?select=train.csv).

### 2.2. Запустить контейнеры

Из корня репозитория:

````bash
docker-compose up -d
````

Можно проверить, что все контейнеры поднялись:

````bash
docker ps
````

Должны быть:

* `clickhouse`
* `hw-3-kafka-1`
* `hw-3-zookeeper-1`
* `hw-3-akhq-1`
* `app`

> Можно зайти в интерфейс **AKHQ** и посмотреть топики Kafka:
>
> * Открыть в браузере: [http://localhost:8080](http://localhost:8080)

---

### 2.3. Создать таблицы в ClickHouse

Все DDL хранятся в `sql/create_tables.sql` и оптимизированная версив в `sql/create_tables_optimized.sql`.
Применить их:

````bash
docker exec -i clickhouse clickhouse-client -u click --password click --multiquery < sql/create_tables.sql
````

Или оптимизированную версию:
````bash
docker exec -i clickhouse clickhouse-client -u click --password click --multiquery < sql/create_tables_optimized.sql
````

Можно проверить, что таблицы создались:

````bash
docker exec -it clickhouse clickhouse-client -u click --password click -q "SHOW TABLES"
````

В списке должны быть:

* `transactions_kafka`
* `transactions`
* `transactions_mv`

---

### 2.4. Установить зависимости и запустить продюсер Kafka

Зайдите в контейнер `app`:

````bash
docker exec -it app bash
````

Внутри контейнера:

1. Установить Python-зависимости:

   ````bash
   pip install -r requirements.txt
   ````

2. Запустить продюсер, который прочитает `data/train.csv` и отправит всё в Kafka-топик `transactions`:

   ````bash
   python src/kafka_producer.py
   ````

При успешной работе в логах будет что-то вроде:

````text
[INFO] kafka_producer starting
[INFO] Sent 100000 messages. Offset: 99999 Partition: 0
...
[INFO] Sending complete. Total messages sent: 786431
[INFO] Closing Kafka producer
````

Выйти из контейнера:

````bash
exit
````

---

### 2.5. Опционально: проверить, что данные дошли до ClickHouse

Зайти в ClickHouse-клиент:

````bash
docker exec -it clickhouse clickhouse-client -u click --password click
````

Внутри клиента выполнить:

````sql
-- Проверить, сколько записей уже в основной таблице
SELECT count() FROM transactions;

-- Посмотреть несколько строк
SELECT *
FROM transactions
LIMIT 5;
````

> При необходимости можно посмотреть структуру таблиц:
>
> ````sql
> DESCRIBE TABLE transactions_kafka;
> DESCRIBE TABLE transactions;
> ````

---

### 2.6. Выполнить аналитический запрос

Запрос уже лежит в `sql/query_max_tx_by_state.sql`.
Вывести результат в консоль:

````bash
docker exec -it clickhouse clickhouse-client -u click --password click -q "$(cat sql/query_max_tx_by_state.sql)"
````

Сохранить результат в csv:

````bash
docker exec -i clickhouse clickhouse-client -u click --password click --format CSV --query="$(cat sql/query_max_tx_by_state.sql)" > result/max_tx_by_state.csv
````

В `result/max_tx_by_state.csv` должены появиться резултаты выполнения запроса.
