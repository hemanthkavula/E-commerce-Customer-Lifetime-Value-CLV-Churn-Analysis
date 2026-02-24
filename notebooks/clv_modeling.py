import warnings
import numpy as np
import pandas as pd

from lifetimes.utils import summary_data_from_transaction_data
from lifetimes import BetaGeoFitter, GammaGammaFitter
from lifetimes.utils import ConvergenceError

from connect_mysql import read_sql, write_df

warnings.filterwarnings("ignore", category=RuntimeWarning)

# 1) Read clean transactions (invoice-level sales already computed in SQL)
tx = read_sql("""
SELECT customer_id, invoice_date, invoice_no, sales
FROM fact_transactions
WHERE customer_id IS NOT NULL
  AND sales > 0
  AND invoice_no IS NOT NULL
  AND invoice_date IS NOT NULL;
""")

tx["invoice_date"] = pd.to_datetime(tx["invoice_date"])

# 2) Build invoice-level "transaction value" (lifetimes expects one row per transaction)
order_values = (
    tx.groupby(["customer_id", "invoice_no", "invoice_date"], as_index=False)["sales"]
      .sum()
      .rename(columns={"sales": "order_value"})
)

obs_end = order_values["invoice_date"].max()

summary = summary_data_from_transaction_data(
    order_values,
    customer_id_col="customer_id",
    datetime_col="invoice_date",
    monetary_value_col="order_value",
    observation_period_end=obs_end,
    freq="D"
)

# 3) CLEAN SUMMARY to avoid BG/NBD convergence issues
# Remove degenerate rows: T=0 or invalid relationships
summary = summary[
    (summary["T"] > 0) &
    (summary["recency"] >= 0) &
    (summary["T"] >= summary["recency"])
].copy()

# Optional but highly recommended: trim extreme outliers that destabilize optimization
# (especially Online Retail — a few customers can dominate)
summary = summary[summary["frequency"] <= summary["frequency"].quantile(0.995)]
summary = summary[summary["monetary_value"] <= summary["monetary_value"].quantile(0.995)]

# Quick diagnostics (keeps you sane)
print(summary[["frequency", "recency", "T", "monetary_value"]].describe())
print("Rows after cleaning:", len(summary))
print("T==0:", int((summary["T"] == 0).sum()))
print("Any T<recency:", int((summary["T"] < summary["recency"]).sum()))

# 4) Fit BG/NBD (use stronger penalizer for stability)
bgf = BetaGeoFitter(penalizer_coef=0.1)

try:
    bgf.fit(summary["frequency"], summary["recency"], summary["T"])
except ConvergenceError:
    # fallback: even stronger regularization
    bgf = BetaGeoFitter(penalizer_coef=1.0)
    bgf.fit(summary["frequency"], summary["recency"], summary["T"])

print("BG/NBD params:", bgf.params_)

# 5) Fit Gamma-Gamma (ONLY repeat customers: frequency > 0)
gg_data = summary[(summary["frequency"] > 0) & (summary["monetary_value"] > 0)].copy()

# If very few repeat customers, Gamma-Gamma can be unstable. Guard it.
use_gg = len(gg_data) >= 50

if use_gg:
    gg = GammaGammaFitter(penalizer_coef=0.1)
    gg.fit(gg_data["frequency"], gg_data["monetary_value"])
    summary["predicted_avg_value"] = gg.conditional_expected_average_profit(
        summary["frequency"].clip(lower=0),
        summary["monetary_value"].clip(lower=1e-6)
    )
else:
    # fallback: use historical monetary_value as expected value
    summary["predicted_avg_value"] = summary["monetary_value"]
    print("Warning: Not enough repeat customers for Gamma-Gamma. Using monetary_value fallback.")

# 6) Predict purchases and CLV
summary["pred_purchases_6m"]  = bgf.predict(30 * 6,  summary["frequency"], summary["recency"], summary["T"])
summary["pred_purchases_12m"] = bgf.predict(30 * 12, summary["frequency"], summary["recency"], summary["T"])

summary["clv_6m"]  = summary["pred_purchases_6m"]  * summary["predicted_avg_value"]
summary["clv_12m"] = summary["pred_purchases_12m"] * summary["predicted_avg_value"]

clv_out = summary.reset_index()[[
    "customer_id",
    "clv_6m", "clv_12m",
    "pred_purchases_6m", "pred_purchases_12m",
    "predicted_avg_value"
]].copy()

# 7) Merge segment
seg = read_sql("SELECT customer_id, segment FROM mart_customer_features;")
clv_out = clv_out.merge(seg, on="customer_id", how="left")

# 8) Write back to MySQL mart_customer_clv
clv_out = clv_out.rename(columns={
    "pred_purchases_6m": "predicted_purchases_6m",
    "pred_purchases_12m": "predicted_purchases_12m"
})

write_df(clv_out, "mart_customer_clv", if_exists="replace")
print("Saved: mart_customer_clv  | rows:", len(clv_out))
