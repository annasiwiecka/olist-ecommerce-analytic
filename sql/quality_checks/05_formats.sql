-- ===== format checks: raw values vs target types in the clean schema =====
SELECT string_agg(sql, E'\nUNION ALL\n' ORDER BY ord) || E'\nORDER BY issues DESC;'
FROM (
    -- ====== can the raw text be cast to the clean column type ======
    SELECT r.table_name || r.ordinal_position AS ord,
        format(
            'SELECT %L AS check_name, COUNT(*) AS issues FROM raw.%I WHERE %I IS NOT NULL AND NOT pg_input_is_valid(%I, %L)',
            r.table_name || '.' || r.column_name || ': not ' || c.data_type,
            r.table_name, r.column_name, r.column_name, c.data_type
           ) AS sql

    FROM information_schema.columns r
    JOIN information_schema.columns c
    ON c.table_schema = 'clean'
    AND c.table_name  = r.table_name
    AND c.column_name = r.column_name
    WHERE r.table_schema = 'raw'
    AND c.data_type NOT IN ('character varying', 'text')

    UNION ALL

    -- ===== for timestamp columns: is the format exactly ISO =====
    SELECT r.table_name || r.ordinal_position || 'iso',
        format(
            'SELECT %L, COUNT(*) FROM raw.%I WHERE %I IS NOT NULL AND %I !~ %L',
            r.table_name || '.' || r.column_name || ': not ISO format',
            r.table_name, r.column_name, r.column_name,
            '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'
           )

    FROM information_schema.columns r
    JOIN information_schema.columns c
    ON c.table_schema = 'clean'
    AND c.table_name  = r.table_name
    AND c.column_name = r.column_name
    WHERE r.table_schema = 'raw'
    AND c.data_type LIKE 'timestamp%'
) checks -- with  \gexec in SQL Shell