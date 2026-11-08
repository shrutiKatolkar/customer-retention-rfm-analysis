/* =====================================================================
   Project : Customer Retention & RFM Segmentation
   File    : 04_rfm.sql
   Purpose : Segment customers using RFM analysis.
   Input   : clean_retail_final
   Output  : rfm_base      - Recency, Frequency, Monetary per customer
             rfm_scores    - 1 to 5 score for each of R, F, M
             rfm_segments  - customer segment (Champions, Loyal, ...)
   Run     : Execute the whole script (Ctrl + Shift + Enter).
   ===================================================================== */
 
USE retail_project;
 
-- ---------------------------------------------------------------------
-- 0. Reset (drop in reverse order of dependency)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS rfm_segments;
DROP TABLE IF EXISTS rfm_scores;
DROP TABLE IF EXISTS rfm_base;
 
-- ---------------------------------------------------------------------
-- 1. RFM metrics per customer
--    Recency   : days since last purchase (reference date = 2011-12-10,
--                one day after the last order in the data)
--    Frequency : number of distinct invoices
--    Monetary  : total spend
-- ---------------------------------------------------------------------
CREATE TABLE rfm_base AS
SELECT
    CustomerID,
    DATEDIFF('2011-12-10', MAX(InvoiceDate)) AS Recency,
    COUNT(DISTINCT InvoiceNo)                AS Frequency,
    ROUND(SUM(TotalPrice), 2)                AS Monetary
FROM clean_retail_final
GROUP BY CustomerID;
 
-- ---------------------------------------------------------------------
-- 2. RFM scores (1 = worst, 5 = best) using NTILE quintiles
--    Recency is sorted DESC so that recent buyers get the highest score.
-- ---------------------------------------------------------------------
CREATE TABLE rfm_scores AS
SELECT
    CustomerID, Recency, Frequency, Monetary,
    NTILE(5) OVER (ORDER BY Recency   DESC) AS R_score,
    NTILE(5) OVER (ORDER BY Frequency ASC)  AS F_score,
    NTILE(5) OVER (ORDER BY Monetary  ASC)  AS M_score
FROM rfm_base;
 
-- ---------------------------------------------------------------------
-- 3. Segments (CASE is evaluated top to bottom, so order matters)
-- ---------------------------------------------------------------------
CREATE TABLE rfm_segments AS
SELECT
    CustomerID, Recency, Frequency, Monetary,
    R_score, F_score, M_score,
    CASE
        WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Champions'
        WHEN R_score >= 3 AND F_score >= 3                  THEN 'Loyal'
        WHEN R_score >= 4 AND F_score <= 2                  THEN 'New / Promising'
        WHEN R_score <= 2 AND F_score >= 3                  THEN 'At Risk'
        WHEN R_score <= 2 AND F_score <= 2                  THEN 'Lost'
        ELSE 'Needs Attention'
    END AS Segment
FROM rfm_scores;
 
-- ---------------------------------------------------------------------
-- 4. Segment summary (share of customers vs share of revenue)
--    Expected: Champions = 22.6% of customers, 65.1% of revenue
-- ---------------------------------------------------------------------
SELECT
    Segment,
    COUNT(*)                                                       AS customers,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 1)               AS pct_customers,
    ROUND(SUM(Monetary), 0)                                        AS revenue,
    ROUND(SUM(Monetary) * 100 / SUM(SUM(Monetary)) OVER (), 1)     AS pct_revenue
FROM rfm_segments
GROUP BY Segment
ORDER BY revenue DESC;
 
-- ---------------------------------------------------------------------
-- 5. Pareto check: revenue share of the top 20% customers
--    Expected: 74.7
-- ---------------------------------------------------------------------
SELECT
    ROUND(SUM(Monetary) * 100 / (SELECT SUM(Monetary) FROM rfm_base), 1)
        AS pct_revenue_top20
FROM (
    SELECT Monetary,
           NTILE(5) OVER (ORDER BY Monetary DESC) AS grp
    FROM rfm_base
) AS t
WHERE grp = 1;
 