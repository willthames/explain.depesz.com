BEGIN;
    ALTER TABLE public.plans add column optimization_for TEXT;
DO $$
DECLARE
    v_part_name TEXT;
    v_sql       TEXT;
BEGIN
    FOR v_part_name IN 
        SELECT
            c.relname
        FROM
            pg_catalog.pg_inherits i
            JOIN pg_class c ON i.inhrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE
            i.inhparent = 'public.plans'::regclass
            AND n.nspname = 'plans'
        ORDER BY c.relname
    LOOP
        raise notice 'Adding index on plans.% (optimization_for)', v_part_name;
        v_sql := format( 'CREATE INDEX %I ON plans.%I (optimization_for)', v_part_name || '_optimization_for', v_part_name );
        execute v_sql;
    END LOOP;
END;
$$;
COMMIT;

