# Retail Store Sales & Operations Analytics

## Project Overview

This project analyzes a large retail store dataset using SQL to understand sales performance, product performance, customer behavior, promotions, returns, shipments, stores, suppliers, and employee productivity.

The project is designed around practical business questions that can help a retail business understand where revenue is generated, where profitability is under pressure, how promotions affect sales, which products and customers contribute the most value, and where operational improvements may be needed.

---

## Business Objectives

The analysis focuses on:

- Measuring overall retail business performance
- Comparing revenue across stores and categories
- Identifying top-performing products
- Analyzing monthly revenue trends and Month-over-Month growth
- Understanding customer lifetime value
- Evaluating promotion performance
- Measuring returns and refund impact
- Analyzing shipment performance and late shipments
- Comparing store revenue with employee count
- Identifying products with high revenue but negative gross profit
- Measuring category and product contribution
- Building a consolidated monthly business performance report

---

## Database

**Database Name:** `retail_store_analytics`

### Tables

| Table | Approx. Rows | Purpose |
|---|---:|---|
| stores | 100 | Store information and locations |
| suppliers | 200 | Supplier information |
| categories | 30 | Product categories |
| customers | 50,000 | Customer information |
| employees | 1,000 | Store employee information |
| products | 10,000 | Product catalog and pricing |
| promotions | Project dataset | Promotion and discount information |
| orders | 300,000 | Customer order records |
| order_items | 640,767 | Products included in each order |
| payments | 300,000 | Payment records |
| returns | 30,000 | Returned orders/items and refund information |
| shipments | 300,000 | Shipment and delivery information |

---

## Database Relationships

The main relationships are:

```text
Stores
  |
  +---- Employees
  |
  +---- Orders
           |
           +---- Order Items ---- Products ---- Categories
           |                       |
           |                       +---- Suppliers
           |
           +---- Payments
           |
           +---- Returns
           |
           +---- Shipments
           |
           +---- Promotions
```

---

## Business Calculations

### Revenue

Revenue is calculated using the item quantity, item price, and applicable promotion discount:

```text
Revenue = Quantity × Item Price × (1 - Discount / 100)
```

### Gross Profit

Gross profit is calculated by comparing the discounted selling price with the product cost:

```text
Gross Profit = Quantity × (Discounted Selling Price - Product Cost)
```

### Net Revenue

Net revenue accounts for refunds from returned items:

```text
Net Revenue = Gross Revenue - Return Refunds
```

### Month-over-Month Growth

Monthly revenue growth is calculated using the previous month's revenue:

```text
MoM Growth % = ((Current Month Revenue - Previous Month Revenue)
               / Previous Month Revenue) × 100
```

---

## Analysis Covered

The SQL analysis contains 24 business-focused questions covering:

1. Overall business scale
2. Revenue by store
3. Revenue and units by category
4. Monthly revenue trends
5. Top products by revenue
6. Average Order Value by store
7. Promotion performance
8. Supplier revenue contribution
9. Returns and refunds by category
10. Shipment status distribution
11. Store-level late shipment rate
12. Top customers by lifetime revenue
13. Customers active across multiple months
14. Month-over-Month revenue growth
15. Months performing above average revenue
16. Top category by month
17. Top 3 products within each category
18. Store revenue contribution
19. Revenue per employee
20. High-revenue products with negative gross profit
21. Promotion discount vs revenue and AOV
22. Monthly net revenue after refunds
23. Customers generating above-average revenue
24. Consolidated monthly business performance report

---

## SQL Concepts Used

The project uses a wide range of SQL techniques, including:

- SELECT
- WHERE
- CASE
- GROUP BY
- HAVING
- ORDER BY
- Aggregate functions
- INNER JOIN
- LEFT JOIN
- Subqueries
- Common Table Expressions (CTEs)
- Date functions
- Conditional aggregation
- DISTINCT
- UNION-style analytical thinking
- Window functions
- LAG()
- SUM() OVER()
- ROW_NUMBER()
- DENSE_RANK()
- PARTITION BY
- Running and contribution calculations
- Multi-table business analysis

---

## Project Files

### 1. Database

`retail_store_analytics_database.sql`

Contains the complete database structure and data required to recreate the project.

### 2. SQL Business Analysis

`Retail_Store_Business_Analysis_SQL_Questions.sql`

Contains the complete business analysis with 24 SQL questions, approaches, queries, key insights, summary, and recommendations.

### 3. README

`README.md`

Project documentation containing the project overview, database structure, business calculations, analysis areas, and results.

---

## How to Run

### Step 1: Create the Database

Open the database SQL file in MySQL:

```sql
SOURCE retail_store_analytics_database.sql;
```

Or open the file in MySQL Workbench and execute it.

### Step 2: Select the Database

```sql
USE retail_store_analytics;
```

### Step 3: Run the Analysis

Open:

```text
Retail_Store_Business_Analysis_SQL_Questions.sql
```

Run the queries individually to explore each business question and result.

---

## Key Insights

The analysis produced several important observations:

- The dataset contains approximately 300,000 orders and more than 640,000 order items, providing a broad base for retail analysis.
- Revenue is distributed across multiple stores and product categories rather than being concentrated in a single business area.
- Several categories contribute strongly to total revenue, including areas such as Accessories, Pet Supplies, Computers & Laptops, Watches, and Personal Care.
- Monthly revenue changes over time, making Month-over-Month analysis useful for identifying periods of growth and decline.
- Promotion discounts have a direct effect on realized selling prices, revenue, and Average Order Value.
- Some products generate significant revenue while producing negative gross profit, highlighting the importance of analyzing profitability alongside sales volume.
- Returns and refunds create a measurable impact on net revenue.
- Shipment performance varies across stores, making late-shipment rate an important operational metric.
- Revenue per employee provides another way to compare store productivity.
- Customer-level analysis helps identify high-value customers and customers with repeated activity across different months.

These observations are based on the synthetic project dataset and the calculations implemented in the SQL analysis.

---

## Business Summary

The project combines sales, customer, product, promotion, financial, and operational data into a single retail analytics environment.

The analysis shows why looking only at total sales can hide important business factors. Revenue needs to be evaluated together with discounts, product cost, returns, customer activity, shipping performance, and store productivity.

The final monthly performance query brings several of these metrics together into one report that can be used as a recurring business-performance view.

---

## Recommendations

Based on the analysis:

1. Review products with high revenue but negative gross profit and evaluate their pricing, cost structure, and promotional discounts.
2. Evaluate promotions using both revenue and Average Order Value instead of measuring success only by sales volume.
3. Monitor store-level late shipment rates and investigate locations with consistently higher delays.
4. Track category-level return rates and refund amounts to identify products or categories requiring operational attention.
5. Use Month-over-Month and rolling-period analysis together to understand changes in business performance.
6. Compare revenue per employee across stores to identify differences in store productivity.
7. Monitor high-value customers and repeat activity to understand customer contribution over time.
8. Use the consolidated monthly performance report for regular business monitoring.

---

## Tools Used

- MySQL
- MySQL Workbench
- SQL
- Relational Database Design
- Data Analysis
- Business Analytics

---

## Dataset Disclaimer

This project uses a fully synthetic dataset created specifically for this portfolio project.

The data was not copied, scraped, downloaded, or taken from any external dataset or real company database. Customer names, email addresses, locations, stores, suppliers, products, transactions, payments, shipments, returns, and other records are fictional and generated for analytical demonstration purposes.

This project is intended for educational, portfolio, and demonstration use only.

---

## 👤 Author

**Vikash Singh Shekhawat**

SQL | Excel | Power BI | Python
