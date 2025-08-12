# Python Utilities - Comprehensive Guide

## Overview

The Python utilities in Amazon Redshift Utils provide automated solutions for common operational tasks. These tools handle everything from table maintenance to data migration and workload analysis.

## 1. AnalyzeVacuumUtility

### Purpose
Automates VACUUM and ANALYZE operations based on table statistics and system alerts, ensuring optimal query performance and storage efficiency.

### Installation
```bash
cd src/AnalyzeVacuumUtility
pip install -r ../requirements.txt
```

### Usage

#### Basic Command
```bash
python3 analyze-vacuum-schema.py \
  --db mydb \
  --db-user admin \
  --db-pwd password \
  --db-host mycluster.region.redshift.amazonaws.com \
  --db-port 5439 \
  --schema-name public
```

#### With Configuration File
```bash
python3 analyze-vacuum-schema.py \
  --config-file config.yaml \
  --output-file vacuum_log.txt
```

### Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--analyze-flag` | True | Enable ANALYZE operations |
| `--vacuum-flag` | True | Enable VACUUM operations |
| `--schema-name` | public | Target schema (or ALL for all schemas) |
| `--table-name` | - | Specific table (optional) |
| `--min-unsorted-pct` | 5 | Minimum unsorted percentage threshold |
| `--max-unsorted-pct` | 50 | Maximum unsorted percentage threshold |
| `--stats-off-pct` | 10 | Statistics inaccuracy threshold |
| `--max-table-size-mb` | 716800 | Maximum table size for vacuum (700GB) |
| `--min-interleaved-skew` | 1.4 | Interleaved sort key skew threshold |
| `--slot-count` | 1 | Number of WLM slots to use |
| `--ignore-errors` | False | Continue on errors |

### Operation Phases

#### VACUUM Phase 1: Alert-Based
- Queries `stl_alert_event_log` for vacuum recommendations
- Prioritizes tables with most alerts
- Looks back 7 days by default

#### VACUUM Phase 2: Threshold-Based
- Analyzes table statistics
- Checks unsorted percentage
- Evaluates table size constraints

#### ANALYZE Phase 1: Alert-Based
- Identifies tables with missing statistics alerts
- Processes tables with predicate usage

#### ANALYZE Phase 2: Statistics-Based
- Checks statistics accuracy
- Analyzes tables exceeding threshold

### Best Practices

```bash
# Daily maintenance for critical tables
python3 analyze-vacuum-schema.py \
  --schema-name production \
  --max-table-size-mb 102400 \  # 100GB limit
  --min-unsorted-pct 10 \
  --output-file daily_maintenance.log

# Weekly deep maintenance
python3 analyze-vacuum-schema.py \
  --schema-name ALL \
  --max-unsorted-pct 75 \
  --slot-count 3 \
  --output-file weekly_maintenance.log

# Single table optimization
python3 analyze-vacuum-schema.py \
  --schema-name sales \
  --table-name fact_orders \
  --vacuum-flag True \
  --analyze-flag False
```

### Monitoring Output
```
Analyzing Table: sales.fact_orders
  Unsorted: 23.5%
  Stats Off: 8.2%
  Size: 45,678 MB
  Action: VACUUM SORT ONLY
  Duration: 145 seconds
  Rows Sorted: 12,345,678
```

## 2. UnloadCopyUtility

### Purpose
Migrates data between Redshift clusters using S3 as an encrypted staging area. Supports cross-region transfers and automatic cleanup.

### Installation
```bash
cd src/UnloadCopyUtility
pip install -r requirements.txt
```

### Configuration

#### JSON Configuration File
```json
{
  "unloadSource": {
    "clusterEndpoint": "source-cluster.region.redshift.amazonaws.com",
    "clusterPort": 5439,
    "connectUser": "admin",
    "connectPwd": "KMS_ENCRYPTED_PASSWORD",
    "db": "sourcedb",
    "schemaName": "public",
    "tableName": "customers"
  },
  "s3Staging": {
    "aws_iam_role": "arn:aws:iam::123456789012:role/RedshiftUnloadRole",
    "s3Bucket": "my-migration-bucket",
    "s3Key": "migrations/2024/",
    "deleteOnSuccess": true,
    "region": "us-west-2"
  },
  "copyTarget": {
    "clusterEndpoint": "target-cluster.region.redshift.amazonaws.com",
    "clusterPort": 5439,
    "connectUser": "admin",
    "connectPwd": "KMS_ENCRYPTED_PASSWORD",
    "db": "targetdb",
    "schemaName": "public",
    "tableName": "customers"
  }
}
```

### Usage Examples

#### Basic Migration
```bash
python3 redshift_unload_copy.py \
  --s3-config-file s3://config-bucket/migration-config.json \
  --region us-west-2
```

#### With Local Config
```bash
python3 redshift_unload_copy.py \
  --config-file /path/to/config.json \
  --log-level DEBUG
```

#### Password Encryption
```bash
# Encrypt password with KMS
./encryptValue.sh us-west-2 alias/redshift-key 'MyPassword123'

# Use in configuration
"connectPwd": "AQICAHi5VCT...encrypted_string..."
```

### Advanced Features

#### Selective Column Migration
```json
{
  "unloadSource": {
    "columns": ["customer_id", "name", "email", "created_date"],
    "whereClause": "WHERE created_date >= '2024-01-01'"
  }
}
```

#### Parallel Processing
```json
{
  "options": {
    "threads": 4,
    "maxFileSize": "50GB",
    "parallel": "ON"
  }
}
```

### Monitoring Progress
```
[INFO] Starting unload from source-cluster.redshift.amazonaws.com
[INFO] Unloading table: public.customers
[INFO] Files staged to: s3://my-migration-bucket/migrations/2024/
[INFO] Starting copy to target-cluster.redshift.amazonaws.com
[INFO] Copy completed: 1,234,567 rows loaded
[INFO] Cleaning up S3 staging area
[SUCCESS] Migration completed successfully
```

## 3. SimpleReplay (Deprecated - Use Redshift Test-Drive)

### Note
SimpleReplay has been moved to [Redshift Test-Drive](https://github.com/aws/redshift-test-drive). This section covers the legacy version for reference.

### Purpose
Captures and replays production workloads for performance testing and troubleshooting.

### Installation
```bash
cd src/SimpleReplay
pip install -r requirements.txt
```

### Workflow

#### Step 1: Extract Workload
```bash
python3 extract.py extract/extract.yaml
```

#### Extract Configuration (extract.yaml)
```yaml
source_cluster_endpoint: prod-cluster.region.redshift.amazonaws.com:5439/proddb
master_username: admin
start_time: "2024-01-15 00:00:00"
end_time: "2024-01-15 23:59:59"
workload_location: s3://workload-bucket/extracts/
```

#### Step 2: Replay Workload
```bash
python3 replay.py replay.yaml
```

#### Replay Configuration (replay.yaml)
```yaml
target_cluster_endpoint: test-cluster.region.redshift.amazonaws.com:5439/testdb
master_username: admin
workload_location: s3://workload-bucket/extracts/
execute_copy_statements: true
execute_unload_statements: false
replay_factor: 1.0  # 1.0 = same speed, 2.0 = double speed
```

#### Step 3: Analyze Results
```bash
python3 replay_analysis.py
```

## 4. ColumnEncodingUtility (Deprecated)

### Note
Use Redshift's automatic table optimization instead:
```sql
ALTER TABLE table_name ALTER SORTKEY AUTO;
ALTER TABLE table_name ALTER DISTSTYLE AUTO;
ALTER TABLE table_name ALTER ENCODE AUTO;
```

### Legacy Usage (For Reference)
```bash
python analyze-schema-compression.py \
  --db mydb \
  --db-user admin \
  --db-host cluster.region.redshift.amazonaws.com \
  --schema public \
  --analyze-table customers
```

## 5. ManifestGenerator

### Purpose
Generates Redshift manifest files to split large COPY operations into manageable batches.

### Installation
```bash
cd src/ManifestGenerator
pip install -r requirements.txt
```

### Usage

#### From S3 Listing
```bash
# Generate manifest from S3 bucket listing
python3 manifestgen.py \
  s3://my-bucket/data/ \
  --prefix manifest_ \
  --num 4 \
  --suffix .json
```

#### From Local CSV
```bash
# Split local file list into manifests
python3 manifestgen.py \
  --input-file file_list.csv \
  --prefix batch_ \
  --num 10 \
  --csv
```

#### From AWS CLI Output
```bash
# Use AWS CLI to list files
aws s3 ls s3://my-bucket/data/ --recursive | \
  python3 manifestgen.py \
    --prefix manifest_ \
    --num 5 \
    --s3-prefix s3://my-bucket/
```

### Output Format
```json
{
  "entries": [
    {"url": "s3://my-bucket/data/file1.gz", "mandatory": true},
    {"url": "s3://my-bucket/data/file2.gz", "mandatory": true}
  ]
}
```

### Use in COPY Command
```sql
COPY table_name
FROM 's3://my-bucket/manifest_1.json'
IAM_ROLE 'arn:aws:iam::123456789012:role/RedshiftRole'
MANIFEST
GZIP;
```

## 6. UserLastLogin

### Purpose
Tracks and reports the last login time for database users, useful for compliance and cleanup.

### Installation
```bash
cd src/UserLastLogin
pip install -r requirements.txt
```

### Usage

#### Provisioned Clusters
```bash
python3 user_last_login.py \
  --cluster my-cluster \
  --dbUser admin \
  --dbName mydb \
  --region us-west-2
```

#### Serverless Workgroups
```bash
python3 user_last_login.py \
  --workgroup my-workgroup \
  --dbName mydb \
  --region us-west-2
```

### Output
```
User Login Report - Generated: 2024-01-15 10:30:00
================================================
Username        Last Login           Days Inactive
--------        ----------           -------------
john_doe        2024-01-14 15:23:00  1
jane_smith      2024-01-10 09:15:00  5
old_app_user    2023-11-01 12:00:00  75
```

## 7. MetadataTransfer

### Purpose
Transfers metadata (users, groups, schemas, privileges) between Redshift clusters.

### Installation
```bash
cd src/MetadataTransfer
pip install -r requirements.txt
```

### Usage

#### Full Metadata Transfer
```bash
python3 metadatacopy.py \
  --tgtcluster target.region.redshift.amazonaws.com \
  --tgtuser admin \
  --srccluster source.region.redshift.amazonaws.com \
  --srcuser admin
```

#### Privileges Only
```bash
python3 userprivs.py \
  --tgtcluster target.region.redshift.amazonaws.com \
  --tgtuser admin \
  --srccluster source.region.redshift.amazonaws.com \
  --srcuser admin
```

### Transfer Components
- Users and passwords
- Groups and memberships
- Schema definitions
- Table/view privileges
- Default privileges
- Database privileges

## 8. UnloadAutoPartitions

### Purpose
Generates and executes UNLOAD commands with automatic partitioning.

### Installation
```bash
cd src/UnloadAutoPartitions
pip install -r requirements.txt
```

### Configuration (config.ini)
```ini
[db_details]
host=cluster.region.redshift.amazonaws.com
port=5439
database=mydb
user=admin
schema=public
table=sales_fact

[unload_details]
partition_column=sale_date
partition_type=daily  # daily, monthly, yearly
s3_path=s3://my-bucket/unloads/
iam_role=arn:aws:iam::123456789012:role/RedshiftRole
```

### Usage
```bash
python3 genunload.py
```

### Generated Output
```sql
-- Partitioned unload commands
UNLOAD ('SELECT * FROM sales_fact WHERE sale_date = ''2024-01-01''')
TO 's3://my-bucket/unloads/year=2024/month=01/day=01/'
IAM_ROLE 'arn:aws:iam::123456789012:role/RedshiftRole'
PARALLEL OFF ALLOWOVERWRITE;

UNLOAD ('SELECT * FROM sales_fact WHERE sale_date = ''2024-01-02''')
TO 's3://my-bucket/unloads/year=2024/month=01/day=02/'
IAM_ROLE 'arn:aws:iam::123456789012:role/RedshiftRole'
PARALLEL OFF ALLOWOVERWRITE;
```

## Common Patterns and Best Practices

### Authentication Methods

#### 1. Direct Password
```bash
python3 utility.py --db-pwd 'MyPassword123'
```

#### 2. Environment Variable
```bash
export PGPASSWORD='MyPassword123'
python3 utility.py
```

#### 3. .pgpass File
```bash
# ~/.pgpass format
hostname:port:database:username:password
echo "cluster.region.redshift.amazonaws.com:5439:mydb:admin:MyPassword123" >> ~/.pgpass
chmod 600 ~/.pgpass
```

#### 4. KMS Encrypted
```bash
# Encrypt
aws kms encrypt --key-id alias/redshift --plaintext 'MyPassword123'
# Use encrypted value in config
```

### Error Handling

All utilities support error handling flags:

```bash
# Continue on errors
python3 utility.py --ignore-errors

# Verbose logging
python3 utility.py --log-level DEBUG

# Output to file
python3 utility.py --output-file operation.log
```

### Performance Optimization

```bash
# Use multiple threads
python3 utility.py --threads 4

# Increase slot count for maintenance
python3 analyze-vacuum-schema.py --slot-count 3

# Limit operation scope
python3 utility.py --max-table-size-mb 10240  # 10GB
```

### Scheduling with Cron

```bash
# Daily analyze/vacuum at 2 AM
0 2 * * * /usr/bin/python3 /path/to/analyze-vacuum-schema.py --config-file /path/to/config.yaml

# Weekly full maintenance Sunday 3 AM
0 3 * * 0 /usr/bin/python3 /path/to/analyze-vacuum-schema.py --schema-name ALL --max-unsorted-pct 90
```

## Troubleshooting

### Connection Issues
```bash
# Test connection
psql -h cluster.region.redshift.amazonaws.com -p 5439 -U admin -d mydb

# Check security groups
aws redshift describe-clusters --cluster-identifier my-cluster
```

### Permission Errors
```sql
-- Grant necessary permissions
GRANT SELECT ON ALL TABLES IN SCHEMA public TO utility_user;
GRANT EXECUTE ON PROCEDURE sp_analyze_minimal TO utility_user;
```

### Performance Issues
```bash
# Reduce scope
python3 utility.py --table-name single_table

# Run during maintenance window
python3 utility.py --time-window "02:00-06:00"
```

## Docker Execution

Build and run utilities in Docker:

```bash
# Build image
docker build -t redshift-utils .

# Run with environment file
docker run --env-file redshift.env redshift-utils analyze-vacuum

# Run with mounted config
docker run -v /local/config:/config redshift-utils unload-copy
```