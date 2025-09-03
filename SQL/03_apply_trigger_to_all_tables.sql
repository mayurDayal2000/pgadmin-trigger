-- This script applies the trigger to all existing tables (except the logger itself).
DO $$
DECLARE
    t_name TEXT;
BEGIN
    FOR t_name IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'calsdv2'
          AND table_type = 'BASE TABLE'
          AND table_name != 'AuditLog' -- Important: Excludes the log table
    LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS audit_trigger ON calsdv2.%I; '
            'CREATE TRIGGER audit_trigger '
            'AFTER INSERT OR UPDATE OR DELETE ON calsdv2.%I '
            'FOR EACH ROW EXECUTE FUNCTION calsdv2.log_trigger_function();',
            t_name, t_name
        );
    END LOOP;
END;
$$;