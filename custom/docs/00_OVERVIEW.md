# Amazon Redshift Utils - Complete Documentation

## Overview

Amazon Redshift Utils is a comprehensive collection of scripts, utilities, and tools designed to help you get the best performance and operational efficiency from your Amazon Redshift data warehouse. This repository, maintained by AWS Labs, provides battle-tested solutions for common Redshift administration tasks, performance optimization, and operational challenges.

## Repository Structure

```
amazon-redshift-utils/
├── src/
│   ├── AdminScripts/          # SQL scripts for diagnostics and monitoring
│   ├── AdminViews/            # Administrative views for cluster management
│   ├── StoredProcedures/      # Reusable stored procedures (deprecated)
│   ├── AnalyzeVacuumUtility/  # Automated table maintenance
│   ├── ColumnEncodingUtility/ # Column compression optimization (deprecated)
│   ├── UnloadCopyUtility/     # Data migration between clusters
│   ├── SimpleReplay/          # Workload capture and replay (moved)
│   ├── RedshiftAutomation/    # Lambda-based automation
│   └── [Other Utilities]/     # Various specialized tools
└── custom/                    # User documentation and scripts
    ├── docs/                  # Comprehensive documentation
    └── scripts/               # Setup and helper scripts
```

## Quick Start Guide

### 1. Setting Up Administrative Views

The fastest way to get started is to install the administrative views in your Redshift cluster:

```bash
# Generate the complete setup script
cd custom/scripts
./generate_admin_setup.sh

# Connect to your Redshift cluster and run:
\i setup_admin_schema_complete.sql
```

This creates an `admin` schema with 46 views for monitoring and managing your cluster.

### 2. Essential Daily Operations

#### Monitor Current Activity
```sql
-- View active sessions and queries
SELECT * FROM admin.v_connection_summary WHERE session_state = 'active';

-- Check for blocking locks
SELECT * FROM admin.v_get_blocking_locks;

-- Monitor WLM queue status
SELECT * FROM admin.v_wlm_queue_state;
```

#### Performance Analysis
```sql
-- Find slow queries from the last 7 days
SELECT * FROM admin.v_check_wlm_query_time 
WHERE total_exec_time > 60000 -- queries over 1 minute
ORDER BY total_exec_time DESC;

-- Check table distribution skew
SELECT * FROM admin.v_check_data_distribution 
WHERE ratio_skew_across_slices > 1.5;
```

#### Generate DDL for Backup/Migration
```sql
-- Generate complete table DDL
SELECT ddl FROM admin.v_generate_tbl_ddl 
WHERE schemaname = 'public' AND tablename = 'your_table';

-- Generate all schema objects
SELECT ddl FROM admin.v_generate_schema_ddl;
```

### 3. Automated Maintenance

#### Analyze & Vacuum Utility
```bash
# Run from src directory
python3 AnalyzeVacuumUtility/analyze-vacuum-schema.py \
  --db mydb \
  --db-user admin \
  --db-pwd $PASSWORD \
  --db-host mycluster.region.redshift.amazonaws.com \
  --schema-name public \
  --analyze-flag True \
  --vacuum-flag True
```

## Key Components

### 1. AdminScripts (23 SQL Scripts)

**Purpose**: Ready-to-run SQL scripts for immediate diagnostics and troubleshooting.

**Categories**:
- **Performance Monitoring**: `top_queries.sql`, `perf_alert.sql`, `copy_performance.sql`
- **Current Activity**: `current_session_info.sql`, `running_queues.sql`, `lock_wait.sql`
- **Table Analysis**: `table_info.sql`, `table_inspector.sql`, `missing_table_stats.sql`
- **WLM Analysis**: `wlm_apex.sql`, `queue_resources_hourly.sql`, `wlm_qmr_rule_candidates.sql`

**Usage Example**:
```sql
-- Run any script directly in your SQL client
\i src/AdminScripts/top_queries.sql
```

### 2. AdminViews (46 Views)

**Purpose**: Permanent views providing comprehensive cluster visibility and management capabilities.

**Categories**:
- **DDL Generation** (10 views): Complete schema recreation capabilities
- **Performance Monitoring** (5 views): Query and WLM analysis
- **Table Analysis** (6 views): Storage, distribution, and optimization insights
- **Security Management** (7 views): User privileges and access control
- **Connection Management** (3 views): Session monitoring and control
- **Lock Analysis** (2 views): Deadlock detection and resolution
- **Maintenance** (3 views): Vacuum and analyze tracking
- **Dependency Analysis** (4 views): Object relationship mapping

### 3. Python Utilities

#### AnalyzeVacuumUtility
- **Status**: Active
- **Purpose**: Automated table maintenance based on statistics and alerts
- **Key Features**: Two-phase approach, configurable thresholds, selective processing

#### UnloadCopyUtility
- **Status**: Active
- **Purpose**: Secure data migration between clusters via S3
- **Key Features**: KMS encryption, automatic cleanup, configuration-driven

#### SimpleReplay (Moved to Redshift Test-Drive)
- **Status**: Deprecated (use aws/redshift-test-drive)
- **Purpose**: Workload replay for performance testing

#### ColumnEncodingUtility
- **Status**: Deprecated (use ALTER TABLE ... ALTER SORTKEY/DISTSTYLE AUTO)
- **Purpose**: Column compression optimization

### 4. Lambda Automation (RedshiftAutomation)

**Purpose**: Serverless execution of utilities via AWS Lambda

**Supported Utilities**:
- Column Encoding Analysis
- Analyze & Vacuum Operations
- System Table Persistence
- WLM Schedule Management

**Deployment**: CloudFormation templates provided

## Best Practices

### Daily Tasks
1. Monitor active sessions using `admin.v_connection_summary`
2. Check for blocking locks with `admin.v_get_blocking_locks`
3. Review WLM queue status via `admin.v_wlm_queue_state`

### Weekly Tasks
1. Analyze top queries: `src/AdminScripts/top_queries.sql`
2. Review performance alerts: `admin.v_check_wlm_query_time`
3. Check table skew: `admin.v_check_data_distribution`
4. Run Analyze & Vacuum utility on critical tables

### Monthly Tasks
1. Review unused tables: `admin.v_extended_table_info WHERE last_scan IS NULL`
2. Analyze fragmentation: `admin.v_fragmentation_info`
3. Audit user privileges: `admin.v_get_obj_priv_by_user`
4. Update column encodings and sort keys

## Security Considerations

### Authentication Options
1. **Direct Password**: Command-line parameter (least secure)
2. **KMS Encrypted**: Base64-encoded encrypted passwords
3. **pgpass File**: Standard PostgreSQL authentication
4. **IAM Authentication**: For supported operations

### Required Permissions
- Most read-only operations: SELECT on system tables
- DDL generation: SELECT on pg_catalog tables
- Maintenance operations: Table owner or superuser
- User management: Superuser privileges

## Migration and Backup

### Complete Schema Backup
```sql
-- Generate all DDL in order
SELECT ddl FROM admin.v_generate_database_ddl;
SELECT ddl FROM admin.v_generate_schema_ddl;
SELECT ddl FROM admin.v_generate_group_ddl;
SELECT ddl FROM admin.v_generate_tbl_ddl ORDER BY tablename;
SELECT ddl FROM admin.v_generate_view_ddl ORDER BY viewname;
SELECT ddl FROM admin.v_generate_udf_ddl;
SELECT ddl FROM admin.v_generate_user_grant_revoke_ddl;
```

### Data Migration
```bash
# Use UnloadCopyUtility for secure data transfer
python3 src/UnloadCopyUtility/redshift_unload_copy.py \
  --s3-config-file s3://my-bucket/config.json \
  --region us-west-2
```

## Troubleshooting Guide

### Common Issues and Solutions

1. **High Query Queue Times**
   - Check: `admin.v_check_wlm_query_time`
   - Solution: Adjust WLM configuration or use Concurrency Scaling

2. **Table Distribution Skew**
   - Check: `admin.v_check_data_distribution`
   - Solution: Choose better distribution key or use AUTO distribution

3. **Slow COPY Operations**
   - Check: `src/AdminScripts/copy_performance.sql`
   - Solution: Split files, use manifest, check compression

4. **Lock Contention**
   - Check: `admin.v_get_blocking_locks`
   - Solution: Optimize transaction boundaries, use MVCC properly

5. **Missing Statistics**
   - Check: `src/AdminScripts/missing_table_stats.sql`
   - Solution: Run ANALYZE on affected tables

## Additional Resources

### Documentation Files in custom/docs/
- `01_ADMIN_SCRIPTS.md` - Detailed AdminScripts documentation
- `02_ADMIN_VIEWS.md` - Complete AdminViews reference
- `03_PYTHON_UTILITIES.md` - Python utility guides
- `04_AUTOMATION.md` - Lambda automation setup
- `05_PERFORMANCE_TUNING.md` - Performance optimization guide
- `06_SECURITY.md` - Security best practices
- `07_TROUBLESHOOTING.md` - Problem resolution guide

### External Resources
- [Amazon Redshift Documentation](https://docs.aws.amazon.com/redshift/)
- [Redshift Test-Drive](https://github.com/aws/redshift-test-drive) - Workload replay tool
- [Amazon Redshift UDFs](https://github.com/aws-samples/amazon-redshift-udfs) - User-defined functions

## Support and Contributing

This is an open-source project maintained by AWS Labs. For issues, feature requests, or contributions:
- GitHub Repository: https://github.com/awslabs/amazon-redshift-utils
- Create issues for bugs or feature requests
- Submit pull requests for contributions

## License

This project is licensed under the Apache-2.0 License. See LICENSE.txt for details.