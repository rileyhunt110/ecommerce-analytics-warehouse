-- =========================================
-- 03_analytics_views.sql
-- Core analytics views for the E-commerce Warehouse
-- =========================================

-- Drop existing views if re-running during development
DROP VIEW IF EXISTS vw_daily_revenue CASCADE;
DROP VIEW IF EXISTS vw_revenue_by_channel CASCADE;
DROP VIEW IF EXISTS vw_revenue_by_category CASCADE;
DROP VIEW IF EXISTS vw_customer_lifetime_value CASCADE;


-- ===========================
-- 1. Daily Revenue (Completed orders only)
-- ===========================
CREATE VIEW vw_daily_revenue AS
SELECT
    d.date_actual                      AS order_date,
    d.year,
    d.month,
    d.week_of_year,
    SUM(o.order_total)                 AS total_revenue,
    SUM(o.order_subtotal)              AS subtotal_revenue,
    SUM(o.order_tax)                   AS total_tax,
    SUM(o.order_shipping)              AS total_shipping,
    COUNT(*)                           AS order_count
FROM fact_order o
JOIN dim_date d
    ON o.order_date_id = d.date_id
WHERE o.order_status = 'Completed'
GROUP BY
    d.date_actual,
    d.year,
    d.month,
    d.week_of_year
ORDER BY
    d.date_actual;


-- ===========================
-- 2. Revenue by Channel
-- ===========================
CREATE VIEW vw_revenue_by_channel AS
SELECT
    c.channel_name,
    c.channel_group,
    d.year,
    d.month,
    SUM(o.order_total)         AS total_revenue,
    COUNT(*)                   AS order_count,
    AVG(o.order_total)         AS avg_order_value
FROM fact_order o
JOIN dim_date d
    ON o.order_date_id = d.date_id
LEFT JOIN dim_channel c
    ON o.channel_id = c.channel_id
WHERE o.order_status = 'Completed'
GROUP BY
    c.channel_name,
    c.channel_group,
    d.year,
    d.month
ORDER BY
    d.year,
    d.month,
    c.channel_name;


-- ===========================
-- 3. Revenue by Product Category
-- ===========================
CREATE VIEW vw_revenue_by_category AS
SELECT
    p.category,
    p.subcategory,
    d.year,
    d.month,
    SUM(oi.line_total)                 AS line_revenue,
    SUM(oi.quantity)                   AS units_sold,
    COUNT(DISTINCT oi.order_id)        AS orders_with_category
FROM fact_order_item oi
JOIN fact_order o
    ON oi.order_id = o.order_id
JOIN dim_product p
    ON oi.product_id = p.product_id
JOIN dim_date d
    ON o.order_date_id = d.date_id
WHERE o.order_status = 'Completed'
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


-- ===========================
-- 4. Customer Lifetime Value (LTV)
-- ===========================
CREATE VIEW vw_customer_lifetime_value AS
SELECT
    c.customer_id,
    c.customer_key,
    c.first_name,
    c.last_name,
    c.segment,
    c.country,
    c.region,
    c.city,
    MIN(d.date_actual)                AS first_order_date,
    MAX(d.date_actual)                AS last_order_date,
    COUNT(DISTINCT o.order_id)        AS total_orders,
    SUM(o.order_total)                AS total_revenue,
    AVG(o.order_total)                AS avg_order_value
FROM dim_customer c
JOIN fact_order o
    ON o.customer_id = c.customer_id
JOIN dim_date d
    ON o.order_date_id = d.date_id
WHERE o.order_status = 'Completed'
GROUP BY
    c.customer_id,
    c.customer_key,
    c.first_name,
    c.last_name,
    c.segment,
    c.country,
    c.region,
    c.city
ORDER BY
    total_revenue DESC;
