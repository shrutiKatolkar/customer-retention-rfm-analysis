/* =====================================================================
   Project : Customer Retention & RFM Segmentation
   File    : 01_create_table.sql
   Purpose : Create the database and the raw table for the CSV import.
   Output  : retail_project.online_retail (empty table)
   Next    : Import online_retail.csv with the Table Data Import Wizard,
             then run 02_data_checks.sql.
   Note    : IF NOT EXISTS is used so that re-running this script never
             deletes data that is already imported.
   ===================================================================== */

CREATE DATABASE IF NOT EXISTS retail_project;
USE retail_project;

-- Raw table: columns match the source CSV exactly.
-- InvoiceDate is kept as text (month/day/year) because the CSV date format
-- is not accepted directly by MySQL. It is converted in 03_cleaning.sql.
-- CustomerID is kept as text because many rows are blank.
CREATE TABLE IF NOT EXISTS online_retail (
    InvoiceNo   VARCHAR(20),
    StockCode   VARCHAR(20),
    Description VARCHAR(255),
    Quantity    INT,
    InvoiceDate VARCHAR(30),
    UnitPrice   DECIMAL(10, 2),
    CustomerID  VARCHAR(20),
    Country     VARCHAR(50)
);