# Omnichannel Retail Cohort & Commercial SQL Analytics

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Advanced_DQL-orange?style=for-the-badge)
![Analytics](https://img.shields.io/badge/Focus-Cohort_%26_Unit_Economics-blue?style=for-the-badge)

A collection of 10 commercial SQL queries analyzing customer retention, basket metrics, and channel migration for a coffee equipment and consumables retailer.

The focus is on practical analytical queries using CTEs, Window Functions, and basic data integrity constraints in PostgreSQL.

---

## 🛠️ Data Model

```text
  [ Customers ] (customer_id PK)
         |
         | 1:N
         v
  [ Order_Lines ] (line_id PK, order_id, FK customer_id, FK product_id)
         ^
         | 1:N
         |
  [ Products ] (product_id PK)
```

---

* **Data integrity:** Added `CHECK` constraints on `price`, `discount`, and `total_cost` to prevent negative values.
* **Granularity:** Line-item grain (`Order_Lines`) handles multi-item baskets and individual item discounts.
* **Edge cases handled:** Explicit handling of `NULL` discounts via `COALESCE` and zero-value warranty replacements.

## 📋 Query Index (10 Business Scenarios)

All queries are consolidated in [`sql/02_advanced_commercial_kpis.sql`](sql/02_advanced_commercial_kpis.sql):

| # | Business Scenario | Analytical Technique / SQL Stack |
|---|-------------------|----------------------------------|
| 1 | Customer order concentration & volume share | `COUNT(DISTINCT)`, Window `SUM() OVER ()` |
| 2 | Hardware sales run-rate in Flagship stores | Date window filtering, type-safe `INNER JOIN` |
| 3 | Trailing 90-day limited edition sales velocity | Subquery date intervals (`INTERVAL '90 days'`) |
| 4 | Gross vs. net revenue & discount exposure audit | `DATE_TRUNC`, CTE order-level pre-aggregation |
| 5 | Consumable attachment rate (Razor & Blade ratio) | Conditional aggregation `COUNT(CASE WHEN...)` |
| 6 | Cohort inactivity & retail channel migration | Anti-join pattern (`LEFT JOIN ... WHERE ... IS NULL`) |
| 7 | Basket line-item depth & average ticket audit | `AVG()`, handling denormalized order totals |
| 8 | Top-selling product per territory | Partitioned ranking via `DENSE_RANK() OVER ()` |
| 9 | Time between 1st and 2nd purchase velocity | Chronological navigation via `ROW_NUMBER()`, `LAG()` |
| 10 | Cumulative running revenue realization | Running total via `SUM() OVER (ORDER BY month)` |

---

## 💡 Core Analytical Highlights

Selected commercial patterns implemented in sql/02_advanced_commercial_kpis.sql:

### 1. Cohort Channel Migration (Lapsed Flagship Customers)

Finds customers registered in 2022+ who stopped buying at Flagship stores (>180 days) but placed 3+ orders through partner retail chains:

```sql
WITH flagship_active AS (
    SELECT DISTINCT customer_id
    FROM Order_Lines
    WHERE order_channel = 'Flagship Store'
      AND date >= (SELECT MAX(date) - INTERVAL '180 days' FROM Order_Lines)
)
SELECT
    c.customer_id,
    c.name,
    COUNT(DISTINCT o.order_id) AS retail_transactions
FROM Customers c
INNER JOIN Order_Lines o ON c.customer_id = o.customer_id
LEFT JOIN flagship_active fa ON c.customer_id = fa.customer_id
WHERE c.registration_date >= '2022-01-01'
  AND o.order_channel IN ('Convenience Store', 'National Supermarket')
  AND fa.customer_id IS NULL
GROUP BY c.customer_id, c.name
HAVING COUNT(DISTINCT o.order_id) >= 3;
```

### 2. Time-to-Second-Purchase Velocity (Window Navigation)

Calculates the average days between a customer's first and second purchase using `ROW_NUMBER()` and `LAG()`:

```sql
WITH customer_orders AS (
    SELECT
        customer_id,
        order_id,
        date AS order_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY date ASC) AS order_seq
    FROM Order_Lines
),
time_diff AS (
    SELECT
        customer_id,
        order_date AS second_purchase_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS first_purchase_date
    FROM customer_orders
    WHERE order_seq <= 2
)
SELECT
    ROUND(AVG(second_purchase_date::DATE - first_purchase_date::DATE), 1) AS avg_days_to_second_purchase
FROM time_diff
WHERE first_purchase_date IS NOT NULL;
```

### 3. Consumable Attachment Rate (Razor-and-Blade Metric)

Measures what percentage of total orders include coffee pods:

```sql
SELECT
    ROUND(
        COUNT(DISTINCT CASE WHEN p.product_type = 'Consumables' THEN o.order_id END) * 100.0
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS pods_attachment_pct
FROM Order_Lines o
LEFT JOIN Products p ON o.product_id = p.product_id;
```

## 🚀 How to Run Locally

1. **Clone the repository:**
   ```bash
   git clone https://github.com/SzymonKhrapachenko/omnichannel-retail-cohort-sql-analytics.git
   cd omnichannel-retail-cohort-sql-analytics
   ```

2. **Build schema and load mock data:**
   Run `sql/01_dwh_schema_and_mock_data.sql` in DBeaver, pgAdmin, or psql:
   ```bash
   psql -U <username> -d <database_name> -f sql/01_dwh_schema_and_mock_data.sql
   ```

3. **Run queries:**
   Execute sql/02_advanced_commercial_kpis.sql. 
   Validation note: Query 6 should return exactly 1 row (Taras H., 3 partner orders), confirming     the anti-join logic correctly identifies     the lapsed cohort.

---

## 📁 Repository Structure

```text
├── sql/
│   ├── 01_dwh_schema_and_mock_data.sql   # DDL Schema, Defensive Constraints & Seed Dataset
│   └── 02_advanced_commercial_kpis.sql   # 10 Advanced Analytical Queries (CTEs, Windowing)
└── README.md                             # Project Overview & Query Documentation
```
