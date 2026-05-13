-- =============================================================================
-- 01_schema.sql — daudzdimensiju (zvaigznes) shēma: 1 fakti + 3 dimensijas
-- Katra tabula: vismaz 5 kolonnas (izņemot PK/FK tehniskos — šeit 5+ datu kolonnu).
-- =============================================================================

SET DEFINE OFF;

-- Droša atkārtota palaišana (tabulas/MV var neeksistēt)
BEGIN EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_cat_reg_year';
EXCEPTION WHEN OTHERS THEN IF SQLCODE NOT IN (-12003, -942) THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_region_month_sales';
EXCEPTION WHEN OTHERS THEN IF SQLCODE NOT IN (-12003, -942) THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_year_category_sales';
EXCEPTION WHEN OTHERS THEN IF SQLCODE NOT IN (-12003, -942) THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE fact_sales CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_calendar CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_product CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_store CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/

-- Laika dimensija: hierarhija Gads -> Ceturksnis -> Mēnesis -> Diena
CREATE TABLE dim_calendar (
    calendar_id    NUMBER(10) PRIMARY KEY,
    full_date      DATE NOT NULL,
    year_no        NUMBER(4) NOT NULL,
    quarter_no     NUMBER(1) NOT NULL CHECK (quarter_no BETWEEN 1 AND 4),
    month_no       NUMBER(2) NOT NULL CHECK (month_no BETWEEN 1 AND 12),
    day_no         NUMBER(2) NOT NULL CHECK (day_no BETWEEN 1 AND 31),
    iso_week_no    NUMBER(2)
);

-- Preču dimensija: Kategorija -> Apakškategorija -> Prece
CREATE TABLE dim_product (
    product_id       NUMBER(10) PRIMARY KEY,
    product_name     VARCHAR2(120) NOT NULL,
    category_name    VARCHAR2(80) NOT NULL,
    subcategory_name VARCHAR2(80) NOT NULL,
    brand_name       VARCHAR2(80) NOT NULL,
    sku_code         VARCHAR2(40)
);

-- Veikala dimensija: Valsts -> Reģions -> Pilsēta -> Veikals
CREATE TABLE dim_store (
    store_id     NUMBER(10) PRIMARY KEY,
    store_name   VARCHAR2(120) NOT NULL,
    city_name    VARCHAR2(80) NOT NULL,
    region_name  VARCHAR2(80) NOT NULL,
    country_name VARCHAR2(80) NOT NULL,
    store_type   VARCHAR2(40)
);

-- Faktu tabula: mērītāji — daudzums, cena, atlaide, rindas summa
CREATE TABLE fact_sales (
    sale_id        NUMBER(12) PRIMARY KEY,
    calendar_id    NUMBER(10) NOT NULL,
    product_id     NUMBER(10) NOT NULL,
    store_id       NUMBER(10) NOT NULL,
    quantity_sold  NUMBER(8) NOT NULL CHECK (quantity_sold >= 0),
    unit_price     NUMBER(12,2) NOT NULL CHECK (unit_price >= 0),
    discount_pct   NUMBER(5,2) DEFAULT 0 CHECK (discount_pct BETWEEN 0 AND 100),
    line_amount    NUMBER(14,2) NOT NULL,
    CONSTRAINT fk_fs_cal  FOREIGN KEY (calendar_id) REFERENCES dim_calendar (calendar_id),
    CONSTRAINT fk_fs_prod FOREIGN KEY (product_id)  REFERENCES dim_product (product_id),
    CONSTRAINT fk_fs_str  FOREIGN KEY (store_id)    REFERENCES dim_store (store_id)
);

COMMENT ON TABLE fact_sales IS 'Faktu tabula: pārdošanas notikumi (grain: viena rinda = viena pārdošanas pozīcija).';

EXIT;
