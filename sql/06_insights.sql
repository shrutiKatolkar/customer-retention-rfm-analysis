/* =====================================================================
   Project : Customer Retention & RFM Segmentation
   File    : 06_insights.sql
   Purpose : Extra business insights used in the README.
   Input   : clean_retail_final
   ===================================================================== */

USE retail_project;

-- 1. Revenue share of the top 5 countries.
--    Expected: United Kingdom 82.0, Netherlands 3.2, EIRE 3.0,
--              Germany 2.6, France 2.4
SELECT
    Country,
    ROUND(SUM(TotalPrice) * 100 /
          (SELECT SUM(TotalPrice) FROM clean_retail_final), 1) AS pct_revenue
FROM clean_retail_final
GROUP BY Country
ORDER BY pct_revenue DESC
LIMIT 5;