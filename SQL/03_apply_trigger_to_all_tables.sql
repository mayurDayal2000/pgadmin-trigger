-- This script applies the trigger to all existing tables (except the logger itself).
DO $$
DECLARE
    t_name TEXT;
BEGIN
    FOR t_name IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_type = 'BASE TABLE'
          AND table_name != 'audit_logger' -- Important: Excludes the log table
    LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS audit_trigger ON public.%I; '
            'CREATE TRIGGER audit_trigger '
            'AFTER INSERT OR UPDATE OR DELETE ON public.%I '
            'FOR EACH ROW EXECUTE FUNCTION public.log_trigger_function();',
            t_name, t_name
        );
    END LOOP;
END;
$$;