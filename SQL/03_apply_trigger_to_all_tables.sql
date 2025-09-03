DO $$
DECLARE
    t_name TEXT;
BEGIN
    FOR t_name IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'calsdv2'
          AND table_type = 'BASE TABLE'
          AND table_name != 'AuditLog'
    LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS "AuditTrigger" ON calsdv2.%I; '
            'CREATE TRIGGER "AuditTrigger" '
            'AFTER INSERT OR UPDATE OR DELETE ON calsdv2.%I '
            'FOR EACH ROW EXECUTE FUNCTION calsdv2."LogTriggerFunction"();',
            t_name, t_name
        );
    END LOOP;
END;
$$;