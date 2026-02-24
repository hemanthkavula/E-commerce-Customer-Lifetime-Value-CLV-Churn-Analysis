import pandas as pd
import matplotlib.pyplot as plt
from connect_mysql import read_sql

df = read_sql("SELECT * FROM fact_transactions;")
print(df.shape)
print(df.head())

# Revenue trend by month
df["invoice_month"] = pd.to_datetime(df["invoice_date"]).dt.to_period("M").astype(str)
monthly = df.groupby("invoice_month")["sales"].sum().reset_index()

plt.figure()
plt.plot(monthly["invoice_month"], monthly["sales"])
plt.xticks(rotation=60)
plt.title("Monthly Revenue Trend")
plt.tight_layout()
plt.show()

# Top countries by revenue
top_countries = df.groupby("country")["sales"].sum().sort_values(ascending=False).head(10)
print(top_countries)

# % returning customers
orders_per_customer = df.groupby("customer_id")["invoice_no"].nunique()
returning_pct = (orders_per_customer.gt(1).mean() * 100)
print("Returning customers %:", round(returning_pct, 2))
