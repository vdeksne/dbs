-- =============================================================================
-- Task2 / sql / 06_object_load.sql
-- Datu pārliešana no relāciju tabulām uz salikto objektu tabulu
-- =============================================================================

TRUNCATE TABLE t2_region_obj_tab;

DECLARE
    v_stores t2_store_nt;
    v_lines  t2_sale_line_nt;
BEGIN
    FOR r IN (SELECT region_id, r_name FROM t2_region ORDER BY region_id) LOOP
        v_stores := t2_store_nt();

        FOR s IN (
            SELECT store_id, s_name
            FROM   t2_store
            WHERE  region_id = r.region_id
            ORDER BY store_id
        ) LOOP
            v_lines := t2_sale_line_nt();

            FOR sl IN (
                SELECT sl.sale_id,
                       sl.qty,
                       sl.sale_date,
                       p.product_id,
                       p.p_name,
                       p.unit_price
                FROM   t2_sale sl,
                       t2_product p
                WHERE  sl.product_id = p.product_id
                AND    sl.store_id = s.store_id
                ORDER BY sl.sale_id
            ) LOOP
                v_lines.EXTEND;
                v_lines(v_lines.LAST) := t2_sale_line_t(
                    sl.sale_id,
                    sl.qty,
                    sl.sale_date,
                    t2_product_t(sl.product_id, sl.p_name, sl.unit_price)
                );
            END LOOP;

            v_stores.EXTEND;
            v_stores(v_stores.LAST) := t2_store_t(s.store_id, s.s_name, v_lines);
        END LOOP;

        INSERT INTO t2_region_obj_tab
        VALUES (t2_region_o(r.region_id, r.r_name, v_stores));
    END LOOP;

    COMMIT;
END;
/

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'T2_REGION_OBJ_TAB', CASCADE => TRUE);
END;
/

SELECT 't2_region_obj_tab', COUNT(*) FROM t2_region_obj_tab;

EXIT;
