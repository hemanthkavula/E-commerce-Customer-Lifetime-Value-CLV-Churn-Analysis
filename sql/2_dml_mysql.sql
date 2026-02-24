use retail_clv;

INSERT INTO fact_transactions (invoice_no, invoice_ts, invoice_date, customer_id, stock_code, quantity, unit_price, sales, country)
SELECT InvoiceNo, InvoiceDate, DATE(InvoiceDate), CustomerID, StockCode, Quantity, UnitPrice, ROUND(Quantity * UnitPrice, 2) AS sales, Country
FROM stg_retail
WHERE CustomerID IS NOT NULL
  AND Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo IS NOT NULL
  AND InvoiceNo NOT LIKE 'C%';

INSERT INTO dim_customer (customer_id, country, first_purchase_date, last_purchase_date)
SELECT CustomerID, Country, MIN(DATE(InvoiceDate)) AS  first_purchase_date, MAX(DATE(InvoiceDate)) AS last_purchase_date FROM stg_retail GROUP BY CustomerID, Country;

INSERT INTO dim_product (stock_code, description) 
SELECT StockCode, MAX(Description) FROM stg_retail GROUP BY StockCode;

INSERT INTO dim_date (`date_key`, `date`, `year`, `month`, `week`, `day`)
WITH RECURSIVE d AS (
  SELECT DATE(MIN(invoice_date)) AS dt
  FROM fact_transactions
  UNION ALL
  SELECT DATE_ADD(dt, INTERVAL 1 DAY)
  FROM d
  WHERE dt < (SELECT DATE(MAX(invoice_date)) FROM fact_transactions)
)
SELECT
  CAST(DATE_FORMAT(dt, '%Y%m%d') AS UNSIGNED) AS date_key,
  dt AS `date`,
  YEAR(dt) AS `year`,
  MONTH(dt) AS `month`,
  WEEK(dt, 3) AS `week`,
  DAY(dt) AS `day`
FROM d;

INSERT INTO mart_customer_daily(customer_id, date, orders, items, revenue)
SELECT customer_id, invoice_date as date, count(DISTINCT invoice_no) as orders, SUM(quantity) AS items, ROUND(SUM(sales),2) AS revenue FROM fact_transactions GROUP BY customer_id, invoice_date;
