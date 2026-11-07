-- 1. Customer order volume share (Window function)

WITH client_orders AS (
    SELECT
        c.customer_id,
        c.name AS customer_name,
        c.city,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM Customers c
    LEFT JOIN Order_Lines o 
        ON c.customer_id = o.customer_id
    GROUP BY 
        c.customer_id, 
        c.name, 
        c.city
)
SELECT
    customer_id,
    customer_name,
    city,
    total_orders,
    ROUND(total_orders * 100.0 / SUM(total_orders) OVER (), 2) AS order_share_pct
FROM client_orders
ORDER BY total_orders DESC;



-- 2. Hardware run-rate in Flagship stores (April 2023)

SELECT
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    COUNT(DISTINCT o.order_id)    AS total_transactions
FROM Order_Lines o
INNER JOIN Products p 
    ON o.product_id = p.product_id
WHERE o.order_channel = 'Flagship Store'
  AND p.product_type = 'Machine'
  AND o.date >= '2023-04-01'
  AND o.date < '2023-05-01';



-- 3. Trailing 90-day Limited Edition sales in Kyiv

SELECT 
    COUNT(*)                                            AS units_sold,
    COALESCE(SUM(o.price - COALESCE(o.discount, 0)), 0) AS net_revenue
FROM Order_Lines o
INNER JOIN Customers c 
    ON o.customer_id = c.customer_id
INNER JOIN Products p 
    ON o.product_id = p.product_id
WHERE LOWER(c.city) = 'kyiv'
  AND p.product_name LIKE '%Limited%'
  AND o.date >= (SELECT MAX(date) - INTERVAL '90 days' FROM Order_Lines);



-- 4. Monthly gross/net revenue & discount exposure (Order-Level Grain)

WITH order_level_metrics AS (
    SELECT 
        order_id,
        DATE_TRUNC('month', MAX(date))::DATE AS sales_month,
        SUM(price)                           AS order_gross_revenue,
        SUM(COALESCE(discount, 0))           AS order_total_discount
    FROM Order_Lines
    GROUP BY order_id
)
SELECT 
    sales_month,
    SUM(order_gross_revenue)                        AS gross_revenue,
    SUM(order_gross_revenue - order_total_discount) AS net_revenue,
    COUNT(CASE WHEN order_total_discount = 0 THEN order_id END) AS full_price_orders,
    COUNT(CASE WHEN order_total_discount > 0 THEN order_id END) AS discounted_orders
FROM order_level_metrics
GROUP BY sales_month
ORDER BY sales_month;



-- 5. Consumable attachment rate (Orders with pods vs total orders)

SELECT
    ROUND(
        COUNT(DISTINCT CASE WHEN p.product_type = 'Consumables' THEN o.order_id END) * 100.0
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS pods_attachment_pct
FROM Order_Lines o
LEFT JOIN Products p 
    ON o.product_id = p.product_id;



-- 6. Cohort inactivity: Lapsed in Flagship (>180d) but active in Retail (3+ orders)

WITH flagship_active AS (
    SELECT DISTINCT 
        customer_id
    FROM Order_Lines
    WHERE order_channel = 'Flagship Store'
      AND date >= (SELECT MAX(date) - INTERVAL '180 days' FROM Order_Lines)
)
SELECT
    c.customer_id,
    c.name,
    COUNT(DISTINCT o.order_id) AS retail_transactions
FROM Customers c
INNER JOIN Order_Lines o 
    ON c.customer_id = o.customer_id
LEFT JOIN flagship_active fa 
    ON c.customer_id = fa.customer_id
WHERE c.registration_date >= '2022-01-01'
  AND o.order_channel IN ('Convenience Store', 'National Supermarket')
  AND fa.customer_id IS NULL
GROUP BY 
    c.customer_id, 
    c.name
HAVING COUNT(DISTINCT o.order_id) >= 3;



-- 7. Basket metrics and settled check value

SELECT
    order_id,
    COUNT(product_id)    AS total_line_items,
    ROUND(AVG(price), 2) AS avg_unit_price,
    MAX(total_cost)      AS total_basket_value -- Handles denormalized order totals
FROM Order_Lines
GROUP BY order_id
ORDER BY order_id;



-- 8. Top selling product per region (DENSE_RANK Window Function)

WITH regional_sales AS (
    SELECT
        c.region,
        p.product_name,
        SUM(o.price - COALESCE(o.discount, 0)) AS total_net_revenue
    FROM Order_Lines o
    INNER JOIN Customers c 
        ON o.customer_id = c.customer_id
    INNER JOIN Products p 
        ON o.product_id = p.product_id
    GROUP BY 
        c.region, 
        p.product_name
),
ranked_sales AS (
    SELECT
        region,
        product_name,
        total_net_revenue,
        DENSE_RANK() OVER (
            PARTITION BY region 
            ORDER BY total_net_revenue DESC
        ) AS rank
    FROM regional_sales
)
SELECT
    region,
    product_name,
    total_net_revenue
FROM ranked_sales
WHERE rank = 1;



-- 9. Time between first and second purchase (LAG/LEAD Logic)

WITH customer_orders AS (
    SELECT
        customer_id,
        order_id,
        date AS order_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY date ASC
        ) AS order_seq
    FROM Order_Lines
),
time_diff AS (
    SELECT
        customer_id,
        order_date AS second_purchase_date,
        LAG(order_date) OVER (
            PARTITION BY customer_id 
            ORDER BY order_date ASC
        ) AS first_purchase_date
    FROM customer_orders
    WHERE order_seq <= 2
)
SELECT
    ROUND(AVG(second_purchase_date::DATE - first_purchase_date::DATE), 1) AS avg_days_to_second_purchase
FROM time_diff
WHERE first_purchase_date IS NOT NULL;



-- 10. Cumulative (Running) Revenue by Month

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', date)::DATE    AS sales_month,
        SUM(price - COALESCE(discount, 0)) AS net_revenue
    FROM Order_Lines
    GROUP BY DATE_TRUNC('month', date)::DATE
)
SELECT
    sales_month,
    net_revenue,
    SUM(net_revenue) OVER (ORDER BY sales_month) AS cumulative_revenue
FROM monthly_sales
ORDER BY sales_month;