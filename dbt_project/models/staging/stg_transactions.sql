{{ config(materialized='view') }}

with source as (
    select * from {{ source('transactions_source', 'transactions') }}
),
renamed as (
    select
        toDateTime(transaction_time) as transaction_time,
        toString(merch) as merchant_name,
        toString(cat_id) as category,
        toFloat64(amount) as amount,
        {{ amount_bucket('amount') }} as amount_segment,
        toString(name_1) as first_name,
        toString(name_2) as last_name,
        toString(gender) as gender,
        toString(us_state) as state,
        toFloat64(lat) as lat,
        toFloat64(lon) as lon,
        toUInt8(target) as is_fraud
    from source
)
select * from renamed