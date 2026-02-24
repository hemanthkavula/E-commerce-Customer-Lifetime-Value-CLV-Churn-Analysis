

# Customer Lifetime Value (CLV) & Churn Prediction  
### End-to-End Customer Analytics Pipeline (MySQL + Python)

Built a production-style customer analytics system to segment users, predict future revenue, and identify churn risk using transactional e-commerce data (Online Retail II).

---

## 🚀 Project Highlights

- Designed a **star schema data warehouse** in MySQL
- Engineered RFM and behavioral features using advanced SQL (CTEs, window functions)
- Implemented **probabilistic CLV modeling (BG/NBD + Gamma-Gamma)**
- Built a **churn prediction model (Logistic Regression)**
- Generated an actionable customer targeting file for marketing teams
- Delivered a complete SQL → ML → Business workflow

---

## 📊 Business Objective

Help an e-commerce company answer:

- Who are our most valuable customers?
- How much revenue will each customer generate in the next 6–12 months?
- Which customers are at risk of churn?
- Where should we focus retention budget?

---

## 🏗 Architecture

**Database (MySQL)**  
- Fact table: `fact_transactions`  
- Dimensions: customer, product, date  
- Analytics marts:
  - `mart_customer_features`
  - `mart_customer_clv`
  - `mart_customer_churn`

**Python Modeling Layer**
- pandas for transformation
- lifetimes for CLV
- scikit-learn for churn prediction

---

## 📈 RFM Segmentation

Computed using SQL:

- Recency (days since last purchase)
- Frequency (invoice count)
- Monetary (total revenue)

Customers bucketed into:
Champions | Loyal | Potential Loyalists | At Risk | Lost

---

## 💰 CLV Modeling

Used probabilistic models:

- **BG/NBD** → predicts future purchase frequency
- **Gamma-Gamma** → predicts expected order value

CLV Formula:

CLV = Expected Purchases × Expected Average Order Value

Generated:
- 6-month CLV
- 12-month CLV
- Predicted purchase counts
- Predicted monetary value

---

## 🔮 Churn Prediction

Churn defined as:

No purchase in the last 60 days.

Features used:
- RFM metrics
- Order value statistics
- Purchase interval behavior
- Recent 30/60/90 day revenue
- Country

Model:
- Logistic Regression baseline
- Evaluated using ROC-AUC, precision, recall

Output:
- Customer-level churn probability

---

## 🎯 Business Impact

Combined CLV + churn probability to create a retention playbook:

- High CLV + High Churn → Immediate intervention
- High CLV + Low Churn → Loyalty rewards
- Low CLV + High Churn → Cost-efficient winback
- New Customers → Onboarding nurture

Final output:
`excel/retention_target_list.xlsx`

---

## 🧠 Key Skills Demonstrated

- Data warehousing & star schema design
- Advanced SQL (window functions, NTILE, CTEs)
- Feature engineering
- Probabilistic customer lifetime modeling
- Classification modeling
- Business translation of ML outputs

---

## ⚙ How to Run

1. Run SQL scripts in order (DDL → Cleaning → RFM → Churn features)
2. Install Python dependencies:
