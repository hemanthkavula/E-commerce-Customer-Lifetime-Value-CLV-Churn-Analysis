CREATE DATABASE retail_clv;

USE retail_clv;

DROP TABLE IF EXISTS stg_retail;
CREATE TABLE stg_retail (
  InvoiceNo    VARCHAR(20),
  StockCode    VARCHAR(50),
  Description  VARCHAR(255),
  Quantity     INT,
  InvoiceDate  DATETIME,
  UnitPrice    DECIMAL(12,4),
  CustomerID   INT,
  Country      VARCHAR(80)
);

-- Facts
DROP TABLE IF EXISTS fact_transactions;
CREATE TABLE fact_transactions (
  transaction_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  invoice_no     VARCHAR(20),
  invoice_ts     DATETIME,
  invoice_date   DATE,
  customer_id    INT,
  stock_code     VARCHAR(50),
  quantity       INT,
  unit_price     DECIMAL(12,4),
  sales          DECIMAL(14,4),
  country        VARCHAR(80),
  INDEX idx_customer_date (customer_id, invoice_date),
  INDEX idx_invoice (invoice_no),
  INDEX idx_stock (stock_code)
);

-- Dimensions
DROP TABLE IF EXISTS dim_customer;
CREATE TABLE dim_customer (
  customer_id          INT PRIMARY KEY,
  country              VARCHAR(80),
  first_purchase_date  DATE,
  last_purchase_date   DATE
);

DROP TABLE IF EXISTS dim_product;
CREATE TABLE dim_product (
  stock_code   VARCHAR(50) PRIMARY KEY,
  description  VARCHAR(255)
);

DROP TABLE IF EXISTS dim_date;
CREATE TABLE dim_date (
  date_key   INT PRIMARY KEY,     -- YYYYMMDD
  date       DATE UNIQUE,
  year       INT,
  month      INT,
  week       INT,
  day        INT
);

-- Derived marts
DROP TABLE IF EXISTS mart_customer_daily;
CREATE TABLE mart_customer_daily (
  customer_id INT,
  date        DATE,
  orders      INT,
  items       INT,
  revenue     DECIMAL(14,4),
  PRIMARY KEY (customer_id, date)
);

DROP TABLE IF EXISTS mart_customer_features;
CREATE TABLE mart_customer_features (
  customer_id INT PRIMARY KEY,
  recency_days INT,
  frequency INT,
  monetary DECIMAL(14,4),
  avg_order_value DECIMAL(14,4),
  avg_items_per_order DECIMAL(14,4),
  mean_days_between_orders DECIMAL(14,4),
  std_days_between_orders DECIMAL(14,4),
  last_30d_revenue DECIMAL(14,4),
  last_60d_revenue DECIMAL(14,4),
  last_90d_revenue DECIMAL(14,4),
  country VARCHAR(80),
  r_score INT,
  f_score INT,
  m_score INT,
  rfm_score VARCHAR(10),
  segment VARCHAR(50)
);

DROP TABLE IF EXISTS mart_customer_clv;
CREATE TABLE mart_customer_clv (
  customer_id INT PRIMARY KEY,
  clv_6m  DECIMAL(14,4),
  clv_12m DECIMAL(14,4),
  predicted_purchases_6m  DECIMAL(14,4),
  predicted_purchases_12m DECIMAL(14,4),
  predicted_avg_value     DECIMAL(14,4),
  segment VARCHAR(50),
  model_run_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS mart_customer_churn;
CREATE TABLE mart_customer_churn (
  customer_id INT PRIMARY KEY,
  churn_label TINYINT,
  churn_prob  DECIMAL(6,5),
  model_run_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);





