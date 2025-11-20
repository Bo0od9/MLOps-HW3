CREATE TABLE transactions_kafka
(
    raw String
) ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka:29092',
    kafka_topic_list = 'transactions',
    kafka_group_name = 'transactions_clickhouse_opt',
    kafka_num_consumers = 1,
    kafka_format = 'JSONAsString';

CREATE TABLE transactions
(
    transaction_time    DateTime CODEC(DoubleDelta, ZSTD),
    merch               LowCardinality(String) CODEC(ZSTD),
    cat_id              LowCardinality(String) CODEC(ZSTD),
    amount              Float64 CODEC(ZSTD),
    name_1              String CODEC(ZSTD),
    name_2              String CODEC(ZSTD),
    gender              FixedString(1) CODEC(ZSTD),
    street              String CODEC(ZSTD),
    one_city            LowCardinality(String) CODEC(ZSTD),
    us_state            FixedString(2) CODEC(ZSTD),
    post_code           String CODEC(ZSTD),
    lat                 Float64 CODEC(ZSTD),
    lon                 Float64 CODEC(ZSTD),
    population_city     UInt32 CODEC(DoubleDelta, ZSTD),
    jobs                LowCardinality(String) CODEC(ZSTD),
    merchant_lat        Float64 CODEC(ZSTD),
    merchant_lon        Float64 CODEC(ZSTD),
    target              UInt8 CODEC(ZSTD)
) ENGINE = MergeTree
PARTITION BY toYYYYMM(transaction_time)
ORDER BY (us_state, transaction_time, cat_id, amount);

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
