BEGIN;
CREATE OR REPLACE FUNCTION register_plan(in_title text, in_plan text, in_is_public boolean, in_is_anonymized boolean, in_username text, in_optimization_for TEXT) RETURNS register_plan_return
    LANGUAGE plpgsql
    AS $$
DECLARE
    use_hash_length int4 := 2;
    reply register_plan_return;
    use_sql TEXT;
BEGIN
    reply.delete_key := get_random_string( 50 );
    LOOP
        reply.id := get_random_string(use_hash_length);
        use_sql := format( 'INSERT INTO plans.%I (id, title, plan, is_public, entered_on, is_anonymized, delete_key, added_by, optimization_for) VALUES ($1, $2, $3, $4, now(), $5, $6, $7, $8 )', 'part_' || substr(reply.id, 1, 1) );
        BEGIN
            execute use_sql using reply.id, in_title, in_plan, in_is_public, in_is_anonymized, reply.delete_key, in_username, in_optimization_for;
            RETURN reply;
        EXCEPTION WHEN unique_violation THEN
                -- do nothing
        END;
        use_hash_length := use_hash_length + 1;
        IF use_hash_length >= 30 THEN
            raise exception 'Random string of length == 30 requested. something''s wrong.';
        END IF;
    END LOOP;
END;
$$;
COMMIT;
