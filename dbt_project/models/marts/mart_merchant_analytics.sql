{{ config(materialized='table', order_by='merchant_name') }}
select
    merchant_name,
    category,
    count(*) as transactions_count,
    sum(amount) as total_revenue,
    countIf(is_fraud = 1) as fraud_count,
    if(count(*) > 10 AND (countIf(is_fraud = 1) / count(*)) > 0.05, 1, 0) as is_suspicious_merchant
from {{ ref('stg_transactions') }}
group by merchant_name, category