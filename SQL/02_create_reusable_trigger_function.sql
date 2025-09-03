CREATE OR REPLACE FUNCTION calsdv2."LogTriggerFunction"()
RETURNS TRIGGER AS $$
DECLARE
    pk_columns TEXT[];
    pk_values_array TEXT[];
    pk_values_jsonb JSONB;
    record_for_pk RECORD;
    key_name TEXT;
BEGIN
    SELECT array_agg(kcu.column_name::TEXT)
    INTO pk_columns
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu USING (constraint_name, table_schema)
    WHERE tc.constraint_type = 'PRIMARY KEY' AND tc.table_name = TG_TABLE_NAME AND tc.table_schema = TG_TABLE_SCHEMA;

    IF pk_columns IS NOT NULL THEN
        IF (TG_OP = 'UPDATE' OR TG_OP = 'DELETE') THEN
            record_for_pk := OLD;
        ELSE
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

    IF (TG_OP = 'INSERT') THEN
        INSERT INTO calsdv2."AuditLog"("TableName", "PrimaryKey", "Operation", "Changes", "BeforeChange", "UserName", "ChangedAt")
        VALUES (TG_TABLE_NAME, pk_values_jsonb, TG_OP, to_jsonb(NEW), NULL, session_user, now());

    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO calsdv2."AuditLog"("TableName", "PrimaryKey", "Operation", "Changes", "BeforeChange", "UserName", "ChangedAt")
        VALUES (TG_TABLE_NAME, pk_values_jsonb, TG_OP, calsdv2."JsonbDiffVals"(to_jsonb(OLD), to_jsonb(NEW)), to_jsonb(OLD), session_user, now());

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO calsdv2."AuditLog"("TableName", "PrimaryKey", "Operation", "Changes", "BeforeChange", "UserName", "ChangedAt")
        VALUES (TG_TABLE_NAME, pk_values_jsonb, TG_OP, NULL, to_jsonb(OLD), session_user, now());
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;