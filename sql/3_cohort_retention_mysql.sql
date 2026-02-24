USE retail_clv;

WITH customer_first AS (
  SELECT
    customer_id,
    DATE_FORMAT(MIN(invoice_date), '%Y-%m-01') AS cohort_month
  FROM fact_transactions
  GROUP BY customer_id
),
activity AS (
  SELECT
    f.customer_id,
    DATE_FORMAT(f.invoice_date, '%Y-%m-01') AS activity_month,
    cf.cohort_month
  FROM fact_transactions f
  JOIN customer_first cf ON f.customer_id = cf.customer_id
  GROUP BY f.customer_id, DATE_FORMAT(f.invoice_date, '%Y-%m-01'), cf.cohort_month
),
cohort_indexed AS (
  SELECT
    cohort_month,
    activity_month,
    TIMESTAMPDIFF(MONTH, cohort_month, activity_month) AS month_number,
    COUNT(DISTINCT customer_id) AS active_customers
  FROM activity
  GROUP BY cohort_month, activity_month, month_number
),
cohort_size AS (
  SELECT
    cohort_month,
    MAX(active_customers) AS cohort_size
  FROM cohort_indexed
  WHERE month_number = 0
  GROUP BY cohort_month
)
SELECT
  ci.cohort_month,
  ci.month_number,
  ci.active_customers,
  cs.cohort_size,
  ROUND(ci.active_customers / cs.cohort_size, 4) AS retention_rate
FROM cohort_indexed ci
JOIN cohort_size cs USING (cohort_month)
ORDER BY ci.cohort_month, ci.month_number;
