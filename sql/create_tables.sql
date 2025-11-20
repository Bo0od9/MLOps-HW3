CREATE TABLE transactions_kafka
(
    raw String
) ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka:29092',
    kafka_topic_list = 'transactions',
    kafka_group_name = 'transactions_clickhouse',
    kafka_num_consumers = 1,
    kafka_format = 'JSONAsString';

CREATE TABLE transactions
(
    transaction_time    DateTime,
    merch               String,
    cat_id              String,
    amount              Float64,
    name_1              String,
    name_2              String,
    gender              FixedString(1),
    street              String,
    one_city            String,
    us_state            FixedString(2),
    post_code           String,
    lat                 Float64,
    lon                 Float64,
    population_city     UInt32,
    jobs                String,
    merchant_lat        Float64,
    merchant_lon        Float64,
    target              UInt8
) ENGINE = MergeTree
PARTITION BY toYYYYMM(transaction_time)
ORDER BY (us_state, transaction_time);

CREATE MATERIALIZED VIEW transactions_mv
TO transactions
AS
SELECT
    parseDateTimeBestEffort(JSONExtractString(raw, 'transaction_time')) AS transaction_time,
    JSONExtractString(raw, 'merch')                                     AS merch,
    JSONExtractString(raw, 'cat_id')                                    AS cat_id,
    toFloat64(JSONExtractString(raw, 'amount'))                         AS amount,
    JSONExtractString(raw, 'name_1')                                    AS name_1,
    JSONExtractString(raw, 'name_2')                                    AS name_2,
    JSONExtractString(raw, 'gender')                                    AS gender,
    JSONExtractString(raw, 'street')                                    AS street,
    JSONExtractString(raw, 'one_city')                                  AS one_city,
    JSONExtractString(raw, 'us_state')                                  AS us_state,
    JSONExtractString(raw, 'post_code')                                 AS post_code,
    toFloat64(JSONExtractString(raw, 'lat'))                            AS lat,
    toFloat64(JSONExtractString(raw, 'lon'))                            AS lon,
    toUInt32(JSONExtractString(raw, 'population_city'))                 AS population_city,
    JSONExtractString(raw, 'jobs')                                      AS jobs,
    toFloat64(JSONExtractString(raw, 'merchant_lat'))                   AS merchant_lat,
    toFloat64(JSONExtractString(raw, 'merchant_lon'))                   AS merchant_lon,
    toUInt8(JSONExtractString(raw, 'target'))                           AS target
FROM transactions_kafka;