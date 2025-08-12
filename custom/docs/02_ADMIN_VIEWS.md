# AdminViews - Complete Reference Guide

## Overview

The AdminViews collection provides 46 sophisticated views that transform Redshift system tables into actionable administrative interfaces. These views are designed to be installed in an `admin` schema for easy access and organization.

## Installation

### Quick Setup
```bash
# Generate and run the complete setup script
cd custom/scripts
./generate_admin_setup.sh
# Then in Redshift:
\i setup_admin_schema_complete.sql
```

### Manual Installation
```sql
-- Create admin schema
CREATE SCHEMA IF NOT EXISTS admin;
GRANT USAGE ON SCHEMA admin TO PUBLIC;

-- Install individual views from src/AdminViews/*.sql
-- Prefix each with 'admin.' schema
```

## View Categories and Reference

### 1. DDL Generation Views (10 views)

These views are essential for schema migration, backup, and documentation.

#### v_generate_database_ddl
**Purpose**: Generate CREATE DATABASE statements

**Usage**:
```sql
SELECT ddl FROM admin.v_generate_database_ddl 
WHERE datname = 'mydb';
```

**Output**: Complete CREATE DATABASE statement with connection limits

#### v_generate_schema_ddl
**Purpose**: Generate CREATE SCHEMA statements with authorization

**Usage**:
```sql
SELECT ddl FROM admin.v_generate_schema_ddl 
WHERE schemaname NOT IN ('pg_catalog', 'information_schema');
```

**Output**: Schema creation with ownership

#### v_generate_group_ddl
**Purpose**: Generate CREATE GROUP statements

**Usage**:
```sql
SELECT ddl FROM admin.v_generate_group_ddl;
```

**Output**: All group definitions

#### v_generate_tbl_ddl
**Purpose**: Complete table DDL including all properties

**Features**:
- Column definitions with encoding
- Distribution and sort keys
- Constraints and defaults
- Table permissions
- Comments

**Usage**:
```sql
-- Single table
SELECT ddl FROM admin.v_generate_tbl_ddl 
WHERE schemaname = 'public' AND tablename = 'orders';

-- All tables in schema
SELECT ddl FROM admin.v_generate_tbl_ddl 
WHERE schemaname = 'public'
ORDER BY tablename;
```

**Important Notes**:
- Foreign keys generated separately
- Handles BACKUP NO tables
- Includes ownership information

#### v_generate_view_ddl
**Purpose**: Generate CREATE VIEW statements

**Usage**:
```sql
SELECT ddl FROM admin.v_generate_view_ddl 
WHERE schemaname = 'public';
```

**Supports**: Regular views and materialized views

#### v_generate_external_tbl_ddl
**Purpose**: Generate Spectrum external table DDL

**Usage**:
```sql
SELECT ddl FROM admin.v_generate_external_tbl_ddl 
WHERE schemaname = 'spectrum';
```

**Features**:
- Partition definitions
- Table properties
- External location

#### v_generate_udf_ddl
**Purpose**: Generate user-defined function DDL

**Usage**:
```sql
SELECT ddl FROM admin.v_generate_udf_ddl 
WHERE schemaname = 'public';
```

**Note**: Excludes stored procedures (use v_get_stored_proc_params)

#### v_generate_user_grant_revoke_ddl
**Purpose**: Comprehensive privilege DDL generation

**Usage**:
```sql
-- All grants for a user
SELECT ddl FROM admin.v_generate_user_grant_revoke_ddl 
WHERE grantee = 'analyst';

-- All grants on a table
SELECT ddl FROM admin.v_generate_user_grant_revoke_ddl 
WHERE objname = 'sales';
```

**Coverage**:
- Table/view privileges
- Schema privileges
- Database privileges
- Column-level privileges
- Default ACLs

#### v_generate_user_object_permissions
**Purpose**: Object-level permission DDL

**Usage**:
```sql
SELECT * FROM admin.v_generate_user_object_permissions 
WHERE username = 'dataeng';
```

#### v_generate_unload_copy_cmd
**Purpose**: Generate UNLOAD/COPY command templates

**Usage**:
```sql
SELECT * FROM admin.v_generate_unload_copy_cmd 
WHERE tablename = 'fact_sales';
```

**Output**: Ready-to-customize UNLOAD and COPY commands

### 2. Performance Monitoring Views (5 views)

#### v_check_wlm_query_time
**Purpose**: WLM queue and execution time analysis

**Key Columns**:
- total_queue_time
- total_exec_time
- query_priority
- service_class

**Usage**:
```sql
-- Queries with high queue time
SELECT * FROM admin.v_check_wlm_query_time 
WHERE total_queue_time > 5000  -- 5 seconds
ORDER BY total_queue_time DESC;
```

#### v_check_wlm_query_trend_daily
**Purpose**: Daily WLM performance trends

**Usage**:
```sql
-- Last 30 days trend
SELECT * FROM admin.v_check_wlm_query_trend_daily 
WHERE day >= CURRENT_DATE - 30
ORDER BY day, service_class;
```

#### v_check_wlm_query_trend_hourly
**Purpose**: Hourly WLM performance patterns

**Usage**:
```sql
-- Today's hourly pattern
SELECT * FROM admin.v_check_wlm_query_trend_hourly 
WHERE hour >= CURRENT_DATE
ORDER BY hour;
```

#### v_wlm_queue_state
**Purpose**: Current WLM configuration and state

**Usage**:
```sql
SELECT * FROM admin.v_wlm_queue_state;
```

**Shows**:
- Queue configuration
- Current slot usage
- Memory allocation
- Query count

#### v_query_type_duration_summary
**Purpose**: Performance by query type (SELECT, INSERT, etc.)

**Usage**:
```sql
SELECT * FROM admin.v_query_type_duration_summary 
ORDER BY query_count DESC;
```

**Metrics**: P25, P50, P75, P90, P99 percentiles

### 3. Table and Storage Analysis Views (6 views)

#### v_check_data_distribution
**Purpose**: Analyze data distribution across slices

**Key Metrics**:
- slice_num: Slice identifier
- num_values: Row count per slice
- pct_of_total: Percentage of total rows
- ratio_to_optimal: Skew ratio

**Usage**:
```sql
-- Find skewed tables
SELECT * FROM admin.v_check_data_distribution 
WHERE ratio_to_optimal > 1.5
ORDER BY ratio_to_optimal DESC;
```

**Action Thresholds**:
- ratio > 1.5: Consider redistribution
- ratio > 2.0: High priority for optimization

#### v_extended_table_info
**Purpose**: Comprehensive table analysis

**Features**:
- Storage metrics
- Compression efficiency
- Scan patterns
- Alert history
- Sort key effectiveness

**Usage**:
```sql
-- Tables needing maintenance
SELECT * FROM admin.v_extended_table_info 
WHERE pct_unsorted > 20 
   OR pct_stats_off > 10
ORDER BY size_in_mb DESC;
```

#### v_space_used_per_tbl
**Purpose**: Storage utilization analysis

**Key Columns**:
- size_in_mb
- pct_unsorted
- rows_per_slice (skew indicator)
- recommendation (VACUUM advice)

**Usage**:
```sql
-- Large unsorted tables
SELECT * FROM admin.v_space_used_per_tbl 
WHERE size_in_mb > 1000 
  AND pct_unsorted > 10
ORDER BY size_in_mb DESC;
```

#### v_fragmentation_info
**Purpose**: Identify fragmented tables

**Usage**:
```sql
-- Tables with high fragmentation
SELECT * FROM admin.v_fragmentation_info 
WHERE estimated_space_gain_mb > 100
ORDER BY estimated_space_gain_mb DESC;
```

#### v_get_tbl_scan_frequency
**Purpose**: Table access patterns

**Usage**:
```sql
-- Frequently scanned tables
SELECT * FROM admin.v_get_tbl_scan_frequency 
ORDER BY scan_count DESC
LIMIT 20;
```

#### v_get_tbl_reads_and_writes
**Purpose**: Read/write activity analysis

**Usage**:
```sql
-- High activity tables
SELECT * FROM admin.v_get_tbl_reads_and_writes 
WHERE read_count + write_count > 1000
ORDER BY total_operations DESC;
```

### 4. Security and Access Management Views (7 views)

#### v_get_obj_priv_by_user
**Purpose**: User privileges on tables and views

**Privilege Columns**:
- sel (SELECT)
- ins (INSERT)
- upd (UPDATE)
- del (DELETE)
- ref (REFERENCES)

**Usage**:
```sql
-- All privileges for a user
SELECT * FROM admin.v_get_obj_priv_by_user 
WHERE username = 'analyst';

-- Users with DELETE privilege
SELECT * FROM admin.v_get_obj_priv_by_user 
WHERE del = 1;
```

#### v_get_schema_priv_by_user
**Purpose**: Schema-level privileges

**Usage**:
```sql
SELECT * FROM admin.v_get_schema_priv_by_user 
WHERE username = 'developer';
```

#### v_get_tbl_priv_by_user / v_get_tbl_priv_by_group
**Purpose**: Table privileges by user or group

**Usage**:
```sql
-- User privileges
SELECT * FROM admin.v_get_tbl_priv_by_user 
WHERE tablename = 'sensitive_data';

-- Group privileges
SELECT * FROM admin.v_get_tbl_priv_by_group 
WHERE groupname = 'analysts';
```

#### v_get_view_priv_by_user
**Purpose**: View access privileges

**Usage**:
```sql
SELECT * FROM admin.v_get_view_priv_by_user 
WHERE viewname LIKE 'report_%';
```

#### v_find_dropuser_objs
**Purpose**: Objects owned by user (pre-deletion check)

**Usage**:
```sql
SELECT * FROM admin.v_find_dropuser_objs 
WHERE username = 'departing_user';
```

**Output**: Object list with ownership transfer commands

#### v_get_users_in_group
**Purpose**: Group membership listing

**Usage**:
```sql
SELECT * FROM admin.v_get_users_in_group 
ORDER BY groupname, username;
```

### 5. Connection and Session Management Views (3 views)

#### v_connection_summary
**Purpose**: Comprehensive connection tracking

**Key Information**:
- Connection duration
- Application name
- Driver version
- Connection state

**Usage**:
```sql
-- Active connections
SELECT * FROM admin.v_connection_summary 
WHERE session_state = 'active'
ORDER BY connection_start;

-- Long-running connections
SELECT * FROM admin.v_connection_summary 
WHERE duration_minutes > 60;
```

#### v_open_session
**Purpose**: Currently open connections

**Usage**:
```sql
SELECT * FROM admin.v_open_session 
ORDER BY connection_start DESC;
```

#### v_session_leakage_by_cnt
**Purpose**: Detect connection leaks

**Usage**:
```sql
SELECT * FROM admin.v_session_leakage_by_cnt 
WHERE leaked_sessions > 0;
```

### 6. Lock and Transaction Analysis Views (2 views)

#### v_check_transaction_locks
**Purpose**: Current lock status

**Lock Modes**:
- AccessShareLock (SELECT)
- RowShareLock (SELECT FOR UPDATE)
- RowExclusiveLock (INSERT, UPDATE, DELETE)
- ShareRowExclusiveLock (VACUUM, ANALYZE)
- AccessExclusiveLock (DROP, TRUNCATE, ALTER)

**Usage**:
```sql
-- All current locks
SELECT * FROM admin.v_check_transaction_locks;

-- Exclusive locks only
SELECT * FROM admin.v_check_transaction_locks 
WHERE lock_mode LIKE '%Exclusive%';
```

#### v_get_blocking_locks
**Purpose**: Detailed blocking analysis

**Usage**:
```sql
SELECT * FROM admin.v_get_blocking_locks;
```

**Output**:
- Blocker details
- Blocked session info
- Lock wait time
- Query text

### 7. Operational Utility Views (3 views)

#### v_generate_cancel_query
**Purpose**: Generate CANCEL commands for running queries

**Usage**:
```sql
-- Cancel long-running queries
SELECT cancel_command 
FROM admin.v_generate_cancel_query 
WHERE duration_seconds > 300;  -- 5 minutes
```

#### v_generate_terminate_session
**Purpose**: Generate session termination commands

**Usage**:
```sql
-- Terminate idle sessions
SELECT terminate_command 
FROM admin.v_generate_terminate_session 
WHERE session_state = 'idle' 
  AND idle_minutes > 30;
```

#### v_generate_cursor_query
**Purpose**: Active cursor management

**Usage**:
```sql
SELECT * FROM admin.v_generate_cursor_query;
```

**Shows**: Cursor name, size, query text, owner

### 8. Maintenance Views (3 views)

#### v_get_vacuum_details
**Purpose**: VACUUM operation history

**Usage**:
```sql
-- Recent vacuum operations
SELECT * FROM admin.v_get_vacuum_details 
WHERE vacuum_start > CURRENT_DATE - 7
ORDER BY vacuum_start DESC;
```

#### v_vacuum_summary
**Purpose**: VACUUM operation summary

**Usage**:
```sql
SELECT * FROM admin.v_vacuum_summary 
ORDER BY vacuum_end DESC
LIMIT 50;
```

#### v_get_cluster_restart_ts
**Purpose**: Last cluster restart time

**Usage**:
```sql
SELECT * FROM admin.v_get_cluster_restart_ts;
```

### 9. Session Analysis Views (2 views)

#### v_my_last_query_summary
**Purpose**: Analyze last query in current session

**Usage**:
```sql
-- After running a query
SELECT * FROM admin.v_my_last_query_summary;
```

**Output**: Formatted execution plan and metrics

#### v_my_last_copy_errors
**Purpose**: COPY errors from current session

**Usage**:
```sql
-- After failed COPY
SELECT * FROM admin.v_my_last_copy_errors;
```

### 10. Dependency Analysis Views (4 views)

#### v_object_dependency
**Purpose**: Complete object dependency map

**Usage**:
```sql
-- Dependencies for a table
SELECT * FROM admin.v_object_dependency 
WHERE source_name = 'fact_sales';
```

#### v_view_dependency
**Purpose**: View-to-table dependencies

**Usage**:
```sql
SELECT * FROM admin.v_view_dependency 
WHERE view_schema = 'reports';
```

#### v_constraint_dependency
**Purpose**: Foreign key relationships

**Usage**:
```sql
SELECT * FROM admin.v_constraint_dependency 
WHERE source_table = 'orders';
```

#### v_view_table_column_dependency
**Purpose**: Column-level view dependencies

**Usage**:
```sql
SELECT * FROM admin.v_view_table_column_dependency 
WHERE base_table = 'customers';
```

### 11. Stored Procedure Support (1 view)

#### v_get_stored_proc_params
**Purpose**: Stored procedure parameter information

**Usage**:
```sql
SELECT * FROM admin.v_get_stored_proc_params 
WHERE procedure_name = 'sp_analyze_tables';
```

## Common Use Cases

### Daily Operations Dashboard
```sql
-- Morning health check queries
SELECT 'Active Sessions' as metric, COUNT(*) as value 
FROM admin.v_connection_summary WHERE session_state = 'active'
UNION ALL
SELECT 'Blocked Queries', COUNT(*) 
FROM admin.v_get_blocking_locks
UNION ALL
SELECT 'Queued Queries', COUNT(*) 
FROM admin.v_wlm_queue_state WHERE queued > 0
UNION ALL
SELECT 'Tables Need Vacuum', COUNT(*) 
FROM admin.v_space_used_per_tbl WHERE pct_unsorted > 20;
```

### Migration Script Generation
```sql
-- Complete schema export
SELECT ddl FROM admin.v_generate_schema_ddl 
WHERE schemaname = 'production'
UNION ALL
SELECT ddl FROM admin.v_generate_tbl_ddl 
WHERE schemaname = 'production'
UNION ALL
SELECT ddl FROM admin.v_generate_view_ddl 
WHERE schemaname = 'production'
UNION ALL
SELECT ddl FROM admin.v_generate_user_grant_revoke_ddl 
WHERE objname IN (SELECT tablename FROM admin.v_generate_tbl_ddl WHERE schemaname = 'production');
```

### Security Audit
```sql
-- Users with excessive privileges
SELECT username, COUNT(*) as privileged_objects 
FROM admin.v_get_obj_priv_by_user 
WHERE del = 1 OR upd = 1
GROUP BY username
HAVING COUNT(*) > 10
ORDER BY privileged_objects DESC;
```

### Performance Troubleshooting
```sql
-- Problem identification workflow
-- Step 1: Check current issues
SELECT * FROM admin.v_get_blocking_locks;

-- Step 2: Review queue status
SELECT * FROM admin.v_wlm_queue_state;

-- Step 3: Identify slow queries
SELECT * FROM admin.v_check_wlm_query_time 
WHERE total_exec_time > 60000 
ORDER BY total_exec_time DESC LIMIT 10;

-- Step 4: Check table health
SELECT * FROM admin.v_check_data_distribution 
WHERE ratio_to_optimal > 2.0;
```

## Best Practices

1. **Regular Monitoring**: Schedule key views to run daily/weekly
2. **Access Control**: Grant SELECT on admin schema selectively
3. **Performance**: These views query system tables; use during maintenance windows for heavy analysis
4. **Customization**: Create wrapper views with your specific filters
5. **Documentation**: Document which views your team uses and why

## Troubleshooting View Issues

### View Returns No Data
- Check time-based filters in view definition
- Verify system table permissions
- Ensure activity exists to report

### View Performance Issues
- Run ANALYZE on system tables
- Check cluster load
- Consider caching results for dashboards

### Permission Errors
Required permissions:
- SELECT on system tables (stl_*, stv_*, svl_*, svv_*)
- SELECT on pg_catalog tables
- USAGE on admin schema