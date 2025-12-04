# ecommerce-analytics-warehouse

# 🛒 E-Commerce Analytics Warehouse

A fully-featured PostgreSQL analytics warehouse designed to simulate the data stack behind a modern e-commerce business.

This project demonstrates:

- Data warehouse schema design (star schema)
- Synthetic data generation for customers, orders, products, and channels
- Advanced SQL analytics (RFM, LTV, Cohorts, Margins, Market Basket)
- A complete Jupyter analytics dashboard with visualizations
- Forecasting + customer segmentation (KMeans)
- Real-world business insights powered by SQL + Python

This repo is built to be a **showcase project for data analysts / data engineers / data scientists**.

---

# 📂 Repository Structure

``` bash
ecommerce-analytics-warehouse/
│
├── sql/
│ ├── 01_schema.sql # Star schema + constraints
│ ├── 02_seed_helpers.sql # Helper functions for synthetic data
│ ├── 03_sample_dimensions.sql # Date + static dimension loading
│ ├── 04_example_queries.sql # Basic warehouse queries
│ ├── 05_advanced_analytics.sql # RFM, LTV, cohorts, margins, basket analysis
│
├── data/
│ └── synthetic/
│ └── generate_data.py # Synthetic data generator (customers/products/orders)
│
├── notebooks/
│ └── analytics.ipynb # Full analytics report with charts
│
├── requirements.txt # Python dependencies
└── README.md # ← You are here
```

markdown
Copy code

---

# 🧱 **1. Warehouse Architecture**

This project uses a **star schema** optimized for analytics:

### **Fact Tables**
| Table | Description |
|-------|-------------|
| `fact_order` | Header-level order information (order totals, status, channel, date) |
| `fact_order_item` | Line-item level detail (product, quantity, price, margin inputs) |

### **Dimension Tables**
| Dim | Description |
|------|-------------|
| `dim_customer` | Customer attributes (demographics, sign-up date, segment) |
| `dim_product` | Product catalog (category, cost, price, attributes) |
| `dim_channel` | Marketing/acquisition channels |
| `dim_date` | Calendar dimension for all date-based analytics |

### **ERD (Entity Relationship Diagram)**

dim_customer ----

fact_order ---- fact_order_item ---- dim_product
dim_channel -----/
dim_date -----/

yaml
Copy code

This design supports efficient analytical queries and can scale to millions of facts.

---

# 🧪 **2. Generating Synthetic Data**

The dataset is generated using:

python data/synthetic/generate_data.py

yaml
Copy code

This script creates:

- **5,000+ customers**
- **100+ products across multiple categories**
- **~3,000 orders and 10,000+ line items**
- Realistic timestamps, segments, prices, discounts, and more

All data is inserted directly into PostgreSQL via psycopg2.

---

# 📊 **3. Advanced Analytics Views**

The warehouse includes a suite of **business-critical SQL views**:

### 🔹 Revenue & Performance Views
- `vw_daily_revenue`
- `vw_revenue_by_channel`
- `vw_revenue_by_category`
- `vw_category_margin_monthly`

### 🔹 Customer Value Models
- `vw_customer_rfm_base`
- `vw_customer_rfm_scores`
- `vw_customer_ltv_segments`

### 🔹 Retention & Cohorts
- `vw_cohort_retention` — monthly cohort churn/retention curves

### 🔹 Product Recommendation Signals
- `vw_product_pairs`
- `vw_product_association_rules`  
  (support, confidence, lift)

These views power the notebook analysis layer.

---

# 📓 **4. Analytics Notebook (analytics.ipynb)**

The `notebooks/analytics.ipynb` file is a fully polished, end-to-end exploratory data analysis report.

It contains:

---

## 📈 **4.1 KPI Dashboard**

- Total revenue  
- Order count  
- Customer count  
- Average Order Value  
- High-level business snapshot  

---

## 📉 **4.2 Revenue Trends**

- Monthly revenue line chart  
- Channel contribution bar chart  
- Category profitability over time  

---

## 👥 **4.3 Customer Value Analytics**

### **RFM Scoring**
- Recency (days since last order)  
- Frequency (order count)  
- Monetary Value (total revenue)  
- Top customers table  
- RFM scatter plot  

### **LTV Segments (Bronze → Platinum)**
- Revenue distribution  
- Customer distribution  

---

## 🔁 **4.4 Cohort Retention Analysis**

- Cohort month definitions  
- Retention heatmap  
- Month-over-month survival curves  

---

## 🛍️ **4.5 Product Insights**

### **Market Basket Analysis (Association Rules)**
- Support  
- Confidence  
- Lift  
- “Frequently bought together” recommendations  

---

## 📅 **4.6 Seasonality**

- Category-by-month heatmap  
- Identification of seasonal product categories  

---

## 📈 **4.7 Sales Forecasting**

- Monthly revenue aggregation  
- 3-month moving average  
- Forward forecast visualization  

---

## 🤖 **4.8 Customer Segmentation (K-Means)**

- Normalized RFM features  
- 4-cluster segmentation  
- Visualization of customer segments  
- Cluster summaries (e.g., VIP, low-value, churn risk)  

---

# ▶️ **5. How to Run the Project**

### **1. Clone the repository**

git clone https://github.com/<your-username>/ecommerce-analytics-warehouse.git
cd ecommerce-analytics-warehouse

shell
Copy code

### **2. Create virtual environment & install dependencies**

python -m venv .venv
.venv/Scripts/activate # Windows
pip install -r requirements.txt

pgsql
Copy code

### **3. Create PostgreSQL database**

Open `psql`:

```sql
CREATE DATABASE ecommerce_warehouse;
\c ecommerce_warehouse
\i sql/01_schema.sql
\i sql/02_seed_helpers.sql
\i sql/03_sample_dimensions.sql
4. Generate the synthetic dataset
bash
Copy code
python data/synthetic/generate_data.py
5. Load advanced analytics views
pgsql
Copy code
\i sql/05_advanced_analytics.sql
6. Open the notebook
bash
Copy code
jupyter notebook notebooks/analytics.ipynb
Run all cells → all visualizations will render.

