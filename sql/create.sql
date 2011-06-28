--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: get_random_string(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_random_string(string_length integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: register_plan(text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION register_plan(in_plan text, in_is_public boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: register_plan(text, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION register_plan(in_plan text, in_is_public boolean, in_is_anonymized boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    use_hash_length int4 := 2;
    use_hash text;
BEGIN
    LOOP
        use_hash := get_random_string(use_hash_length);
        BEGIN
            INSERT INTO plans (id, plan, is_public, entered_on, is_anonymized) values (use_hash, in_plan, in_is_public, now(), in_is_anonymized);
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
$$;


--
-- Name: register_plan(text, text, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION register_plan(in_title text, in_plan text, in_is_public boolean, in_is_anonymized boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    use_hash_length int4 := 2;
    use_hash text;
BEGIN
    LOOP
        use_hash := get_random_string(use_hash_length);
        BEGIN
            INSERT INTO plans (id, title, plan, is_public, entered_on, is_anonymized) values (use_hash, in_title, in_plan, in_is_public, now(), in_is_anonymized);
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
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: another; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE another (
    i integer
);


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE plans (
    id text NOT NULL,
    plan text NOT NULL,
    entered_on timestamp with time zone DEFAULT now() NOT NULL,
    is_public boolean DEFAULT true NOT NULL,
    is_anonymized boolean DEFAULT false NOT NULL,
    title text
);


--
-- Name: z; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE z (
    i integer NOT NULL,
    j integer NOT NULL
);


--
-- Name: plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: z_i_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY z
    ADD CONSTRAINT z_i_key UNIQUE (i);


--
-- Name: z_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY z
    ADD CONSTRAINT z_pkey PRIMARY KEY (j, i);


--
-- Name: r; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX r ON z USING btree (j);


--
-- PostgreSQL database dump complete
--

