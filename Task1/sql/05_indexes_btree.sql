-- =============================================================================
-- 05_indexes_btree.sql — B-koka indeksi uz FK (faktu tabula)
-- Pēc tam atkārtojiet tos pašus 3 vaicājumus un salīdziniet plānus / laiku.
-- =============================================================================

SET TIMING ON
SET LINESIZE 220

-- B-tree indeksi (parasti automātiski izmanto vienādrādības un JOIN uz FK)
CREATE INDEX idx_fs_btree_cal   ON fact_sales (calendar_id);
CREATE INDEX idx_fs_btree_prod  ON fact_sales (product_id);
CREATE INDEX idx_fs_btree_store ON fact_sales (store_id);

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'FACT_SALES', CASCADE => TRUE);

-- Q1
EXPLAIN PLAN SET STATEMENT_ID = 'Q1_BTREE' FOR
SELECT c.year_no, p.category_name,
       SUM(fs.line_amount) AS sum_amount, COUNT(*) AS cnt_rows
FROM   fact_sales fs
JOIN   dim_calendar c ON c.calendar_id = fs.calendar_id
JOIN   dim_product  p ON p.product_id = fs.product_id
GROUP BY c.year_no, p.category_name;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q1_BTREE', 'TYPICAL'));

-- Q2
EXPLAIN PLAN SET STATEMENT_ID = 'Q2_BTREE' FOR
SELECT s.region_name,
       ROUND(AVG(fs.unit_price), 4) AS avg_price,
       SUM(fs.line_amount) AS sum_amount
FROM   fact_sales fs
JOIN   dim_store s ON s.store_id = fs.store_id
GROUP BY s.region_name;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q2_BTREE', 'TYPICAL'));

-- Q3
EXPLAIN PLAN SET STATEMENT_ID = 'Q3_BTREE' FOR
SELECT c.quarter_no, s.store_name, COUNT(*) AS cnt_sales
FROM   fact_sales fs
JOIN   dim_calendar c ON c.calendar_id = fs.calendar_id
JOIN   dim_store    s ON s.store_id = fs.store_id
GROUP BY c.quarter_no, s.store_name;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q3_BTREE', 'TYPICAL'));

EXIT;
