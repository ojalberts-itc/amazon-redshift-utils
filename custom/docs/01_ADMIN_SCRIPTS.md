# AdminScripts - Detailed Documentation

## Overview

The AdminScripts directory contains 23 SQL scripts that provide immediate diagnostic and monitoring capabilities for Amazon Redshift clusters. These scripts are designed to be run directly in any SQL client connected to your Redshift cluster.

## Script Categories and Usage

### Performance Monitoring Scripts

#### 1. copy_performance.sql
**Purpose**: Analyzes COPY operation performance over the last 7 days.

**Key Metrics**:
- File count per COPY operation
- Data size in MB
- Execution time
- Throughput (MB/s)

**Usage**:
```sql
\i src/AdminScripts/copy_performance.sql
```

**When to Use**: 
- Troubleshooting slow data loads
- Optimizing COPY operations
- Capacity planning for ETL windows

#### 2. perf_alert.sql
**Purpose**: Comprehensive performance alert analysis with detailed context and solutions.

**Alert Types Detected**:
- Missing statistics
- Very selective filters
- Scanned deleted rows
- Nested loop joins
- Data distribution issues
- Broadcast operations

**Usage**:
```sql
\i src/AdminScripts/perf_alert.sql
```

**Output Includes**:
- Alert description
- Affected tables
- Query text
- Proposed solutions
- Event timestamps

#### 3. top_queries.sql
**Purpose**: Identifies the 50 most resource-intensive queries from the last 7 days.

**Metrics Provided**:
- Query frequency
- Min/Max/Avg execution time
- Total runtime
- Alert event count

**Usage**:
```sql
\i src/AdminScripts/top_queries.sql
```

**Best Practice**: Run weekly to identify optimization candidates.

#### 4. top_queries_and_cursors.sql
**Purpose**: Enhanced version including cursor operations and detailed resource metrics.

**Additional Metrics**:
- CPU usage (seconds)
- Spill to disk (MB)
- Rows scanned vs returned
- WLM queue information
- Cursor operations

**Usage**:
```sql
\i src/AdminScripts/top_queries_and_cursors.sql
```

### Current Activity Monitoring

#### 5. current_session_info.sql
**Purpose**: Real-time view of active sessions and their queries.

**Information Displayed**:
- Session duration
- User and database
- Current query ID
- SQL text being executed

**Usage**:
```sql
\i src/AdminScripts/current_session_info.sql
```

**Use Case**: Immediate visibility into what's running right now.

#### 6. running_queues.sql
**Purpose**: Comprehensive view of WLM queue status with resource consumption.

**Metrics Shown**:
- Queue position
- Execution time
- CPU usage
- Memory spill
- Alert counts

**Usage**:
```sql
\i src/AdminScripts/running_queues.sql
```

#### 7. queuing_queries.sql
**Purpose**: Shows queries waiting in WLM queues.

**Key Information**:
- Queue wait time
- Service class
- Slot usage
- Query priorities

**Usage**:
```sql
\i src/AdminScripts/queuing_queries.sql
```

**Action Items**: If queries are queuing, consider:
- Adjusting WLM configuration
- Enabling Concurrency Scaling
- Optimizing long-running queries

#### 8. lock_wait.sql
**Purpose**: Analyzes lock contention and blocking relationships.

**Output Details**:
- Lock holder information
- Waiting sessions
- Lock duration
- Blocking chain analysis

**Usage**:
```sql
\i src/AdminScripts/lock_wait.sql
```

### Table Analysis Scripts

#### 9. table_info.sql
**Purpose**: Comprehensive table storage and structure analysis.

**Information Provided**:
- Table size and row count
- Distribution style and skew
- Sort key effectiveness
- Encoding efficiency
- Statistics freshness

**Usage**:
```sql
\i src/AdminScripts/table_info.sql
```

**Optimization Hints**:
- Skew ratio > 1.5: Consider different distribution key
- Unsorted % > 20%: Schedule VACUUM
- Stats off % > 10%: Run ANALYZE

#### 10. table_inspector.sql
**Purpose**: Deep dive into table distribution following AWS best practices.

**Analysis Includes**:
- Slice-level distribution
- Skew ratios
- Encoding status
- Storage efficiency

**Usage**:
```sql
\i src/AdminScripts/table_inspector.sql
```

#### 11. unscanned_table_summary.sql
**Purpose**: Identifies tables not accessed recently for potential cleanup.

**Metrics**:
- Storage used by unscanned tables
- Percentage of total cluster storage
- Last scan timestamps

**Usage**:
```sql
\i src/AdminScripts/unscanned_table_summary.sql
```

**Action**: Consider archiving or dropping unused tables.

#### 12. missing_table_stats.sql
**Purpose**: Finds queries affected by missing statistics.

**Output**:
- Queries with suboptimal plans
- Tables needing ANALYZE
- Plan node warnings

**Usage**:
```sql
\i src/AdminScripts/missing_table_stats.sql
```

### Filter and Query Pattern Analysis

#### 13. filter_used.sql
**Purpose**: Analyzes filter effectiveness and sort key usage.

**Information**:
- Filter types and frequency
- Scan time analysis
- Sort key utilization

**Usage**:
```sql
\i src/AdminScripts/filter_used.sql
```

**Optimization**: Use results to design better sort keys.

#### 14. predicate_columns.sql
**Purpose**: Identifies columns frequently used in WHERE clauses.

**Analysis**:
- Predicate frequency
- Column statistics
- Current key usage

**Usage**:
```sql
\i src/AdminScripts/predicate_columns.sql
```

**Best Practice**: Consider these columns for sort keys or distribution keys.

### WLM (Workload Management) Analysis

#### 15. wlm_apex.sql
**Purpose**: Identifies peak WLM usage and capacity constraints.

**Metrics**:
- Maximum concurrent slots used
- Peak usage timestamps
- Last queuing event

**Usage**:
```sql
\i src/AdminScripts/wlm_apex.sql
```

#### 16. wlm_apex_hourly.sql
**Purpose**: Hourly breakdown of WLM high-water marks.

**Output**:
- Hour-by-hour peak usage
- Service class breakdown
- Capacity planning data

**Usage**:
```sql
\i src/AdminScripts/wlm_apex_hourly.sql
```

#### 17. queue_resources_hourly.sql
**Purpose**: Detailed resource consumption by WLM queue and hour.

**Metrics**:
- CPU seconds
- Spill to disk
- Rows processed
- Query counts

**Usage**:
```sql
\i src/AdminScripts/queue_resources_hourly.sql
```

#### 18. wlm_qmr_rule_candidates.sql
**Purpose**: Suggests Query Monitoring Rules based on historical metrics.

**Recommendations**:
- 99th percentile thresholds
- Rule action suggestions
- Impact analysis

**Usage**:
```sql
\i src/AdminScripts/wlm_qmr_rule_candidates.sql
```

**Implementation**: Use output to create QMR rules preventing runaway queries.

### Data Management Scripts

#### 19. insert_into_table_dk_mismatch.sql
**Purpose**: Identifies INSERT operations with distribution key mismatches.

**Detection**:
- Source vs target distribution keys
- Data movement requirements
- Performance impact

**Usage**:
```sql
\i src/AdminScripts/insert_into_table_dk_mismatch.sql
```

**Fix**: Align distribution keys or use temporary staging tables.

### Administrative Scripts

#### 20. user_to_be_dropped_objs.sql
**Purpose**: Lists all objects owned by a user before deletion.

**Output**:
- Functions
- Databases
- Schemas
- Tables and views

**Usage**:
```sql
\i src/AdminScripts/user_to_be_dropped_objs.sql
```

#### 21. user_to_be_dropped_privs.sql
**Purpose**: Shows all privileges granted to/by a user.

**Information**:
- Direct privileges
- Group memberships
- Granted privileges

**Usage**:
```sql
\i src/AdminScripts/user_to_be_dropped_privs.sql
```

### Utility Scripts

#### 22. generate_calendar.sql
**Purpose**: Creates a calendar dimension table for analytics.

**Features**:
- 150-year range (1900-2049)
- Holiday detection
- Business day flags
- Quarter/Week calculations

**Usage**:
```sql
\i src/AdminScripts/generate_calendar.sql
```

**Result**: Creates `dim_calendar` table with comprehensive date attributes.

#### 23. table_alerts.sql
**Purpose**: Table-specific performance alerts without query text.

**Focus**:
- Table-level issues
- Scan performance
- Statistics problems

**Usage**:
```sql
\i src/AdminScripts/table_alerts.sql
```

## Best Practices for Using AdminScripts

### Daily Monitoring Routine
```sql
-- Morning checks
\i current_session_info.sql    -- Active sessions
\i running_queues.sql          -- Queue status
\i lock_wait.sql               -- Lock issues
```

### Weekly Performance Review
```sql
-- Performance analysis
\i top_queries.sql             -- Slow queries
\i perf_alert.sql             -- Performance alerts
\i table_alerts.sql           -- Table issues
\i wlm_apex_hourly.sql        -- WLM patterns
```

### Monthly Optimization
```sql
-- Deep analysis
\i table_info.sql             -- Table health
\i predicate_columns.sql      -- Sort key candidates
\i unscanned_table_summary.sql -- Cleanup opportunities
\i missing_table_stats.sql    -- Statistics gaps
```

## Customizing Scripts

Most scripts can be customized by modifying:

1. **Time ranges**: Change `CURRENT_DATE - 7` to different intervals
2. **Thresholds**: Adjust percentage or size limits
3. **Filters**: Add schema or table name filters
4. **Output limits**: Change LIMIT clauses

Example customization:
```sql
-- Original: last 7 days
WHERE starttime > CURRENT_DATE - 7

-- Modified: last 30 days
WHERE starttime > CURRENT_DATE - 30

-- Add schema filter
AND schemaname = 'production'
```

## Integration with Monitoring

These scripts can be:
1. Scheduled via cron for regular reports
2. Integrated into monitoring dashboards
3. Used in Lambda functions for automated alerts
4. Combined with CloudWatch metrics

## Performance Impact

Most scripts are lightweight and safe for production use. However:

- **Heavy scripts**: `table_info.sql`, `predicate_columns.sql`
- **Run during maintenance windows**: Deep analysis scripts
- **Cache results**: For frequently accessed metrics

## Troubleshooting Common Issues

### Script Returns No Results
- Check time range filters
- Verify system table permissions
- Ensure cluster has activity to analyze

### Script Runs Slowly
- System tables may need VACUUM
- Consider running during off-peak hours
- Check for cluster resource constraints

### Permission Errors
Required permissions:
- SELECT on system tables (stl_*, stv_*, svl_*, svv_*)
- SELECT on pg_catalog tables
- Access to target schemas for analysis