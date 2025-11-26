{{ config(materialized='table', order_by='transaction_date') }}
select
    toDate(transaction_time) as transaction_date,
    state,
    count(*) as total_transactions,
    sum(amount) as total_amount,
    avg(amount) as avg_check,
    quantile(0.95)(amount) as p95_amount,
    countIf(amount_segment = 'large' OR amount_segment = 'extra_large') as large_transactions_count
from {{ ref('stg_transactions') }}
group by transaction_date, state