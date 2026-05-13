-- =============================================================================
-- 07_materialized_views.sql — 3 materializētie skati, refresh, laiki, rewrite
-- MV3 būvējas uz MV1 un MV2 (JOIN pēc year_no).
-- =============================================================================

SET TIMING ON
SET LINESIZE 220
SET SERVEROUTPUT ON SIZE UNLIMITED

ALTER SESSION SET QUERY_REWRITE_ENABLED = TRUE;
ALTER SESSION SET QUERY_REWRITE_INTEGRITY = TRUSTED;

-- (Pēc uzdevuma 5/6) pieņemsim kādu indeksu režīmu; šeit paliež BITMAP, ja eksistē.
-- Ieteikums: EXEC DBMS_STATS.GATHER_SCHEMA_STATS(USER);

WHENEVER SQLERROR CONTINUE

DROP MATERIALIZED VIEW mv_cat_reg_year;
DROP MATERIALIZED VIEW mv_region_month_sales;
DROP MATERIALIZED VIEW mv_year_category_sales;

WHENEVER SQLERROR EXIT SQL.SQLCODE

-- MV1: faktu + dimensijas — pārdošana pēc gada un preču kategorijas
CREATE MATERIALIZED VIEW mv_year_category_sales
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT c.year_no,
       p.category_name,
       SUM(fs.line_amount)   AS total_amount,
       COUNT(*)              AS cnt_rows,
       SUM(fs.quantity_sold) AS sum_qty
FROM   fact_sales fs
JOIN   dim_calendar c ON c.calendar_id = fs.calendar_id
JOIN   dim_product  p ON p.product_id = fs.product_id
GROUP BY c.year_no, p.category_name;

-- MV2: pārdošana pēc reģiona un laika mēneša (nepieciešams year JOIN ar MV1)
CREATE MATERIALIZED VIEW mv_region_month_sales
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT c.year_no,
       c.month_no,
       s.region_name,
       SUM(fs.line_amount)   AS total_amount,
       COUNT(*)              AS cnt_rows,
       SUM(fs.quantity_sold) AS sum_qty
FROM   fact_sales fs
JOIN   dim_calendar c ON c.calendar_id = fs.calendar_id
JOIN   dim_store    s ON s.store_id = fs.store_id
GROUP BY c.year_no, c.month_no, s.region_name;

-- MV3: balstīts uz MV1 un MV2 — salīdzinoša matrica (gads × kategorija × reģions)
CREATE MATERIALIZED VIEW mv_cat_reg_year
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT y.year_no,
       y.category_name,
       r.region_name,
       y.total_amount AS amount_by_category_year,
       r.total_amount AS amount_by_region_month,
       y.sum_qty      AS qty_by_category,
       r.sum_qty      AS qty_by_region_month
FROM   mv_year_category_sales y
JOIN   mv_region_month_sales r
       ON y.year_no = r.year_no;

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'MV_YEAR_CATEGORY_SALES', CASCADE => TRUE);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'MV_REGION_MONTH_SALES', CASCADE => TRUE);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'MV_CAT_REG_YEAR', CASCADE => TRUE);

-- ---------- Refresh laiku mērījumi ----------
DECLARE
    t0 NUMBER;
    t1 NUMBER;
BEGIN
    t0 := DBMS_UTILITY.GET_TIME;
    DBMS_MVIEW.REFRESH('MV_YEAR_CATEGORY_SALES', method => 'C', atomic_refresh => FALSE);
    t1 := DBMS_UTILITY.GET_TIME;
    DBMS_OUTPUT.PUT_LINE('REFRESH MV_YEAR_CATEGORY_SALES (centisekundes): ' || (t1 - t0) / 100.0);

    t0 := DBMS_UTILITY.GET_TIME;
    DBMS_MVIEW.REFRESH('MV_REGION_MONTH_SALES', method => 'C', atomic_refresh => FALSE);
    t1 := DBMS_UTILITY.GET_TIME;
    DBMS_OUTPUT.PUT_LINE('REFRESH MV_REGION_MONTH_SALES (centisekundes): ' || (t1 - t0) / 100.0);

    t0 := DBMS_UTILITY.GET_TIME;
    DBMS_MVIEW.REFRESH('MV_CAT_REG_YEAR', method => 'C', atomic_refresh => FALSE);
    t1 := DBMS_UTILITY.GET_TIME;
    DBMS_OUTPUT.PUT_LINE('REFRESH MV_CAT_REG_YEAR (centisekundes): ' || (t1 - t0) / 100.0);
END;
/

-- ---------- Query rewrite: DBMS_MVIEW.EXPLAIN_REWRITE ----------
-- Vienreiz sesijā (kā SYS vai ar tiesībām): @?/rdbms/admin/utlrwr.sql
-- Tad šī procedūra aizpilda REWRITE_TABLE un kļūst redzams vai MV atbilst.

DECLARE
    q1 CLOB;
BEGIN
    q1 := 'SELECT c.year_no, p.category_name, SUM(fs.line_amount) ' ||
          'FROM fact_sales fs ' ||
          'JOIN dim_calendar c ON c.calendar_id = fs.calendar_id ' ||
          'JOIN dim_product p ON p.product_id = fs.product_id ' ||
          'GROUP BY c.year_no, p.category_name';
    DBMS_MVIEW.EXPLAIN_REWRITE(q1, 'MV_YEAR_CATEGORY_SALES', 'LAB_MV1');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('EXPLAIN_REWRITE neizdevās (bieži: nav utlrwr.sql / rewrite_table): ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Risinājums: @?/rdbms/admin/utlrwr.sql ; pēc tam atkārtot plūsmu.');
END;
/

PROMPT ---- Ja izveidota rewrite_table, skatiet: SELECT * FROM rewrite_table WHERE statement_id='LAB_MV1';

-- ---------- EXPLAIN PLAN — meklējiet plānā MAT_VIEW ... vai uzraudziet NOTE sadaļu ----------
EXPLAIN PLAN SET STATEMENT_ID = 'RW_Q1' FOR
SELECT /*+ REWRITE */
       c.year_no,
       p.category_name,
       SUM(fs.line_amount) AS total_amount
FROM   fact_sales fs
JOIN   dim_calendar c ON c.calendar_id = fs.calendar_id
JOIN   dim_product  p ON p.product_id = fs.product_id
GROUP BY c.year_no, p.category_name;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'RW_Q1', 'TYPICAL +NOTE'));

EXIT;
