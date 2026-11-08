/* =====================================================================
   Project : Customer Retention & RFM Segmentation
   File    : 02_data_checks.sql
   Purpose : Profile the raw data and find quality issues before cleaning.
   Input   : online_retail (raw, 541,909 rows)
   Output  : none (read-only checks; the table is not modified)
   ===================================================================== */

USE retail_project;

-- 1. Total rows. Expected: 541,909
SELECT COUNT(*) AS total_rows
FROM online_retail;

-- 2. Rows with missing CustomerID. Expected: 135,080 (about 25%)
SELECT COUNT(*) AS blank_customers
FROM online_retail
WHERE CustomerID = '' OR CustomerID IS NULL;

-- 3. Rows with negative quantity (returns). Expected: 10,624
SELECT COUNT(*) AS negative_qty
FROM online_retail
WHERE Quantity < 0;

-- 4. Cancelled invoices (InvoiceNo starts with 'C'). Expected: 9,288
SELECT COUNT(*) AS cancelled
FROM online_retail
WHERE InvoiceNo LIKE 'C%';

-- 5. Zero or negative unit price. Expected: 2,521
SELECT COUNT(*) AS bad_price
FROM online_retail
WHERE UnitPrice <= 0;

-- 6. Unique customers and countries.
--    Expected: 4,373 customers (includes the blank value, so 4,372 real
--    customers) and 38 countries.
SELECT COUNT(DISTINCT CustomerID) AS customers,
       COUNT(DISTINCT Country)    AS countries
FROM online_retail;