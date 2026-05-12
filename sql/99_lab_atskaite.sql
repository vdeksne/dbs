REM =============================================================================
REM 99_lab_atskaite.sql
REM Izveido vienkāršu LAB_ATBILDES.txt VISAM RTU OLAP uzdevuma punktiem 1 līdz 8.
REM PRIEKŠ nosacījums: PLAN_TABLE satur EXPLAIN PLAN no palaišām 04, 05 un 06
REM                     (statement_id: Q?_NO_IDX, Q?_BTREE, Q?_BITMAP).
REM ARĪ: 07 jau veiksmīgi izveidojis trīs materializētos skatus.
REM SQL*Plus: neizmantot PROMPT līnijas ar "---", jo '--' sāk SQL komentāru.
REM Palaišana: sqlplus lietotajs/parole@//host:1521/FREEPDB1 @sql/99_lab_atskaite.sql (cwd = saknes projekta mape LAB_ATBILDES.txt vietai)
REM =============================================================================

SET ECHO OFF
SET FEEDBACK ON
SET HEADING ON
SET VERIFY OFF
SET DEFINE OFF
SET SQLBLANKLINES ON
SET LINESIZE 240
SET PAGESIZE 9999
SET LONG 800000
SET LONGCHUNKSIZE 800000
SET TRIMSPOOL ON
SET TAB OFF
SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT WRAPPED

ALTER SESSION SET QUERY_REWRITE_ENABLED = TRUE;
ALTER SESSION SET QUERY_REWRITE_INTEGRITY = TRUSTED;

COLUMN apraksts FORMAT A78 WORD_WRAPPED

SPOOL LAB_ATBILDES.txt REPLACE

REM *****************************************************************************
PROMPT
PROMPT *************************************************************************
PROMPT   PRAKTISKAIS DARBS: DAUDZDIMENSIJU DATU BĀZE (atskaites izvade)
PROMPT *************************************************************************

SELECT 'Ģenerēts: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
       || '; lietotājs=' || SYS_CONTEXT('USERENV', 'SESSION_USER') AS teksts
FROM dual;


REM *****************************************************************************
REM 1.-2. Projektu apraksts; grafika skatīt schema_diagram.txt
REM *****************************************************************************
PROMPT
PROMPT [1.-2.] Zvaigžņu shēma: FACT_SALES plus trīs dimensijas un hierarhijas

SELECT lvl,
       CAST(apraksts AS VARCHAR2(500)) apraksts
FROM (
 SELECT 1 lvl,
  'FACT_SALES faktu tabula: vienai pārdošanas pozīcijai vienā laikā vienā vietā vienai precei.' apraksts FROM dual
 UNION ALL SELECT 2,
  ' DIM_CALENDAR laikā hierarhija gads ceturksnis mēnesis diena kolonnās year_no quarter_no month_no day_no un full_date.' FROM dual
 UNION ALL SELECT 3,
  ' DIM_PRODUCT hierarhija kategorija apakškategorija zīmols nosaukums sku kods (vismaz piecas kolonnas papildus atslēgai).' FROM dual
 UNION ALL SELECT 4,
  ' DIM_STORE hierarhija valsts reģions pilsēta veikala tips un veikala nosaukums.' FROM dual
 UNION ALL SELECT 5,
  ' Grafiskais attēls: schema_diagram.txt (ASCII vai Mermaid ER blokā).' FROM dual
) ORDER BY lvl;


REM *****************************************************************************
REM 3.-4. DATU tilpums un darbspējīgas struktūras pārbaude
REM *****************************************************************************
PROMPT
PROMPT [3.-4.] Dimensijas vismaz 20 rindas faktu tabula vismaz 100 000 rindas

WITH s AS (
  SELECT 'dim_calendar' tb, COUNT(*) rc FROM dim_calendar UNION ALL
  SELECT 'dim_product',   COUNT(*) FROM dim_product UNION ALL
  SELECT 'dim_store',     COUNT(*) FROM dim_store UNION ALL
  SELECT 'fact_sales',    COUNT(*) FROM fact_sales
)
SELECT tb tabula,
       rc rindas,
       CASE WHEN tb = 'fact_sales' THEN
         CASE WHEN rc >= 100000 THEN 'prasība izpildīta' ELSE 'trūkst faktu rindu' END
       ELSE
         CASE WHEN rc >= 20 THEN 'prasība izpildīta' ELSE 'trūkst dimensiju rindu' END
       END stāvoklis
FROM s
ORDER BY tb;


PROMPT
PROMPT [4.] Kontroles SELECT: piecas pirmās faktu rindas ar JOIN uz dimensijām

SELECT fs.sale_id,
       TO_CHAR(c.full_date,'YYYY-MM-DD') datums,
       p.category_name,
       s.region_name,
       fs.quantity_sold,
       fs.line_amount
FROM   fact_sales fs
JOIN   dim_calendar c ON c.calendar_id = fs.calendar_id
JOIN   dim_product  p ON p.product_id  = fs.product_id
JOIN   dim_store    s ON s.store_id    = fs.store_id
WHERE  fs.sale_id <= 5
ORDER BY fs.sale_id;


REM *****************************************************************************
REM 5 PLAN_TABLE saknes COST iz EXPLAIN kuri jau tika veikti failos 04 05 un 06
REM *****************************************************************************
PROMPT
PROMPT [5.] Agregātvaicājumi: salīdziniet saknes COST trīs situācijās (bez/B-tree/bit)

WITH lp AS (
  SELECT statement_id, MAX(plan_id) max_pid FROM plan_table GROUP BY statement_id
),
roots_q1 AS (
  SELECT p.statement_id, MAX(NVL(p.cost,0)) AS cost
  FROM   plan_table p
  JOIN   lp ON lp.statement_id = p.statement_id AND lp.max_pid = p.plan_id
  WHERE  UPPER(p.operation) LIKE 'SELECT STATEMENT%'
  AND    p.parent_id IS NULL
  AND    p.statement_id IN ('Q1_NO_IDX','Q1_BTREE','Q1_BITMAP')
  GROUP BY p.statement_id
)
SELECT 'Q1 gads+kategorija SUM COUNT' AS apraksts,
       MAX(DECODE(statement_id,'Q1_NO_IDX', cost)) NAV_INDEKSA_COST,
       MAX(DECODE(statement_id,'Q1_BTREE',  cost)) B_TREE_COST,
       MAX(DECODE(statement_id,'Q1_BITMAP', cost)) BITMAP_COST
FROM   roots_q1;


WITH lp AS (
  SELECT statement_id, MAX(plan_id) max_pid FROM plan_table GROUP BY statement_id
),
roots_q2 AS (
  SELECT p.statement_id, MAX(NVL(p.cost,0)) AS cost
  FROM   plan_table p
  JOIN   lp ON lp.statement_id = p.statement_id AND lp.max_pid = p.plan_id
  WHERE  UPPER(p.operation) LIKE 'SELECT STATEMENT%'
  AND    p.parent_id IS NULL
  AND    p.statement_id IN ('Q2_NO_IDX','Q2_BTREE','Q2_BITMAP')
  GROUP BY p.statement_id
)
SELECT 'Q2 reģions AVG SUM COUNT' apraksts,
       MAX(DECODE(statement_id,'Q2_NO_IDX', cost)) NAV_INDEKSA_COST,
       MAX(DECODE(statement_id,'Q2_BTREE',  cost)) B_TREE_COST,
       MAX(DECODE(statement_id,'Q2_BITMAP', cost)) BITMAP_COST
FROM   roots_q2;


WITH lp AS (
  SELECT statement_id, MAX(plan_id) max_pid FROM plan_table GROUP BY statement_id
),
roots_q3 AS (
  SELECT p.statement_id, MAX(NVL(p.cost,0)) AS cost
  FROM   plan_table p
  JOIN   lp ON lp.statement_id = p.statement_id AND lp.max_pid = p.plan_id
  WHERE  UPPER(p.operation) LIKE 'SELECT STATEMENT%'
  AND    p.parent_id IS NULL
  AND    p.statement_id IN ('Q3_NO_IDX','Q3_BTREE','Q3_BITMAP')
  GROUP BY p.statement_id
)
SELECT 'Q3 ceturksnis un veikala nosaukums COUNT SUM' apraksts,
       MAX(DECODE(statement_id,'Q3_NO_IDX', cost)) NAV_INDEKSA_COST,
       MAX(DECODE(statement_id,'Q3_BTREE',  cost)) B_TREE_COST,
       MAX(DECODE(statement_id,'Q3_BITMAP', cost)) BITMAP_COST
FROM   roots_q3;


PROMPT
PROMPT [5.] Skaidrojums: mazāks COST optimizeram parasti norāda vieglāk plānu ar līdzīgu statistiku.
PROMPT Pilni EXPLAIN PLAN izvades bija skriptos 04 05 un 06. Ja BITMAP_COST ir NULL pārbaudiet CREATE BITMAP kļūdu vai indeksu tipu uz FACT_SALES.
PROMPT Piezīme prasmīgam secinājumam: COST ir optimizer modelis nevis sekundes; BitMap ne vienmār ir mazākais COST.
PROMPT Šīs trīs rindas ar COST ielīmējiet arī Word dokumenta rezultātu tabulā.


REM *****************************************************************************
REM 6 MATERIALIZĒTI skati refres laiks un QUERY REWRITE plānam NOTE
REM *****************************************************************************
PROMPT
PROMPT [6.] Materializētu skatu COMPLETE refres laiki sekundēs no DBMS_UTILITY.GET_TIME centisekundēm / 100

DECLARE
    t0 NUMBER;
    t1 NUMBER;
BEGIN
    t0 := DBMS_UTILITY.GET_TIME;
    DBMS_MVIEW.REFRESH('MV_YEAR_CATEGORY_SALES', method => 'C', atomic_refresh => FALSE);
    t1 := DBMS_UTILITY.GET_TIME;
    DBMS_OUTPUT.PUT_LINE('MV_YEAR_CATEGORY_SALES_refresh_s ' || ROUND((t1-t0)/100.0,4));

    t0 := DBMS_UTILITY.GET_TIME;
    DBMS_MVIEW.REFRESH('MV_REGION_MONTH_SALES', method => 'C', atomic_refresh => FALSE);
    t1 := DBMS_UTILITY.GET_TIME;
    DBMS_OUTPUT.PUT_LINE('MV_REGION_MONTH_SALES_refresh_s ' || ROUND((t1-t0)/100.0,4));

    t0 := DBMS_UTILITY.GET_TIME;
    DBMS_MVIEW.REFRESH('MV_CAT_REG_YEAR', method => 'C', atomic_refresh => FALSE);
    t1 := DBMS_UTILITY.GET_TIME;
    DBMS_OUTPUT.PUT_LINE('MV_CAT_REG_YEAR_refresh_s ' || ROUND((t1-t0)/100.0,4));
EXCEPTION
WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('REFRESH_KLUDA ' || SQLERRM);
END;
/


PROMPT
PROMPT [6.] USER_MVIEWS (rewrite iespēja)

SELECT mview_name,
       rewrite_capability
FROM   user_mviews
ORDER BY mview_name;


PROMPT
PROMPT [6.] REWRITE pierādījums: EXPLAIN PLAN ar hint REWRITE un NOTE sadaļu

DELETE FROM plan_table WHERE statement_id = 'ATSK_RW_Q1';

EXPLAIN PLAN SET STATEMENT_ID = 'ATSK_RW_Q1' FOR
SELECT /*+ REWRITE */
       c.year_no,
       p.category_name,
       SUM(fs.line_amount) AS total_amount
FROM   fact_sales fs
JOIN   dim_calendar c ON c.calendar_id = fs.calendar_id
JOIN   dim_product  p ON p.product_id = fs.product_id
GROUP BY c.year_no, p.category_name;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'ATSK_RW_Q1', 'TYPICAL +NOTE'));


REM *****************************************************************************
REM 7.-8. Secinājumi kas jāpapildina ar jūsu interpretāciju
REM *****************************************************************************
PROMPT
PROMPT [7.] Ievietojiet šajā failā redzamos skaitļus un plānus kopsavilkuma tabulās atskaitē.
PROMPT [8.] Īss secinājumu saraksts (papildināt ar pārliecinošu argumentāciju).

SELECT 'Bitmap indeksi uz zemu kardinalitātes atslēgām zvaigžņu shēmā bieži samazina JOIN un filtra izmaksas agregātiem salīdzinot ar pilnu tabulas skenēšanu.' AS secinajums FROM dual
UNION ALL SELECT 'B-koka indeksi uz faktu ārējām atslēgām palīdz efektīvi savienot lielo faktu tabulu ar mazajām dimensiju tabulām.'
FROM dual
UNION ALL SELECT 'Materializētie skati ar query rewrite ļauj lasīt jau iepriekš saglabātos agregātus tāpēc analītiskie vaicājumi kļūst ātrāki bet datu svaigums ir atkarīgs no refresh.'
FROM dual
UNION ALL SELECT 'Trūkumi: refresh izmaksas liels diska un CPU patēriņš ja dati bieži mainās un modelis ir mazāk piemērots tipiskam OLTP ar smagu rakstīšanu.'
FROM dual;


SPOOL OFF
EXIT;
