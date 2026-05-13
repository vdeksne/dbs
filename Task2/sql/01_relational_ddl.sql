-- =============================================================================
-- Task2 / sql / 01_relational_ddl.sql
-- Četras relāciju tabulas ar FK (Oracle).
-- =============================================================================

WHENEVER SQLERROR CONTINUE

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE t2_sale CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE t2_store CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE t2_product CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE t2_region CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

WHENEVER SQLERROR EXIT SQL.SQLCODE

CREATE TABLE t2_region (
    region_id   NUMBER(6) PRIMARY KEY,
    r_name      VARCHAR2(120) NOT NULL
);

CREATE TABLE t2_store (
    store_id    NUMBER(8) PRIMARY KEY,
    region_id   NUMBER(6) NOT NULL,
    s_name      VARCHAR2(160) NOT NULL,
    CONSTRAINT fk_t2_store_reg FOREIGN KEY (region_id) REFERENCES t2_region (region_id)
);

CREATE TABLE t2_product (
    product_id   NUMBER(10) PRIMARY KEY,
    p_name       VARCHAR2(200) NOT NULL,
    unit_price   NUMBER(14,2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE t2_sale (
    sale_id      NUMBER(12) PRIMARY KEY,
    store_id     NUMBER(8) NOT NULL,
    product_id   NUMBER(10) NOT NULL,
    qty          NUMBER(8) NOT NULL CHECK (qty > 0),
    sale_date    DATE NOT NULL,
    CONSTRAINT fk_t2_sale_store   FOREIGN KEY (store_id)   REFERENCES t2_store (store_id),
    CONSTRAINT fk_t2_sale_product FOREIGN KEY (product_id) REFERENCES t2_product (product_id)
);

CREATE INDEX idx_t2_sale_store   ON t2_sale (store_id);
CREATE INDEX idx_t2_sale_product ON t2_sale (product_id);
CREATE INDEX idx_t2_sale_date    ON t2_sale (sale_date);

EXIT;
