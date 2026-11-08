/* =====================================================================
   Project : Customer Retention & RFM Segmentation
   File    : 05_cohort.sql
   Purpose : Monthly cohort retention analysis.
   Input   : clean_retail_final
   Output  : cohort_base       - months in which each customer ordered
             cohort_index      - month number since first purchase
             cohort_retention  - customers and retention % per cohort
   Note    : Retention = share of a cohort that ordered again in month N.
             Data ends on 2011-12-09, so the last month is incomplete.
   Run     : Execute the whole script (Ctrl + Shift + Enter).
   ===================================================================== */
 
USE retail_project;
 
-- ---------------------------------------------------------------------
-- 0. Reset (drop in reverse order of dependency)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS cohort_retention;
DROP TABLE IF EXISTS cohort_index;
DROP TABLE IF EXISTS cohort_base;
 
-- ---------------------------------------------------------------------
-- 1. Cohort month = month of the customer's first order
-- ---------------------------------------------------------------------
CREATE TABLE cohort_base AS
WITH monthly AS (
    SELECT DISTINCT
        CustomerID,
        CAST(DATE_FORMAT(InvoiceDate, '%Y-%m-01') AS DATE) AS order_month
    FROM clean_retail_final
)
SELECT
    CustomerID,
    order_month,
    MIN(order_month) OVER (PARTITION BY CustomerID) AS cohort_month
FROM monthly;
 
-- Check: cohort sizes should add up to 4,338 customers
SELECT cohort_month, COUNT(DISTINCT CustomerID) AS cohort_size
FROM cohort_base
GROUP BY cohort_month
ORDER BY cohort_month;
 
-- ---------------------------------------------------------------------
-- 2. Month number = months passed since the cohort month (0 = first month)
-- ---------------------------------------------------------------------
CREATE TABLE cohort_index AS
SELECT
    CustomerID,
    cohort_month,
    order_month,
    TIMESTAMPDIFF(MONTH, cohort_month, order_month) AS month_number
FROM cohort_base;
 
-- ---------------------------------------------------------------------
-- 3. Retention % = customers active in month N / cohort size (month 0)
-- ---------------------------------------------------------------------
CREATE TABLE cohort_retention AS
SELECT
    cohort_month,
    month_number,
    COUNT(DISTINCT CustomerID) AS customers,
    ROUND(
        COUNT(DISTINCT CustomerID) * 100 /
        FIRST_VALUE(COUNT(DISTINCT CustomerID))
            OVER (PARTITION BY cohort_month ORDER BY month_number),
        1) AS retention_pct
FROM cohort_index
GROUP BY cohort_month, month_number;
 
-- ---------------------------------------------------------------------
-- 4. Average retention across cohorts
--    Expected: month 1 about 20.6%. Later months rest on fewer cohorts,
--    so treat them with caution.
-- ---------------------------------------------------------------------
SELECT
    month_number,
    ROUND(AVG(retention_pct), 1) AS avg_retention_pct,
    COUNT(*)                     AS cohorts_counted
FROM cohort_retention
GROUP BY month_number
ORDER BY month_number;
 