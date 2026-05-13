-- =============================================================================
-- Task2 / sql / 04_relational_queries_plan.sql
-- Pieci SELECT: visas četras tabulas, savienojums klasiskā FROM a,b WHERE (bez JOIN sintakses)
-- Divi vaicājumi izmanto f2_line_value un f2_region_label (RQ1, RQ2)
-- Izpilda EXPLAIN PLAN — COST vērtības salīdzināšanai (plāna attēlus atskaitē neliekam pēc uzdevuma)
-- =============================================================================

SET LINESIZE 220 PAGESIZE 200
SET SERVEROUTPUT OFF

DELETE FROM plan_table;
COMMIT;

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'T2_REGION');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'T2_STORE');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'T2_PRODUCT');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'T2_SALE');
END;
/

-- RQ1: funkcija f2_line_value — kopējā pārdošanas vērtība pa reģioniem
EXPLAIN PLAN SET STATEMENT_ID = 'T2_RQ1' FOR
SELECT r.region_id,
       SUM(f2_line_value(p.unit_price, sl.qty)) AS kopeja_summa
FROM   t2_region r,
       t2_store s,
       t2_product p,
       t2_sale sl
WHERE  r.region_id = s.region_id
AND    s.store_id = sl.store_id
AND    p.product_id = sl.product_id
GROUP BY r.region_id;

-- RQ2: funkcija f2_region_label — uzmērkēšana un rindu skaits
EXPLAIN PLAN SET STATEMENT_ID = 'T2_RQ2' FOR
SELECT f2_region_label(r.region_id) AS reg_kods,
       COUNT(*) AS izp_rindas
FROM   t2_region r,
       t2_store s,
       t2_product p,
       t2_sale sl
WHERE  r.region_id = s.region_id
AND    s.store_id = sl.store_id
AND    p.product_id = sl.product_id
GROUP BY r.region_id;

-- RQ3: vidējā pārdotā daudzuma un preces cenas summa (funkcijas nav obligātas)
EXPLAIN PLAN SET STATEMENT_ID = 'T2_RQ3' FOR
SELECT AVG(sl.qty) AS vid_daudzums,
       SUM(p.unit_price) AS cenu_summa
FROM   t2_region r,
       t2_store s,
       t2_product p,
       t2_sale sl
WHERE  r.region_id = s.region_id
AND    s.store_id = sl.store_id
AND    p.product_id = sl.product_id
AND    r.region_id IN (1, 2, 3);

-- RQ4: ieraksti ar konkrētu datumu intervālu
EXPLAIN PLAN SET STATEMENT_ID = 'T2_RQ4' FOR
SELECT SUM(sl.qty) AS kopejais_daudzums
FROM   t2_region r,
       t2_store s,
       t2_product p,
       t2_sale sl
WHERE  r.region_id = s.region_id
AND    s.store_id = sl.store_id
AND    p.product_id = sl.product_id
AND    sl.sale_date >= DATE '2019-03-01'
AND    sl.sale_date < DATE '2019-05-01';

-- RQ5: reģioni ar lielu pārdoto daudzumu kopsummā
EXPLAIN PLAN SET STATEMENT_ID = 'T2_RQ5' FOR
SELECT r.region_id,
       SUM(sl.qty) AS kopa_qty
FROM   t2_region r,
       t2_store s,
       t2_product p,
       t2_sale sl
WHERE  r.region_id = s.region_id
AND    s.store_id = sl.store_id
AND    p.product_id = sl.product_id
GROUP BY r.region_id
HAVING SUM(sl.qty) > 15000;

PROMPT === Relāciju: saknes SELECT STATEMENT — COST ===
SELECT p.statement_id,
       p.cost AS root_cost
FROM   plan_table p
WHERE  p.operation = 'SELECT STATEMENT'
AND    p.parent_id IS NULL
AND    p.statement_id IN ('T2_RQ1','T2_RQ2','T2_RQ3','T2_RQ4','T2_RQ5')
ORDER BY p.statement_id;

EXIT;
