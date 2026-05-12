-- =============================================================================
-- 08_gather_stats.sql — DBMS_STATS pēc masveida INSERT (obligāti salīdzinošiem EXPLAIN)
-- =============================================================================

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'DIM_CALENDAR', CASCADE => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'DIM_PRODUCT', CASCADE => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'DIM_STORE', CASCADE => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'FACT_SALES', CASCADE => TRUE);
END;
/

EXIT;
