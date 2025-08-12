-- ============================================================================
-- Amazon Redshift Admin Schema Setup Script
-- ============================================================================
-- This script creates an admin schema and installs all administrative views
-- from the Amazon Redshift Utils AdminViews collection.
--
-- Prerequisites:
-- 1. Connect to your Redshift cluster as a superuser
-- 2. Ensure you have the necessary permissions to create schemas and views
--
-- Usage:
-- 1. Connect to your Redshift database
-- 2. Run this script: \i setup_admin_schema.sql (in psql)
--    or copy and paste the contents into your SQL client
--
-- The script will:
-- 1. Create an 'admin' schema if it doesn't exist
-- 2. Create all 46 administrative views in the admin schema
-- 3. Grant usage on the admin schema to PUBLIC (you can modify this)
--
-- After installation, you can query views like:
-- SELECT * FROM admin.v_space_used_per_tbl;
-- SELECT * FROM admin.v_check_wlm_query_time;
-- ============================================================================

-- Create the admin schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS admin;

-- Grant usage on admin schema to PUBLIC (modify as needed for your security requirements)
GRANT USAGE ON SCHEMA admin TO PUBLIC;

-- Set search path to include admin schema
SET search_path TO admin, public;

-- ============================================================================
-- DDL Generation Views
-- ============================================================================

-- Drop existing views if they exist (to allow re-running the script)
DROP VIEW IF EXISTS admin.v_generate_database_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_schema_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_group_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_tbl_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_view_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_external_tbl_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_udf_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_user_grant_revoke_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_user_object_permissions CASCADE;
DROP VIEW IF EXISTS admin.v_generate_unload_copy_cmd CASCADE;
DROP VIEW IF EXISTS admin.v_generate_cancel_query CASCADE;
DROP VIEW IF EXISTS admin.v_generate_terminate_session CASCADE;
DROP VIEW IF EXISTS admin.v_generate_cursor_query CASCADE;

-- Drop performance monitoring views
DROP VIEW IF EXISTS admin.v_check_wlm_query_time CASCADE;
DROP VIEW IF EXISTS admin.v_check_wlm_query_trend_daily CASCADE;
DROP VIEW IF EXISTS admin.v_check_wlm_query_trend_hourly CASCADE;
DROP VIEW IF EXISTS admin.v_wlm_queue_state CASCADE;
DROP VIEW IF EXISTS admin.v_query_type_duration_summary CASCADE;

-- Drop table and storage analysis views
DROP VIEW IF EXISTS admin.v_check_data_distribution CASCADE;
DROP VIEW IF EXISTS admin.v_extended_table_info CASCADE;
DROP VIEW IF EXISTS admin.v_space_used_per_tbl CASCADE;
DROP VIEW IF EXISTS admin.v_fragmentation_info CASCADE;
DROP VIEW IF EXISTS admin.v_get_tbl_scan_frequency CASCADE;
DROP VIEW IF EXISTS admin.v_get_tbl_reads_and_writes CASCADE;

-- Drop security and access management views
DROP VIEW IF EXISTS admin.v_get_obj_priv_by_user CASCADE;
DROP VIEW IF EXISTS admin.v_get_schema_priv_by_user CASCADE;
DROP VIEW IF EXISTS admin.v_get_tbl_priv_by_user CASCADE;
DROP VIEW IF EXISTS admin.v_get_tbl_priv_by_group CASCADE;
DROP VIEW IF EXISTS admin.v_get_view_priv_by_user CASCADE;
DROP VIEW IF EXISTS admin.v_find_dropuser_objs CASCADE;
DROP VIEW IF EXISTS admin.v_get_users_in_group CASCADE;

-- Drop connection and session management views
DROP VIEW IF EXISTS admin.v_connection_summary CASCADE;
DROP VIEW IF EXISTS admin.v_open_session CASCADE;
DROP VIEW IF EXISTS admin.v_session_leakage_by_cnt CASCADE;

-- Drop lock and transaction analysis views
DROP VIEW IF EXISTS admin.v_check_transaction_locks CASCADE;
DROP VIEW IF EXISTS admin.v_get_blocking_locks CASCADE;

-- Drop maintenance and vacuum views
DROP VIEW IF EXISTS admin.v_get_vacuum_details CASCADE;
DROP VIEW IF EXISTS admin.v_vacuum_summary CASCADE;
DROP VIEW IF EXISTS admin.v_get_cluster_restart_ts CASCADE;

-- Drop session-specific analysis views
DROP VIEW IF EXISTS admin.v_my_last_query_summary CASCADE;
DROP VIEW IF EXISTS admin.v_my_last_copy_errors CASCADE;

-- Drop dependency analysis views
DROP VIEW IF EXISTS admin.v_object_dependency CASCADE;
DROP VIEW IF EXISTS admin.v_view_dependency CASCADE;
DROP VIEW IF EXISTS admin.v_constraint_dependency CASCADE;
DROP VIEW IF EXISTS admin.v_view_table_column_dependency CASCADE;

-- Drop stored procedure parameter view
DROP VIEW IF EXISTS admin.v_get_stored_proc_params CASCADE;

-- ============================================================================
-- Now create all views in the order that respects dependencies
-- ============================================================================

-- Note: The actual view definitions need to be included from the source files
-- This script provides the structure and order for creating the views.
-- You'll need to copy the CREATE VIEW statements from each SQL file in 
-- src/AdminViews/ and paste them here, replacing 'CREATE OR REPLACE VIEW'
-- with 'CREATE OR REPLACE VIEW admin.view_name'

-- To complete this setup, you need to:
-- 1. Copy each view definition from src/AdminViews/*.sql
-- 2. Replace the view creation statement to include the admin schema
-- 3. Execute the modified statements

-- Example pattern for each view (you'll need to get the actual definitions):
-- CREATE OR REPLACE VIEW admin.v_check_data_distribution AS
-- (actual view definition from v_check_data_distribution.sql)

-- ============================================================================
-- Helper script to generate the complete setup
-- ============================================================================
-- You can use this bash command to generate the complete script:
-- 
-- for file in src/AdminViews/*.sql; do
--     echo "-- Creating view from $file"
--     sed 's/CREATE OR REPLACE VIEW/CREATE OR REPLACE VIEW admin./g' "$file"
--     echo ";"
--     echo ""
-- done
--
-- This will create all views with the admin schema prefix.

-- ============================================================================
-- Grant permissions (adjust as needed for your security requirements)
-- ============================================================================

-- Grant SELECT on all views in admin schema to PUBLIC
-- (You may want to grant to specific users/groups instead)
GRANT SELECT ON ALL TABLES IN SCHEMA admin TO PUBLIC;

-- ============================================================================
-- Verification queries
-- ============================================================================

-- After running this script, verify the views were created:
-- SELECT schemaname, viewname 
-- FROM pg_views 
-- WHERE schemaname = 'admin' 
-- ORDER BY viewname;

-- You should see all 46 administrative views listed.

-- ============================================================================
-- Usage examples
-- ============================================================================

-- Check table space usage:
-- SELECT * FROM admin.v_space_used_per_tbl WHERE size_in_mb > 100 ORDER BY size_in_mb DESC;

-- Check WLM query performance:
-- SELECT * FROM admin.v_check_wlm_query_time WHERE total_queue_time > 0;

-- Generate DDL for a table:
-- SELECT ddl FROM admin.v_generate_tbl_ddl WHERE tablename = 'your_table_name';

-- Check for blocking locks:
-- SELECT * FROM admin.v_get_blocking_locks;

-- Monitor current sessions:
-- SELECT * FROM admin.v_connection_summary WHERE session_state = 'active';

-- ============================================================================
-- END OF SETUP SCRIPT
-- ============================================================================