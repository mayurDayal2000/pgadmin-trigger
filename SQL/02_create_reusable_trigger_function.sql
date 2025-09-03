-- Creates the main trigger function.
CREATE OR REPLACE FUNCTION calsdv2.log_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    pk_columns TEXT[];
    pk_values_array TEXT[];
    pk_values_jsonb JSONB;
    record_for_pk RECORD;
    key_name TEXT;
BEGIN
    -- Dynamically find all primary key column names for the table.
    SELECT array_agg(kcu.column_name::TEXT)
    INTO pk_columns
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu USING (constraint_name, table_schema)
    WHERE tc.constraint_type = 'PRIMARY KEY' AND tc.table_name = TG_TABLE_NAME AND tc.table_schema = TG_TABLE_SCHEMA;

    -- This block correctly builds a JSONB object from the primary key(s).
    IF pk_columns IS NOT NULL THEN
        IF (TG_OP = 'UPDATE' OR TG_OP = 'DELETE') THEN
            record_for_pk := OLD;
        ELSE -- For INSERT
            record_for_pk := NEW;
        END IF;

        FOREACH key_name IN ARRAY pk_columns LOOP
            pk_values_array := array_append(
                pk_values_array,
                (to_jsonb(record_for_pk) ->> key_name)
            );
        END LOOP;

        pk_values_jsonb := jsonb_object(pk_columns, pk_values_array);
    END IF;

    -- Insert the audit data into the log table.
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO calsdv2.AuditLog(table_name, primarykey, operation, changes, beforechange, username, changedat)
        VALUES (TG_TABLE_NAME, pk_values_jsonb, TG_OP, to_jsonb(NEW), NULL, session_user, now());

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO calsdv2.AuditLog(table_name, primarykey, operation, changes, beforechange, username, changedat)
        VALUES (TG_TABLE_NAME, pk_values_jsonb, TG_OP, calsdv2.jsonb_diff_vals(to_jsonb(OLD), to_jsonb(NEW)), to_jsonb(OLD), session_user, now());

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO calsdv2.AuditLog(table_name, primarykey, operation, changes, beforechange, username, changedat)
        VALUES (TG_TABLE_NAME, pk_values_jsonb, TG_OP, NULL, to_jsonb(OLD), session_user, now());
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
