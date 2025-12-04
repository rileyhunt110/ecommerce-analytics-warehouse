# ecommerce-analytics-warehouse

# E-Commerce Analytics Warehouse

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

# Repository Structure

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

# **1. Warehouse Architecture**

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


This design supports efficient analytical queries and can scale to millions of facts.

---

# **2. Generating Synthetic Data**

The dataset is generated using:

python data/synthetic/generate_data.py

This script creates:

- **5,000+ customers**
- **100+ products across multiple categories**
- **~3,000 orders and 10,000+ line items**
- Realistic timestamps, segments, prices, discounts, and more

All data is inserted directly into PostgreSQL via psycopg2.

---

# **3. Advanced Analytics Views**

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

# **4. Analytics Notebook (analytics.ipynb)**

The `notebooks/analytics.ipynb` file is a fully polished, end-to-end exploratory data analysis report.

It contains:

---

## **4.1 KPI Dashboard**

- Total revenue  
- Order count  
- Customer count  
- Average Order Value  
- High-level business snapshot  

---

## **4.2 Revenue Trends**

- Monthly revenue line chart  
- Channel contribution bar chart  
- Category profitability over time  

---

## **4.3 Customer Value Analytics**

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

## **4.4 Cohort Retention Analysis**

- Cohort month definitions  
- Retention heatmap  
- Month-over-month survival curves  

---

## **4.5 Product Insights**

### **Market Basket Analysis (Association Rules)**
- Support  
- Confidence  
- Lift  
- “Frequently bought together” recommendations  

---

## **4.6 Seasonality**

- Category-by-month heatmap  
- Identification of seasonal product categories  

---

## **4.7 Sales Forecasting**

- Monthly revenue aggregation  
- 3-month moving average  
- Forward forecast visualization  

---

## **4.8 Customer Segmentation (K-Means)**

- Normalized RFM features  
- 4-cluster segmentation  
- Visualization of customer segments  
- Cluster summaries (e.g., VIP, low-value, churn risk)  

---

# **5. How to Run the Project**

This section walks through everything needed to install PostgreSQL, set up authentication, generate the synthetic dataset, load the warehouse schema, and run the analytics notebook.

## **5.1 Setting Up a PostgreSQL Password**

Before running this project, PostgreSQL must have a valid password for the postgres superuser.

If you don’t know your password or haven’t set one, choose one of the methods below.

Open a terminal (PowerShell, Bash, etc.):

psql -U postgres


Inside the PostgreSQL shell:

ALTER USER postgres PASSWORD 'your_password_here';
\q


If you don't know your password and cannot log in, try:

psql -U postgres --no-password


If it still fails, use Method 2.

Method 2 — Reset Password Using "trust" Mode (If Locked Out)

Locate PostgreSQL’s configuration directory.

### Windows default:

C:\Program Files\PostgreSQL\<version>\data\


Open pg_hba.conf as Administrator.

Find:

host    all    all    127.0.0.1/32    scram-sha-256


Change to:

host    all    all    127.0.0.1/32    trust


Restart PostgreSQL:

### Windows:

net stop postgresql-x64-14
net start postgresql-x64-14


Log in without a password:

psql -U postgres


Reset the password:

ALTER USER postgres PASSWORD 'your_new_password';


Revert pg_hba.conf back to scram-sha-256.

Restart PostgreSQL again.

Method 3 — Set Password Using pgAdmin (GUI Option)

Open pgAdmin

Navigate to:

Servers → PostgreSQL → Login/Group Roles → postgres


Right-click → Properties

Go to Definition

Set a new password

Save

Using Your Password in This Project

To avoid hard-coding passwords, this project uses environment variables:

### Windows PowerShell:
setx PG_PASSWORD "your_password_here"

### macOS / Linux (.bashrc or .zshrc):
export PG_PASSWORD="your_password_here"

Notebook Configuration (analytics.ipynb):
import os

DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "dbname": "ecommerce_warehouse",
    "user": "postgres",
    "password": os.getenv("PG_PASSWORD"),
}

## **5.2 Clone the Repository**
git clone https://github.com/<your-username>/ecommerce-analytics-warehouse.git
cd ecommerce-analytics-warehouse

## **5.3 Create a Virtual Environment & Install Dependencies**
python -m venv .venv


### Windows:

.venv\Scripts\activate


### macOS/Linux:

source .venv/bin/activate


Install dependencies:

pip install -r requirements.txt

## **5.4 Create the PostgreSQL Database**

Open psql:

psql -U postgres


Then run:

CREATE DATABASE ecommerce_warehouse;
\c ecommerce_warehouse
\i sql/01_schema.sql
\i sql/02_seed_helpers.sql
\i sql/03_sample_dimensions.sql

## **5.5 Generate Synthetic Data**
python data/synthetic/generate_data.py


This populates all fact and dimension tables.

## **5.6 Load Advanced Analytics Views**
\i sql/05_advanced_analytics.sql

## **5.7 Open the Analytics Notebook**
jupyter notebook notebooks/analytics.ipynb


Run all cells → all charts and analytics will render.
