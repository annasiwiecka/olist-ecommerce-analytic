-- ========= numbers of NULL rows for each row in every table =========

SELECT string_agg(
    format(
    'SELECT %L AS table_name, %L AS column_name, COUNT(*) FILTER (WHERE %I IS NULL) AS missing, COUNT(*) AS total_rows FROM raw.%I',
    table_name, column_name, column_name, table_name
    ),
    E'\nUNION ALL\n'
    ORDER BY table_name, ordinal_position
) || E'\nORDER BY missing DESC;'
FROM information_schema.columns
WHERE table_schema = 'raw'; -- with  \gexec in SQL Shell