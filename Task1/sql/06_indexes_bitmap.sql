-- =============================================================================
-- 06_indexes_bitmap.sql — B-koku dzēšana, BITMAP indeksi uz tiem pašiem FK
-- Ja BitMap nav pieejams (licence), komentējiet CREATE BITMAP un saglabājiet BTREE.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET LINESIZE 220

BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_fs_btree_cal';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -1418 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_fs_btree_prod';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -1418 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_fs_btree_store';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -1418 THEN RAISE; END IF; END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE BITMAP INDEX idx_fs_bm_cal   ON fact_sales (calendar_id)';
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('BITMAP calendar_id: ' || SQLERRM);
END;
/
BEGIN
    EXECUTE IMMEDIATE 'CREATE BITMAP INDEX idx_fs_bm_prod  ON fact_sales (product_id)';
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('BITMAP product_id: ' || SQLERRM);
END;
/
BEGIN
    EXECUTE IMMEDIATE 'CREATE BITMAP INDEX idx_fs_bm_store ON fact_sales (store_id)';
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('BITMAP store_id: ' || SQLERRM);
END;
/

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'FACT_SALES', CASCADE => TRUE);

EXPLAIN PLAN SET STATEMENT_ID = 'Q1_BITMAP' FOR
SELECT c.year_no, p.category_name,
       SUM(fs.line_amount) AS sum_amount, COUNT(*) AS cnt_rows
FROM   fact_sales fs
JOIN   dim_calendar c ON c.calendar_id = fs.calendar_id
JOIN   dim_product  p ON p.product_id = fs.product_id
GROUP BY c.year_no, p.category_name;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q1_BITMAP', 'TYPICAL'));

EXPLAIN PLAN SET STATEMENT_ID = 'Q2_BITMAP' FOR
SELECT s.region_name,
       ROUND(AVG(fs.unit_price), 4) AS avg_price,
       SUM(fs.line_amount) AS sum_amount
FROM   fact_sales fs
JOIN   dim_store s ON s.store_id = fs.store_id
GROUP BY s.region_name;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q2_BITMAP', 'TYPICAL'));

EXPLAIN PLAN SET STATEMENT_ID = 'Q3_BITMAP' FOR
SELECT c.quarter_no, s.store_name, COUNT(*) AS cnt_sales
FROM   fact_sales fs
JOIN   dim_calendar c ON c.calendar_id = fs.calendar_id
JOIN   dim_store    s ON s.store_id = fs.store_id
GROUP BY c.quarter_no, s.store_name;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q3_BITMAP', 'TYPICAL'));

EXIT;
