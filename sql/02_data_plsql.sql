-- =============================================================================
-- 02_data_plsql.sql — aizpildīšana ar PL/SQL un DBMS_RANDOM
-- Dimensijas: >= 20 rindas katra; fakti: >= 100 000 rindas
-- Faktu ielāde: masveida INSERT (ātrums); priekšrocības/mērķis — PL/SQL bloks
-- un DBMS_RANDOM, kā prasa uzdevums.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON

DECLARE
    c_dim_min      CONSTANT PLS_INTEGER := 25;  -- dimensiju apjoms (>= 20)
    c_fact_rows    CONSTANT PLS_INTEGER := 120000;  -- faktu skaits (>= 100000)

    v_start_date   DATE := DATE '2019-01-01';

    PROCEDURE seed_random IS
    BEGIN
        DBMS_RANDOM.SEED(42);
    END seed_random;

BEGIN
    seed_random;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE fact_sales';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE dim_calendar';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE dim_product';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE dim_store';

    -- --- dim_calendar ---
    FOR i IN 1 .. c_dim_min LOOP
        INSERT INTO dim_calendar (
            calendar_id, full_date, year_no, quarter_no, month_no, day_no, iso_week_no
        ) VALUES (
            i,
            v_start_date + (i - 1),
            TO_NUMBER(TO_CHAR(v_start_date + (i - 1), 'YYYY')),
            TO_NUMBER(TO_CHAR(v_start_date + (i - 1), 'Q')),
            TO_NUMBER(TO_CHAR(v_start_date + (i - 1), 'MM')),
            TO_NUMBER(TO_CHAR(v_start_date + (i - 1), 'DD')),
            NULL
        );
    END LOOP;

    -- --- dim_product (DBMS_RANDOM.STRING preču nosaukumam) ---
    FOR p IN 1 .. c_dim_min LOOP
        INSERT INTO dim_product (
            product_id,
            product_name,
            category_name,
            subcategory_name,
            brand_name,
            sku_code
        ) VALUES (
            p,
            'Product_' || p || '_' || DBMS_RANDOM.STRING('X', 6),
            'CAT' || CHR(64 + MOD(p - 1, 5) + 1),
            'SUB' || TO_CHAR(MOD(p, 4)),
            'Brand_' || TO_CHAR(MOD(p, 7)),
            'SKU' || LPAD(TO_CHAR(p), 6, '0')
        );
    END LOOP;

    -- --- dim_store ---
    FOR s IN 1 .. c_dim_min LOOP
        INSERT INTO dim_store (
            store_id,
            store_name,
            city_name,
            region_name,
            country_name,
            store_type
        ) VALUES (
            s,
            'Store_' || TO_CHAR(s),
            'City_' || TO_CHAR(MOD(s, 6)),
            'Region_' || TO_CHAR(MOD(s, 4)),
            CASE WHEN MOD(s, 2) = 0 THEN 'LV' ELSE 'LT' END,
            CASE WHEN MOD(s, 3) = 0 THEN 'Hyper' WHEN MOD(s, 3) = 1 THEN 'Mini' ELSE 'Standard' END
        );
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Dimensijas ielādētas: ' || c_dim_min || ' rindas katra.');
END;
/

BEGIN
    DBMS_RANDOM.SEED(42);
END;
/

-- Masveida fakti (viena rinda = salīdzināmi nejauši lielumi qty/price/disc → line_amount)
INSERT INTO fact_sales (sale_id, calendar_id, product_id, store_id,
                        quantity_sold, unit_price, discount_pct, line_amount)
SELECT
    lvl,
    cal_id,
    prod_id,
    str_id,
    qty,
    price,
    disc,
    ROUND(qty * price * (1 - disc / 100), 2)
FROM (
    SELECT
        LEVEL AS lvl,
        TRUNC(DBMS_RANDOM.VALUE(1, 25.999))     AS cal_id,
        TRUNC(DBMS_RANDOM.VALUE(1, 25.999))     AS prod_id,
        TRUNC(DBMS_RANDOM.VALUE(1, 25.999))     AS str_id,
        TRUNC(DBMS_RANDOM.VALUE(1, 12.999))     AS qty,
        ROUND(DBMS_RANDOM.VALUE(0.5, 250), 2)   AS price,
        ROUND(DBMS_RANDOM.VALUE(0, 25), 2)      AS disc
    FROM   dual
    CONNECT BY LEVEL <= 120000
);

COMMIT;

SELECT 'fact_sales' AS tbl, COUNT(*) AS cnt FROM fact_sales;

EXIT;
