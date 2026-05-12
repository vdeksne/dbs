-- =============================================================================
-- 03_verify.sql — darbspējas pārbaude (uzdevums 4)
-- =============================================================================

SET LINESIZE 200
SET PAGESIZE 50

SELECT 'dim_calendar' AS tbl, COUNT(*) AS cnt FROM dim_calendar
UNION ALL SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL SELECT 'dim_store', COUNT(*) FROM dim_store
UNION ALL SELECT 'fact_sales', COUNT(*) FROM fact_sales;

SELECT fs.sale_id, c.full_date, p.category_name, s.region_name,
       fs.quantity_sold, fs.unit_price, fs.line_amount
FROM   fact_sales fs
JOIN   dim_calendar c ON c.calendar_id = fs.calendar_id
JOIN   dim_product  p ON p.product_id = fs.product_id
JOIN   dim_store    s ON s.store_id = fs.store_id
WHERE  fs.sale_id <= 5
ORDER BY fs.sale_id;

EXIT;
