SELECT
    us_state,
    argMax(cat_id, amount) as category_of_max_tx_by_state,
    max(amount) as max_amount
FROM transactions
GROUP BY us_state
ORDER BY max_amount;