-- =============================================================================
-- Task2 / sql / 05_object_types.sql
-- Relāciju–objektu modelis: salikta objektu tabula ar kolekcijām un metodēm
-- Hierarhija: reģions -> veikali (kolekcija) -> pārdošanas rindas (kolekcija) -> prece (iegults objekts)
-- =============================================================================

WHENEVER SQLERROR CONTINUE

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE t2_region_obj_tab CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE t2_region_o FORCE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE t2_store_nt FORCE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE t2_store_t FORCE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE t2_sale_line_nt FORCE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE t2_sale_line_t FORCE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE t2_product_t FORCE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

WHENEVER SQLERROR EXIT SQL.SQLCODE

CREATE OR REPLACE TYPE t2_product_t AS OBJECT (
    product_id   NUMBER(10),
    p_name       VARCHAR2(200),
    unit_price   NUMBER(14,2),
    MEMBER FUNCTION revenue_for_qty(p_qty NUMBER) RETURN NUMBER
);
/

CREATE OR REPLACE TYPE BODY t2_product_t AS
    MEMBER FUNCTION revenue_for_qty(p_qty NUMBER) RETURN NUMBER IS
    BEGIN
        RETURN ROUND(NVL(unit_price, 0) * NVL(p_qty, 0), 2);
    END;
END;
/

CREATE OR REPLACE TYPE t2_sale_line_t AS OBJECT (
    sale_id    NUMBER(12),
    qty        NUMBER(8),
    sale_date  DATE,
    prod       t2_product_t,
    MEMBER FUNCTION line_value RETURN NUMBER
);
/

CREATE OR REPLACE TYPE BODY t2_sale_line_t AS
    MEMBER FUNCTION line_value RETURN NUMBER IS
    BEGIN
        RETURN prod.revenue_for_qty(qty);
    END;
END;
/

CREATE OR REPLACE TYPE t2_sale_line_nt AS TABLE OF t2_sale_line_t;
/

CREATE OR REPLACE TYPE t2_store_t AS OBJECT (
    store_id   NUMBER(8),
    s_name     VARCHAR2(160),
    lines      t2_sale_line_nt,
    MEMBER FUNCTION store_line_value RETURN NUMBER
);
/

CREATE OR REPLACE TYPE BODY t2_store_t AS
    MEMBER FUNCTION store_line_value RETURN NUMBER IS
        v_sum NUMBER := 0;
        i     PLS_INTEGER;
    BEGIN
        IF lines IS NULL THEN
            RETURN 0;
        END IF;
        i := lines.FIRST;
        WHILE i IS NOT NULL LOOP
            v_sum := v_sum + NVL(lines(i).line_value(), 0);
            i := lines.NEXT(i);
        END LOOP;
        RETURN v_sum;
    END;
END;
/

CREATE OR REPLACE TYPE t2_store_nt AS TABLE OF t2_store_t;
/

CREATE OR REPLACE TYPE t2_region_o AS OBJECT (
    region_id   NUMBER(6),
    r_name      VARCHAR2(120),
    stores      t2_store_nt,
    MEMBER FUNCTION region_label RETURN VARCHAR2,
    MEMBER FUNCTION total_line_value RETURN NUMBER,
    MEMBER FUNCTION total_qty RETURN NUMBER
);
/

CREATE OR REPLACE TYPE BODY t2_region_o AS
    MEMBER FUNCTION region_label RETURN VARCHAR2 IS
    BEGIN
        RETURN 'REG-' || LPAD(TO_CHAR(NVL(region_id, 0)), 3, '0');
    END;

    MEMBER FUNCTION total_line_value RETURN NUMBER IS
        v_sum NUMBER := 0;
        i     PLS_INTEGER;
        j     PLS_INTEGER;
    BEGIN
        IF stores IS NULL THEN
            RETURN 0;
        END IF;
        i := stores.FIRST;
        WHILE i IS NOT NULL LOOP
            IF stores(i).lines IS NOT NULL THEN
                j := stores(i).lines.FIRST;
                WHILE j IS NOT NULL LOOP
                    v_sum := v_sum + NVL(stores(i).lines(j).line_value(), 0);
                    j := stores(i).lines.NEXT(j);
                END LOOP;
            END IF;
            i := stores.NEXT(i);
        END LOOP;
        RETURN v_sum;
    END;

    MEMBER FUNCTION total_qty RETURN NUMBER IS
        v_sum NUMBER := 0;
        i     PLS_INTEGER;
        j     PLS_INTEGER;
    BEGIN
        IF stores IS NULL THEN
            RETURN 0;
        END IF;
        i := stores.FIRST;
        WHILE i IS NOT NULL LOOP
            IF stores(i).lines IS NOT NULL THEN
                j := stores(i).lines.FIRST;
                WHILE j IS NOT NULL LOOP
                    v_sum := v_sum + NVL(stores(i).lines(j).qty, 0);
                    j := stores(i).lines.NEXT(j);
                END LOOP;
            END IF;
            i := stores.NEXT(i);
        END LOOP;
        RETURN v_sum;
    END;
END;
/

CREATE TABLE t2_region_obj_tab OF t2_region_o (
    CONSTRAINT pk_t2_region_obj PRIMARY KEY (region_id)
)
NESTED TABLE stores STORE AS t2_ot_stores_tab (
    NESTED TABLE lines STORE AS t2_ot_lines_tab
);

EXIT;
