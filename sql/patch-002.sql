CREATE TABLE users (
    username TEXT PRIMARY KEY,
    password TEXT,
    registered timestamptz
);

ALTER TABLE plans add column added_by TEXT references users ( username );

DROP FUNCTION register_plan(in_title text, in_plan text, in_is_public boolean, in_is_anonymized boolean);
CREATE FUNCTION register_plan(in_title text, in_plan text, in_is_public boolean, in_is_anonymized boolean, in_username text) RETURNS register_plan_return
    LANGUAGE plpgsql
    AS $$
DECLARE
    use_hash_length int4 := 2;
    reply register_plan_return;
BEGIN
    reply.delete_key := get_random_string( 50 );
    LOOP
        reply.id := get_random_string(use_hash_length);
        BEGIN
            INSERT INTO plans (id, title, plan, is_public, entered_on, is_anonymized, delete_key, added_by) values (reply.id, in_title, in_plan, in_is_public, now(), in_is_anonymized, reply.delete_key, in_username );
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
