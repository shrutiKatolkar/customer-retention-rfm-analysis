/* =====================================================================
   Project : Customer Retention & RFM Segmentation
   File    : 03_cleaning.sql
   Purpose : Clean the raw online-retail data without touching the original.
   Input   : online_retail        (541,909 raw rows)
   Output  : clean_retail         (397,880 rows)  - invalid rows removed
             clean_retail_final   (392,688 rows)  - duplicates removed
   Run     : Execute the whole script (Ctrl + Shift + Enter).
   ===================================================================== */
 
USE retail_project;
 
-- ---------------------------------------------------------------------
-- 0. Reset (makes the script safe to re-run)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS clean_retail_final;
DROP TABLE IF EXISTS clean_retail;
 
-- ---------------------------------------------------------------------
-- 1. Remove invalid rows and fix data types
--    Issues found in raw data (see 02_data_checks.sql):
--      - 135,080 rows with missing CustomerID (RFM needs a customer)
--      - 9,288 cancelled invoices (InvoiceNo starts with 'C')
--      - 10,624 rows with negative quantity (returns)
--      - 2,521 rows with zero or negative unit price
--    InvoiceDate is stored as text (month/day/year), so convert to DATETIME.
-- ---------------------------------------------------------------------
CREATE TABLE clean_retail AS
SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i') AS InvoiceDate,
    UnitPrice,
    CAST(CustomerID AS UNSIGNED)               AS CustomerID,
    Country,
    ROUND(Quantity * UnitPrice, 2)             AS TotalPrice
FROM online_retail
WHERE CustomerID <> ''
  AND CustomerID IS NOT NULL
  AND InvoiceNo NOT LIKE 'C%'
  AND Quantity  > 0
  AND UnitPrice > 0;
 
-- ---------------------------------------------------------------------
-- 2. Check duplicates (exact same row repeated)
--    Result: 4,809 duplicate groups = 5,192 extra rows (about 1.3%)
-- ---------------------------------------------------------------------
SELECT
    COUNT(*)         AS duplicate_groups,
    SUM(cnt - 1)     AS extra_rows
FROM (
    SELECT COUNT(*) AS cnt
    FROM clean_retail
    GROUP BY InvoiceNo, StockCode, Description, Quantity,
             InvoiceDate, UnitPrice, CustomerID, Country
    HAVING COUNT(*) > 1
) AS d;
 
-- ---------------------------------------------------------------------
-- 3. Remove duplicates -> final analysis table
-- ---------------------------------------------------------------------
CREATE TABLE clean_retail_final AS
SELECT DISTINCT
    InvoiceNo, StockCode, Description, Quantity,
    InvoiceDate, UnitPrice, CustomerID, Country, TotalPrice
FROM clean_retail;
 
-- ---------------------------------------------------------------------
-- 4. Validation
--    Expected: 392,688 rows | 4,338 customers | revenue about 8,887,208.89
--    Dates from 2010-12-01 to 2011-12-09 | 0 bad dates
-- ---------------------------------------------------------------------
SELECT
    COUNT(*)                       AS final_rows,
    COUNT(DISTINCT CustomerID)     AS customers,
    ROUND(SUM(TotalPrice), 2)      AS total_revenue,
    MIN(InvoiceDate)               AS first_date,
    MAX(InvoiceDate)               AS last_date,
    SUM(InvoiceDate IS NULL)       AS bad_dates
FROM clean_retail_final;