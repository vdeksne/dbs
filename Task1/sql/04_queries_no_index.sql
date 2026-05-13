-- =============================================================================
-- 04_queries_no_index.sql — 3 agregātu vaicājumi, EXPLAIN PLAN
-- PIRMS tam: nav faktu tabulas indeksu (vai 06 sākuma stāvoklis).
-- Ieteiksme: @08_gather_stats.sql
-- =============================================================================

SET LINESIZE 220
SET PAGESIZE 100
SET TIMING ON

ALTER SESSION SET STATISTICS_LEVEL = ALL;

-- Pārliecinieties, ka nav indeksu uz fact_sales (kā kontrole)
-- SELECT index_name FROM user_ind_columns WHERE table_name = 'FACT_SALES';

-- Q1: SUM, COUNT pēc gada un preču kategorijas
EXPLAIN PLAN SET STATEMENT_ID = 'Q1_NO_IDX' FOR
SELECT c.year_no,
       p.category_name,
       SUM(fs.line_amount)     AS sum_amount,
       COUNT(*)                AS cnt_rows,
       SUM(fs.quantity_sold)   AS sum_qty
FROM   fact_sales fs
JOIN   dim_calendar c ON c.calendar_id = fs.calendar_id
JOIN   dim_product  p ON p.product_id = fs.product_id
GROUP BY c.year_no, p.category_name;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q1_NO_IDX', 'TYPICAL'));

SELECT c.year_no, p.category_name,
       SUM(fs.line_amount) AS sum_amount, COUNT(*) AS cnt_rows
FROM   fact_sales fs
JOIN   dim_calendar c ON c.calendar_id = fs.calendar_id
JOIN   dim_product  p ON p.product_id = fs.product_id
GROUP BY c.year_no, p.category_name
ORDER BY c.year_no, p.category_name;

-- Q2: AVG, SUM pēc reģiona (dimensija veikals)
EXPLAIN PLAN SET STATEMENT_ID = 'Q2_NO_IDX' FOR
SELECT s.region_name,
       ROUND(AVG(fs.unit_price), 4) AS avg_price,
       SUM(fs.line_amount)         AS sum_amount,
       COUNT(*)                    AS cnt_rows
FROM   fact_sales fs
JOIN   dim_store s ON s.store_id = fs.store_id
GROUP BY s.region_name;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q2_NO_IDX', 'TYPICAL'));

SELECT s.region_name,
       ROUND(AVG(fs.unit_price), 4) AS avg_price,
       SUM(fs.line_amount) AS sum_amount
FROM   fact_sales fs
JOIN   dim_store s ON s.store_id = fs.store_id
GROUP BY s.region_name;

-- Q3: COUNT, SUM pēc ceturkšņa un veikala
EXPLAIN PLAN SET STATEMENT_ID = 'Q3_NO_IDX' FOR
SELECT c.quarter_no,
       s.store_name,
       COUNT(*)              AS cnt_sales,
       SUM(fs.quantity_sold) AS sum_qty
FROM   fact_sales fs
JOIN   dim_calendar c ON c.calendar_id = fs.calendar_id
JOIN   dim_store    s ON s.store_id = fs.store_id
GROUP BY c.quarter_no, s.store_name;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q3_NO_IDX', 'TYPICAL'));

SELECT c.quarter_no, s.store_name, COUNT(*) AS cnt_sales
FROM   fact_sales fs
JOIN   dim_calendar c ON c.calendar_id = fs.calendar_id
JOIN   dim_store    s ON s.store_id = fs.store_id
GROUP BY c.quarter_no, s.store_name
ORDER BY c.quarter_no, s.store_name;

EXIT;
