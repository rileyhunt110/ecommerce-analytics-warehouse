-- =========================================
-- 04_example_queries.sql
-- Example analytics queries for portfolio
-- =========================================


/**************************************
 * 1. Revenue by Month (Completed Orders Only)
 **************************************/
SELECT
    d.year,
    d.month,
    SUM(o.order_total) AS total_revenue,
    COUNT(*) AS order_count,
    ROUND(AVG(o.order_total), 2) AS avg_order_value
FROM fact_order o
JOIN dim_date d ON d.date_id = o.order_date_id
WHERE o.order_status = 'Completed'
GROUP BY d.year, d.month
ORDER BY d.year, d.month;


/**************************************
 * 2. Year-over-Year Revenue Growth
 **************************************/
SELECT
    curr.year,
    curr.month,
    curr.total_revenue,
    prev.total_revenue AS prev_year_revenue,
    ROUND(
        100.0 * (curr.total_revenue - prev.total_revenue) / NULLIF(prev.total_revenue, 0),
        2
    ) AS yoy_growth_percent
FROM (
    SELECT
        d.year,
        d.month,
        SUM(o.order_total) AS total_revenue
    FROM fact_order o
    JOIN dim_date d ON d.date_id = o.order_date_id
    WHERE o.order_status = 'Completed'
    GROUP BY d.year, d.month
) curr
LEFT JOIN (
    SELECT
        d.year + 1 AS year,
        d.month,
        SUM(o.order_total) AS total_revenue
    FROM fact_order o
    JOIN dim_date d ON d.date_id = o.order_date_id
    WHERE o.order_status = 'Completed'
    GROUP BY d.year, d.month
) prev
ON curr.year = prev.year AND curr.month = prev.month
ORDER BY curr.year, curr.month;


/**************************************
 * 3. Top 20 Customers by Lifetime Revenue
 **************************************/
SELECT
    customer_key,
    first_name,
    last_name,
    segment,
    total_orders,
    total_revenue,
    avg_order_value
FROM vw_customer_lifetime_value
ORDER BY total_revenue DESC
LIMIT 20;


/**************************************
 * 4. Customer Cohorts by Signup Month
 **************************************/
SELECT
    DATE_TRUNC('month', c.created_date) AS cohort_month,
    d.year,
    d.month,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(o.order_total) AS revenue
FROM dim_customer c
JOIN fact_order o ON o.customer_id = c.customer_id
JOIN dim_date d ON d.date_id = o.order_date_id
WHERE o.order_status = 'Completed'
GROUP BY cohort_month, d.year, d.month
ORDER BY cohort_month, d.year, d.month;


/**************************************
 * 5. Revenue by Channel (Top 10 Months)
 **************************************/
SELECT
    channel_name,
    year,
    month,
    SUM(total_revenue) AS revenue
FROM vw_revenue_by_channel
GROUP BY channel_name, year, month
ORDER BY revenue DESC
LIMIT 10;


/**************************************
 * 6. Best-Selling Products by Revenue
 **************************************/
SELECT
    p.product_name,
    p.category,
    p.subcategory,
    SUM(oi.line_total) AS revenue,
    SUM(oi.quantity) AS units_sold
FROM fact_order_item oi
JOIN dim_product p ON p.product_id = oi.product_id
JOIN fact_order o ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_name, p.category, p.subcategory
ORDER BY revenue DESC
LIMIT 20;


/**************************************
 * 7. Profitability by Product (Revenue - Cost)
 **************************************/
SELECT
    p.product_name,
    p.category,
    p.cost,
    SUM(oi.line_total) AS revenue,
    SUM(oi.quantity * p.cost) AS total_cost,
    SUM(oi.line_total) - SUM(oi.quantity * p.cost) AS gross_profit
FROM fact_order_item oi
JOIN dim_product p ON p.product_id = oi.product_id
JOIN fact_order o ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_name, p.category, p.cost
ORDER BY gross_profit DESC
LIMIT 20;


/**************************************
 * 8. Customer Repeat Rate (How many customers placed >1 order)
 **************************************/
WITH order_counts AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders
    FROM fact_order
    WHERE order_status = 'Completed'
    GROUP BY customer_id
)
SELECT
    COUNT(*) FILTER (WHERE total_orders = 1) AS one_time_customers,
    COUNT(*) FILTER (WHERE total_orders > 1) AS repeat_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE total_orders > 1) / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_rate_percent
FROM order_counts;


/**************************************
 * 9. Order Distribution by Weekday
 **************************************/
SELECT
    d.day_of_week,
    CASE d.day_of_week
         WHEN 1 THEN 'Monday'
         WHEN 2 THEN 'Tuesday'
         WHEN 3 THEN 'Wednesday'
         WHEN 4 THEN 'Thursday'
         WHEN 5 THEN 'Friday'
         WHEN 6 THEN 'Saturday'
         WHEN 7 THEN 'Sunday'
    END AS weekday_name,
    COUNT(*) AS orders
FROM fact_order o
JOIN dim_date d ON d.date_id = o.order_date_id
WHERE o.order_status = 'Completed'
GROUP BY d.day_of_week
ORDER BY d.day_of_week;


/**************************************
 * 10. Average Order Size by Customer Segment
 **************************************/
SELECT
    c.segment,
    COUNT(*) AS total_orders,
    ROUND(AVG(o.order_total), 2) AS avg_order_value,
    SUM(o.order_total) AS total_revenue
FROM fact_order o
JOIN dim_customer c ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.segment
ORDER BY total_revenue DESC;
