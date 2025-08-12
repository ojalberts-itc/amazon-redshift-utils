#!/bin/bash

# ============================================================================
# Generate Complete Admin Schema Setup Script
# ============================================================================
# This script generates a complete SQL setup script that includes all
# AdminViews definitions from the Amazon Redshift Utils repository.
#
# Usage: ./generate_admin_setup.sh
# Output: setup_admin_schema_complete.sql
# ============================================================================

# Get the repository root directory
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ADMIN_VIEWS_DIR="$REPO_ROOT/src/AdminViews"
OUTPUT_FILE="$REPO_ROOT/custom/scripts/setup_admin_schema_complete.sql"

# Check if AdminViews directory exists
if [ ! -d "$ADMIN_VIEWS_DIR" ]; then
    echo "Error: AdminViews directory not found at $ADMIN_VIEWS_DIR"
    exit 1
fi

# Start creating the output file
cat > "$OUTPUT_FILE" << 'EOF'
-- ============================================================================
-- Amazon Redshift Admin Schema Setup Script - Complete Version
-- ============================================================================
-- Generated on: $(date)
-- This script creates an admin schema and installs all administrative views
-- from the Amazon Redshift Utils AdminViews collection.
--
-- Prerequisites:
-- 1. Connect to your Redshift cluster as a superuser
-- 2. Ensure you have the necessary permissions to create schemas and views
--
-- Usage:
-- 1. Connect to your Redshift database
-- 2. Run this script: \i setup_admin_schema_complete.sql (in psql)
--    or copy and paste the contents into your SQL client
--
-- The script will:
-- 1. Create an 'admin' schema if it doesn't exist
-- 2. Create all administrative views in the admin schema
-- 3. Grant usage on the admin schema to PUBLIC (you can modify this)
-- ============================================================================

-- Create the admin schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS admin;

-- Grant usage on admin schema to PUBLIC (modify as needed for your security requirements)
GRANT USAGE ON SCHEMA admin TO PUBLIC;

-- Set search path to include admin schema
SET search_path TO admin, public;

-- ============================================================================
-- Drop existing views to allow re-running the script
-- ============================================================================

EOF

# Generate DROP statements for all views
echo "-- Drop all existing admin views" >> "$OUTPUT_FILE"
for file in "$ADMIN_VIEWS_DIR"/*.sql; do
    if [ -f "$file" ]; then
        view_name=$(basename "$file" .sql)
        echo "DROP VIEW IF EXISTS admin.$view_name CASCADE;" >> "$OUTPUT_FILE"
    fi
done

echo "" >> "$OUTPUT_FILE"
echo "-- ============================================================================" >> "$OUTPUT_FILE"
echo "-- Create Administrative Views" >> "$OUTPUT_FILE"
echo "-- ============================================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Define the order of view creation to handle dependencies
# Views that don't depend on others should come first
VIEW_ORDER=(
    # Base views with no dependencies
    "v_generate_database_ddl.sql"
    "v_generate_group_ddl.sql"
    "v_get_cluster_restart_ts.sql"
    "v_get_users_in_group.sql"
    "v_my_last_copy_errors.sql"
    "v_my_last_query_summary.sql"
    "v_open_session.sql"
    "v_session_leakage_by_cnt.sql"
    "v_generate_cancel_query.sql"
    "v_generate_terminate_session.sql"
    "v_generate_unload_copy_cmd.sql"
    "v_get_stored_proc_params.sql"
    
    # Views that may have basic dependencies
    "v_check_data_distribution.sql"
    "v_check_transaction_locks.sql"
    "v_check_wlm_query_time.sql"
    "v_check_wlm_query_trend_daily.sql"
    "v_check_wlm_query_trend_hourly.sql"
    "v_connection_summary.sql"
    "v_fragmentation_info.sql"
    "v_generate_cursor_query.sql"
    "v_generate_schema_ddl.sql"
    "v_generate_udf_ddl.sql"
    "v_get_blocking_locks.sql"
    "v_get_obj_priv_by_user.sql"
    "v_get_schema_priv_by_user.sql"
    "v_get_tbl_priv_by_group.sql"
    "v_get_tbl_priv_by_user.sql"
    "v_get_tbl_reads_and_writes.sql"
    "v_get_tbl_scan_frequency.sql"
    "v_get_vacuum_details.sql"
    "v_get_view_priv_by_user.sql"
    "v_query_type_duration_summary.sql"
    "v_space_used_per_tbl.sql"
    "v_vacuum_summary.sql"
    "v_wlm_queue_state.sql"
    "v_find_dropuser_objs.sql"
    
    # Dependency views
    "v_view_dependency.sql"
    "v_constraint_dependency.sql"
    "v_view_table_column_dependency.sql"
    
    # Complex views that may depend on others
    "v_extended_table_info.sql"
    "v_generate_external_tbl_ddl.sql"
    "v_generate_tbl_ddl.sql"
    "v_generate_view_ddl.sql"
    "v_generate_user_object_permissions.sql"
    "v_generate_user_grant_revoke_ddl.sql"
    "v_object_dependency.sql"
)

# Process views in order
for view_file in "${VIEW_ORDER[@]}"; do
    file_path="$ADMIN_VIEWS_DIR/$view_file"
    if [ -f "$file_path" ]; then
        view_name=$(basename "$view_file" .sql)
        
        echo "" >> "$OUTPUT_FILE"
        echo "-- ============================================================================" >> "$OUTPUT_FILE"
        echo "-- Creating view: $view_name" >> "$OUTPUT_FILE"
        echo "-- Source: $view_file" >> "$OUTPUT_FILE"
        echo "-- ============================================================================" >> "$OUTPUT_FILE"
        
        # Read the SQL file and modify it to use admin schema
        # Replace CREATE OR REPLACE VIEW with CREATE OR REPLACE VIEW admin.
        # Also handle CREATE VIEW (without OR REPLACE)
        sed -e 's/^CREATE OR REPLACE VIEW /CREATE OR REPLACE VIEW admin./g' \
            -e 's/^CREATE VIEW /CREATE VIEW admin./g' \
            -e 's/^create or replace view /CREATE OR REPLACE VIEW admin./g' \
            -e 's/^create view /CREATE VIEW admin./g' \
            "$file_path" >> "$OUTPUT_FILE"
        
        # Add a semicolon if not present
        if ! tail -n1 "$file_path" | grep -q ';$'; then
            echo ";" >> "$OUTPUT_FILE"
        fi
    else
        echo "Warning: View file not found: $view_file" >&2
    fi
done

# Add any views not in the ordered list
echo "" >> "$OUTPUT_FILE"
echo "-- ============================================================================" >> "$OUTPUT_FILE"
echo "-- Additional views not in dependency order" >> "$OUTPUT_FILE"
echo "-- ============================================================================" >> "$OUTPUT_FILE"

for file in "$ADMIN_VIEWS_DIR"/*.sql; do
    if [ -f "$file" ]; then
        view_file=$(basename "$file")
        # Check if this view was already processed
        if [[ ! " ${VIEW_ORDER[@]} " =~ " ${view_file} " ]]; then
            view_name=$(basename "$view_file" .sql)
            
            echo "" >> "$OUTPUT_FILE"
            echo "-- Creating view: $view_name" >> "$OUTPUT_FILE"
            echo "-- Source: $view_file" >> "$OUTPUT_FILE"
            
            sed -e 's/^CREATE OR REPLACE VIEW /CREATE OR REPLACE VIEW admin./g' \
                -e 's/^CREATE VIEW /CREATE VIEW admin./g' \
                -e 's/^create or replace view /CREATE OR REPLACE VIEW admin./g' \
                -e 's/^create view /CREATE VIEW admin./g' \
                "$file" >> "$OUTPUT_FILE"
            
            if ! tail -n1 "$file" | grep -q ';$'; then
                echo ";" >> "$OUTPUT_FILE"
            fi
        fi
    fi
done

# Add footer with permissions and verification
cat >> "$OUTPUT_FILE" << 'EOF'

-- ============================================================================
-- Grant permissions
-- ============================================================================

-- Grant SELECT on all views in admin schema to PUBLIC
-- (You may want to grant to specific users/groups instead)
GRANT SELECT ON ALL TABLES IN SCHEMA admin TO PUBLIC;

-- ============================================================================
-- Verification queries
-- ============================================================================

-- Count of views created
SELECT COUNT(*) as view_count
FROM pg_views 
WHERE schemaname = 'admin';

-- List all admin views
SELECT schemaname, viewname 
FROM pg_views 
WHERE schemaname = 'admin' 
ORDER BY viewname;

-- ============================================================================
-- Usage examples
-- ============================================================================

-- Check table space usage:
-- SELECT * FROM admin.v_space_used_per_tbl WHERE size_in_mb > 100 ORDER BY size_in_mb DESC;

-- Check WLM query performance:
-- SELECT * FROM admin.v_check_wlm_query_time WHERE total_queue_time > 0;

-- Generate DDL for a table:
-- SELECT ddl FROM admin.v_generate_tbl_ddl WHERE schemaname = 'public' AND tablename = 'your_table';

-- Check for blocking locks:
-- SELECT * FROM admin.v_get_blocking_locks;

-- Monitor current sessions:
-- SELECT * FROM admin.v_connection_summary WHERE session_state = 'active';

-- Generate schema migration DDL:
-- SELECT ddl FROM admin.v_generate_schema_ddl;
-- SELECT ddl FROM admin.v_generate_tbl_ddl ORDER BY tablename;
-- SELECT ddl FROM admin.v_generate_view_ddl ORDER BY viewname;

-- Find unused tables:
-- SELECT * FROM admin.v_extended_table_info WHERE last_scan IS NULL;

-- Check data distribution skew:
-- SELECT * FROM admin.v_check_data_distribution WHERE ratio_skew_across_slices > 1.5;

-- ============================================================================
-- END OF SETUP SCRIPT
-- ============================================================================
EOF

echo "Successfully generated: $OUTPUT_FILE"
echo ""
echo "To use this script:"
echo "1. Connect to your Redshift cluster as a superuser"
echo "2. Run: \\i $OUTPUT_FILE (in psql)"
echo "   Or copy and paste the contents into your SQL client"
echo ""
echo "The script will create all $(ls -1 "$ADMIN_VIEWS_DIR"/*.sql 2>/dev/null | wc -l) administrative views in the 'admin' schema."