-- =============================================================================
-- Task2 / sql / 02_relational_data.sql
-- Testa dati: T2_SALE >= 100 000 rindas
-- =============================================================================

BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE t2_sale';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE t2_store';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE t2_product';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE t2_region';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN DBMS_RANDOM.SEED(137); END;
/

INSERT INTO t2_region (region_id, r_name)
SELECT LEVEL, 'Reģions_' || LEVEL FROM dual CONNECT BY LEVEL <= 5;

-- 25 veikali: pieci uz katru reģionu (region_id skaita 1 līdz 5)
INSERT INTO t2_store (store_id, region_id, s_name)
SELECT s,
       1 + FLOOR((s - 1) / 5),
       'Veikals_' || s
FROM   (SELECT LEVEL s FROM dual CONNECT BY LEVEL <= 25);

INSERT INTO t2_product (product_id, p_name, unit_price)
SELECT LEVEL,
       'Produkts_' || LEVEL,
       ROUND(DBMS_RANDOM.VALUE(0.5, 500), 2)
FROM   dual
CONNECT BY LEVEL <= 200;

COMMIT;

INSERT INTO t2_sale (sale_id, store_id, product_id, qty, sale_date)
SELECT sale_row,
       TRUNC(DBMS_RANDOM.VALUE(1, 25.999)),
       TRUNC(DBMS_RANDOM.VALUE(1, 200.999)),
       TRUNC(DBMS_RANDOM.VALUE(1, 20)),
       DATE '2019-01-01' + MOD(sale_row, 240)
FROM (
    SELECT LEVEL AS sale_row FROM dual CONNECT BY LEVEL <= 120000
);

COMMIT;

SELECT 't2_region', COUNT(*) FROM t2_region UNION ALL
SELECT 't2_store', COUNT(*) FROM t2_store UNION ALL
SELECT 't2_product', COUNT(*) FROM t2_product UNION ALL
SELECT 't2_sale', COUNT(*) FROM t2_sale;

EXIT;
