-- SQLite-compatible customer retention analysis
-- Observation window: 2024-01-01 through 2025-12-31.
-- Repeat purchase rate = customers with >=2 orders / customers with >=1 order.
-- Cohort month is the month of FIRST PURCHASE, not signup.

-- 1. Customer-level metrics using CTEs and LEFT JOIN
WITH customer_metrics AS (
 SELECT c.customer_id,c.acquisition_channel,c.region,
        COUNT(o.order_id) AS order_count,
        COALESCE(ROUND(SUM(o.order_amount),2),0) AS lifetime_revenue
 FROM customers c LEFT JOIN orders o ON c.customer_id=o.customer_id
 GROUP BY c.customer_id,c.acquisition_channel,c.region
)
SELECT acquisition_channel,
 COUNT(*) AS acquired_customers,
 SUM(CASE WHEN order_count>=1 THEN 1 ELSE 0 END) AS purchasing_customers,
 SUM(CASE WHEN order_count>=2 THEN 1 ELSE 0 END) AS repeat_customers,
 ROUND(100.0*SUM(CASE WHEN order_count>=2 THEN 1 ELSE 0 END)/
 NULLIF(SUM(CASE WHEN order_count>=1 THEN 1 ELSE 0 END),0),1) AS repeat_purchase_pct,
 ROUND(SUM(lifetime_revenue),2) AS total_revenue
FROM customer_metrics GROUP BY acquisition_channel ORDER BY repeat_purchase_pct DESC;

-- 2. Rank customers by spend using a window function
WITH spending AS (
 SELECT c.customer_id,c.acquisition_channel,COUNT(o.order_id) AS orders,
        ROUND(COALESCE(SUM(o.order_amount),0),2) AS revenue
 FROM customers c LEFT JOIN orders o ON c.customer_id=o.customer_id
 GROUP BY c.customer_id,c.acquisition_channel
)
SELECT *, DENSE_RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM spending ORDER BY revenue DESC LIMIT 20;

-- 3. Monthly first-purchase cohorts and month-1 retention
-- Month-1 retention = share of first-time purchasers ordering again
-- in the NEXT calendar month (not any time after first purchase).
WITH first_purchase AS (
 SELECT customer_id,MIN(order_date) AS first_date FROM orders GROUP BY customer_id
),
cohorts AS (
 SELECT customer_id,substr(first_date,1,7) AS cohort_month,
        CAST(strftime('%Y',first_date) AS INT)*12+CAST(strftime('%m',first_date) AS INT) AS cohort_index
 FROM first_purchase
),
activity AS (
 SELECT DISTINCT o.customer_id,
        CAST(strftime('%Y',o.order_date) AS INT)*12+CAST(strftime('%m',o.order_date) AS INT) AS activity_index
 FROM orders o
)
SELECT c.cohort_month,COUNT(*) AS cohort_customers,
 SUM(CASE WHEN a.activity_index IS NOT NULL THEN 1 ELSE 0 END) AS retained_month_1,
 ROUND(100.0*SUM(CASE WHEN a.activity_index IS NOT NULL THEN 1 ELSE 0 END)/COUNT(*),1) AS retention_pct
FROM cohorts c LEFT JOIN activity a ON a.customer_id=c.customer_id AND a.activity_index=c.cohort_index+1
WHERE c.cohort_month<'2025-12'
GROUP BY c.cohort_month ORDER BY c.cohort_month;

-- 4. Months between purchases using LAG
WITH gaps AS (
 SELECT customer_id,order_date,
 LAG(order_date) OVER(PARTITION BY customer_id ORDER BY order_date,order_id) AS previous_order
 FROM orders
)
SELECT ROUND(AVG(julianday(order_date)-julianday(previous_order)),1) AS avg_days_between_orders
FROM gaps WHERE previous_order IS NOT NULL;
