\connect template1 postgres

\set ON_ERROR_STOP OFF

DROP DATABASE "explain";

DROP USER "explain";

\set ON_ERROR_STOP ON

CREATE USER "explain" WITH password 'explain';

CREATE DATABASE "explain" WITH encoding 'utf8' owner "explain";

\connect "explain" postgres

CREATE procedural LANGUAGE plpgsql;

\connect "explain" "explain"

-- plan
CREATE TABLE plans (
    id          TEXT        PRIMARY KEY,
    plan        TEXT        NOT NULL,
    entered_on  timestamptz NOT NULL DEFAULT now( ),
    is_public   bool        NOT NULL DEFAULT 'true'
);

CREATE OR REPLACE FUNCTION get_random_string( string_length INT4 ) RETURNS TEXT AS $$
DECLARE
    possible_chars TEXT = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    output TEXT = '';
    i INT4;
    pos INT4;
BEGIN
    FOR i IN 1..string_length LOOP
        pos := 1 + cast( random( ) * ( length( possible_chars ) - 1 ) AS INT4 );
        output := output || substr( possible_chars, pos, 1 );
        END LOOP;
    RETURN output;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION register_plan( in_plan TEXT, in_is_public BOOL ) RETURNS TEXT AS $$
DECLARE
    use_hash_length INT4 := 2;
    use_hash TEXT;
BEGIN
    LOOP
        use_hash := get_random_string( use_hash_length );

        BEGIN
            INSERT INTO plans ( id, plan, is_public, entered_on ) VALUES ( use_hash, in_plan, in_is_public, now( ) );
            RETURN use_hash;
        EXCEPTION when unique_violation THEN
                -- do nothing
        END;

        use_hash_length := use_hash_length + 1;

        IF use_hash_length >= 30 THEN
            raise EXCEPTION 'Random string of length == 30 requested. Something is wrong.';
        END IF;

    END LOOP;
END;
$$ LANGUAGE plpgsql;
