{{ config(materialized='table', order_by='category') }}
select
    category,
    count(*) as total_transactions,
    countIf(is_fraud = 1) as fraud_count,
    round(countIf(is_fraud = 1) * 100.0 / count(*), 2) as fraud_rate_percent,
    sumIf(amount, is_fraud = 1) as fraud_amount
from {{ ref('stg_transactions') }}
group by category