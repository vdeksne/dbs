-- =============================================================================
-- Task2 / sql / 03_functions.sql
-- Divas PL/SQL funkcijas (izmanto relāciju testa vaicājumos)
-- =============================================================================

CREATE OR REPLACE FUNCTION f2_line_value(p_unit_price NUMBER, p_qty NUMBER)
RETURN NUMBER
DETERMINISTIC IS
BEGIN
    RETURN ROUND(NVL(p_unit_price, 0) * NVL(p_qty, 0), 2);
END f2_line_value;
/

CREATE OR REPLACE FUNCTION f2_region_label(p_region_id NUMBER)
RETURN VARCHAR2
DETERMINISTIC IS
BEGIN
    RETURN 'REG-' || LPAD(TO_CHAR(NVL(p_region_id, 0)), 3, '0');
END f2_region_label;
/

EXIT;
