import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score, classification_report
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression
from connect_mysql import read_sql, write_df

features = read_sql("""
SELECT
  f.customer_id,
  f.recency_days, f.frequency, f.monetary,
  f.avg_order_value, f.avg_items_per_order,
  f.mean_days_between_orders, f.std_days_between_orders,
  f.last_30d_revenue, f.last_60d_revenue, f.last_90d_revenue,
  f.country,
  l.churn_label
FROM mart_customer_features f
JOIN churn_labels l USING (customer_id);
""")

# basic cleanup
features = features.fillna(0)

X = features.drop(columns=["churn_label"])
y = features["churn_label"]

num_cols = [c for c in X.columns if c not in ["customer_id", "country"]]
cat_cols = ["country"]

preprocess = ColumnTransformer([
    ("num", "passthrough", num_cols),
    ("cat", OneHotEncoder(handle_unknown="ignore"), cat_cols),
])

model = Pipeline([
    ("prep", preprocess),
    ("clf", LogisticRegression(max_iter=2000))
])

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

model.fit(X_train, y_train)
probs = model.predict_proba(X_test)[:, 1]
print("ROC-AUC:", roc_auc_score(y_test, probs))
print(classification_report(y_test, (probs >= 0.5).astype(int)))

# score all customers
all_probs = model.predict_proba(X)[:, 1]
out = pd.DataFrame({
    "customer_id": X["customer_id"],
    "churn_label": y.astype(int),
    "churn_prob": all_probs
})

write_df(out, "mart_customer_churn", if_exists="replace")
