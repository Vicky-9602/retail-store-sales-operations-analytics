/*
======================================================================
RETAIL STORE SALES & OPERATIONS ANALYTICS
Business Analysis SQL Project
======================================================================

Database:
    retail_store_analytics

Core tables:
    stores
    suppliers
    categories
    customers
    employees
    products
    promotions
    orders
    order_items
    payments
    returns
    shipments

Revenue rule used in this project:
    Gross Revenue = qty * item_price * (1 - promotion_discount / 100)

Profit rule:
    Profit = qty * (discounted_item_price - product_cost)

Net Revenue:
    Net Revenue = Gross Revenue - Return Refunds

Important:
    The database contains no order-status column. Order-level sales
    are therefore based on recorded orders, while shipment status and
    returns are analyzed separately.

Comments contain only the business question and approach.
SQL solutions are outside the comments.

MySQL 8+ recommended.
======================================================================
*/

USE retail_store_analytics;


/* =====================================================================
Q01

QUESTION:
How large is the retail business in terms of customers, products,
stores, suppliers, orders, and total order items?

APPROACH:
Use separate aggregate counts from the relevant master and transaction
tables. Return the business scale as one summary row.
===================================================================== */

SELECT
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM products) AS total_products,
    (SELECT COUNT(*) FROM stores) AS total_stores,
    (SELECT COUNT(*) FROM suppliers) AS total_suppliers,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COUNT(*) FROM order_items) AS total_order_items;


/* =====================================================================
Q02

QUESTION:
Which stores generate the highest sales revenue?

APPROACH:
Join orders with order_items and promotions, calculate discounted
line revenue, aggregate it by store, and sort stores from highest
to lowest revenue.
===================================================================== */

SELECT
    s.store_id,
    s.store_name,
    s.city,
    ROUND(
        SUM(oi.qty * oi.price * (1 - p.discount / 100)),
        2
    ) AS gross_revenue
FROM stores s
JOIN orders o
    ON s.store_id = o.store_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN promotions p
    ON o.promotion_id = p.promotion_id
GROUP BY
    s.store_id,
    s.store_name,
    s.city
ORDER BY gross_revenue DESC;


/* =====================================================================
Q03

QUESTION:
Which product categories generate the most revenue and how many units
are sold in each category?

APPROACH:
Connect products to order_items, orders, promotions, and categories.
Calculate discounted revenue and total quantity, then aggregate by
category.
===================================================================== */

SELECT
    c.category_id,
    c.category_name,
    SUM(oi.qty) AS units_sold,
    ROUND(
        SUM(oi.qty * oi.price * (1 - p.discount / 100)),
        2
    ) AS gross_revenue
FROM categories c
JOIN products pr
    ON c.category_id = pr.category_id
JOIN order_items oi
    ON pr.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
JOIN promotions p
    ON o.promotion_id = p.promotion_id
GROUP BY
    c.category_id,
    c.category_name
ORDER BY gross_revenue DESC;


/* =====================================================================
Q04

QUESTION:
What is the monthly revenue trend of the business?

APPROACH:
Extract the month from order_date, calculate discounted revenue at
order-item level, and aggregate the result chronologically by month.
===================================================================== */

SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.qty) AS units_sold,
    ROUND(
        SUM(oi.qty * oi.price * (1 - p.discount / 100)),
        2
    ) AS gross_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN promotions p
    ON o.promotion_id = p.promotion_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month;


/* =====================================================================
Q05

QUESTION:
What are the top 10 products by revenue, and how many units has
each product sold?

APPROACH:
Aggregate discounted revenue and units at product level. Join the
category table so the product's business category is visible in the
result, then keep the highest-revenue products.
===================================================================== */

SELECT
    pr.product_id,
    pr.product_name,
    c.category_name,
    SUM(oi.qty) AS units_sold,
    ROUND(
        SUM(oi.qty * oi.price * (1 - promo.discount / 100)),
        2
    ) AS revenue
FROM products pr
JOIN categories c
    ON pr.category_id = c.category_id
JOIN order_items oi
    ON pr.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
JOIN promotions promo
    ON o.promotion_id = promo.promotion_id
GROUP BY
    pr.product_id,
    pr.product_name,
    c.category_name
ORDER BY revenue DESC
LIMIT 10;


/* =====================================================================
Q06

QUESTION:
What is the average order value for each store, and how does it
compare with the store's total revenue and order volume?

APPROACH:
First calculate one revenue value per order so multiple order items do
not inflate the order count. Then aggregate those order-level results
by store and calculate average order value.
===================================================================== */

WITH order_value AS (
    SELECT
        o.order_id,
        o.store_id,
        SUM(
            oi.qty * oi.price * (1 - p.discount / 100)
        ) AS order_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN promotions p
        ON o.promotion_id = p.promotion_id
    GROUP BY
        o.order_id,
        o.store_id
)
SELECT
    s.store_id,
    s.store_name,
    COUNT(ov.order_id) AS total_orders,
    ROUND(SUM(ov.order_revenue), 2) AS total_revenue,
    ROUND(AVG(ov.order_revenue), 2) AS average_order_value
FROM stores s
JOIN order_value ov
    ON s.store_id = ov.store_id
GROUP BY
    s.store_id,
    s.store_name
ORDER BY average_order_value DESC;


/* =====================================================================
Q07

QUESTION:
Which promotions generate the most revenue and which promotions
attract the highest number of orders?

APPROACH:
Join promotions with orders and order_items. Aggregate discounted
revenue and distinct orders by promotion, then compare the commercial
performance of the promotions.
===================================================================== */

SELECT
    p.promotion_id,
    p.promotion_name,
    p.discount,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(
        SUM(oi.qty * oi.price * (1 - p.discount / 100)),
        2
    ) AS revenue,
    ROUND(
        SUM(oi.qty * oi.price * (1 - p.discount / 100))
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value
FROM promotions p
JOIN orders o
    ON p.promotion_id = o.promotion_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    p.promotion_id,
    p.promotion_name,
    p.discount
ORDER BY revenue DESC;


/* =====================================================================
Q08

QUESTION:
Which suppliers contribute the most sales revenue?

APPROACH:
Connect suppliers to products and transaction records. Calculate
discounted revenue by supplier and include units sold so revenue can
be viewed alongside product volume.
===================================================================== */

SELECT
    s.supplier_id,
    s.supplier_name,
    s.country,
    SUM(oi.qty) AS units_sold,
    ROUND(
        SUM(oi.qty * oi.price * (1 - p.discount / 100)),
        2
    ) AS revenue
FROM suppliers s
JOIN products pr
    ON s.supplier_id = pr.supplier_id
JOIN order_items oi
    ON pr.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
JOIN promotions p
    ON o.promotion_id = p.promotion_id
GROUP BY
    s.supplier_id,
    s.supplier_name,
    s.country
ORDER BY revenue DESC
LIMIT 15;


/* =====================================================================
Q09

QUESTION:
How much revenue has been refunded through product returns, and
which categories are affected the most?

APPROACH:
Connect returns to order_items and products, then summarize refund
amount and returned item count by category. Compare refund value with
the original sales value of those returned items.
===================================================================== */

SELECT
    c.category_name,
    COUNT(DISTINCT r.return_id) AS returned_items,
    ROUND(SUM(r.refund), 2) AS total_refund,
    ROUND(
        SUM(oi.qty * oi.price * (1 - p.discount / 100)),
        2
    ) AS original_returned_item_revenue
FROM returns r
JOIN order_items oi
    ON r.order_item_id = oi.order_item_id
JOIN products pr
    ON oi.product_id = pr.product_id
JOIN categories c
    ON pr.category_id = c.category_id
JOIN orders o
    ON oi.order_id = o.order_id
JOIN promotions p
    ON o.promotion_id = p.promotion_id
GROUP BY c.category_name
ORDER BY total_refund DESC;


/* =====================================================================
Q10

QUESTION:
What percentage of shipments are delivered, shipped, or late?

APPROACH:
Use conditional aggregation on shipment status. Calculate each
status count and divide it by the total number of shipments to show
the operational distribution.
===================================================================== */

SELECT
    COUNT(*) AS total_shipments,
    SUM(status = 'delivered') AS delivered_shipments,
    SUM(status = 'shipped') AS shipped_shipments,
    SUM(status = 'late') AS late_shipments,
    ROUND(
        SUM(status = 'delivered') / COUNT(*) * 100,
        2
    ) AS delivered_pct,
    ROUND(
        SUM(status = 'late') / COUNT(*) * 100,
        2
    ) AS late_pct
FROM shipments;


/* =====================================================================
Q11

QUESTION:
Which stores have the highest late-shipment rate?

APPROACH:
Join shipments to orders and stores. Count all shipments and late
shipments per store, then calculate late-shipment percentage. Use
HAVING to focus on stores with meaningful shipment volume.
===================================================================== */

SELECT
    s.store_id,
    s.store_name,
    COUNT(*) AS total_shipments,
    SUM(sh.status = 'late') AS late_shipments,
    ROUND(
        SUM(sh.status = 'late') / COUNT(*) * 100,
        2
    ) AS late_shipment_rate_pct
FROM stores s
JOIN orders o
    ON s.store_id = o.store_id
JOIN shipments sh
    ON o.order_id = sh.order_id
GROUP BY
    s.store_id,
    s.store_name
HAVING COUNT(*) >= 1000
ORDER BY late_shipment_rate_pct DESC;


/* =====================================================================
Q12

QUESTION:
Which customers have generated the highest lifetime revenue?

APPROACH:
Aggregate discounted order-item revenue by customer. Join customer
details and rank customers by total revenue while also showing their
order count and average order value.
===================================================================== */

SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(
        SUM(oi.qty * oi.price * (1 - p.discount / 100)),
        2
    ) AS lifetime_revenue,
    ROUND(
        SUM(oi.qty * oi.price * (1 - p.discount / 100))
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN promotions p
    ON o.promotion_id = p.promotion_id
GROUP BY
    c.customer_id,
    c.customer_name,
    c.city
ORDER BY lifetime_revenue DESC
LIMIT 20;


/* =====================================================================
Q13

QUESTION:
Which customers have placed orders in at least three different
calendar months?

APPROACH:
Create a distinct customer-month activity dataset so multiple orders
within one month count as one active month. Aggregate by customer and
use HAVING to keep customers with at least three active months.
===================================================================== */

WITH customer_months AS (
    SELECT DISTINCT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS order_month
    FROM orders
)
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(cm.order_month) AS active_months
FROM customers c
JOIN customer_months cm
    ON c.customer_id = cm.customer_id
GROUP BY
    c.customer_id,
    c.customer_name
HAVING COUNT(cm.order_month) >= 3
ORDER BY active_months DESC, c.customer_id;


/* =====================================================================
Q14

QUESTION:
What is the Month-over-Month revenue growth for each month?

APPROACH:
First aggregate monthly revenue. Use LAG() to retrieve the previous
month's revenue, then calculate the percentage change between the
current and previous month.
===================================================================== */

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(
            oi.qty * oi.price * (1 - p.discount / 100)
        ) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN promotions p
        ON o.promotion_id = p.promotion_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
monthly_growth AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY month
        ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0) * 100,
        2
    ) AS mom_growth_pct
FROM monthly_growth
ORDER BY month;


/* =====================================================================
Q15

QUESTION:
Which months have revenue above the average monthly revenue for
the entire period?

APPROACH:
Calculate monthly revenue first. Use a scalar subquery to calculate
the average monthly revenue from that monthly dataset, then compare
each month against the benchmark.
===================================================================== */

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(
            oi.qty * oi.price * (1 - p.discount / 100)
        ) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN promotions p
        ON o.promotion_id = p.promotion_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        (SELECT AVG(revenue) FROM monthly_revenue),
        2
    ) AS average_monthly_revenue
FROM monthly_revenue
WHERE revenue > (
    SELECT AVG(revenue)
    FROM monthly_revenue
)
ORDER BY revenue DESC;


/* =====================================================================
Q16

QUESTION:
For every month, which product category generated the highest
revenue?

APPROACH:
Calculate revenue by month and category. Use ROW_NUMBER() with
PARTITION BY month to rank categories independently within each month,
then keep the highest-ranked category.
===================================================================== */

WITH monthly_category AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        c.category_name,
        SUM(
            oi.qty * oi.price * (1 - p.discount / 100)
        ) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products pr
        ON oi.product_id = pr.product_id
    JOIN categories c
        ON pr.category_id = c.category_id
    JOIN promotions p
        ON o.promotion_id = p.promotion_id
    GROUP BY
        DATE_FORMAT(o.order_date, '%Y-%m'),
        c.category_name
),
ranked_categories AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY month
            ORDER BY revenue DESC
        ) AS category_rank
    FROM monthly_category
)
SELECT
    month,
    category_name,
    ROUND(revenue, 2) AS revenue
FROM ranked_categories
WHERE category_rank = 1
ORDER BY month;


/* =====================================================================
Q17

QUESTION:
What are the top three products by revenue inside every category?

APPROACH:
Aggregate revenue at product level and use DENSE_RANK() partitioned
by category. This keeps the ranking independent for each category
and preserves ties.
===================================================================== */

WITH product_revenue AS (
    SELECT
        c.category_name,
        pr.product_id,
        pr.product_name,
        SUM(
            oi.qty * oi.price * (1 - p.discount / 100)
        ) AS revenue
    FROM products pr
    JOIN categories c
        ON pr.category_id = c.category_id
    JOIN order_items oi
        ON pr.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN promotions p
        ON o.promotion_id = p.promotion_id
    GROUP BY
        c.category_name,
        pr.product_id,
        pr.product_name
),
ranked_products AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY category_name
            ORDER BY revenue DESC
        ) AS category_rank
    FROM product_revenue
)
SELECT
    category_name,
    product_id,
    product_name,
    ROUND(revenue, 2) AS revenue,
    category_rank
FROM ranked_products
WHERE category_rank <= 3
ORDER BY category_name, category_rank, revenue DESC;


/* =====================================================================
Q18

QUESTION:
Which stores contribute the largest percentage of total company
revenue?

APPROACH:
Calculate store-level revenue first. Use a window SUM() across all
stores to calculate each store's contribution to total revenue.
===================================================================== */

WITH store_revenue AS (
    SELECT
        s.store_id,
        s.store_name,
        SUM(
            oi.qty * oi.price * (1 - p.discount / 100)
        ) AS revenue
    FROM stores s
    JOIN orders o
        ON s.store_id = o.store_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN promotions p
        ON o.promotion_id = p.promotion_id
    GROUP BY
        s.store_id,
        s.store_name
)
SELECT
    store_id,
    store_name,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        revenue / SUM(revenue) OVER () * 100,
        2
    ) AS revenue_contribution_pct
FROM store_revenue
ORDER BY revenue_contribution_pct DESC;


/* =====================================================================
Q19

QUESTION:
How much revenue does each store generate per employee?

APPROACH:
Calculate store revenue separately from employee counts to avoid
multiplying transaction rows by employee rows. Join the two aggregated
datasets and calculate revenue per employee.
===================================================================== */

WITH store_revenue AS (
    SELECT
        store_id,
        SUM(
            oi.qty * oi.price * (1 - p.discount / 100)
        ) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN promotions p
        ON o.promotion_id = p.promotion_id
    GROUP BY store_id
),
store_staff AS (
    SELECT
        store_id,
        COUNT(*) AS employee_count,
        ROUND(AVG(salary), 2) AS average_salary
    FROM employees
    GROUP BY store_id
)
SELECT
    s.store_id,
    s.store_name,
    ss.employee_count,
    ss.average_salary,
    ROUND(sr.revenue, 2) AS revenue,
    ROUND(
        sr.revenue / NULLIF(ss.employee_count, 0),
        2
    ) AS revenue_per_employee
FROM stores s
JOIN store_revenue sr
    ON s.store_id = sr.store_id
JOIN store_staff ss
    ON s.store_id = ss.store_id
ORDER BY revenue_per_employee DESC;


/* =====================================================================
Q20

QUESTION:
Which products generate high revenue but have negative gross profit?

APPROACH:
Calculate product revenue and gross profit after promotion discounts.
Filter products where revenue is positive but gross profit is below
zero, then order them by the size of their revenue.
===================================================================== */

SELECT
    pr.product_id,
    pr.product_name,
    c.category_name,
    ROUND(
        SUM(oi.qty * oi.price * (1 - promo.discount / 100)),
        2
    ) AS revenue,
    ROUND(
        SUM(
            oi.qty * (
                oi.price * (1 - promo.discount / 100)
                - pr.price
            )
        ),
        2
    ) AS gross_profit
FROM products pr
JOIN categories c
    ON pr.category_id = c.category_id
JOIN order_items oi
    ON pr.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
JOIN promotions promo
    ON o.promotion_id = promo.promotion_id
GROUP BY
    pr.product_id,
    pr.product_name,
    c.category_name
HAVING gross_profit < 0
ORDER BY revenue DESC;


/* =====================================================================
Q21

QUESTION:
How does the level of promotion discount relate to revenue and
average order value?

APPROACH:
Group orders by their promotion discount. Calculate order-level
revenue first, then summarize order count, revenue, and average order
value for each discount level.
===================================================================== */

WITH order_value AS (
    SELECT
        o.order_id,
        p.discount,
        SUM(
            oi.qty * oi.price * (1 - p.discount / 100)
        ) AS order_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN promotions p
        ON o.promotion_id = p.promotion_id
    GROUP BY
        o.order_id,
        p.discount
)
SELECT
    discount,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_revenue), 2) AS revenue,
    ROUND(AVG(order_revenue), 2) AS average_order_value
FROM order_value
GROUP BY discount
ORDER BY discount;


/* =====================================================================
Q22

QUESTION:
What is the net revenue by month after subtracting product return
refunds?

APPROACH:
Calculate monthly gross revenue from orders and monthly refund value
from returns separately. Combine both datasets by month and calculate
net revenue. Use COALESCE() for months without recorded refunds.
===================================================================== */

WITH monthly_gross AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(
            oi.qty * oi.price * (1 - p.discount / 100)
        ) AS gross_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN promotions p
        ON o.promotion_id = p.promotion_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
monthly_refunds AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(r.refund) AS refunds
    FROM returns r
    JOIN order_items oi
        ON r.order_item_id = oi.order_item_id
    JOIN orders o
        ON oi.order_id = o.order_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    g.month,
    ROUND(g.gross_revenue, 2) AS gross_revenue,
    ROUND(COALESCE(r.refunds, 0), 2) AS refunds,
    ROUND(
        g.gross_revenue - COALESCE(r.refunds, 0),
        2
    ) AS net_revenue
FROM monthly_gross g
LEFT JOIN monthly_refunds r
    ON g.month = r.month
ORDER BY g.month;


/* =====================================================================
Q23

QUESTION:
Which customers generate more revenue than the average customer
revenue?

APPROACH:
First calculate lifetime revenue for every customer. Use a second
aggregation layer to calculate the average customer revenue, then
compare each customer's revenue against that benchmark.
===================================================================== */

WITH customer_revenue AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(
            oi.qty * oi.price * (1 - p.discount / 100)
        ) AS revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN promotions p
        ON o.promotion_id = p.promotion_id
    GROUP BY
        c.customer_id,
        c.customer_name
)
SELECT
    customer_id,
    customer_name,
    ROUND(revenue, 2) AS lifetime_revenue,
    ROUND(
        (SELECT AVG(revenue) FROM customer_revenue),
        2
    ) AS average_customer_revenue
FROM customer_revenue
WHERE revenue > (
    SELECT AVG(revenue)
    FROM customer_revenue
)
ORDER BY revenue DESC;


/* =====================================================================
Q24

QUESTION:
Create a monthly business performance report containing revenue,
previous-month revenue, MoM growth, orders, average order value,
refunds, net revenue, and the highest-revenue category for each month.

APPROACH:
Build separate monthly order metrics, monthly refunds, and monthly
category revenue. Use LAG() for previous-month revenue, calculate
MoM growth, rank categories within each month, and combine all
components into one chronological business report.
===================================================================== */

WITH monthly_orders AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(
            oi.qty * oi.price * (1 - p.discount / 100)
        ) AS gross_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN promotions p
        ON o.promotion_id = p.promotion_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
monthly_with_lag AS (
    SELECT
        month,
        total_orders,
        gross_revenue,
        LAG(gross_revenue) OVER (
            ORDER BY month
        ) AS previous_month_revenue
    FROM monthly_orders
),
monthly_refunds AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(r.refund) AS refunds
    FROM returns r
    JOIN order_items oi
        ON r.order_item_id = oi.order_item_id
    JOIN orders o
        ON oi.order_id = o.order_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
monthly_category AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        c.category_name,
        SUM(
            oi.qty * oi.price * (1 - p.discount / 100)
        ) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products pr
        ON oi.product_id = pr.product_id
    JOIN categories c
        ON pr.category_id = c.category_id
    JOIN promotions p
        ON o.promotion_id = p.promotion_id
    GROUP BY
        DATE_FORMAT(o.order_date, '%Y-%m'),
        c.category_name
),
ranked_categories AS (
    SELECT
        month,
        category_name,
        revenue,
        ROW_NUMBER() OVER (
            PARTITION BY month
            ORDER BY revenue DESC
        ) AS category_rank
    FROM monthly_category
)
SELECT
    m.month,
    m.total_orders,
    ROUND(m.gross_revenue, 2) AS gross_revenue,
    ROUND(m.previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        (m.gross_revenue - m.previous_month_revenue)
        / NULLIF(m.previous_month_revenue, 0) * 100,
        2
    ) AS mom_growth_pct,
    ROUND(
        m.gross_revenue / NULLIF(m.total_orders, 0),
        2
    ) AS average_order_value,
    ROUND(COALESCE(r.refunds, 0), 2) AS refunds,
    ROUND(
        m.gross_revenue - COALESCE(r.refunds, 0),
        2
    ) AS net_revenue,
    rc.category_name AS top_category,
    ROUND(rc.revenue, 2) AS top_category_revenue
FROM monthly_with_lag m
LEFT JOIN monthly_refunds r
    ON m.month = r.month
LEFT JOIN ranked_categories rc
    ON m.month = rc.month
   AND rc.category_rank = 1
ORDER BY m.month;


/*
======================================================================
KEY INSIGHTS FROM THE DATA
======================================================================

1. The dataset contains 300,000 orders and more than 640,000 order
   items, creating a broad transaction base for revenue and operations
   analysis.

2. Gross revenue is approximately 3.15 billion in the dataset period.
   The calculated product-level gross profit is negative overall, which
   indicates that discounted selling prices frequently fall below the
   stored product cost.

3. Accessories, Pet Supplies, Computers & Laptops, Watches, and
   Personal Care are among the largest revenue-producing categories.
   Revenue leadership does not automatically translate into stronger
   margins.

4. The monthly revenue series shows noticeable month-to-month
   fluctuations. March 2022 records one of the strongest positive
   monthly changes, while January 2024 shows a very large decline.
   The final period should be interpreted carefully because the
   available date distribution is not uniform across every month.

5. Shipment operations contain delivered, shipped, and late orders.
   Late-shipment rate is therefore an important operational metric
   alongside revenue.

6. Returns represent a meaningful financial impact because refunds
   reduce the amount of revenue retained by the business. Category-
   level return analysis can help identify products that require
   quality, expectation, or assortment review.

7. Revenue is distributed across many stores, so store-level analysis
   is useful for identifying differences in sales productivity,
   shipment performance, and employee productivity.

8. Promotion discounts have a direct effect on realized selling price.
   Comparing discount levels with revenue and average order value helps
   separate high sales volume from efficient promotional performance.


======================================================================
SUMMARY
======================================================================

The database supports a complete retail analytics workflow:

    Customers
        ↓
    Orders
        ↓
    Order Items
        ↓
    Products → Categories → Suppliers
        ↓
    Promotions
        ↓
    Payments / Returns / Shipments
        ↓
    Stores / Employees

The analysis moves from basic transaction summaries to customer,
product, category, store, promotion, return, shipment, and time-based
performance analysis.

The final monthly business report combines revenue, MoM growth, order
volume, average order value, refunds, net revenue, and category
performance into one reusable business view.


======================================================================
RECOMMENDATIONS
======================================================================

1. Review products with negative gross profit and compare their price
   structure, supplier cost, and promotion discount before increasing
   their sales volume.

2. Evaluate promotions using both revenue and average order value.
   A higher discount should not be judged only by order volume.

3. Monitor late-shipment rates at store level and investigate stores
   with consistently high late percentages.

4. Track category-level return rates and refund values to identify
   products or categories that may require quality or assortment
   improvements.

5. Use MoM revenue and rolling-period analysis together. A single
   strong or weak month should be interpreted alongside the surrounding
   trend.

6. Compare revenue per employee across stores to identify differences
   in operational productivity and staffing requirements.

7. Build a recurring monthly reporting process around the final query
   so revenue, net revenue, growth, returns, and category performance
   can be reviewed consistently.

======================================================================
*/
