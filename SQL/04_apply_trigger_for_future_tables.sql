-- This script automates the process for any new tables you create.

CREATE OR REPLACE FUNCTION calsdv2.auto_apply_audit_trigger()
RETURNS event_trigger AS $$
DECLARE
    obj RECORD;
BEGIN
    FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands() WHERE command_tag = 'CREATE TABLE' LOOP
        -- This check ensures the trigger is not attached to the audit table itself.
        IF obj.schema_name = 'calsdv2' AND obj.object_identity != 'calsdv2.AuditLog' THEN
            EXECUTE format(
                'CREATE TRIGGER audit_trigger '
                'AFTER INSERT OR UPDATE OR DELETE ON %s '
                'FOR EACH ROW EXECUTE FUNCTION calsdv2.log_trigger_function();',
                obj.object_identity
            );
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


-- Create the event trigger that fires after a table is created.
DROP EVENT TRIGGER IF EXISTS auto_audit_trigger_on_create;
CREATE EVENT TRIGGER auto_audit_trigger_on_create
ON ddl_command_end
WHEN TAG IN ('CREATE TABLE')
EXECUTE FUNCTION calsdv2.auto_apply_audit_trigger();