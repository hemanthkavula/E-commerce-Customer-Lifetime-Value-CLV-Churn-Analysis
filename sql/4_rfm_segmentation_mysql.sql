INSERT INTO mart_customer_features (
  customer_id,
  recency_days,
  frequency,
  monetary,
  country,
  r_score,
  f_score,
  m_score,
  rfm_score,
  segment,
  avg_order_value,
  avg_items_per_order,
  mean_days_between_orders,
  std_days_between_orders,
  last_30d_revenue,
  last_60d_revenue,
  last_90d_revenue
)
WITH max_date_cte AS (
SELECT max(invoice_date) AS max_date FROM fact_transactions
),
rfm_cte AS (
SELECT customer_id, DATEDIFF((SELECT max_date FROM max_date_cte), MAX(invoice_date)) AS recency_days, COUNT(DISTINCT invoice_no) AS frequency, SUM(sales) AS monetary, MAX(country) AS country FROM fact_transactions GROUP BY customer_id
),
rfm_score_cte AS(
SELECT *, NTILE(5) OVER(ORDER BY recency_days DESC) AS r_score, NTILE(5) OVER(ORDER BY frequency) AS f_score, NTILE(5) OVER(ORDER BY monetary) AS m_score FROM rfm_cte
)
SELECT customer_id, recency_days, frequency, monetary, country, r_score, f_score, m_score, CONCAT(r_score, f_score, m_score) AS rfm_score, 
CASE
    WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
    WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal'
    WHEN r_score >= 3 AND f_score >= 3 THEN 'Potential Loyalists'
    WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
    WHEN r_score = 1 AND f_score <= 2 THEN 'Lost'
    ELSE 'Need Attention'
  END AS segment,
  -- placeholders (filled in churn features step) to avoid nulls later
  NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM rfm_score_cte
ON DUPLICATE KEY UPDATE
  recency_days=VALUES(recency_days),
  frequency=VALUES(frequency),
  monetary=VALUES(monetary),
  country=VALUES(country),
  r_score=VALUES(r_score),
  f_score=VALUES(f_score),
  m_score=VALUES(m_score),
  rfm_score=VALUES(rfm_score),
  segment=VALUES(segment);
  
select * from mart_customer_features;
  