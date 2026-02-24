Customer Lifetime Value (CLV) and Churn Prediction

Using MySQL and Python on the Online Retail II Dataset

Project Overview

This project builds an end-to-end customer analytics pipeline to:

Segment customers using RFM analysis

Predict Customer Lifetime Value (6 and 12 months)

Identify customers at risk of churn

Generate an actionable retention targeting list

The project demonstrates database design, SQL analytics, feature engineering, probabilistic CLV modeling, and churn prediction using machine learning.

Tech Stack

Database: MySQL (Workbench)
Language: Python
Libraries: pandas, numpy, matplotlib, scikit-learn, lifetimes
Output: Excel targeting file

Business Problem

An e-commerce company wants to:

Identify high-value customers.

Predict future customer revenue contribution.

Detect churn risk early.

Allocate marketing budget more effectively.

The objective is to combine SQL analytics and predictive modeling to support data-driven retention strategy.

Dataset

Online Retail II transactional dataset containing:

InvoiceNo

StockCode

Description

Quantity

InvoiceDate

UnitPrice

CustomerID

Country

Each row represents a purchased product line.

Data Cleaning Decisions

The dataset contains cancellations and invalid entries.

The following filters were applied:

CustomerID IS NOT NULL

Quantity > 0

UnitPrice > 0

InvoiceNo NOT LIKE 'C%' (removed cancellations)

Derived fields created:

sales = Quantity × UnitPrice

invoice_date (DATE format)

monthly cohort identifiers

These rules ensure only valid revenue-generating transactions are used for modeling.

Database Architecture (Star Schema)

Staging:

stg_retail (raw imported CSV)

Fact Table:

fact_transactions (cleaned transactional data)

Dimension Tables:

dim_customer

dim_product

dim_date

Analytics Marts:

mart_customer_daily

mart_customer_features

mart_customer_clv

mart_customer_churn

This separation supports scalable analytics and modeling.

Exploratory Data Analysis

Performed in Python:

Monthly revenue trend

Top countries by revenue

Percentage of returning customers

Order value distribution

Revenue concentration analysis

Key observations:

A small percentage of customers contribute a large portion of revenue.

Returning customers generate significantly higher total spend.

Revenue shows periodic spikes suggesting seasonal behavior.

Cohort Retention Analysis

Customers were grouped by first purchase month.

Retention Rate = Active Customers in Month N / Customers in Cohort Month

This analysis highlights how quickly customers drop off after acquisition and identifies stronger acquisition periods.

RFM Segmentation

RFM metrics were computed using SQL:

Recency = Days since last purchase
Frequency = Number of distinct invoices
Monetary = Total revenue

Customers were scored using NTILE(5) and grouped into:

Champions

Loyal

Potential Loyalists

At Risk

Lost

Need Attention

This provides interpretable marketing segments.

Customer Lifetime Value (CLV) Modeling

Probabilistic models were implemented using the lifetimes library.

Models used:

BG/NBD to predict expected future purchases

Gamma-Gamma to predict expected average order value

CLV formula:

CLV = Expected Purchases × Expected Average Order Value

Outputs generated:

clv_6m

clv_12m

predicted_purchases_6m

predicted_purchases_12m

predicted_avg_value

Results are stored in mart_customer_clv.

Churn Prediction Model

Churn Definition:

Customer is labeled churned if no purchase in the last 60 days.

Features used:

RFM metrics

Average order value

Average items per order

Purchase interval mean and standard deviation

Revenue in last 30, 60, and 90 days

Country

Model:

Logistic Regression baseline

Evaluated using ROC-AUC, precision, recall, and confusion matrix

Output:

churn_prob (probability of churn per customer)

Results are stored in mart_customer_churn.

Business Targeting Strategy

Customers are prioritized using CLV and churn probability.

High CLV + High Churn Risk → Immediate retention campaign
High CLV + Low Churn Risk → Loyalty rewards
Low CLV + High Churn Risk → Low-cost winback
New Customers → Onboarding strategy

Final output exported to:

excel/retention_target_list.xlsx

The file includes:

CustomerID
Country
Segment
CLV_12m
Churn_Prob
Recommended_Action

How to Run the Project

Step 1 — Database Setup

Run SQL scripts in this order:

01_ddl_mysql.sql

Import CSV into stg_retail using MySQL Workbench

02_load_clean_mysql.sql

04_rfm_segmentation_mysql.sql

05_churn_features_mysql.sql

Step 2 — Python Setup

Install dependencies:

pip install pandas numpy matplotlib scikit-learn lifetimes sqlalchemy mysql-connector-python openpyxl

Run notebooks in order:

EDA

CLV modeling

Churn modeling

Excel export

Key Learnings

Star schema design improves analytics workflow.

SQL window functions are powerful for segmentation.

Probabilistic CLV models provide stronger forecasting than simple averages.

Combining CLV with churn probability enables intelligent marketing prioritization.

Future Improvements

Implement XGBoost for churn prediction

Hyperparameter tuning

SHAP feature importance for explainability

Deploy as a Flask API

Add dashboard visualization

Author

Your Name
LinkedIn: Your LinkedIn
Portfolio: Your Portfolio

