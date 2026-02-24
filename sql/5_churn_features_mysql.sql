USE retail_csv;

WITH max_date_cte AS (
SELECT MAX(invoice_date) AS max_date FROM fact_transactions
),
customer_last_cte AS (
SELECT customer_id, MAX(invoice_date) AS last_order_date FROM  fact_transactions GROUP BY customer_id
),
churn_cte AS (
SELECT customer_id, 
CASE WHEN DATEDIFF((SELECT max_date FROM max_date_cte),last_order_date) > 60 THEN 1
ELSE 0
END AS churn_label
FROM customer_last_cte
),
order_level AS (
  SELECT
    customer_id,
    invoice_no,
    MIN(invoice_date) AS order_date,
    SUM(quantity) AS items_in_order,
    SUM(sales) AS revenue_in_order
  FROM fact_transactions
  GROUP BY customer_id, invoice_no
),
intervals AS (
  SELECT
    customer_id,
    DATEDIFF(order_date,
      LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)
    ) AS days_between
  FROM order_level
),
interval_stats AS (
  SELECT
    customer_id,
    AVG(days_between) AS mean_days_between_orders,
    STDDEV_SAMP(days_between) AS std_days_between_orders
  FROM intervals
  WHERE days_between IS NOT NULL
  GROUP BY customer_id
),
last_windows AS (
  SELECT
    f.customer_id,
    SUM(CASE WHEN f.invoice_date >= DATE_SUB((SELECT max_date FROM max_date_cte), INTERVAL 30 DAY) THEN f.sales ELSE 0 END) AS last_30d_revenue,
    SUM(CASE WHEN f.invoice_date >= DATE_SUB((SELECT max_date FROM max_date_cte), INTERVAL 60 DAY) THEN f.sales ELSE 0 END) AS last_60d_revenue,
    SUM(CASE WHEN f.invoice_date >= DATE_SUB((SELECT max_date FROM max_date_cte), INTERVAL 90 DAY) THEN f.sales ELSE 0 END) AS last_90d_revenue,
    AVG(f.sales) AS avg_line_sales
  FROM fact_transactions f
  GROUP BY f.customer_id
),
order_stats AS (
  SELECT
    customer_id,
    AVG(revenue_in_order) AS avg_order_value,
    AVG(items_in_order) AS avg_items_per_order
  FROM order_level
  GROUP BY customer_id
)

UPDATE mart_customer_features m
LEFT JOIN churn_cte c ON m.customer_id = c.customer_id
LEFT JOIN order_stats os ON m.customer_id = os.customer_id
LEFT JOIN interval_stats isx ON m.customer_id = isx.customer_id
LEFT JOIN last_windows lw ON m.customer_id = lw.customer_id
SET
  m.avg_order_value = os.avg_order_value,
  m.avg_items_per_order = os.avg_items_per_order,
  m.mean_days_between_orders = isx.mean_days_between_orders,
  m.std_days_between_orders = isx.std_days_between_orders,
  m.last_30d_revenue = lw.last_30d_revenue,
  m.last_60d_revenue = lw.last_60d_revenue,
  m.last_90d_revenue = lw.last_90d_revenue;

DROP TABLE IF EXISTS churn_labels;
CREATE TABLE churn_labels AS

WITH max_date_cte AS (
	SELECT MAX(invoice_date) AS max_date FROM fact_transactions
),
customer_last_cte AS (
	SELECT customer_id, MAX(invoice_date) AS last_order_date FROM  fact_transactions GROUP BY customer_id
)
SELECT customer_id, 
	CASE WHEN DATEDIFF((SELECT max_date FROM max_date_cte),last_order_date) > 60 THEN 1
	ELSE 0
	END AS churn_label
	FROM customer_last_cte;

select * from churn_labels;