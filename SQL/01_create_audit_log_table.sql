-- Create a helper function to calculate the difference between two JSONB objects.
-- This is needed to populate the 'changes' column for UPDATE operations.
CREATE OR REPLACE FUNCTION calsdv2.jsonb_diff_vals(old_data JSONB, new_data JSONB)
RETURNS JSONB AS $$
DECLARE
    result JSONB := '{}'::jsonb;
    entry RECORD;
BEGIN
    FOR entry IN SELECT * FROM jsonb_each(new_data) LOOP
        IF NOT(old_data ? entry.key) OR (old_data -> entry.key IS DISTINCT FROM entry.value) THEN
            result := result || jsonb_build_object(entry.key, entry.value);
        END IF;
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;


-- Define the table that will store every change record
-- DROP TABLE IF EXISTS calsdv2.AuditLog;
CREATE TABLE calsdv2.AuditLog (
    AuditId      BIGSERIAL PRIMARY KEY,
    TableName    VARCHAR(255) NOT NULL,
    PrimaryKey   JSONB,
    Operation     VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    Changes       JSONB,
    BeforeChange JSONB,
    UserName     VARCHAR(255) NOT NULL DEFAULT session_user,
    ChangedAt    TIMESTAMP NOT NULL DEFAULT now()
);
