{{ config(materialized='table', order_by='state') }}
select
    state,
    count(*) as total_transactions,
    uniq(merchant_name) as distinct_merchants,
    countIf(is_fraud = 1) as fraud_cases,
    round(countIf(is_fraud = 1) * 100.0 / count(*), 2) as fraud_rate,
    sum(amount) as total_money_lost
from {{ ref('stg_transactions') }}
group by state