-- =============================================================================
-- Task2 / sql / 07_object_queries_plan.sql
-- Pieci SELECT uz objektu tabulu (TABLE kolekcijām, MEMBER metodes)
-- Atbilst 04_relational_queries_plan.sql (OQ1..OQ5 = RQ1..RQ5)
-- =============================================================================

SET LINESIZE 220 PAGESIZE 200
SET SERVEROUTPUT OFF

DELETE FROM plan_table;
COMMIT;

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'T2_REGION_OBJ_TAB', CASCADE => TRUE);
END;
/

-- OQ1: MEMBER line_value (analoga f2_line_value)
EXPLAIN PLAN SET STATEMENT_ID = 'T2_OQ1' FOR
SELECT t.region_id,
       SUM(l.line_value()) AS kopeja_summa
FROM   t2_region_obj_tab t,
       TABLE(t.stores) st,
       TABLE(st.lines) l
GROUP BY t.region_id;

-- OQ2: MEMBER region_label (analoga f2_region_label)
EXPLAIN PLAN SET STATEMENT_ID = 'T2_OQ2' FOR
SELECT MAX(t.region_label()) AS reg_kods,
       COUNT(*) AS izp_rindas,
       t.region_id
FROM   t2_region_obj_tab t,
       TABLE(t.stores) st,
       TABLE(st.lines) l
GROUP BY t.region_id;

-- OQ3: atbilst RQ3; produkta MEMBER revenue_for_qty (vienāds ar rindas vērtību — filtrs tautoloģiski patiess)
EXPLAIN PLAN SET STATEMENT_ID = 'T2_OQ3' FOR
SELECT AVG(l.qty) AS vid_daudzums,
       SUM(l.prod.unit_price) AS cenu_summa
FROM   t2_region_obj_tab t,
       TABLE(t.stores) st,
       TABLE(st.lines) l
WHERE  t.region_id IN (1, 2, 3)
AND    (l.prod).revenue_for_qty(l.qty) = l.line_value();

-- OQ4: datumu intervāls (atbilst RQ4 — tikai daudzuma summa)
EXPLAIN PLAN SET STATEMENT_ID = 'T2_OQ4' FOR
SELECT SUM(l.qty) AS kopejais_daudzums
FROM   t2_region_obj_tab t,
       TABLE(t.stores) st,
       TABLE(st.lines) l
WHERE  l.sale_date >= DATE '2019-03-01'
AND    l.sale_date < DATE '2019-05-01'
AND    l.line_value() >= 0;

-- OQ5: reģioni ar lielu pārdoto daudzumu
EXPLAIN PLAN SET STATEMENT_ID = 'T2_OQ5' FOR
SELECT t.region_id,
       SUM(l.qty) AS kopa_qty,
       MAX(t.total_qty()) AS reģiona_kopā_qty_metode
FROM   t2_region_obj_tab t,
       TABLE(t.stores) st,
       TABLE(st.lines) l
GROUP BY t.region_id
HAVING SUM(l.qty) > 15000;

PROMPT === Objektu tabula: saknes SELECT STATEMENT — COST ===
SELECT p.statement_id,
       p.cost AS root_cost
FROM   plan_table p
WHERE  p.operation = 'SELECT STATEMENT'
AND    p.parent_id IS NULL
AND    p.statement_id IN ('T2_OQ1','T2_OQ2','T2_OQ3','T2_OQ4','T2_OQ5')
ORDER BY p.statement_id;

EXIT;
