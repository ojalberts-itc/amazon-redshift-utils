# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Amazon Redshift Utilities is a collection of scripts and utilities to help get the best performance from Amazon Redshift data warehouse. The repository contains administrative scripts, views, stored procedures, and various utility tools for managing and optimizing Redshift clusters.

## Key Components and Architecture

### Main Utility Categories

1. **AdminScripts** (`src/AdminScripts/`) - SQL scripts for diagnostics and monitoring
2. **AdminViews** (`src/AdminViews/`) - SQL views for cluster management and DDL generation
3. **StoredProcedures** (`src/StoredProcedures/`) - Reusable stored procedures for common tasks
4. **AnalyzeVacuumUtility** (`src/AnalyzeVacuumUtility/`) - Automated VACUUM and ANALYZE operations
5. **ColumnEncodingUtility** (`src/ColumnEncodingUtility/`) - Optimize column compression encodings
6. **UnloadCopyUtility** (`src/UnloadCopyUtility/`) - Migrate data between clusters/databases
7. **SimpleReplay** (`src/SimpleReplay/`) - Capture and replay cluster workloads
8. **RedshiftAutomation** (`src/RedshiftAutomation/`) - Lambda-based automation framework

### Python Utilities Pattern

Most Python utilities follow this pattern:
- Main script in utility folder (e.g., `analyze-vacuum-schema.py`)
- Supporting modules in `lib/` subdirectory
- Configuration via command-line arguments or config files
- Database connections using pg8000 or redshift-connector libraries
- KMS encryption support for passwords

## Common Development Commands

### Running Utilities

```bash
# From src directory
python3 ./<folder>/<utility> <args>

# Example: Run Analyze Vacuum Utility
python3 ./AnalyzeVacuumUtility/analyze-vacuum-schema.py \
  --db <database> --host <host> --port <port> \
  --user <user> --schema <schema>

# Example: Run Column Encoding Utility
python3 ./ColumnEncodingUtility/analyze-schema-compression.py \
  --db <database> --host <host> --port <port> \
  --user <user> --schema <schema>
```

### Docker Execution

```bash
# Build Docker image
docker build -t amazon-redshift-utils .

# Run utilities via Docker
docker run --net host --rm -it -e DB=my-database ... amazon-redshift-utils analyze-vacuum
docker run --net host --rm -it -e CONFIG_FILE=s3://... amazon-redshift-utils unload-copy
docker run --net host --rm -it -e DB=my-database ... amazon-redshift-utils column-encoding
```

### Testing

```bash
# Run UnloadCopyUtility tests (Python 3 required)
cd src/UnloadCopyUtility/tests
python3 -m pytest redshift_unload_copy_unittests.py
python3 -m pytest ddl_helpers_tests.py
python3 -m pytest global_config_unittests.py
```

### Building Lambda Packages

```bash
# Build RedshiftAutomation for Lambda
cd src/RedshiftAutomation
./build.sh

# Build QMRNotificationUtility for Lambda
cd src/QMRNotificationUtility/lambda
./build.sh
```

## Database Connection Configuration

### Authentication Methods

1. **Direct Password**: Pass via command line argument
2. **KMS Encrypted**: Base64 encoded KMS encrypted string in configs
3. **pgpass File**: Use `.pgpass` file for authentication
4. **Environment Variable**: Use `$PGPASS` environment variable

### Common Connection Parameters

- `--db` / `-d`: Database name
- `--host` / `-t`: Cluster endpoint
- `--port` / `-p`: Port (default 5439)
- `--user` / `-u`: Database user
- `--password` / `-w`: Password (various formats supported)
- `--schema` / `-s`: Schema name

## Project Dependencies

Main Python dependencies (from `src/requirements.txt`):
- pg8000==1.11.0
- redshift-connector==2.0.908
- boto3==1.5.3
- pgpasslib==1.1.0

## Important SQL Patterns

- System tables prefixed with `stl_`, `stv_`, `svl_`, `svv_`
- Use `pg_catalog` and `information_schema` for metadata
- Leverage Redshift-specific commands: VACUUM, ANALYZE, COPY, UNLOAD
- Consider sort keys and distribution keys for performance

## Lambda Automation Pattern

Utilities can be deployed as Lambda functions:
1. Package utility with dependencies
2. Deploy using CloudFormation templates
3. Schedule via CloudWatch Events
4. Configuration via environment variables or S3