# Amazon Redshift Utils - Quick Reference Guide

## Essential Commands

### Daily Operations

```sql
-- Check current activity
SELECT * FROM admin.v_connection_summary WHERE session_state = 'active';
SELECT * FROM admin.v_get_blocking_locks;
SELECT * FROM admin.v_wlm_queue_state;

-- Kill problematic queries
SELECT cancel_command FROM admin.v_generate_cancel_query WHERE duration_seconds > 300;

-- Table health check
SELECT * FROM admin.v_space_used_per_tbl 
WHERE pct_unsorted > 20 OR pct_stats_off > 10
ORDER BY size_in_mb DESC;
```

### Performance Troubleshooting

```sql
-- Slow queries (last 7 days)
\i src/AdminScripts/top_queries.sql

-- Performance alerts
\i src/AdminScripts/perf_alert.sql

-- WLM analysis
SELECT * FROM admin.v_check_wlm_query_time 
WHERE total_queue_time > 5000
ORDER BY total_queue_time DESC;

-- Table distribution issues
SELECT * FROM admin.v_check_data_distribution 
WHERE ratio_to_optimal > 1.5;
```

### Maintenance Operations

```bash
# Analyze and vacuum
python3 src/AnalyzeVacuumUtility/analyze-vacuum-schema.py \
  --db mydb --db-user admin --db-pwd $PGPASSWORD \
  --db-host cluster.region.redshift.amazonaws.com \
  --schema-name public

# Data migration
python3 src/UnloadCopyUtility/redshift_unload_copy.py \
  --s3-config-file s3://bucket/config.json \
  --region us-west-2
```

### DDL Generation

```sql
-- Backup table structure
SELECT ddl FROM admin.v_generate_tbl_ddl 
WHERE schemaname = 'public' AND tablename = 'mytable';

-- Export all schema objects
SELECT ddl FROM admin.v_generate_schema_ddl WHERE schemaname = 'public'
UNION ALL
SELECT ddl FROM admin.v_generate_tbl_ddl WHERE schemaname = 'public'
UNION ALL
SELECT ddl FROM admin.v_generate_view_ddl WHERE schemaname = 'public';
```

## Setup Checklist

### 1. Install Admin Views
```bash
cd custom/scripts
./generate_admin_setup.sh
# In Redshift:
\i setup_admin_schema_complete.sql
```

### 2. Configure Python Environment
```bash
cd src
pip install -r requirements.txt
```

### 3. Set Up Authentication
```bash
# Option 1: pgpass file
echo "host:5439:db:user:password" >> ~/.pgpass
chmod 600 ~/.pgpass

# Option 2: Environment variable
export PGPASSWORD='your_password'
```

### 4. Schedule Maintenance
```bash
# Add to crontab
0 2 * * * /path/to/analyze-vacuum-schema.py --config-file /path/to/config.yaml
```

## Key Admin Views by Use Case

### Monitoring
- `v_connection_summary` - Active connections
- `v_wlm_queue_state` - Queue status
- `v_get_blocking_locks` - Lock conflicts
- `v_check_wlm_query_time` - Query performance

### Optimization
- `v_check_data_distribution` - Table skew
- `v_extended_table_info` - Table health
- `v_space_used_per_tbl` - Storage analysis
- `v_fragmentation_info` - Fragmentation

### Security
- `v_get_obj_priv_by_user` - User privileges
- `v_find_dropuser_objs` - User owned objects
- `v_get_users_in_group` - Group membership

### Migration
- `v_generate_tbl_ddl` - Table DDL
- `v_generate_view_ddl` - View DDL
- `v_generate_user_grant_revoke_ddl` - Permissions

## Key AdminScripts by Use Case

### Daily Monitoring
- `current_session_info.sql` - Active sessions
- `running_queues.sql` - Queue activity
- `lock_wait.sql` - Lock waits

### Weekly Analysis
- `top_queries.sql` - Slow queries
- `perf_alert.sql` - Performance issues
- `table_info.sql` - Table statistics

### Optimization
- `predicate_columns.sql` - Sort key candidates
- `filter_used.sql` - Filter effectiveness
- `missing_table_stats.sql` - Statistics gaps

## Python Utilities Summary

| Utility | Purpose | Status |
|---------|---------|--------|
| AnalyzeVacuumUtility | Table maintenance | Active |
| UnloadCopyUtility | Data migration | Active |
| SimpleReplay | Workload replay | Moved to Test-Drive |
| ColumnEncodingUtility | Compression optimization | Deprecated |
| ManifestGenerator | COPY manifest creation | Active |
| UserLastLogin | Login tracking | Active |
| MetadataTransfer | Metadata migration | Active |
| RedshiftAutomation | Lambda automation | Active |

## Common SQL Patterns

### Find Large Unsorted Tables
```sql
SELECT * FROM admin.v_space_used_per_tbl 
WHERE size_in_mb > 1000 AND pct_unsorted > 20
ORDER BY size_in_mb DESC;
```

### Identify Unused Tables
```sql
SELECT * FROM admin.v_extended_table_info 
WHERE last_scan IS NULL OR last_scan < CURRENT_DATE - 30;
```

### Check User Activity
```sql
SELECT username, COUNT(*) as active_queries
FROM admin.v_connection_summary 
WHERE session_state = 'active'
GROUP BY username;
```

### Generate Migration Script
```sql
WITH ddl_order AS (
  SELECT 1 as seq, 'SCHEMA' as type, ddl FROM admin.v_generate_schema_ddl
  UNION ALL
  SELECT 2, 'TABLE', ddl FROM admin.v_generate_tbl_ddl
  UNION ALL
  SELECT 3, 'VIEW', ddl FROM admin.v_generate_view_ddl
  UNION ALL
  SELECT 4, 'GRANT', ddl FROM admin.v_generate_user_grant_revoke_ddl
)
SELECT ddl FROM ddl_order ORDER BY seq, type;
```

## Troubleshooting Decision Tree

```
Query Running Slow?
├── Check current locks: v_get_blocking_locks
├── Check WLM queue: v_wlm_queue_state
└── Check query plan: v_my_last_query_summary

Table Performance Issues?
├── Check distribution: v_check_data_distribution
├── Check sort order: v_space_used_per_tbl (pct_unsorted)
└── Check statistics: missing_table_stats.sql

Connection Problems?
├── Check active sessions: v_connection_summary
├── Check session leaks: v_session_leakage_by_cnt
└── Generate terminate commands: v_generate_terminate_session

Storage Issues?
├── Check table sizes: v_space_used_per_tbl
├── Check fragmentation: v_fragmentation_info
└── Find unused tables: unscanned_table_summary.sql
```

## Performance Thresholds

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| Queue Time | > 5 sec | > 30 sec | Review WLM config |
| Distribution Skew | > 1.5x | > 2.0x | Change dist key |
| Unsorted % | > 10% | > 20% | Run VACUUM |
| Stats Off % | > 10% | > 20% | Run ANALYZE |
| Fragmentation | > 10% | > 25% | Deep copy table |

## Emergency Procedures

### Kill All Queries from User
```sql
SELECT pg_terminate_backend(pid)
FROM stv_sessions
WHERE user_name = 'problematic_user';
```

### Emergency VACUUM
```sql
-- Minimal vacuum for critical table
VACUUM SORT ONLY schema.table_name;
```

### Quick Stats Update
```sql
-- Fast analyze on predicate columns
ANALYZE schema.table_name PREDICATE COLUMNS;
```

### Force Query Cancellation
```sql
CANCEL <query_id>;
-- or
SELECT pg_cancel_backend(<pid>);
```

## Resource Links

- **Documentation**: custom/docs/
- **Setup Scripts**: custom/scripts/
- **Admin Views SQL**: src/AdminViews/
- **Admin Scripts SQL**: src/AdminScripts/
- **Python Utilities**: src/*/
- **GitHub**: https://github.com/awslabs/amazon-redshift-utils