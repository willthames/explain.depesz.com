CREATE TABLE plans (
    id         TEXT        PRIMARY KEY,
	plan       TEXT        NOT NULL,
	entered_on TIMESTAMPTZ NOT NULL DEFAULT now(),
	is_public  BOOL        NOT NULL DEFAULT 'true'
);

CREATE OR REPLACE FUNCTION get_random_string(string_length INT4) RETURNS TEXT
AS $BODY$
DECLARE
    possible_chars TEXT = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    output TEXT = '';
    i INT4;
    pos INT4;
BEGIN
    FOR i IN 1..string_length LOOP
        pos := 1 + cast( random() * ( length(possible_chars) - 1) as INT4 );
        output := output || substr(possible_chars, pos, 1);
    END LOOP;
    RETURN output;
END;
$BODY$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION register_plan( in_plan TEXT, in_is_public bool ) RETURNS TEXT as $$
DECLARE
    use_hash_length int4 := 2;
    use_hash text;
BEGIN
    LOOP
        use_hash := get_random_string(use_hash_length);
        BEGIN
            INSERT INTO plans (id, plan, is_public, entered_on) values (use_hash, in_plan, in_is_public, now());
            RETURN use_hash;
        EXCEPTION WHEN unique_violation THEN
                -- do nothing
        END;
        use_hash_length := use_hash_length + 1;
        IF use_hash_length >= 30 THEN
            raise exception 'Random string of length == 30 requested. something''s wrong.';
        END IF;
    END LOOP;
END;
$$ language plpgsql;
