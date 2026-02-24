import pandas as pd
from connect_mysql import read_sql
import os

# project root (one level above notebooks)
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
EXCEL_DIR = os.path.join(PROJECT_ROOT, "excel")

# make sure folder exists
os.makedirs(EXCEL_DIR, exist_ok=True)

OUTPUT_PATH = os.path.join(EXCEL_DIR, "retention_target_list.xlsx")

df = read_sql("""
WITH clv_ranked AS (
  SELECT
    customer_id,
    clv_12m,
    NTILE(5) OVER (ORDER BY clv_12m) AS clv_quintile
  FROM mart_customer_clv
)
SELECT
  f.customer_id AS CustomerID,
  f.country AS Country,
  f.segment AS Segment,
  c.clv_12m AS CLV_12m,
  ch.churn_prob AS Churn_Prob,
  CASE
    WHEN cr.clv_quintile = 5 AND ch.churn_prob >= 0.6 THEN 'URGENT retention outreach'
    WHEN cr.clv_quintile = 5 AND ch.churn_prob < 0.6 THEN 'Loyalty / VIP rewards'
    WHEN cr.clv_quintile < 5 AND ch.churn_prob >= 0.6 THEN 'Low-cost winback'
    ELSE 'Onboarding / nurture'
  END AS Recommended_Action
FROM mart_customer_features f
JOIN mart_customer_clv c     ON f.customer_id = c.customer_id
JOIN mart_customer_churn ch  ON f.customer_id = ch.customer_id
JOIN clv_ranked cr           ON f.customer_id = cr.customer_id;
""")

print("Rows exported:", len(df))
print("Saving to:", OUTPUT_PATH)

df.to_excel(OUTPUT_PATH, index=False)

print("✅ Excel file saved successfully")
