-- =========================================
-- 05_advanced_analytics.sql
-- Advanced analytics views for the E-commerce Warehouse
-- =========================================

-- Drop in dependency-safe order
DROP VIEW IF EXISTS vw_category_margin_monthly CASCADE;
DROP VIEW IF EXISTS vw_product_pairs CASCADE;
DROP VIEW IF EXISTS vw_cohort_retention CASCADE;
DROP VIEW IF EXISTS vw_customer_ltv_segments CASCADE;
DROP VIEW IF EXISTS vw_customer_rfm_scores CASCADE;
DROP VIEW IF EXISTS vw_customer_rfm_base CASCADE;


-- =========================================================
-- 1. Customer RFM (Recency, Frequency, Monetary) base metrics
-- =========================================================
-- recency_days is calculated relative to the max date in dim_date,
-- so it stays stable regardless of "today".
CREATE VIEW vw_customer_rfm_base AS
WITH max_date AS (
    SELECT MAX(date_actual) AS max_date FROM dim_date
)
SELECT
    c.customer_id,
    c.customer_key,
    c.first_name,
    c.last_name,
    c.segment,
    MIN(d.date_actual) AS first_order_date,
    MAX(d.date_actual) AS last_order_date,
    (SELECT max_date FROM max_date) - MAX(d.date_actual) AS recency_days,
    COUNT(DISTINCT o.order_id) AS frequency,
    SUM(o.order_total) AS monetary_value
FROM dim_customer c
JOIN fact_order o
    ON o.customer_id = c.customer_id
   AND o.order_status = 'Completed'
JOIN dim_date d
    ON d.date_id = o.order_date_id
GROUP BY
    c.customer_id,
    c.customer_key,
    c.first_name,
    c.last_name,
    c.segment;


-- =========================================================
-- 2. RFM scores (1–5) and combined code/score
-- =========================================================
-- Higher score is better:
-- - recency_score: 5 = most recent
-- - frequency_score: 5 = most frequent
-- - monetary_score: 5 = highest spend
CREATE VIEW vw_customer_rfm_scores AS
SELECT
    b.customer_id,
    b.customer_key,
    b.first_name,
    b.last_name,
    b.segment,
    b.first_order_date,
    b.last_order_date,
    b.recency_days,
    b.frequency,
    b.monetary_value,
    r_score AS recency_score,
    f_score AS frequency_score,
    m_score AS monetary_score,
    (r_score * 100 + f_score * 10 + m_score) AS rfm_score,
    (r_score::text || f_score::text || m_score::text) AS rfm_code
FROM (
    SELECT
        b.*,
        NTILE(5) OVER (ORDER BY recency_days ASC)  AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC)    AS f_score,
        NTILE(5) OVER (ORDER BY monetary_value DESC) AS m_score
    FROM vw_customer_rfm_base b
) b;


-- =========================================================
-- 3. LTV segments (Bronze/Silver/Gold/Platinum)
-- =========================================================
-- Based on total_revenue from vw_customer_lifetime_value
CREATE VIEW vw_customer_ltv_segments AS
SELECT
    l.*,
    quartile,
    CASE quartile
        WHEN 1 THEN 'Bronze'
        WHEN 2 THEN 'Silver'
        WHEN 3 THEN 'Gold'
        WHEN 4 THEN 'Platinum'
    END AS ltv_segment
FROM (
    SELECT
        l.*,
        NTILE(4) OVER (ORDER BY total_revenue) AS quartile
    FROM vw_customer_lifetime_value l
) l;


-- =========================================================
-- 4. Cohort retention: customers grouped by first order month
-- =========================================================
-- For each cohort_month, shows how many customers are active in each
-- subsequent month and what percent of the cohort that represents.
CREATE VIEW vw_cohort_retention AS
WITH first_orders AS (
    SELECT
        c.customer_id,
        MIN(d.date_actual) AS first_order_date,
        DATE_TRUNC('month', MIN(d.date_actual))::date AS cohort_month
    FROM dim_customer c
    JOIN fact_order o
        ON o.customer_id = c.customer_id
       AND o.order_status = 'Completed'
    JOIN dim_date d
        ON d.date_id = o.order_date_id
    GROUP BY c.customer_id
),
activity AS (
    SELECT
        fo.customer_id,
        fo.cohort_month,
        DATE_TRUNC('month', d.date_actual)::date AS activity_month
    FROM first_orders fo
    JOIN fact_order o
        ON o.customer_id = fo.customer_id
       AND o.order_status = 'Completed'
    JOIN dim_date d
        ON d.date_id = o.order_date_id
),
cohort_stats AS (
    SELECT
        cohort_month,
        activity_month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM activity
    GROUP BY cohort_month, activity_month
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM first_orders
    GROUP BY cohort_month
)
SELECT
    c.cohort_month,
    c.activity_month,
    (
        (EXTRACT(YEAR FROM c.activity_month) - EXTRACT(YEAR FROM c.cohort_month)) * 12
        + (EXTRACT(MONTH FROM c.activity_month) - EXTRACT(MONTH FROM c.cohort_month))
    )::int AS months_since_cohort_start,
    cs.cohort_size,
    c.active_customers,
    ROUND(100.0 * c.active_customers / cs.cohort_size, 2) AS retention_percent
FROM cohort_stats c
JOIN cohort_sizes cs USING (cohort_month)
ORDER BY
    c.cohort_month,
    c.activity_month;


-- =========================================================
-- 5. Product pairs (basket analysis style)
-- =========================================================
-- Products that frequently appear together in the same order.
-- We keep only pairs with at least 5 co-occurrence orders.
CREATE VIEW vw_product_pairs AS
SELECT
    p1.product_id  AS product_id_1,
    p1.product_name AS product_name_1,
    p2.product_id  AS product_id_2,
    p2.product_name AS product_name_2,
    COUNT(DISTINCT oi1.order_id) AS cooccurrence_orders
FROM fact_order_item oi1
JOIN fact_order_item oi2
    ON oi1.order_id = oi2.order_id
   AND oi1.product_id < oi2.product_id
JOIN fact_order o
    ON o.order_id = oi1.order_id
   AND o.order_status = 'Completed'
JOIN dim_product p1
    ON p1.product_id = oi1.product_id
JOIN dim_product p2
    ON p2.product_id = oi2.product_id
GROUP BY
    p1.product_id,
    p1.product_name,
    p2.product_id,
    p2.product_name
HAVING COUNT(DISTINCT oi1.order_id) >= 5
ORDER BY
    cooccurrence_orders DESC;


-- =========================================================
-- 6. Category margin over time (revenue, cost, profit, margin%)
-- =========================================================
CREATE VIEW vw_category_margin_monthly AS
SELECT
    p.category,
    p.subcategory,
    d.year,
    d.month,
    SUM(oi.line_total) AS revenue,
    SUM(oi.quantity * p.cost) AS total_cost,
    SUM(oi.line_total) - SUM(oi.quantity * p.cost) AS gross_profit,
    CASE
        WHEN SUM(oi.line_total) = 0 THEN 0
        ELSE ROUND(
            100.0 * (SUM(oi.line_total) - SUM(oi.quantity * p.cost)) / SUM(oi.line_total),
            2
        )
    END AS gross_margin_percent
FROM fact_order_item oi
JOIN fact_order o
    ON o.order_id = oi.order_id
   AND o.order_status = 'Completed'
JOIN dim_product p
    ON p.product_id = oi.product_id
JOIN dim_date d
    ON d.date_id = o.order_date_id
GROUP BY
    p.category,
    p.subcategory,
    d.year,
    d.month
ORDER BY
    d.year,
    d.month,
    p.category,
    p.subcategory;
