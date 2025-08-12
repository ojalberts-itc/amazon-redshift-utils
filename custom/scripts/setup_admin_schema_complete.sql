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

-- Drop all existing admin views
DROP VIEW IF EXISTS admin.v_check_data_distribution CASCADE;
DROP VIEW IF EXISTS admin.v_check_transaction_locks CASCADE;
DROP VIEW IF EXISTS admin.v_check_wlm_query_time CASCADE;
DROP VIEW IF EXISTS admin.v_check_wlm_query_trend_daily CASCADE;
DROP VIEW IF EXISTS admin.v_check_wlm_query_trend_hourly CASCADE;
DROP VIEW IF EXISTS admin.v_connection_summary CASCADE;
DROP VIEW IF EXISTS admin.v_constraint_dependency CASCADE;
DROP VIEW IF EXISTS admin.v_extended_table_info CASCADE;
DROP VIEW IF EXISTS admin.v_find_dropuser_objs CASCADE;
DROP VIEW IF EXISTS admin.v_fragmentation_info CASCADE;
DROP VIEW IF EXISTS admin.v_generate_cancel_query CASCADE;
DROP VIEW IF EXISTS admin.v_generate_cursor_query CASCADE;
DROP VIEW IF EXISTS admin.v_generate_database_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_external_tbl_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_group_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_schema_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_tbl_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_terminate_session CASCADE;
DROP VIEW IF EXISTS admin.v_generate_udf_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_unload_copy_cmd CASCADE;
DROP VIEW IF EXISTS admin.v_generate_user_grant_revoke_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_generate_user_object_permissions CASCADE;
DROP VIEW IF EXISTS admin.v_generate_view_ddl CASCADE;
DROP VIEW IF EXISTS admin.v_get_blocking_locks CASCADE;
DROP VIEW IF EXISTS admin.v_get_cluster_restart_ts CASCADE;
DROP VIEW IF EXISTS admin.v_get_obj_priv_by_user CASCADE;
DROP VIEW IF EXISTS admin.v_get_schema_priv_by_user CASCADE;
DROP VIEW IF EXISTS admin.v_get_stored_proc_params CASCADE;
DROP VIEW IF EXISTS admin.v_get_tbl_priv_by_group CASCADE;
DROP VIEW IF EXISTS admin.v_get_tbl_priv_by_user CASCADE;
DROP VIEW IF EXISTS admin.v_get_tbl_reads_and_writes CASCADE;
DROP VIEW IF EXISTS admin.v_get_tbl_scan_frequency CASCADE;
DROP VIEW IF EXISTS admin.v_get_users_in_group CASCADE;
DROP VIEW IF EXISTS admin.v_get_vacuum_details CASCADE;
DROP VIEW IF EXISTS admin.v_get_view_priv_by_user CASCADE;
DROP VIEW IF EXISTS admin.v_my_last_copy_errors CASCADE;
DROP VIEW IF EXISTS admin.v_my_last_query_summary CASCADE;
DROP VIEW IF EXISTS admin.v_object_dependency CASCADE;
DROP VIEW IF EXISTS admin.v_open_session CASCADE;
DROP VIEW IF EXISTS admin.v_query_type_duration_summary CASCADE;
DROP VIEW IF EXISTS admin.v_session_leakage_by_cnt CASCADE;
DROP VIEW IF EXISTS admin.v_space_used_per_tbl CASCADE;
DROP VIEW IF EXISTS admin.v_vacuum_summary CASCADE;
DROP VIEW IF EXISTS admin.v_view_dependency CASCADE;
DROP VIEW IF EXISTS admin.v_view_table_column_dependency CASCADE;
DROP VIEW IF EXISTS admin.v_wlm_queue_state CASCADE;

-- ============================================================================
-- Create Administrative Views
-- ============================================================================


-- ============================================================================
-- Creating view: v_generate_database_ddl
-- Source: v_generate_database_ddl.sql
-- ============================================================================
--DROP VIEW admin.v_generate_database_ddl;
/**********************************************************************************************
Purpose: View to get the DDL for a database 
History:
2018-01-20 pvbouwel Create the view
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_generate_database_ddl
AS
SELECT
  datname as datname,
  'CREATE DATABASE ' + QUOTE_IDENT(datname) + ' WITH CONNECTION LIMIT ' + datconnlimit + ';' AS ddl
FROM pg_catalog.pg_database_info
WHERE datdba >= 100
ORDER BY datname
;

;

-- ============================================================================
-- Creating view: v_generate_group_ddl
-- Source: v_generate_group_ddl.sql
-- ============================================================================
--DROP VIEW admin.v_generate_group_ddl;
/**********************************************************************************************
Purpose: View to get the DDL for a group.  
History:
2014-02-11 jjschmit Created
2018-01-15 pvbouwel Add QUOTE_IDENT for group names
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_generate_group_ddl
AS
SELECT groname AS groupname, 'CREATE GROUP ' + QUOTE_IDENT(groname) + ';' AS ddl FROM pg_catalog.pg_group ORDER BY groname
;


;

-- ============================================================================
-- Creating view: v_get_cluster_restart_ts
-- Source: v_get_cluster_restart_ts.sql
-- ============================================================================
--DROP VIEW admin.v_get_cluster_restart_ts ;
/**********************************************************************************************
Purpose: View to get the datetime of when Redshift cluster was recently restarted
History:
2015-07-01 srinikri Created
2016-11-07 chriz-bigdata added userid=1 filter to eliminate false positives
**********************************************************************************************/ 
CREATE OR REPLACE VIEW admin.admin.v_get_cluster_restart_ts 
AS
SELECT sysdate current_ts, endtime AS restart_ts
FROM stl_utilitytext
WHERE text LIKE '%xen_is_up.sql%' AND userid = 1
ORDER BY endtime DESC;

-- ============================================================================
-- Creating view: v_get_users_in_group
-- Source: v_get_users_in_group.sql
-- ============================================================================
/**********************************************************************************************
Purpose: View to get all users in a group
History:
2013-10-29 jjschmit Created
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_get_users_in_group
AS
SELECT 
	pg_group.groname
	,pg_group.grosysid
	,pg_user.*
FROM pg_group, pg_user 
WHERE pg_user.usesysid = ANY(pg_group.grolist) 
ORDER BY 1,2 
;
;

-- ============================================================================
-- Creating view: v_my_last_copy_errors
-- Source: v_my_last_copy_errors.sql
-- ============================================================================
/**********************************************************************************************
Purpose: View to help you see the issues with the last copy run in the session

Notes: 
                
History:
2018-01-18 meyersi Created View Script

**********************************************************************************************/

CREATE OR REPLACE VIEW admin.admin.v_my_last_copy_errors as 
select query, 
       starttime,
       filename, 
       line_number,
       err_reason,
       colname,
       type column_type,
       col_length,
       raw_field_value
from stl_load_errors le
where le.query = pg_last_copy_id();

-- ============================================================================
-- Creating view: v_my_last_query_summary
-- Source: v_my_last_query_summary.sql
-- ============================================================================
/**********************************************************************************************
Purpose:        View to help you see the summary of the last query that was run

Notes: Query simply applies formatting to SVL_QUERY_SUMMARY for the last run query by the session 
       via the pg_last_query_id() function. Please note that this function may return null for
       queries that are taking advantage of resultset caching.
                
History:
2018-01-18 meyersi Created View Script

**********************************************************************************************/

CREATE OR REPLACE VIEW admin.admin.v_my_last_query_summary as 
select query,
       maxtime, 
       avgtime, 
       rows, 
       bytes, 
       lpad(' ',stm+seg+step) || label as label, 
       is_diskbased, 
       workmem, 
       is_rrscan, 
       is_delayed_scan, 
       rows_pre_filter 
from svl_query_summary 
where query = pg_last_query_id() 
order by stm, seg, step;

-- ============================================================================
-- Creating view: v_open_session
-- Source: v_open_session.sql
-- ============================================================================
CREATE OR REPLACE VIEW admin.admin.v_open_session
AS
SELECT
	CASE WHEN disc.recordtime IS NULL THEN 'Y' ELSE 'N' END AS connected
	,init.recordtime AS conn_recordtime
	,disc.recordtime AS disconn_recordtime
	,init.pid AS pid
	,init.remotehost
	,init.remoteport
	,init.username AS username
	,disc.duration AS conn_duration
FROM 
	(SELECT event, recordtime, remotehost, remoteport, pid, username FROM stl_connection_log WHERE event = 'initiating session') AS init
LEFT OUTER JOIN
	(SELECT event, recordtime, remotehost, remoteport, pid, username, duration FROM stl_connection_log WHERE event = 'disconnecting session') AS disc
		ON init.pid = disc.pid
		AND init.remotehost = disc.remotehost
		AND init.remoteport = disc.remoteport
;
-- ============================================================================
-- Creating view: v_session_leakage_by_cnt
-- Source: v_session_leakage_by_cnt.sql
-- ============================================================================
CREATE OR REPLACE VIEW admin.admin.v_session_leakage_by_cnt
AS 
SELECT 
	i.remotehost
	,i.username
	,i.eventcount AS connects
	,d.eventcount AS disconnects
FROM 
	( 
	SELECT 
		remotehost
		,username
		,COUNT(*) AS eventcount
	FROM 
		stl_connection_log
     WHERE event = 'initiating session'
	GROUP BY remotehost, username
	) AS i
LEFT OUTER JOIN 
	( 
	SELECT 
		remotehost
		,username
		,COUNT(*) AS eventcount
	FROM 
		stl_connection_log
	WHERE event = 'disconnecting session'
     GROUP BY remotehost, username
     ) AS d 
     	ON i.remotehost = d.remotehost 
     	AND i.username = d.username
ORDER BY i.eventcount - COALESCE(d.eventcount, 0) DESC;
-- ============================================================================
-- Creating view: v_generate_cancel_query
-- Source: v_generate_cancel_query.sql
-- ============================================================================
--DROP VIEW admin.v_generate_cancel_query;
/**********************************************************************************************
Purpose: View to get cancel query 
History:
2015-07-01 srinikri Created
**********************************************************************************************/ 
CREATE OR REPLACE VIEW admin.admin.v_generate_cancel_query
AS
SELECT pid,
       starttime,
       duration,
       TRIM(user_name) AS "USER",
       TRIM(query) AS querytxt,
       'CANCEL  ' + pid::VARCHAR(20) + ';' AS cancel_query
FROM stv_recents
WHERE status = 'Running'
ORDER BY starttime DESC;

-- ============================================================================
-- Creating view: v_generate_terminate_session
-- Source: v_generate_terminate_session.sql
-- ============================================================================
--DROP VIEW admin.v_generate_terminate_session;
/**********************************************************************************************
Purpose: View to generate pg_terminate_backend statements 
History:
2016-05-25 chriz-bigdata Created
**********************************************************************************************/ 
CREATE OR REPLACE VIEW admin.admin.v_generate_terminate_session
AS
SELECT process,
       starttime,
       TRIM(user_name) AS "user",
       'SELECT pg_terminate_backend(' || process || ');' AS terminate_stmt
FROM stv_sessions
WHERE user_name != 'rdsdb'
AND process != pg_backend_pid()
ORDER BY starttime;

-- ============================================================================
-- Creating view: v_generate_unload_copy_cmd
-- Source: v_generate_unload_copy_cmd.sql
-- ============================================================================
--DROP VIEW admin.v_generate_unload_copy_cmd;
/**********************************************************************************************
Purpose: View to get that will generate unload and copy commands for an object.  After running
	the view the user will need to fill in what filter to use in the UNLOAD query if any
	(--WHERE audit_id > ___auditid___), the bucket location (__bucketname__) and the AWS
	credentials (__creds_here__).  The where clause is commented out currently and can
	be left so if the UNLOAD needs to get all data of the table.
History:
2014-02-12 jjschmit Created
2022-08-15 saeedma8 excluded system tables
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_generate_unload_copy_cmd
AS
SELECT
	schemaname
	,tablename
	,cmd_type
	,dml
FROM
	(
	SELECT 
		schemaname
		,tablename
		,'unload' AS cmd_type
		,'UNLOAD (''SELECT * FROM ' + schemaname + '.' + tablename + ' --WHERE audit_id > ___auditid___'') TO ''s3://__bucketname__/' + TO_CHAR(GETDATE(), 'YYYYMMDD_HH24MISSMS')  + '/'  + schemaname + '.' + tablename + '-'' CREDENTIALS ''__creds_here__'' GZIP DELIMITER ''\\t'';' AS dml
	FROM 
		pg_tables
WHERE schemaname !~ '^information_schema|catalog_history|pg_' 
	UNION ALL
	SELECT 
		schemaname
		,tablename
		,'copy' AS cmd_type
		,'COPY ' + schemaname + '.' + tablename + ' FROM ''s3://__bucketname__/' + TO_CHAR(GETDATE(), 'YYYYMMDD_HH24MISSMS')  + '/'  + schemaname + '.' + tablename + '-'' CREDENTIALS ''__creds_here__'' GZIP DELIMITER ''\\t'';' AS copy_dml
	FROM 
		pg_tables 
	)
WHERE schemaname !~ '^information_schema|catalog_history|pg_'
ORDER BY 3 DESC,1,2
;
;

-- ============================================================================
-- Creating view: v_get_stored_proc_params
-- Source: v_get_stored_proc_params.sql
-- ============================================================================
/**********************************************************************************************
Purpose: List all stored procedures with their input parameters
History:
2020-04-15 joeharris76 Created
2023-02-20 saeedma8 added serverless prolang id
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_get_stored_proc_params
AS
WITH arguments 
AS (SELECT oid, arg_num
         , arg_names[arg_num]     AS arg_name
         , arg_types[arg_num - 1] AS arg_type
    FROM (SELECT GENERATE_SERIES(1, arg_count) AS arg_num
               , arg_names, arg_types, oid
          FROM (SELECT oid
                     , proargnames AS arg_names
                     , proargtypes AS arg_types
                     , pronargs    AS arg_count
                FROM pg_proc
                WHERE proowner != 1
                  AND prolang in (100356, 101857) ) t) t)
SELECT n.nspname                     AS schema_name
     , p.proname                     AS proc_name
     , p.oid::INT                    AS proc_id
     , a.arg_num                     AS order
     , NVL(a.arg_name, '')           AS parameter
     , FORMAT_TYPE(a.arg_type, NULL) AS data_type 
FROM pg_proc                p
     LEFT JOIN pg_namespace n   ON n.oid = p.pronamespace
     LEFT JOIN arguments    a   ON a.oid = p.oid
WHERE p.proowner != 1
  AND p.prolang in (100356, 101857)
ORDER BY 1,2,3,4;

-- ============================================================================
-- Creating view: v_check_data_distribution
-- Source: v_check_data_distribution.sql
-- ============================================================================
--DROP VIEW admin.v_check_data_distribution;
/**********************************************************************************************
Purpose: View to get data distribution across slices
History:
2014-01-30 jjschmit Created
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_check_data_distribution
AS
SELECT 
	slice
	,pgn.oid AS schema_oid
	,pgn.nspname AS schemaname
	,id AS tbl_oid
	,name AS tablename
	,stv.diststyle AS diststyle
  	,stv.sortkey1 AS sortkey
	,rows AS rowcount_on_slice
	,SUM(rows) OVER (PARTITION BY name, id) AS total_rowcount
	,CASE
		WHEN rows IS NULL OR rows = 0 THEN 0
		ELSE ROUND(CAST(rows AS FLOAT) / CAST((SUM(rows) OVER (PARTITION BY id)) AS FLOAT) * 100, 3) 
		END AS distrib_pct
	,CASE
		WHEN rows IS NULL OR rows = 0 THEN 0
		ELSE ROUND(CAST((MIN(rows) OVER (PARTITION BY id)) AS FLOAT) / CAST((SUM(rows) OVER (PARTITION BY id)) AS FLOAT) * 100, 3) 
		END AS min_distrib_pct
	,CASE
		WHEN rows IS NULL OR rows = 0 THEN 0
		ELSE ROUND(CAST((MAX(rows) OVER (PARTITION BY id)) AS FLOAT) / CAST((SUM(rows) OVER (PARTITION BY id)) AS FLOAT) * 100, 3) 
		END AS max_distrib_pct
FROM 
	stv_tbl_perm AS perm
INNER JOIN
	pg_class AS pgc 
		ON pgc.oid = perm.id
INNER JOIN
	pg_namespace AS pgn 
		ON pgn.oid = pgc.relnamespace
INNER JOIN
  svv_table_info AS stv
    ON stv.schema = pgn.nspname AND stv."table" = name
WHERE slice < 3201
AND pgc.relowner > 1
;
;

-- ============================================================================
-- Creating view: v_check_transaction_locks
-- Source: v_check_transaction_locks.sql
-- ============================================================================
--DROP VIEW admin.v_check_transaction_locks;
/**********************************************************************************************
Purpose: View to get information about the locks held by open transactions 
History:
2015-07-01 srinikri Created
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_check_transaction_locks
AS
SELECT sysdate AS system_ts,
TRIM(n.nspname) schemaname,
TRIM(c.relname) tablename,
TRIM(l.database) databasename,
l.transaction ,
l.pid,
a.usename,
l.mode,
l.granted
FROM pg_catalog.pg_locks l
JOIN pg_catalog.pg_class c ON c.oid = l.relation
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
JOIN pg_catalog.pg_stat_activity a ON a.procpid = l.pid
;
-- ============================================================================
-- Creating view: v_check_wlm_query_time
-- Source: v_check_wlm_query_time.sql
-- ============================================================================

--DROP VIEW admin.v_check_wlm_query_time;
/**********************************************************************************************
Purpose: View to get  WLM Queue Wait Time , Execution Time and Total Time by Query for the past 7 Days 
History:
2015-07-01 srinikri Created
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_check_wlm_query_time
AS
SELECT TRIM(DATABASE) AS DB,
       w.query,
       SUBSTRING(q.querytxt,1,100) AS querytxt,
       w.queue_start_time,
       w.service_class AS class,
       w.slot_count AS slots,
       w.total_queue_time / 1000000 AS queue_seconds,
       w.total_exec_time / 1000000 exec_seconds,
       (w.total_queue_time + w.total_exec_time) / 1000000 AS total_seconds
FROM stl_wlm_query w
  LEFT JOIN stl_query q
         ON q.query = w.query
        AND q.userid = w.userid
WHERE w.queue_start_time >= DATEADD (day,-7,CURRENT_DATE)
AND   w.total_queue_time > 0
AND   w.userid > 1
AND   q.starttime >= DATEADD (day,-7,CURRENT_DATE)
ORDER BY w.total_queue_time DESC,
         w.queue_start_time DESC;

-- ============================================================================
-- Creating view: v_check_wlm_query_trend_daily
-- Source: v_check_wlm_query_trend_daily.sql
-- ============================================================================

--DROP VIEW admin.v_check_wlm_query_trend_daily;
/**********************************************************************************************
Purpose: View to get  WLM Query Count, Queue Wait Time , Execution Time and Total Time by Day 
History:
2015-07-01 srinikri Created
2015-07-23 ericfe updated column to be a proper date
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_check_wlm_query_trend_daily
AS
SELECT trunc(a.service_class_start_time) AS day, 
       a.service_class, 
       b.condition AS service_class_condition, 
       COUNT(a.query) AS query_count, 
       SUM(a.total_queue_time) AS total_queue_time_sum, 
       SUM(a.total_exec_time) AS total_exec_time_sum, 
       (SUM(a.total_queue_time)::FLOAT/ NULLIF(SUM(a.total_exec_time),0)::FLOAT)*100 AS percent_wlm_queue_time 
FROM stl_wlm_query a 
  JOIN stv_wlm_classification_config b ON a.service_class = b.action_service_class 
GROUP BY trunc(a.service_class_start_time) , 
         a.service_class, 
         b.condition 
ORDER BY trunc(a.service_class_start_time) DESC, 
         a.service_class DESC;

-- ============================================================================
-- Creating view: v_check_wlm_query_trend_hourly
-- Source: v_check_wlm_query_trend_hourly.sql
-- ============================================================================

--DROP VIEW admin.v_check_wlm_query_trend_hourly;
/**********************************************************************************************
Purpose: View to get  WLM Query Count, Queue Wait Time , Execution Time and Total Time by Hour
History:
2015-07-01 srinikri Created
2015-07-23 ericfe updated column to be a proper timestamp
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_check_wlm_query_trend_hourly
AS
SELECT date_trunc('hour',a.service_class_start_time) AS hour,
       a.service_class,
       b.condition AS service_class_condition,
       COUNT(a.query) AS query_count,
       SUM(a.total_queue_time) AS total_queue_time_sum,
       SUM(a.total_exec_time) AS total_exec_time_sum,
       (NVL(SUM(a.total_queue_time)::FLOAT,0)/ nullif(SUM(a.total_exec_time)::FLOAT,0))*100 AS percent_wlm_queue_time
FROM stl_wlm_query a
  join stv_wlm_classification_config b ON a.service_class = b.action_service_class
GROUP BY date_trunc('hour',a.service_class_start_time),
         a.service_class,
         b.condition
ORDER BY date_trunc('hour',a.service_class_start_time) DESC,
         a.service_class DESC;
-- ============================================================================
-- Creating view: v_connection_summary
-- Source: v_connection_summary.sql
-- ============================================================================

/**********************************************************************************************
Purpose:      View to flatten stl_connection_log table and provide details like session start
              and end time, duration in human readble format and current state i.e disconnected,
              terminated by admin, active or connection lost
History:
2017-12-29 adedotua created
2023-02-09 updated view to use sessionid for joins. added new columns 
           os_version, driver_version and sessionid. fully qualified table names.

**********************************************************************************************/ 
CREATE OR REPLACE VIEW admin.admin.V_CONNECTION_SUMMARY AS
SELECT a.username::varchar
,a.pid
,a.recordtime as authentication_time
,b.recordtime as session_starttime
,d.recordtime as session_endtime
,a.dbname::varchar
,c.application_name::varchar as app_name
,b.authmethod::varchar
,case when d.duration > 0 then (d.duration/1000000)/86400||' days '||((d.duration/1000000)%86400)/3600||'hrs '
||((d.duration/1000000)%3600)/60||'mins '||(d.duration/1000000%60)||'secs' when f.process is null then null else datediff(s,a.recordtime,getdate())/86400||' days '||(datediff(s,a.recordtime,getdate())%86400)/3600||'hrs '
||(datediff(s,a.recordtime,getdate())%3600)/60||'mins '||(datediff(s,a.recordtime,getdate())%60)||'secs' end as duration
,b.mtu
,b.sslversion::varchar
,b.sslcipher::varchar
,b.remotehost::varchar
,b.remoteport::varchar
,case when e.recordtime is not null then 'Terminated by administrator' 
when d.recordtime is not null then 'Disconnected' 
when f.process is not null then 'Active' else 'Connection Lost' end as current_state
,a.sessionid::varchar
,nvl(a.os_version,b.os_version)::varchar as os_version
,nvl(a.driver_version,b.driver_version)::varchar as driver_version
FROM
(SELECT * FROM pg_catalog.stl_connection_log WHERE event='authenticated') a
LEFT JOIN (SELECT * FROM pg_catalog.stl_connection_log WHERE event='initiating session') b using (sessionid)
LEFT JOIN (SELECT * FROM pg_catalog.stl_connection_log WHERE event='set application_name') c using (sessionid)
LEFT JOIN (SELECT * FROM pg_catalog.stl_connection_log WHERE event='disconnecting session') d using (sessionid) 
LEFT JOIN (SELECT * FROM pg_catalog.stl_connection_log WHERE event='Terminating backend on administrator''s request') e using (sessionid) 
LEFT JOIN pg_catalog.stv_sessions f on a.pid=f.process and a.dbname=f.db_name and a.username=f.user_name 
and datediff(s,f.starttime,a.recordtime) < 5
WHERE a.username <> 'rdsdb'
ORDER BY 3;

-- ============================================================================
-- Creating view: v_fragmentation_info
-- Source: v_fragmentation_info.sql
-- ============================================================================
/**********************************************************************************************
Purpose:      View to list all fragmented tables in the database. Tables can become fragmented
              due to frequent vacuums overlapping with concurrent writes on the same table.
Columns:      tbl - id of the table
              tablename -  name of the table
              dbname - database that contains the table
              est_space_gain - estimated number of blocks that will be released if table is 
                               defragmented via vacuum or deep copy
                               
History:
2017-12-29    adedotua and indubh created
2018-02-06    adedotua refactored the script to use rowid column for estimation
**********************************************************************************************/ 

CREATE OR REPLACE VIEW admin.admin.v_fragmentation_info
AS 
select tbl,tablename,dbname,sum(t_excess_blks) est_space_gain 
from 
(
  select tbl,col,node,tablename,trim(datname) as dbname,sum(excess_blks)*(col+1) as t_excess_blks 
  from 
  (select tbl,slice,col,count(*) total_blks from stv_blocklist where num_values > 0 group by 1,2,3) a
  join (select tbl,slice,max(col) as col from stv_blocklist group by 1,2) b using (tbl,slice,col)
  join (select tbl,slice,col,count(*) - ceil(sum(num_values)/130994.0) as excess_blks from stv_blocklist 
      where num_values > 0 and num_values < 130994 group by 1,2,3) c using (tbl,slice,col)
  join stv_slices d using (slice) 
  join (select id,trim("name") as tablename,db_id from stv_tbl_perm where slice=0) f on b.tbl=f.id
  join pg_database g on f.db_id=g.oid
  where excess_blks > 1
  group by 1,2,3,4,5
)
where tbl > 1 
and t_excess_blks > (select case when sum(capacity) > 200000 then 1024 else 102.4 end from stv_partitions 
                                   where host=owner and host=0 group by host)
 group by 1,2,3
order by 4 desc;

-- ============================================================================
-- Creating view: v_generate_cursor_query
-- Source: v_generate_cursor_query.sql
-- ============================================================================
--DROP VIEW admin.v_generate_cursor_query;
/**********************************************************************************************
Purpose: View to get the query and statistics of the currently active cursors.
History:
2016-09-14 Jan-Zeiseweis Created
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_generate_cursor_query
AS
SELECT
  cur.xid
  , cur.pid
  , cur.userid                                                      AS user_id
  , usr.usename                                                     AS username
  , min(cur.starttime)                                              AS start_time
  , DATEDIFF(second, min(cur.starttime), getdate())                 AS run_time
  , min(cur.byte_count)                                             AS bytes_in_result_set
  , round(min(cur.byte_count) / pow(1024, 2), 2)                    AS mb_in_result_set
  , round(min(cur.byte_count) / pow(1024, 3), 2)                    AS gb_in_result_set
  , min(cur.row_count)                                              AS row_count
  , min(cur.row_count - cur.fetched_rows)                           AS remaining_rows_to_fetch
  , min(cur.fetched_rows)                                           AS fetched_rows
  , listagg(util_text.text)
    WITHIN GROUP (ORDER BY util_text.starttime, util_text.sequence) AS query
FROM STV_ACTIVE_CURSORS cur
  JOIN STL_UTILITYTEXT util_text
    ON cur.pid = util_text.pid 
        AND cur.xid = util_text.xid 
        AND util_text.text != 'begin;'
  JOIN PG_USER usr
    ON usr.usesysid = cur.userid
GROUP BY cur.userid, cur.xid, cur.pid, usr.usename;

-- ============================================================================
-- Creating view: v_generate_schema_ddl
-- Source: v_generate_schema_ddl.sql
-- ============================================================================
--DROP VIEW admin.v_generate_schema_ddl;
/**********************************************************************************************
Purpose: View to get the DDL for schemas.  
History:
2014-02-11 jjschmit Created
2018-01-15 pvbouwel Add QUOTE_IDENT for namespace literal
2018-03-30 burck1 Add logic to add AUTHORIZATION clause
Notes:
If you receive the error
	[Amazon](500310) Invalid operation: cannot change data type of view column "ddl";
then you must drop the view and re-create it using
	DROP VIEW admin.v_generate_schema_ddl;
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_generate_schema_ddl
AS
SELECT
	nspname AS schemaname,
	'CREATE SCHEMA ' + QUOTE_IDENT(nspname) +
		CASE
		WHEN nspowner > 100
		THEN ' AUTHORIZATION ' + QUOTE_IDENT(pg_user.usename)
		ELSE ''
		END
		+ ';' AS ddl
FROM pg_catalog.pg_namespace as pg_namespace
LEFT OUTER JOIN pg_catalog.pg_user pg_user
ON pg_namespace.nspowner=pg_user.usesysid
WHERE nspowner >= 100
ORDER BY nspname
;
;

-- ============================================================================
-- Creating view: v_generate_udf_ddl
-- Source: v_generate_udf_ddl.sql
-- ============================================================================
--DROP VIEW admin.v_generate_udf_ddl;
/**********************************************************************************************
Purpose: View to get the DDL for a UDF. 
History:
2016-04-20 chriz-bigdata Created
2018-01-15 pvbouwel      Add QUOTE_IDENT for identifiers (function name)
2018-01-24 joeharris76   Support for SQL functions
2019-04-03 adedotua      Added schemaname, ending semi-colon and 'OR REPLACE' 
2020-04-15 joeharris76   Exclude stored procedures - use `SHOW PROCEDURE sp_name;` instead
2020-08-17 adedotua      Updated filter to ignore stored procedures
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_generate_udf_ddl
AS
WITH arguments AS (SELECT oid, i, arg_name[i] as argument_name, arg_types[i-1] argument_type
FROM (
  SELECT generate_series(1, arg_count) AS i, arg_name, arg_types,oid
  FROM (SELECT oid, proargnames arg_name, proargtypes arg_types, pronargs arg_count from pg_proc where proowner != 1) t
) t)
SELECT 
	schemaname,
	udfname,
	seq,
	trim(ddl) ddl FROM (
SELECT 
   n.nspname AS schemaname,
   p.proname AS udfname,
   p.oid AS udfoid,
1000 as seq, ('CREATE OR REPLACE FUNCTION ' || QUOTE_IDENT(n.nspname) ||'.'|| QUOTE_IDENT(p.proname) || ' \(')::varchar(max) as ddl
FROM pg_proc p
LEFT JOIN pg_namespace n on n.oid = p.pronamespace
JOIN pg_language l on p.prolang = l.oid
WHERE p.proowner != 1 AND l.lanname <> 'plpgsql'
UNION ALL
SELECT 
   n.nspname AS schemaname,
   p.proname AS udfname,
   p.oid AS udfoid,
2000+nvl(i,0) as seq, case when i = 1 then NVL(argument_name,'') || ' ' || format_type(argument_type,null) else ',' || NVL(argument_name,'') || ' ' || format_type(argument_type,null) end as ddl
FROM pg_proc p
LEFT JOIN pg_namespace n on n.oid = p.pronamespace
LEFT JOIN arguments a on a.oid = p.oid
JOIN pg_language l on p.prolang = l.oid
WHERE p.proowner != 1 AND l.lanname <> 'plpgsql'
UNION ALL
SELECT 
   n.nspname AS schemaname,
   p.proname AS udfname,
   p.oid AS udfoid,
3000 as seq, '\)' as ddl
FROM pg_proc p
LEFT JOIN pg_namespace n on n.oid = p.pronamespace
JOIN pg_language l on p.prolang = l.oid
WHERE p.proowner != 1 AND l.lanname <> 'plpgsql'
UNION ALL
SELECT 
   n.nspname AS schemaname,
   p.proname AS udfname,
   p.oid AS udfoid,
 4000 as seq, '  RETURNS ' || pg_catalog.format_type(p.prorettype, NULL) as ddl
FROM pg_proc p
LEFT JOIN pg_namespace n on n.oid = p.pronamespace
JOIN pg_language l on p.prolang = l.oid
WHERE p.proowner != 1 AND l.lanname <> 'plpgsql'
UNION ALL
SELECT 
   n.nspname AS schemaname,
   p.proname AS udfname,
      p.oid AS udfoid,
5000 AS seq, CASE WHEN p.provolatile = 'v' THEN 'VOLATILE' WHEN p.provolatile = 's' THEN 'STABLE' WHEN p.provolatile = 'i' THEN 'IMMUTABLE' ELSE '' END as ddl
FROM pg_proc p
LEFT JOIN pg_namespace n on n.oid = p.pronamespace
JOIN pg_language l on p.prolang = l.oid
WHERE p.proowner != 1 AND l.lanname <> 'plpgsql'
UNION ALL
SELECT 
   n.nspname AS schemaname,
   p.proname AS udfname,
      p.oid AS udfoid,
6000 AS seq, 'AS $$' as ddl
FROM pg_proc p
LEFT JOIN pg_namespace n on n.oid = p.pronamespace
JOIN pg_language l on p.prolang = l.oid
WHERE p.proowner != 1 AND l.lanname <> 'plpgsql'
UNION ALL
SELECT 
   n.nspname AS schemaname,
   p.proname AS udfname,
      p.oid AS udfoid,
7000 AS seq, p.prosrc as DDL
FROM pg_proc p
LEFT JOIN pg_namespace n on n.oid = p.pronamespace
JOIN pg_language l on p.prolang = l.oid
WHERE p.proowner != 1 AND l.lanname <> 'plpgsql'
UNION ALL
SELECT 
   n.nspname AS schemaname,
   p.proname AS udfname,
      p.oid AS udfoid,
8000 as seq, '$$ LANGUAGE ' + lang.lanname + ';' as ddl
FROM pg_proc p
LEFT JOIN pg_namespace n on n.oid = p.pronamespace
LEFT JOIN (select oid, lanname FROM pg_language) lang on p.prolang = lang.oid
WHERE p.proowner != 1 AND lang.lanname <> 'plpgsql'
)
ORDER BY udfoid,seq;

-- ============================================================================
-- Creating view: v_get_blocking_locks
-- Source: v_get_blocking_locks.sql
-- ============================================================================
--DROP VIEW admin.v_get_blocking_locks;
/**********************************************************************************************
Purpose: View to identify blocking locks as well as determine what/who is blocking a query 

History:
2017-08-16 dbiddle Created
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_get_blocking_locks
AS
WITH locks AS (
       SELECT svv.xid
       ,      l.pid
       ,      svv.txn_owner as username
       ,      TRIM(d.datname) as dbname
       ,      svv.relation
       ,      TRIM(nsp.nspname) as schemaname
       ,      TRIM(c.relname) as objectname
       ,      l.mode
       ,      l.granted
       ,      svv.lockable_object_type as obj_type
       ,      svv.txn_start
       ,      ROUND((EXTRACT(EPOCH FROM current_timestamp) - EXTRACT(EPOCH FROM svv.txn_start)),2) as block_sec
       ,      ROUND((EXTRACT(EPOCH FROM current_timestamp) - EXTRACT(EPOCH FROM svv.txn_start))/60,2) as block_min
       ,      ROUND((EXTRACT(EPOCH FROM current_timestamp) - EXTRACT(EPOCH FROM svv.txn_start))/60/60,2) as block_hr
       ,      CASE WHEN l.granted is false THEN ROUND((EXTRACT(EPOCH FROM current_timestamp) - EXTRACT(EPOCH FROM rct.starttime)),2) ELSE NULL END as waiting
       FROM   pg_catalog.pg_locks l
       INNER JOIN pg_catalog.svv_transactions svv
        ON    l.pid = svv.pid
       AND    l.relation = svv.relation
       AND    svv.lockable_object_type is not null
       LEFT JOIN pg_catalog.pg_class c on c.oid = svv.relation
       LEFT JOIN pg_namespace nsp
        ON    nsp.oid = c.relnamespace
       LEFT JOIN pg_catalog.pg_database d on d.oid = l.database
       LEFT OUTER JOIN stv_recents rct
        ON    rct.pid = l.pid
       WHERE  l.pid <> pg_backend_pid()
)
select distinct * 
FROM  (
       SELECT l.xid
       ,      l.pid
       ,      l.username
       ,      l.dbname
       ,      l.relation
       ,      l.schemaname
       ,      l.objectname
       ,      l.mode
       ,      DECODE(l.granted, true, 'True', false, 'False') granted
       ,      l.obj_type
       ,      l.txn_start
       ,      DECODE(l.granted, true, l.block_sec, NULL) as block_sec
       ,      DECODE(l.granted, true, l.block_min, NULL) as block_min
       ,      DECODE(l.granted, true, l.block_hr, NULL) as block_hr
       ,      waiting
       ,      b.max_sec_blocking
       ,      b.num_blocking
       ,      b.pidlist
       FROM   locks l
       LEFT OUTER JOIN (
              SELECT relation
              ,      mode
              ,      listagg(b.pid, ',') as pidlist
              ,      MIN(block_sec) as min_sec_blocking
              ,      MAX(waiting) as max_sec_blocking
              ,      COUNT(*) as num_blocking
              FROM   locks b
              WHERE  granted is false
              GROUP BY relation
              ,      mode
       ) b
        ON    l.relation = b.relation
       AND    l.granted is true
       AND   (l.mode like '%Exclusive%'
       OR   (l.mode like '%Share%' AND b.mode LIKE '%ExclusiveLock' AND b.mode NOT LIKE '%Share%'))
)
ORDER BY granted DESC
,      max_sec_blocking desc nulls last
,      block_sec DESC
,      waiting desc nulls last
;

-- ============================================================================
-- Creating view: v_get_obj_priv_by_user
-- Source: v_get_obj_priv_by_user.sql
-- ============================================================================
/**********************************************************************************************
Purpose: View to get the table/views that a user has access to
History:
2013-10-29 jjschmit Created
2016-05-24 chriz-bigdata addressed edge case for objects with names containing '.'
2018-01-15 pvbouwel replaces tabs with spaces for nicer behavior in psql client
2022-08-15 saeedma8 excluded system tables
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_get_obj_priv_by_user
AS
SELECT
    * 
FROM 
    (
    SELECT 
        schemaname
        ,objectname
        ,usename
        ,HAS_TABLE_PRIVILEGE(usrs.usename, fullobj, 'select') AS sel
        ,HAS_TABLE_PRIVILEGE(usrs.usename, fullobj, 'insert') AS ins
        ,HAS_TABLE_PRIVILEGE(usrs.usename, fullobj, 'update') AS upd
        ,HAS_TABLE_PRIVILEGE(usrs.usename, fullobj, 'delete') AS del
        ,HAS_TABLE_PRIVILEGE(usrs.usename, fullobj, 'references') AS ref
    FROM
        (
        SELECT schemaname, 't' AS obj_type, tablename AS objectname, QUOTE_IDENT(schemaname) || '.' || QUOTE_IDENT(tablename) AS fullobj FROM pg_tables
        WHERE schemaname !~ '^information_schema|catalog_history|pg_'
        UNION
        SELECT schemaname, 'v' AS obj_type, viewname AS objectname, QUOTE_IDENT(schemaname) || '.' || QUOTE_IDENT(viewname) AS fullobj FROM pg_views
        WHERE schemaname !~ '^information_schema|catalog_history|pg_'
        ) AS objs
        ,(SELECT * FROM pg_user) AS usrs
    ORDER BY fullobj
    )
WHERE (sel = true or ins = true or upd = true or del = true or ref = true)
;
;

-- ============================================================================
-- Creating view: v_get_schema_priv_by_user
-- Source: v_get_schema_priv_by_user.sql
-- ============================================================================
/**********************************************************************************************
Purpose: View to get the schema that a user has access to
History:
2013-10-29 jjschmit Created
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_get_schema_priv_by_user
AS
SELECT
	* 
FROM 
	(
	SELECT 
		schemaname
		,usename
		,HAS_SCHEMA_PRIVILEGE(usrs.usename, schemaname, 'create') AS cre
		,HAS_SCHEMA_PRIVILEGE(usrs.usename, schemaname, 'usage') AS usg
	FROM
		(SELECT nspname AS schemaname FROM pg_namespace) AS objs
	INNER JOIN
		(SELECT * FROM pg_user) AS usrs
			ON 1 = 1
	ORDER BY schemaname
	)
WHERE cre = true OR usg = true
;
;

-- ============================================================================
-- Creating view: v_get_tbl_priv_by_group
-- Source: v_get_tbl_priv_by_group.sql
-- ============================================================================
/**********************************************************************************************
Purpose: View to get the tables that a user group has access to
History:
2021-09-27 milindo Created
2023-03-13 amneet13 return results specific for groups.
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_get_tbl_priv_by_group as
select
    t.namespace as schemaname, t.item as object, pu.groname as groupname
  , decode(charindex('r',split_part(split_part(array_to_string(t.relacl, '|'), 'group '||pu.groname||'=',2 ) ,'/',1)),0,false,true)  as sel
  , decode(charindex('w',split_part(split_part(array_to_string(t.relacl, '|'), 'group '||pu.groname||'=',2 ) ,'/',1)),0,false,true)  as upd
  , decode(charindex('a',split_part(split_part(array_to_string(t.relacl, '|'), 'group '||pu.groname||'=',2 ) ,'/',1)),0,false,true)  as ins
  , decode(charindex('d',split_part(split_part(array_to_string(t.relacl, '|'), 'group '||pu.groname||'=',2 ) ,'/',1)),0,false,true)  as del
  , decode(charindex('D',split_part(split_part(array_to_string(t.relacl, '|'), 'group '||pu.groname||'=',2 ) ,'/',1)),0,false,true)  as drp
  , decode(charindex('R',split_part(split_part(array_to_string(t.relacl, '|'), 'group '||pu.groname||'=',2 ) ,'/',1)),0,false,true)  as ref
from
      (select
            use.usename as subject,
            nsp.nspname as namespace,
            c.relname as item,
            c.relkind as type,
            use2.usename as owner,
            c.relacl
      from
            pg_user use
      cross join pg_class c
      left join pg_namespace nsp on (c.relnamespace = nsp.oid)
      left join pg_user use2 on (c.relowner = use2.usesysid)
      where c.relowner = use.usesysid
      and nsp.nspname !~ '^information_schema|catalog_history|pg_'
      ) t
join pg_group pu on array_to_string(t.relacl, '|') like '%group '||pu.groname||'=%';

-- ============================================================================
-- Creating view: v_get_tbl_priv_by_user
-- Source: v_get_tbl_priv_by_user.sql
-- ============================================================================
/**********************************************************************************************
Purpose: View to get the tables that a user has access to
History:
2013-10-29 jjschmit Created
2022-08-15 saeedma8 excluded system tables
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_get_tbl_priv_by_user
AS
SELECT
	* 
FROM 
	(
	SELECT 
		schemaname
		,tablename
		,usename
		,HAS_TABLE_PRIVILEGE(usrs.usename, obj, 'select') AS sel
		,HAS_TABLE_PRIVILEGE(usrs.usename, obj, 'insert') AS ins
		,HAS_TABLE_PRIVILEGE(usrs.usename, obj, 'update') AS upd
		,HAS_TABLE_PRIVILEGE(usrs.usename, obj, 'delete') AS del
		,HAS_TABLE_PRIVILEGE(usrs.usename, obj, 'references') AS ref
	FROM
		(SELECT schemaname, tablename, '\"' + schemaname + '\"' + '.' + '\"' + tablename + '\"' AS obj FROM pg_tables where schemaname !~ '^information_schema|catalog_history|pg_') AS objs
		,(SELECT * FROM pg_user) AS usrs
	ORDER BY obj
	)
WHERE sel = true or ins = true or upd = true or del = true or ref = true
;

;

-- ============================================================================
-- Creating view: v_get_tbl_reads_and_writes
-- Source: v_get_tbl_reads_and_writes.sql
-- ============================================================================
--DROP VIEW admin.v_get_tbl_reads_and_writes;
/**********************************************************************************************
Purpose: View to get the READ and WRITE operations per table for specific transactions.  
This view should be used with a filter that limits the output for transaction IDs or query IDs.  
This view will help to see what tables are operated on by transactions and to see how transactions
have dependencies between each other.  The operation will be one of the 
following:
 - R if it is a read operation that was done
 - W if it is a write operation that was done
 - A if the query statement got aborted this could be due to a serializable isolation violation
   the user will need to check the query manually.

Another output is the transaction actions (tx_action) which will be:
 - R if the transaction is rolled back
 - C if the transaction is committed

History:
2016-11-03 pvbouwel Created
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_get_tbl_reads_and_writes
AS
WITH v_operations AS 
  ( SELECT query, tbl, 'R' AS operation FROM stl_scan WHERE type=2 GROUP BY query, tbl
      UNION
    SELECT query, tbl, 'W' AS operation FROM stl_delete GROUP BY query, tbl
      UNION
    SELECT query, tbl, 'W' AS operation FROM stl_insert GROUP BY query, tbl
      UNION
    SELECT sq.query AS query, stc.table_id AS tbl, 'A' AS operation FROM stl_query sq LEFT JOIN stl_tr_conflict stc on sq.xid = stc.xact_id  where aborted=1 GROUP BY query, tbl
  ),
v_end_of_transaction AS
  ( SELECT xid, MAX(tx_action) AS tx_action, MAX(endtime) as endtime FROM
    (  SELECT xid, 'R' AS tx_action, endtime FROM stl_utilitytext WHERE text ILIKE '%rollback%' OR text ILIKE '%aborted%'
         UNION ALL
       SELECT xid, 'C' AS tx_action, endtime FROM stl_utilitytext WHERE text ILIKE '%commit%' OR text ILIKE '%end%'
         UNION ALL
       SELECT xid, 'C' AS tx_action, endtime from stl_commit_stats WHERE node=-1
    ) GROUP BY xid
  )
SELECT
  xid
  ,query
  ,tbl
  ,operation
  ,statement_starttime
  ,statement_endtime
  ,transaction_endtime
  ,transaction_action
FROM (
  SELECT
    sq.xid as xid
    ,sq.query as query
    ,vo.tbl as tbl
    ,vo.operation as operation
    ,sq.starttime as statement_starttime
    ,sq.endtime as statement_endtime
    ,ve.endtime as transaction_endtime
    ,ve.tx_action as transaction_action
  FROM stl_query sq
       LEFT JOIN v_operations vo ON sq.query=vo.query
       LEFT JOIN v_end_of_transaction ve ON sq.xid=ve.xid
  UNION ALL
    SELECT
     xid as xid
     ,null as query
     ,null as tbl
     ,'C' as operation
     ,startqueue as statement_starttime
     ,endtime as statement_endtime
     ,endtime as transaction_endtime
     ,'C' as transaction_action
    FROM stl_commit_stats where node=-1
) order by statement_starttime;

-- ============================================================================
-- Creating view: v_get_tbl_scan_frequency
-- Source: v_get_tbl_scan_frequency.sql
-- ============================================================================
--DROP VIEW admin.v_get_tbl_scan_frequency;
/**********************************************************************************************
Purpose: View to identify how frequently queries scan database tables.
History:
2016-03-14 chriz-bigdata Created
2022-08-15 saeedma8 excluded system tables
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_get_tbl_scan_frequency
AS
SELECT 
	database, 
	schema AS schemaname, 
	table_id, 
	"table" AS tablename, 
	size, 
	sortkey1, 
	NVL(s.num_qs,0) num_qs
FROM svv_table_info t
LEFT JOIN (SELECT
   tbl, perm_table_name,
   COUNT(DISTINCT query) num_qs
FROM
   stl_scan s
WHERE 
   s.userid > 1
   AND s.perm_table_name NOT IN ('Internal Worktable','S3')
GROUP BY 
   tbl, perm_table_name) s ON s.tbl = t.table_id
AND t."schema" !~ '^information_schema|catalog_history|pg_'
ORDER BY 7 desc;

-- ============================================================================
-- Creating view: v_get_vacuum_details
-- Source: v_get_vacuum_details.sql
-- ============================================================================
   
--DROP VIEW admin.v_get_vacuum_details;

/**********************************************************************************************
Purpose: View to get vacuum details like table name, Schema Name, Deleted Rows , processing time.
This view could be used to identify tables that are frequently deleted/ updated. 
History:
2015-07-01 srinikri Created
**********************************************************************************************/ 
CREATE OR REPLACE VIEW admin.admin.v_get_vacuum_details
AS 
SELECT vac_start.userid,
       vac_start.xid,
       vac_start.table_id,
       tab.schema_name AS schema_name,
       tab.table_name AS table_name,
       vac_start.status start_status,
       vac_start. "rows" start_rows,
       vac_start. "blocks" start_blocks,
       vac_start. "eventtime" start_time,
	--vac_end.userid,
	--vac_end.xid,
	--vac_end.table_id,
       vac_end.status end_status,
       vac_end. "rows" end_rows,
       vac_end. "blocks" end_blocks,
       vac_end. "eventtime" end_time,
       (vac_start. "rows" - vac_end. "rows") AS rows_deleted,
       (vac_start. "blocks" - vac_end. "blocks") AS blocks_deleted_added,
       datediff(seconds,vac_start. "eventtime",vac_end. "eventtime") AS processing_seconds
FROM stl_vacuum vac_start
 LEFT JOIN stl_vacuum vac_end
    ON vac_start.userid = vac_end.userid
   AND vac_start.table_id = vac_end.table_id
   AND vac_start.xid = vac_end.xid
   AND vac_end.status = 'Finished'

  JOIN (SELECT DISTINCT TRIM(pgn.nspname) AS schema_name,
               name AS table_name,
               tbl.id AS table_id
        FROM stv_tbl_perm tbl
          JOIN pg_class pgc ON pgc.oid = tbl.id
          JOIN pg_namespace pgn ON pgn.oid = pgc.relnamespace) tab ON tab.table_id = vac_start.table_id
WHERE vac_start.status != 'Finished'
ORDER BY rows_deleted DESC;

-- ============================================================================
-- Creating view: v_get_view_priv_by_user
-- Source: v_get_view_priv_by_user.sql
-- ============================================================================
/**********************************************************************************************
Purpose: View to get the views that a user has access to
History:
2013-10-29 jjschmit Created
2016-05-24 chriz-bigdata addressed edge case for objects with names containing '.'
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_get_view_priv_by_user
AS
SELECT
	* 
FROM 
	(
	SELECT 
		schemaname
		,viewname
		,usename
		,HAS_TABLE_PRIVILEGE(usrs.usename, obj, 'select') AS sel
		,HAS_TABLE_PRIVILEGE(usrs.usename, obj, 'insert') AS ins
		,HAS_TABLE_PRIVILEGE(usrs.usename, obj, 'update') AS upd
		,HAS_TABLE_PRIVILEGE(usrs.usename, obj, 'delete') AS del
		,HAS_TABLE_PRIVILEGE(usrs.usename, obj, 'references') AS ref
	FROM
		(SELECT schemaname, viewname, QUOTE_IDENT(schemaname) || '.' || QUOTE_IDENT(viewname) AS obj FROM pg_views ) AS objs
	INNER JOIN
		(SELECT * FROM pg_user) AS usrs
			ON 1 = 1
	ORDER BY obj
	)
WHERE sel = true or ins = true or upd = true or del = true or ref = true
;
;

-- ============================================================================
-- Creating view: v_query_type_duration_summary
-- Source: v_query_type_duration_summary.sql
-- ============================================================================
--DROP VIEW admin.v_query_type_duration_summary;
/**********************************************************************************************
Purpose: View to summarize queries by type (Insert, Select, etc.) per hour for the past 7 Days
History:
2016-07-13 joeharris76 Created
2022-08-15 saeedma8 excluded system tables
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_query_type_duration_summary
AS
SELECT  database, query_type, query_hour
        /* Overall query count and average duration */
       ,COUNT(*)            query_total
       ,AVG(query_duration) avg_duration
        /* Central tendency (truncated mean 25-75%) average query duration */
       ,AVG(CASE WHEN icosile BETWEEN 6 AND 15 THEN query_duration ELSE NULL END) central_duration
        /* Rough 50th percentile (45-55%) average query duration */
       ,AVG(CASE WHEN icosile IN (10,11) THEN query_duration ELSE NULL END) "50th_percentile_dur"
        /* Rough 95th percentile (top 5%) average query duration */
       ,AVG(CASE WHEN icosile = 20 THEN query_duration ELSE NULL END) "95th_percentile_dur"
FROM /* Calculate the icosile (1/20th) for each query by type and hour */
     (SELECT database, query_type, query_duration, query_hour
            ,NTILE(20) OVER (PARTITION BY database, query_type ORDER BY query_duration) icosile
      FROM /* Classify each query and calculate the duration 
              NOTE: The order of the search is important. */
           (SELECT  CASE  WHEN "userid" = 1                                             THEN 'SYSTEM'
                          WHEN REGEXP_INSTR("querytxt",'(padb_|pg_|catalog_history)'  ) THEN 'SYSTEM'
                          WHEN REGEXP_INSTR("querytxt",'[uU][nN][dD][oO][iI][nN][gG] ') THEN 'ROLLBACK'
                          WHEN REGEXP_INSTR("querytxt",'[cC][uU][rR][sS][oO][rR] '    ) THEN 'CURSOR'
                          WHEN REGEXP_INSTR("querytxt",'[fF][eE][tT][cC][hH] '        ) THEN 'CURSOR'
                          WHEN REGEXP_INSTR("querytxt",'[dD][eE][lL][eE][tT][eE] '    ) THEN 'DELETE'
                          WHEN REGEXP_INSTR("querytxt",'[cC][oO][pP][yY] '            ) THEN 'COPY'
                          WHEN REGEXP_INSTR("querytxt",'[uU][pP][dD][aA][tT][eE] '    ) THEN 'UPDATE'
                          WHEN REGEXP_INSTR("querytxt",'[iI][nN][sS][eE][rR][tT] '    ) THEN 'INSERT'
                          WHEN REGEXP_INSTR("querytxt",'[sS][eE][lL][eE][cC][tT] '    ) THEN 'SELECT'
                    ELSE 'OTHER' END query_type
                   ,DATEPART(hour, starttime) AS                    query_hour
                   ,DATEDIFF(milliseconds , starttime , endtime)    query_duration
                  ,database
              FROM stl_query
           ) a
      ) b
GROUP BY 1,2,3
ORDER BY 1,2,3
;

-- ============================================================================
-- Creating view: v_space_used_per_tbl
-- Source: v_space_used_per_tbl.sql
-- ============================================================================
--DROP VIEW admin.v_space_used_per_tbl;
/**********************************************************************************************
Purpose: View to get pull space used per table
History:
2014-01-30 jjschmit Created
2014-02-18 jjschmit Removed hardcoded where clause against 'public' schema
2014-02-21 jjschmit Added pct_unsorted and recommendation fields
2015-03-31 tinkerbotfoo Handled a special case to avoid divide by zero for pct_unsorted
2018-08-10 alexlsts Changed column "tablename" to use "relname" column from pg_class  
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_space_used_per_tbl
AS with info_table as ( SELECT TRIM(pgdb.datname) AS dbase_name
        ,TRIM(pgn.nspname) as schemaname
        ,TRIM(pgc.relname) AS tablename
        ,id AS tbl_oid
        ,b.mbytes AS megabytes
       ,CASE WHEN pgc.reldiststyle = 8
            THEN a.rows_all_dist
            ELSE a.rows END AS rowcount
       ,CASE WHEN pgc.reldiststyle = 8
            THEN a.unsorted_rows_all_dist
            ELSE a.unsorted_rows END AS unsorted_rowcount
       ,CASE WHEN pgc.reldiststyle = 8
          THEN decode( det.n_sortkeys,0, NULL,DECODE( a.rows_all_dist,0,0, (a.unsorted_rows_all_dist::DECIMAL(32)/a.rows_all_dist)*100))::DECIMAL(20,2)
          ELSE decode( det.n_sortkeys,0, NULL,DECODE( a.rows,0,0, (a.unsorted_rows::DECIMAL(32)/a.rows)*100))::DECIMAL(20,2) END
        AS pct_unsorted
FROM ( SELECT
              db_id
              ,id
              ,name
             ,MAX(ROWS) AS rows_all_dist
             ,MAX(ROWS) - MAX(sorted_rows) AS unsorted_rows_all_dist
              ,SUM(rows) AS rows
              ,SUM(rows)-SUM(sorted_rows) AS unsorted_rows
FROM stv_tbl_perm
GROUP BY db_id, id, name
       ) AS a
INNER JOIN
       pg_class AS pgc
ON pgc.oid = a.id
INNER JOIN
       pg_namespace AS pgn
ON pgn.oid = pgc.relnamespace
INNER JOIN
       pg_database AS pgdb
ON pgdb.oid = a.db_id
INNER JOIN (SELECT attrelid,
                     MIN(CASE attisdistkey WHEN 't' THEN attname ELSE NULL END) AS "distkey",
                     MIN(CASE attsortkeyord WHEN 1 THEN attname ELSE NULL END) AS head_sort,
                     MAX(attsortkeyord) AS n_sortkeys,
                     MAX(attencodingtype) AS max_enc,
                     SUM(case when attencodingtype <> 0 then 1 else 0 end)::DECIMAL(20,3)/COUNT(attencodingtype)::DECIMAL(20,3)  *100.00 as pct_enc
              FROM pg_attribute
              GROUP BY 1) AS det ON det.attrelid = a.id
LEFT OUTER JOIN
       ( SELECT
              tbl
              ,COUNT(*) AS mbytes
FROM stv_blocklist
GROUP BY tbl
       ) AS b
ON a.id=b.tbl
WHERE pgc.relowner > 1)
select info.*
    ,CASE WHEN info.rowcount = 0 THEN 'n/a'
        WHEN info.pct_unsorted  >= 20 THEN 'VACUUM SORT recommended'
        ELSE 'n/a'
    END AS recommendation
    from info_table info;
;

-- ============================================================================
-- Creating view: v_vacuum_summary
-- Source: v_vacuum_summary.sql
-- ============================================================================
/**********************************************************************************************
Purpose:      View to flatten stl_vacuum table and provide details like vacuum start and 
              end times, current status, changed rows and freed blocks all in one row
              
Current Version:        1.04

History:
Version 1.01
        2017-12-24 adedotua created
Version 1.02
        2018-12-22 adedotua updated view to account for background auto vacuum process 
Version 1.03
        2018-12-30 adedotua fixed join condition to make vacuum on dropped tables visible
Version 1.04
        2019-04-30 adedotua added is_auto_vacuum flag to indicate whether vacuum was auto vacuum 
Version 1.05
        2019-10-09 adedotua set vac_end_status as null for autovacuum if end status is unknown 
Version 1.06
        2023-02-09 add is_recluster and aborted columns
**********************************************************************************************/ 

CREATE OR REPLACE VIEW admin.admin.v_vacuum_summary as SELECT a.userid
       ,a.xid
       ,d.datname::varchar AS database_name
       ,a.table_id
       ,c.name::varchar AS tablename
       ,a.status::varchar AS vac_start_status
       ,CASE WHEN a.status ilike 'skipped%' THEN null::TEXT
             WHEN f.xid IS NOT NULL THEN 'Running'::TEXT
             WHEN g.aborted = 1 THEN 'Aborted'::TEXT
             WHEN b.status IS NULL and a.status not ilike '%[VacuumBG]%' THEN 'Failed'::TEXT
             ELSE b.status::TEXT
        END::TEXT AS vac_end_status
       ,a.eventtime AS vac_start_time
       ,CASE WHEN g.aborted = 1 THEN g.endtime 
             ELSE b.eventtime 
        END AS vac_end_time
       ,CASE WHEN f.xid IS NOT NULL THEN datediff(s,vac_start_time,getdate())
             WHEN b.eventtime IS NOT NULL THEN datediff(s,vac_start_time,vac_end_time)
             ELSE NULL
        END AS vac_duration_secs
       ,a."rows" AS vac_start_rows
       ,b."rows" AS vac_end_rows
       ,a."rows" - b."rows" AS vac_deleted_rows
       ,a.sortedrows AS vac_start_sorted_rows
       ,b.sortedrows AS vac_end_sorted_rows
       ,a."blocks" AS vac_start_blocks
       ,b."blocks" AS vac_end_blocks
       ,(b."blocks" - a."blocks") AS vac_block_diff
       ,NVL(e.empty_blk_cnt,0) AS empty_blk_cnt
       ,CASE WHEN a.status ilike '%[VacuumBG]%' THEN true ELSE false END is_auto_vacuum
       ,a.is_recluster
       ,g.aborted
       FROM 
       (SELECT * FROM stl_vacuum WHERE status not ilike '%Finished%') a 
       LEFT JOIN stl_vacuum b on (a.xid,a.table_id) = (b.xid,b.table_id) and a.eventtime < b.eventtime 
       LEFT JOIN (SELECT id,name,db_id FROM stv_tbl_perm WHERE slice = 0) c ON a.table_id = c.id
       LEFT JOIN pg_database d ON c.db_id::oid = d.oid
       LEFT JOIN (SELECT tbl,COUNT(*) AS empty_blk_cnt FROM stv_blocklist WHERE num_values = 0 GROUP BY tbl) e ON a.table_id = e.tbl 
       LEFT JOIN (SELECT xid FROM svv_transactions WHERE lockable_object_type = 'transactionid') f on a.xid=f.xid
       LEFT JOIN (select xid,max(endtime) as endtime,max(aborted) as aborted from stl_query group by 1) g on a.xid = g.xid
ORDER BY a.xid;

-- ============================================================================
-- Creating view: v_wlm_queue_state
-- Source: v_wlm_queue_state.sql
-- ============================================================================
--DROP VIEW admin.v_wlm_queue_state;
/**********************************************************************************************
Purpose: Add WLM_QUEUE_STATE_VW view from Amazon Redshift Tutorial https://docs.aws.amazon.com/redshift/latest/dg/tutorial-wlm-understanding-default-processing.html
History:
2019-02-16 benkim05 Created
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_wlm_queue_state
AS
SELECT 
    config.service_class
    , (config.service_class-5) AS queue
    , trim (config.name) AS name
    , trim (class.condition) AS condition
    , config.num_query_tasks AS slots
    , config.query_working_mem AS mem
    , config.max_execution_time AS max_time
    , config.user_group_wild_card AS "user_*"
    , config.query_group_wild_card AS "query_*"
    , state.num_queued_queries queued
    , state.num_executing_queries executing
    , state.num_executed_queries executed
FROM
    STV_WLM_CLASSIFICATION_CONFIG class,
    STV_WLM_SERVICE_CLASS_CONFIG config,
    STV_WLM_SERVICE_CLASS_STATE state
WHERE
    class.action_service_class = config.service_class 
    AND class.action_service_class = state.service_class 
ORDER BY config.service_class;

-- ============================================================================
-- Creating view: v_find_dropuser_objs
-- Source: v_find_dropuser_objs.sql
-- ============================================================================
/**********************************************************************************************
Purpose:        View to help find all objects owned by the user to be dropped
Columns -
objtype:        Type of object user has privilege on. Object types are Function,Schema,
                Table or View, Database, Language or Default ACL
objowner:       Object owner 
userid:         Owner user id
schemaname:     Schema for the object
objname:        Name of the object
ddl:            Generate DDL string to transfer object ownership to new user
Notes:           
                
History:
2017-03-27 adedotua created
2017-04-06 adedotua improvements
2018-01-06 adedotua added ddl column to generate ddl for transferring object ownership
2018-01-15 pvbouwel Add QUOTE_IDENT for identifiers
2018-05-29 adedotua added filter to skip temp tables
2018-08-03 alexlsts added table pg_library with custom message in ddl column

**********************************************************************************************/


CREATE OR REPLACE VIEW admin.admin.v_find_dropuser_objs as 
SELECT owner.objtype,
       owner.objowner,
       owner.userid,
       owner.schemaname,
       owner.objname,
       owner.ddl
FROM (
-- Functions owned by the user
     SELECT 'Function',pgu.usename,pgu.usesysid,nc.nspname,textin (regprocedureout (pproc.oid::regprocedure)),
     'alter '|| case when prorettype = 0::oid then 'procedure' else 'function' end || ' ' ||  textin (regprocedureout (pproc.oid::regprocedure)) || ' owner to ' 
     FROM pg_proc pproc,pg_user pgu,pg_namespace nc
WHERE pproc.pronamespace = nc.oid
AND   pproc.proowner = pgu.usesysid
UNION ALL
-- Databases owned by the user
SELECT 'Database',
       pgu.usename,
       pgu.usesysid,
       NULL,
       pgd.datname,
       'alter database ' || QUOTE_IDENT(pgd.datname) || ' owner to '
FROM pg_database pgd,
     pg_user pgu
WHERE pgd.datdba = pgu.usesysid
UNION ALL
-- Schemas owned by the user
SELECT 'Schema',
       pgu.usename,
       pgu.usesysid,
       NULL,
       pgn.nspname,
       'alter schema '|| QUOTE_IDENT(pgn.nspname) ||' owner to '
FROM pg_namespace pgn,
     pg_user pgu
WHERE pgn.nspowner = pgu.usesysid
UNION ALL
-- Tables or Views owned by the user
SELECT decode(pgc.relkind,
             'r','Table',
             'v','View'
       ) ,
       pgu.usename,
       pgu.usesysid,
       nc.nspname,
       pgc.relname,
       'alter table ' || QUOTE_IDENT(nc.nspname) || '.' || QUOTE_IDENT(pgc.relname) || ' owner to '
FROM pg_class pgc,
     pg_user pgu,
     pg_namespace nc
WHERE pgc.relnamespace = nc.oid
AND   pgc.relkind IN ('r','v')
AND   pgu.usesysid = pgc.relowner
AND   nc.nspname NOT ILIKE 'pg\_temp\_%'
UNION ALL
-- Python libraries owned by the user
SELECT 'Library',
       pgu.usename,
       pgu.usesysid,
       '',
       pgl.name,
       'No DDL available for Python Library. You should DROP OR REPLACE the Python Library'
FROM  pg_library pgl,
      pg_user pgu
WHERE pgl.owner = pgu.usesysid) OWNER ("objtype","objowner","userid","schemaname","objname","ddl") 
WHERE owner.userid > 1;

;

-- ============================================================================
-- Creating view: v_view_dependency
-- Source: v_view_dependency.sql
-- ============================================================================
--DROP VIEW admin.v_view_dependency;
/**********************************************************************************************
Purpose: View to get the the names of the views that are dependent other tables/views.
History:
2014-02-11 jjschmit Created
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_view_dependency
AS
SELECT DISTINCT 
    srcobj.oid AS src_oid
    ,srcnsp.nspname AS src_schemaname
    ,srcobj.relname AS src_objectname
    ,tgtobj.oid AS dependent_viewoid
    ,tgtnsp.nspname AS dependent_schemaname
    ,tgtobj.relname AS dependent_objectname
FROM
    pg_catalog.pg_class AS srcobj
INNER JOIN
    pg_catalog.pg_depend AS srcdep
        ON srcobj.oid = srcdep.refobjid
INNER JOIN
    pg_catalog.pg_depend AS tgtdep
        ON srcdep.objid = tgtdep.objid
JOIN
    pg_catalog.pg_class AS tgtobj
        ON tgtdep.refobjid = tgtobj.oid
        AND srcobj.oid <> tgtobj.oid
LEFT OUTER JOIN
    pg_catalog.pg_namespace AS srcnsp
        ON srcobj.relnamespace = srcnsp.oid
LEFT OUTER JOIN
    pg_catalog.pg_namespace tgtnsp
        ON tgtobj.relnamespace = tgtnsp.oid
WHERE tgtdep.deptype = 'i' --dependency_internal
AND tgtobj.relkind = 'v' --i=index, v=view, s=sequence
;
;

-- ============================================================================
-- Creating view: v_constraint_dependency
-- Source: v_constraint_dependency.sql
-- ============================================================================
--DROP VIEW admin.v_constraint_dependency;
/**********************************************************************************************
Purpose: View to get the the foreign key constraints between tables
    not null, defaults, etc.
History:
2014-02-11 jjschmit Created
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_constraint_dependency
AS
SELECT DISTINCT
    srcobj.oid AS src_oid
    ,srcnsp.nspname AS src_schemaname
    ,srcobj.relname AS src_objectname
    ,tgtobj.oid AS dependent_oid
    ,tgtnsp.nspname AS dependent_schemaname
    ,tgtobj.relname AS dependent_objectname
    ,con.conname AS constraint_name
FROM
    pg_catalog.pg_class AS srcobj
INNER JOIN
    pg_catalog.pg_namespace AS srcnsp
        ON srcobj.relnamespace = srcnsp.oid
INNER JOIN
    pg_catalog.pg_constraint AS con
        ON srcobj.oid = con.confrelid
INNER JOIN
    pg_catalog.pg_class AS tgtobj
        ON tgtobj.oid = con.conrelid
INNER JOIN
    pg_catalog.pg_namespace AS tgtnsp
        ON tgtobj.relnamespace = tgtnsp.oid
;
;

-- ============================================================================
-- Creating view: v_view_table_column_dependency
-- Source: v_view_table_column_dependency.sql
-- ============================================================================
--DROP VIEW admin.v_view_table_column_dependency;
/*************************************************************
Purpose: View to get the the views that depend on specific
    columns to migrate them away from using this column. 

Usage: To find views depending on 'my_col' of table 'my_tbl'
       SELECT * FROM admin.v_view_table_column_dependency
       WHERE tablename='my_tbl' AND columnname='my_col';

History:
2021-04-27 pvbouwel Created
*************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_view_table_column_dependency
AS
SELECT
  pc1.relname AS viewname
  , pc2.relname AS tablename
  , pa.attname AS columnname
FROM pg_depend pd
JOIN pg_rewrite rw ON rw.oid = pd.objid
JOIN pg_class pc1 ON pc1.oid = rw.ev_class
JOIN pg_class pc2 ON pc2.oid = pd.refobjid
JOIN pg_attribute pa ON pa.attrelid = pd.refobjid
  AND pa.attnum = pd.refobjsubid
  AND pa.attnum>0 -- Only user columns
WHERE classid=(SELECT oid FROM pg_class WHERE relname='pg_rewrite') -- dependency from rewriter rule
  AND refclassid=(SELECT oid FROM pg_class WHERE relname='pg_class') -- dependency on a relation
  AND pc2.relowner > 1 -- Only dependencies on non-system relations
;

-- ============================================================================
-- Creating view: v_extended_table_info
-- Source: v_extended_table_info.sql
-- ============================================================================
/**********************************************************************************************
Purpose: Return extended table information for permanent database tables.

Columns:
database: database name
table_id: table oid
tablename: Schema qualified table name
columns: encoded columns / total columns
pk: Y if PK constraint exists, otherwise N
fk: Y if FK constraint exists, otherwise N
max_varchar: Size of the largest column that uses a VARCHAR data type. 
diststyle: diststyle(distkey column): distribution skew ratio
sortkey: sortkey column(sortkey skew)
size: size in MB / minimum table size (percentage storage used)
tbl_rows: Total number of rows in the table
unsorted: Percent of rows in the unsorted space of the table
stats_off: Number that indicates how stale the table's statistics are; 0 is current, 100 is out of date.
scans:rr:filt:sel:del :
  scans: number of scans against the table
  rr: number of range restricted scans (scans which leverage the zone maps) against the table
  filt: number of scans against the table which leveraged filter criteria
  sel: number of scans against the table which triggered an alert for selective query filter
  del: number of scans against the table which triggered an alert for scanning number of deleted rows
last_scan: last time the table was scanned

Notes:
History:
2016-09-12 chriz-bigdata created
2020-11-18 maryna-popova added case for auto distkeys
2022-08-15 saeedma8 excluded system tables
2022-08-16 timjell Update attencodingtype in (0,128)
**********************************************************************************************/

CREATE OR REPLACE VIEW admin.admin.v_extended_table_info AS
WITH tbl_ids AS
(
  SELECT DISTINCT oid
  FROM pg_class c
  WHERE relowner > 1
  AND   relkind = 'r'
),
scan_alerts AS
(
  SELECT s.tbl AS TABLE,
         Nvl(SUM(CASE WHEN TRIM(SPLIT_PART(l.event,':',1)) = 'Very selective query filter' THEN 1 ELSE 0 END),0) AS selective_scans,
         Nvl(SUM(CASE WHEN TRIM(SPLIT_PART(l.event,':',1)) = 'Scanned a large number of deleted rows' THEN 1 ELSE 0 END),0) AS delrows_scans
  FROM stl_alert_event_log AS l
    JOIN stl_scan AS s
      ON s.query = l.query
     AND s.slice = l.slice
     AND s.segment = l.segment
     AND s.step = l.step
  WHERE l.userid > 1
  AND   s.slice = 0
  AND   s.tbl IN (SELECT oid FROM tbl_ids)
  AND   l.event_time >= Dateadd (DAY,-7,CURRENT_DATE)
  AND   TRIM(SPLIT_PART(l.event,':',1)) IN ('Very selective query filter','Scanned a large number of deleted rows')
  GROUP BY 1
),
tbl_scans AS
(
  SELECT tbl,
         MAX(endtime) last_scan,
         Nvl(COUNT(DISTINCT query || LPAD(segment,3,'0')),0) num_scans
  FROM stl_scan s
  WHERE s.userid > 1
  AND   s.tbl IN (SELECT oid FROM tbl_ids)
  GROUP BY tbl
),
rr_scans AS
(
SELECT tbl,
NVL(SUM(CASE WHEN is_rrscan='t' THEN 1 ELSE 0 END),0) rr_scans,
NVL(SUM(CASE WHEN p.info like 'Filter:%' and p.nodeid > 0 THEN 1 ELSE 0 END),0) filtered_scans,
Nvl(COUNT(DISTINCT s.query || LPAD(s.segment,3,'0')),0) num_scans
  FROM stl_scan s
  JOIN stl_plan_info i on (s.userid=i.userid and s.query=i.query and s.segment=i.segment and s.step=i.step)
  JOIN stl_explain p on ( i.userid=p.userid and i.query=p.query and i.nodeid=p.nodeid  )
  WHERE s.userid > 1
  AND s.type = 2
  AND s.slice = 0
  AND   s.tbl IN (SELECT oid FROM tbl_ids)
  GROUP BY tbl
),
pcon AS
(
  SELECT conrelid,
         CASE
           WHEN SUM(
             CASE
               WHEN contype = 'p' THEN 1
               ELSE 0
             END 
           ) > 0 THEN 'Y'
           ELSE NULL
         END pk,
         CASE
           WHEN SUM(
             CASE
               WHEN contype = 'f' THEN 1
               ELSE 0
             END 
           ) > 0 THEN 'Y'
           ELSE NULL
         END fk
  FROM pg_constraint
  WHERE conrelid > 0
  AND   conrelid IN (SELECT oid FROM tbl_ids)
  GROUP BY conrelid
),
colenc AS
(
  SELECT attrelid,
         SUM(CASE WHEN a.attencodingtype IN (0,128) THEN 0 ELSE 1 END) AS encoded_cols,
         COUNT(*) AS cols
  FROM pg_attribute a
  WHERE a.attrelid IN (SELECT oid FROM tbl_ids)
  AND   a.attnum > 0
  GROUP BY a.attrelid
),
stp AS
(
  SELECT id,
         SUM(ROWS) sum_r,
         SUM(sorted_rows) sum_sr,
         MIN(ROWS) min_r,
         MAX(ROWS) max_r,
         Nvl(COUNT(DISTINCT slice),0) pop_slices
  FROM stv_tbl_perm
  WHERE id IN (SELECT oid FROM tbl_ids)
  AND   slice < 6400
  GROUP BY id
),
cluster_info AS
(
  SELECT COUNT(DISTINCT node) node_count FROM stv_slices where type = 'D'
)
SELECT ti.database,
       ti.table_id,
       ti.SCHEMA || '.' || ti."table" AS tablename,
       colenc.encoded_cols || '/' || colenc.cols AS "columns",
       pcon.pk,
       pcon.fk,
       ti.max_varchar,
       CASE
         WHEN ti.diststyle NOT IN ('EVEN','ALL', 'AUTO(EVEN)', 'AUTO(ALL)') THEN ti.diststyle || ': ' || ti.skew_rows
         ELSE ti.diststyle
       END AS diststyle,
      CASE
         WHEN ti.sortkey1 IS NOT NULL AND ti.sortkey1_enc IS NOT NULL THEN ti.sortkey1 || '(' || nvl (skew_sortkey1,0) || ')'
         WHEN ti.sortkey1 IS NOT NULL THEN ti.sortkey1
         ELSE NULL
       END AS "sortkey",
       ti.size || '/' || CASE
         WHEN stp.sum_r = stp.sum_sr OR stp.sum_sr = 0 THEN
           CASE
             WHEN "diststyle" in ('EVEN', 'AUTO(EVEN)')  THEN (stp.pop_slices*(colenc.cols + 3))
             WHEN SUBSTRING("diststyle",1,3) = 'KEY' THEN (stp.pop_slices*(colenc.cols + 3))
             WHEN "diststyle" in ('AUTO(ALL)', 'ALL')  THEN (cluster_info.node_count*(colenc.cols + 3))
           END 
         ELSE
           CASE
             WHEN "diststyle" in ('EVEN', 'AUTO(EVEN)')  THEN (stp.pop_slices*(colenc.cols + 3)*2)
             WHEN SUBSTRING("diststyle",1,3) = 'KEY' THEN (stp.pop_slices*(colenc.cols + 3)*2)
             WHEN "diststyle" in ('AUTO(ALL)', 'ALL') THEN (cluster_info.node_count*(colenc.cols + 3)*2)
           END 
         END|| ' (' || ti.pct_used || ')' AS size,
         ti.tbl_rows,
         ti.unsorted,
         ti.stats_off,
         Nvl(tbl_scans.num_scans,0) || ':' || Nvl(rr_scans.rr_scans,0) || ':' || Nvl(rr_scans.filtered_scans,0) || ':' || Nvl(scan_alerts.selective_scans,0) || ':' || Nvl(scan_alerts.delrows_scans,0) AS "scans:rr:filt:sel:del",tbl_scans.last_scan 
FROM svv_table_info ti 
LEFT JOIN colenc ON colenc.attrelid = ti.table_id 
LEFT JOIN stp ON stp.id = ti.table_id 
LEFT JOIN tbl_scans ON tbl_scans.tbl = ti.table_id 
LEFT JOIN rr_scans ON rr_scans.tbl = ti.table_id
LEFT JOIN pcon ON pcon.conrelid = ti.table_id 
LEFT JOIN scan_alerts ON scan_alerts.table = ti.table_id 
CROSS JOIN cluster_info 
WHERE ti.SCHEMA !~ '^information_schema|catalog_history|pg_'
ORDER BY ti.pct_used DESC;
                                                                                      
;

-- ============================================================================
-- Creating view: v_generate_external_tbl_ddl
-- Source: v_generate_external_tbl_ddl.sql
-- ============================================================================
--DROP VIEW admin.v_generate_external_tbl_ddl;
/**********************************************************************************************
Purpose: View to get the DDL for an external table.

 History:
  2019-07-10 styerp Created
 **********************************************************************************************/

CREATE OR REPLACE VIEW admin.admin.v_generate_external_tbl_ddl AS
    SELECT schemaname
         , tablename
         , seq
         , ddl
        FROM (
             SELECT 'CREATE EXTERNAL TABLE ' + quote_ident(schemaname) + '.' + quote_ident(tablename) + '('
                     + quote_ident(columnname) + ' ' + external_type AS ddl
                  , 0                                                AS seq
                  , schemaname
                  , tablename
                 FROM svv_external_columns
                 WHERE columnnum = 1
             UNION ALL
             SELECT ', ' + quote_ident(columnname) + ' '
                     + decode(external_type, 'double', 'double precision', external_type) AS ddl
                  , columnnum                                                             AS seq
                  , schemaname
                  , tablename
                 FROM svv_external_columns
                 WHERE columnnum > 1
                   AND part_key = 0
             UNION ALL
             SELECT ')'           AS ddl
                  , 100 + max_col AS seq
                  , schemaname
                  , tablename
                 FROM (
                      SELECT schemaname
                           , tablename
                           , max(columnnum) AS max_col
                          FROM svv_external_columns
                          WHERE part_key = 0
                          GROUP BY 1
                                 , 2
                      ) sub
             UNION ALL
             SELECT 'PARTITIONED BY (' + quote_ident(columnname) + ' ' + external_type AS ddl
                  , 100000 + part_key + columnnum                                      AS seq
                  , schemaname
                  , tablename
                 FROM svv_external_columns
                 WHERE part_key = 1

             UNION ALL
             SELECT ',' + quote_ident(columnname) + ' ' + external_type AS ddl
                  , 100000 + part_key + columnnum                       AS seq
                  , schemaname
                  , tablename
                 FROM svv_external_columns
                 WHERE part_key > 1
             UNION ALL
             SELECT ')'                 AS ddl
                  , 999999                                      AS seq
                  , schemaname
                  , tablename
                 FROM svv_external_columns
                 WHERE part_key = 1

             UNION ALL
             SELECT 'ROW FORMAT SERDE ' + quote_literal(serialization_lib)

                  , 1000000 AS seq
                  , schemaname
                  , tablename
                 FROM svv_external_tables
             UNION ALL
             SELECT 'WITH SERDEPROPERTIES ( ' + regexp_replace(
                     regexp_replace(regexp_replace(serde_parameters, '\\{|\\}', ''), '"', '\''), ':', '=') + ')' AS ddl
                  , 1000001                                                                                      AS seq
                  , schemaname
                  , tablename
                 FROM svv_external_tables
                 WHERE serde_parameters IS NOT NULL
             UNION ALL
             SELECT 'STORED AS INPUTFORMAT ' + quote_literal(input_format) + ' OUTPUTFORMAT '
                     + quote_literal(output_format)
                  , 1000001 AS seq
                  , schemaname
                  , tablename
                 FROM svv_external_tables
                 WHERE input_format IS NOT NULL
                   AND output_format IS NOT NULL
             UNION ALL
             SELECT 'LOCATION ' + quote_literal(location)
                  , 1000002 AS seq
                  , schemaname
                  , tablename
                 FROM svv_external_tables

             UNION ALL
             SELECT 'TABLE PROPERTIES (' + quote_literal(
                     regexp_replace(params, $$'EXTERNAL'='TRUE',|'transient_lastDdlTime'='[::digit::]*',$$, NULL))
                     + ')'  AS ddl
                  , 1000004 AS seq
                  , schemaname
                  , tablename
                 FROM (
                      SELECT schemaname
                           , tablename
                           , regexp_replace(regexp_replace(regexp_replace(parameters, '\\{|\\}', ''), '"', '\''), ':',
                                            '=') AS params
                          FROM svv_external_tables
                      ) tbl_params
                 WHERE params IS NOT NULL
             UNION ALL
             SELECT ';'        AS ddl
                  , 9999999999 AS seq
                  , schemaname
                  , tablename
                 FROM svv_external_tables
             ) gen
        WHERE ddl IS NOT NULL
        ORDER BY 1 DESC
               , 2 DESC
               , 3;

-- ============================================================================
-- Creating view: v_generate_tbl_ddl
-- Source: v_generate_tbl_ddl.sql
-- ============================================================================
--DROP VIEW admin.v_generate_tbl_ddl;
/**********************************************************************************************
Purpose: View to get the DDL for a table.  This will contain the distkey, sortkey, constraints,
         not null, defaults, etc.

Notes:   Default view ordering causes foreign keys to be created at the end.
         This is needed due to dependencies of the foreign key constraint and the tables it
         links.  Due to this one should not manually order the output if you are expecting to
         be able to replay the SQL directly from the VIEW query result. It is still possible to
         order if you filter out the FOREIGN KEYS and then apply them later.

         The following filters are useful:
           where ddl not like 'ALTER TABLE %'  -- do not return FOREIGN KEY CONSTRAINTS
           where ddl like 'ALTER TABLE %'      -- only get FOREIGN KEY CONSTRAINTS
           where tablename in ('t1', 't2')     -- only get DDL for specific tables
           where schemaname in ('s1', 's2')    -- only get DDL for specific schemas

         So for example if you want to order DDL on tablename and only want the tables 't1', 't2'
         and 't4' you can do so by using a query like:
           select ddl from (
             (
               select
                 *
               from admin.v_generate_tbl_ddl
               where ddl not like 'ALTER TABLE %'
               order by tablename
             )
             UNION ALL
             (
               select
                 *
               from admin.v_generate_tbl_ddl
               where ddl like 'ALTER TABLE %'
               order by tablename
             )
           ) where tablename in ('t1', 't2', 't4');

History:
2014-02-10 jjschmit Created
2015-05-18 ericfe Added support for Interleaved sortkey
2015-10-31 ericfe Added cast tp increase size of returning constraint name
2016-05-24 chriz-bigdata Added support for BACKUP NO tables
2017-05-03 pvbouwel Change table & schemaname of Foreign key constraints to allow for filters
2018-01-15 pvbouwel Add QUOTE_IDENT for identifiers (schema,table and column names)
2018-05-30 adedotua Add table_id column
2018-05-30 adedotua Added ENCODE RAW keyword for non compressed columns (Issue #308)
2018-10-12 dmenin Added table ownership to the script (as an alter table statment as the owner of the table is the issuer of the CREATE TABLE command)
2019-03-24 adedotua added filter for diststyle AUTO distribution style
2020-11-11 leisersohn Added COMMENT section
2021-25-03 venkat.yerneni Fixed Table COMMENTS and added Column COMMENTS
2022-08-15 timjell Remove double quotes from COMMENTS string (Issue #604)
2022-08-15 timjell Add MOD to unique constraints to prevent incorrect ordering (Issue #595)
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_generate_tbl_ddl
AS
SELECT
 table_id
 ,REGEXP_REPLACE (schemaname, '^zzzzzzzz', '') AS schemaname
 ,REGEXP_REPLACE (tablename, '^zzzzzzzz', '') AS tablename
 ,seq
 ,ddl
FROM
 (
 SELECT
  table_id
  ,schemaname
  ,tablename
  ,seq
  ,ddl
 FROM
  (
  --DROP TABLE
  SELECT
   c.oid::bigint as table_id
   ,n.nspname AS schemaname
   ,c.relname AS tablename
   ,0 AS seq
   ,'--DROP TABLE ' + QUOTE_IDENT(n.nspname) + '.' + QUOTE_IDENT(c.relname) + ';' AS ddl
  FROM pg_namespace AS n
  INNER JOIN pg_class AS c ON n.oid = c.relnamespace
  WHERE c.relkind = 'r'
  --CREATE TABLE
  UNION SELECT
   c.oid::bigint as table_id
   ,n.nspname AS schemaname
   ,c.relname AS tablename
   ,2 AS seq
   ,'CREATE TABLE IF NOT EXISTS ' + QUOTE_IDENT(n.nspname) + '.' + QUOTE_IDENT(c.relname) + '' AS ddl
  FROM pg_namespace AS n
  INNER JOIN pg_class AS c ON n.oid = c.relnamespace
  WHERE c.relkind = 'r'
  --OPEN PAREN COLUMN LIST
  UNION SELECT c.oid::bigint as table_id,n.nspname AS schemaname, c.relname AS tablename, 5 AS seq, '(' AS ddl
  FROM pg_namespace AS n
  INNER JOIN pg_class AS c ON n.oid = c.relnamespace
  WHERE c.relkind = 'r'
  --COLUMN LIST
  UNION SELECT
   table_id
   ,schemaname
   ,tablename
   ,seq
   ,'\t' + col_delim + col_name + ' ' + col_datatype + ' ' + col_nullable + ' ' + col_default + ' ' + col_encoding AS ddl
  FROM
   (
   SELECT
    c.oid::bigint as table_id
   ,n.nspname AS schemaname
    ,c.relname AS tablename
    ,100000000 + a.attnum AS seq
    ,CASE WHEN a.attnum > 1 THEN ',' ELSE '' END AS col_delim
    ,QUOTE_IDENT(a.attname) AS col_name
    ,CASE WHEN STRPOS(UPPER(format_type(a.atttypid, a.atttypmod)), 'CHARACTER VARYING') > 0
      THEN REPLACE(UPPER(format_type(a.atttypid, a.atttypmod)), 'CHARACTER VARYING', 'VARCHAR')
     WHEN STRPOS(UPPER(format_type(a.atttypid, a.atttypmod)), 'CHARACTER') > 0
      THEN REPLACE(UPPER(format_type(a.atttypid, a.atttypmod)), 'CHARACTER', 'CHAR')
     ELSE UPPER(format_type(a.atttypid, a.atttypmod))
     END AS col_datatype
    ,CASE WHEN format_encoding((a.attencodingtype)::integer) = 'none'
     THEN 'ENCODE RAW'
     ELSE 'ENCODE ' + format_encoding((a.attencodingtype)::integer)
     END AS col_encoding
    ,CASE WHEN a.atthasdef IS TRUE THEN 'DEFAULT ' + adef.adsrc ELSE '' END AS col_default
    ,CASE WHEN a.attnotnull IS TRUE THEN 'NOT NULL' ELSE '' END AS col_nullable
   FROM pg_namespace AS n
   INNER JOIN pg_class AS c ON n.oid = c.relnamespace
   INNER JOIN pg_attribute AS a ON c.oid = a.attrelid
   LEFT OUTER JOIN pg_attrdef AS adef ON a.attrelid = adef.adrelid AND a.attnum = adef.adnum
   WHERE c.relkind = 'r'
     AND a.attnum > 0
   ORDER BY a.attnum
   )
  --CONSTRAINT LIST
  UNION (SELECT
   c.oid::bigint as table_id
   ,n.nspname AS schemaname
   ,c.relname AS tablename
   ,200000000 + MOD(CAST(con.oid AS INT),100000000) AS seq
   ,'\t,' + pg_get_constraintdef(con.oid) AS ddl
  FROM pg_constraint AS con
  INNER JOIN pg_class AS c ON c.relnamespace = con.connamespace AND c.oid = con.conrelid
  INNER JOIN pg_namespace AS n ON n.oid = c.relnamespace
  WHERE c.relkind = 'r' AND pg_get_constraintdef(con.oid) NOT LIKE 'FOREIGN KEY%'
  ORDER BY seq)
  --CLOSE PAREN COLUMN LIST
  UNION SELECT c.oid::bigint as table_id,n.nspname AS schemaname, c.relname AS tablename, 299999999 AS seq, ')' AS ddl
  FROM pg_namespace AS n
  INNER JOIN pg_class AS c ON n.oid = c.relnamespace
  WHERE c.relkind = 'r'
  --BACKUP
  UNION SELECT
  c.oid::bigint as table_id
   ,n.nspname AS schemaname
   ,c.relname AS tablename
   ,300000000 AS seq
   ,'BACKUP NO' as ddl
FROM pg_namespace AS n
  INNER JOIN pg_class AS c ON n.oid = c.relnamespace
  INNER JOIN (SELECT
    SPLIT_PART(key,'_',5) id
    FROM pg_conf
    WHERE key LIKE 'pg_class_backup_%'
    AND SPLIT_PART(key,'_',4) = (SELECT
      oid
      FROM pg_database
      WHERE datname = current_database())) t ON t.id=c.oid
  WHERE c.relkind = 'r'
  --BACKUP WARNING
  UNION SELECT
  c.oid::bigint as table_id
   ,n.nspname AS schemaname
   ,c.relname AS tablename
   ,1 AS seq
   ,'--WARNING: This DDL inherited the BACKUP NO property from the source table' as ddl
FROM pg_namespace AS n
  INNER JOIN pg_class AS c ON n.oid = c.relnamespace
  INNER JOIN (SELECT
    SPLIT_PART(key,'_',5) id
    FROM pg_conf
    WHERE key LIKE 'pg_class_backup_%'
    AND SPLIT_PART(key,'_',4) = (SELECT
      oid
      FROM pg_database
      WHERE datname = current_database())) t ON t.id=c.oid
  WHERE c.relkind = 'r'
  --DISTSTYLE
  UNION SELECT
   c.oid::bigint as table_id
   ,n.nspname AS schemaname
   ,c.relname AS tablename
   ,300000001 AS seq
   ,CASE WHEN c.reldiststyle = 0 THEN 'DISTSTYLE EVEN'
    WHEN c.reldiststyle = 1 THEN 'DISTSTYLE KEY'
    WHEN c.reldiststyle = 8 THEN 'DISTSTYLE ALL'
    WHEN c.reldiststyle = 9 THEN 'DISTSTYLE AUTO'
    ELSE '<<Error - UNKNOWN DISTSTYLE>>'
    END AS ddl
  FROM pg_namespace AS n
  INNER JOIN pg_class AS c ON n.oid = c.relnamespace
  WHERE c.relkind = 'r'
  --DISTKEY COLUMNS
  UNION SELECT
   c.oid::bigint as table_id
   ,n.nspname AS schemaname
   ,c.relname AS tablename
   ,400000000 + a.attnum AS seq
   ,' DISTKEY (' + QUOTE_IDENT(a.attname) + ')' AS ddl
  FROM pg_namespace AS n
  INNER JOIN pg_class AS c ON n.oid = c.relnamespace
  INNER JOIN pg_attribute AS a ON c.oid = a.attrelid
  WHERE c.relkind = 'r'
    AND a.attisdistkey IS TRUE
    AND a.attnum > 0
  --SORTKEY COLUMNS
  UNION select table_id,schemaname, tablename, seq,
       case when min_sort <0 then 'INTERLEAVED SORTKEY (' else ' SORTKEY (' end as ddl
from (SELECT
   c.oid::bigint as table_id
   ,n.nspname AS schemaname
   ,c.relname AS tablename
   ,499999999 AS seq
   ,min(attsortkeyord) min_sort FROM pg_namespace AS n
  INNER JOIN  pg_class AS c ON n.oid = c.relnamespace
  INNER JOIN pg_attribute AS a ON c.oid = a.attrelid
  WHERE c.relkind = 'r'
  AND abs(a.attsortkeyord) > 0
  AND a.attnum > 0
  group by 1,2,3,4 )
  UNION (SELECT
   c.oid::bigint as table_id
   ,n.nspname AS schemaname
   ,c.relname AS tablename
   ,500000000 + abs(a.attsortkeyord) AS seq
   ,CASE WHEN abs(a.attsortkeyord) = 1
    THEN '\t' + QUOTE_IDENT(a.attname)
    ELSE '\t, ' + QUOTE_IDENT(a.attname)
    END AS ddl
  FROM  pg_namespace AS n
  INNER JOIN pg_class AS c ON n.oid = c.relnamespace
  INNER JOIN pg_attribute AS a ON c.oid = a.attrelid
  WHERE c.relkind = 'r'
    AND abs(a.attsortkeyord) > 0
    AND a.attnum > 0
  ORDER BY abs(a.attsortkeyord))
  UNION SELECT
   c.oid::bigint as table_id
   ,n.nspname AS schemaname
   ,c.relname AS tablename
   ,599999999 AS seq
   ,'\t)' AS ddl
  FROM pg_namespace AS n
  INNER JOIN  pg_class AS c ON n.oid = c.relnamespace
  INNER JOIN  pg_attribute AS a ON c.oid = a.attrelid
  WHERE c.relkind = 'r'
    AND abs(a.attsortkeyord) > 0
    AND a.attnum > 0
  --END SEMICOLON
  UNION SELECT c.oid::bigint as table_id ,n.nspname AS schemaname, c.relname AS tablename, 600000000 AS seq, ';' AS ddl
  FROM  pg_namespace AS n
  INNER JOIN pg_class AS c ON n.oid = c.relnamespace
  WHERE c.relkind = 'r' 
  --COMMENT
  UNION
  SELECT c.oid::bigint AS table_id,
       n.nspname     AS schemaname,
       c.relname     AS tablename,
       600250000     AS seq,
       ('COMMENT ON '::text + nvl2(cl.column_name, 'column '::text, 'table '::text) + quote_ident(n.nspname::text) + '.'::text + quote_ident(c.relname::text) + nvl2(cl.column_name, '.'::text + cl.column_name::text, ''::text) + ' IS \''::text + trim(des.description) + '\'; '::text)::character VARYING AS ddl
  FROM pg_description des
  JOIN pg_class c ON c.oid = des.objoid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  LEFT JOIN information_schema."columns" cl
  ON cl.ordinal_position::integer = des.objsubid AND cl.table_name::NAME = c.relname
  WHERE c.relkind = 'r'

  UNION
  --TABLE OWNERSHIP AS AN ALTER TABLE STATMENT
  SELECT c.oid::bigint as table_id ,n.nspname AS schemaname, c.relname AS tablename, 600500000 AS seq, 
  'ALTER TABLE ' + QUOTE_IDENT(n.nspname) + '.' + QUOTE_IDENT(c.relname) + ' owner to '+  QUOTE_IDENT(u.usename) +';' AS ddl
  FROM  pg_namespace AS n
  INNER JOIN pg_class AS c ON n.oid = c.relnamespace
  INNER JOIN pg_user AS u ON c.relowner = u.usesysid
  WHERE c.relkind = 'r'
  
  )
  UNION (
    SELECT c.oid::bigint as table_id,'zzzzzzzz' || n.nspname AS schemaname,
       'zzzzzzzz' || c.relname AS tablename,
       700000000 + MOD(CAST(con.oid AS INT),100000000) AS seq,
       'ALTER TABLE ' + QUOTE_IDENT(n.nspname) + '.' + QUOTE_IDENT(c.relname) + ' ADD ' + pg_get_constraintdef(con.oid)::VARCHAR(10240) + ';' AS ddl
    FROM pg_constraint AS con
      INNER JOIN pg_class AS c
             ON c.relnamespace = con.connamespace
             AND c.oid = con.conrelid
      INNER JOIN pg_namespace AS n ON n.oid = c.relnamespace
    WHERE c.relkind = 'r'
    AND con.contype = 'f'
    ORDER BY seq
  )
 ORDER BY table_id,schemaname, tablename, seq
 )
;
;

-- ============================================================================
-- Creating view: v_generate_view_ddl
-- Source: v_generate_view_ddl.sql
-- ============================================================================
--DROP VIEW admin.v_generate_view_ddl;
/**********************************************************************************************
Purpose: View to get the DDL for a view.  
History:
2014-02-10 jjschmit Created
2018-01-15 pvbouwel Replace tabs and add QUOTE_IDENT for identifiers (schema and view names)
2018-08-03 alexlsts Included CASE to check for late binding view 
2021-04-23 pvbouwel Replace logic to identify different cases to support materialized views.
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_generate_view_ddl
AS
SELECT 
    n.nspname AS schemaname
    ,c.relname AS viewname
    ,'--DROP '
    ||  
    CASE STRPOS(LOWER(pg_get_viewdef(c.oid, TRUE)), 'materialized')
      WHEN 8 THEN 'MATERIALIZED '::text --CREATE MATERIALIZED would be the start
      ELSE ''::text
    END 
    ||
    'VIEW ' + QUOTE_IDENT(n.nspname) + '.' + QUOTE_IDENT(c.relname) + ';\n'
    + CASE STRPOS(LOWER(pg_get_viewdef(c.oid, TRUE)), 'create')
        WHEN 1 then '' -- CREATE statement already present
     	ELSE           --no CREATE statement present so no materialized view anyway
          'CREATE OR REPLACE VIEW ' + QUOTE_IDENT(n.nspname) + '.' + QUOTE_IDENT(c.relname) + ' AS\n'
      END || COALESCE(pg_get_viewdef(c.oid, TRUE), '') AS ddl
FROM 
    pg_catalog.pg_class AS c
INNER JOIN
    pg_catalog.pg_namespace AS n
    ON c.relnamespace = n.oid
WHERE relkind = 'v';
;

-- ============================================================================
-- Creating view: v_generate_user_object_permissions
-- Source: v_generate_user_object_permissions.sql
-- ============================================================================
--DROP VIEW admin.v_generate_user_object_permissions;
/**********************************************************************************************
Purpose: View to get the DDL for a users permissions to tables and views.
History:
2014-02-12 jjschmit Created
2018-01-15 pvbouwel Replace tabs with spaces and add QUOTE_IDENT for usernames
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_generate_user_object_permissions
AS
SELECT
  schemaname
  ,objectname
  ,usename
  ,REVERSE(SUBSTRING(REVERSE(CASE WHEN sel IS TRUE THEN 'GRANT SELECT ON ' + QUOTE_IDENT(schemaname) + '.' + QUOTE_IDENT(objectname) + ' TO ' + QUOTE_IDENT(usename) + ';\n' ELSE '' END +
    CASE WHEN ins IS TRUE THEN 'GRANT INSERT ON ' + QUOTE_IDENT(schemaname) + '.' + QUOTE_IDENT(objectname) + ' TO ' + QUOTE_IDENT(usename) + ';\n' ELSE '' END +
    CASE WHEN upd IS TRUE THEN 'GRANT UPDATE ON ' + QUOTE_IDENT(schemaname) + '.' + QUOTE_IDENT(objectname) + ' TO ' + QUOTE_IDENT(usename) + ';\n' ELSE '' END +
    CASE WHEN del IS TRUE THEN 'GRANT DELETE ON ' + QUOTE_IDENT(schemaname) + '.' + QUOTE_IDENT(objectname) + ' TO ' + QUOTE_IDENT(usename) + ';\n' ELSE '' END +
    CASE WHEN ref IS TRUE THEN 'GRANT REFERENCES ON ' + QUOTE_IDENT(schemaname) + '.' + QUOTE_IDENT(objectname) + ' TO ' + QUOTE_IDENT(usename) + ';\n' ELSE '' END), 2)) AS ddl
FROM admin.v_get_obj_priv_by_user
;
;

-- ============================================================================
-- Creating view: v_generate_user_grant_revoke_ddl
-- Source: v_generate_user_grant_revoke_ddl.sql
-- ============================================================================
/*************************************************************************************************************************
Purpose:    View to generate grant or revoke ddl for users and groups. This is useful for 
                  recreating users or group privileges or for revoking privileges before dropping 
                  a user or group. 
            
Current Version:        1.09
Columns -
objowner:   Object owner 
schemaname: Object schema if applicable
objname:    Name of the object the privilege is granted on
grantor:    User that granted the privilege
grantee:    User/Group the privilege is granted to
objtype:    Type of object user has privilege on. Object types are Function, Schema, 
            Table or View, Database, Language or Default ACL
ddltype:    Type of ddl generated i.e grant or revoke
grantseq:   Sequence number to order the DDLs by hierarchy
objseq:           Sequence number to order the objects by hierarchy
ddl:        DDL text
colname:    Name of the column the privilege is granted on
Notes:         This version will NOT work with a cluster that has patch 1.0.12916 and below. Cluster must be on patch 1.0.13059 and above.
                
History:
Version 1.01
      2017-03-01  adedotua created
      2018-03-04  adedotua completely refactored the view to minimize nested loop joins. View is now significantly faster on clusters 
                        with a large number of users and privileges
      2018-03-04  adedotua added column grantseq to help return the DDLs in the order they need to be granted or revoked
      2018-03-04  adedotua renamed column sequence to objseq and username to grantee
Version 1.02
      2018-03-09  adedotua added logic to handle function name generation when there are non-alphabets in the function schemaname
Version 1.03
      2018-04-26  adedotua added missing filter for handling empty default acls
      2018-04-26  adedotua fixed one more edge case where default privilege is granted on schema to user other than schema owner
Version 1.04
      2018-05-02  adedotua added support for privileges granted on pg_catalog tables and other system owned objects
Version 1.05
      2018-06-22  adedotua fixed issue with generation of default privileges grants.
Version 1.06
      2018-11-12  adedotua fixed issue with generation of default privileges revokes for user who granted the privileges (defacluser).    
Version 1.07
      2019-10-10  adedotua added handling for privileges granted on procedures. Increased ddl column to varchar(4000) to incorporate 
                  CrisFavero #460 pull request. Fixed handling for empty default aclitem
Version 1.08
      2020-02-22  adedotua added support for generating grants for column privileges (requires patch 1.0.13059 and above). added schemanames to catalog tables to allow 
                  creating this view as a late binding view
Version 1.09
      2021-07-27  adedotua added support for generating 'DROP' grants and revokes for tables/views.
Version 1.10
      2023-02-08  Fix for issue #660

Steps to revoking grants before dropping a user:
1. Find all grants by granted by user to drop and regrant them as another user (superuser preferably).
select regexp_replace(ddl,grantor,'<superuser>') from v_generate_user_grant_revoke_ddl where grantor='<username>' and ddltype='grant' and objtype <>'default acl' order by objseq,grantseq;
2. Find all grants granted to user to drop and revoke them.
select ddl from v_generate_user_grant_revoke_ddl where ddltype='revoke' and (grantee='<username>' or grantor='<username>') order by objseq, grantseq desc;              
************************************************************************************************************************/

-- DROP view admin.v_generate_user_grant_revoke_ddl;
CREATE OR REPLACE VIEW admin.admin.v_generate_user_grant_revoke_ddl AS
WITH objprivs AS ( 
SELECT objowner, 
      schemaname, 
      objname, 
      objtype,
      CASE WHEN split_part(aclstring,'=',1)='' THEN 'PUBLIC'::text ELSE translate(trim(split_part(aclstring,'=',1)::text),'"','')::text END::text AS grantee,
      translate(trim(split_part(aclstring,'/',2)::text),'"','')::text AS grantor, 
      trim(split_part(split_part(aclstring,'=',2),'/',1))::text AS privilege, 
      CASE WHEN objtype = 'default acl' THEN QUOTE_IDENT(objname) 
            WHEN objtype in ('procedure','function') AND regexp_instr(objname, schemaname) > 0 THEN QUOTE_IDENT(objname)
            WHEN objtype in ('procedure','function','column') THEN QUOTE_IDENT(schemaname)||'.'||QUOTE_IDENT(objname) 
            ELSE nvl(QUOTE_IDENT(schemaname)||'.'||QUOTE_IDENT(objname),QUOTE_IDENT(objname)) END::varchar(5000) as fullobjname,
      CASE WHEN split_part(aclstring,'=',1)='' THEN 'PUBLIC' 
      ELSE trim(split_part(aclstring,'=',1)) 
      END::text as splitgrantee,
      grantseq,
      colname 
      FROM (
            -- TABLE AND VIEW privileges
            SELECT pg_get_userbyid(b.relowner)::text AS objowner, 
            trim(c.nspname)::text AS schemaname,  
            b.relname::varchar(5000) AS objname,
            CASE WHEN relkind='r' THEN 'table' ELSE 'view' END::text AS objtype, 
            TRIM(SPLIT_PART(array_to_string(b.relacl,','), ',', NS.n))::varchar(500) AS aclstring, 
            NS.n as grantseq,
            null::text as colname
            FROM 
            (SELECT oid,generate_series(1,array_upper(relacl,1))  AS n FROM pg_catalog.pg_class) NS
            INNER JOIN pg_catalog.pg_class B ON b.oid = ns.oid AND  NS.n <= array_upper(b.relacl,1)
            INNER JOIN pg_catalog.pg_namespace c on b.relnamespace = c.oid
            where relkind in ('r','v')
            UNION ALL
            -- TABLE AND VIEW column privileges
            SELECT pg_get_userbyid(c.relowner)::text AS objowner, 
            trim(d.nspname)::text AS schemaname,  
            c.relname::varchar(5000) AS objname,
            'column'::text AS objtype, 
            TRIM(SPLIT_PART(array_to_string(b.attacl,','), ',', NS.n))::varchar(500) AS aclstring, 
            NS.n as grantseq,
            b.attname::text as colname
            FROM 
            (SELECT attrelid,generate_series(1,array_upper(attacl,1))  AS n FROM pg_catalog.pg_attribute_info) NS
            INNER JOIN pg_catalog.pg_attribute_info B ON b.attrelid = ns.attrelid AND  NS.n <= array_upper(b.attacl,1)
            INNER JOIN pg_catalog.pg_class c on b.attrelid = c.oid
            INNER JOIN pg_catalog.pg_namespace d on c.relnamespace = d.oid
            where relkind in ('r','v')
            UNION ALL
            -- SCHEMA privileges
            SELECT pg_get_userbyid(b.nspowner)::text AS objowner,
            null::text AS schemaname,
            b.nspname::varchar(5000) AS objname,
            'schema'::text AS objtype,
            TRIM(SPLIT_PART(array_to_string(b.nspacl,','), ',', NS.n))::varchar(500) AS aclstring,
            NS.n as grantseq,
            null::text as colname
            FROM 
            (SELECT oid,generate_series(1,array_upper(nspacl,1)) AS n FROM pg_catalog.pg_namespace) NS
            INNER JOIN pg_catalog.pg_namespace B ON b.oid = ns.oid AND NS.n <= array_upper(b.nspacl,1)
            UNION ALL
            -- DATABASE privileges
            SELECT pg_get_userbyid(b.datdba)::text AS objowner,
            null::text AS schemaname,
            b.datname::varchar(5000) AS objname,
            'database'::text AS objtype,
            TRIM(SPLIT_PART(array_to_string(b.datacl,','), ',', NS.n))::varchar(500) AS aclstring,
            NS.n as grantseq,
            null::text as colname
            FROM 
            (SELECT oid,generate_series(1,array_upper(datacl,1)) AS n FROM pg_catalog.pg_database) NS
            INNER JOIN pg_catalog.pg_database B ON b.oid = ns.oid AND NS.n <= array_upper(b.datacl,1) 
            UNION ALL
            -- FUNCTION privileges 
            SELECT pg_get_userbyid(b.proowner)::text AS objowner,
            trim(c.nspname)::text AS schemaname, 
            textin(regprocedureout(b.oid::regprocedure))::varchar(5000) AS objname,
            decode(prorettype,0,'procedure','function')::text AS objtype,
            TRIM(SPLIT_PART(array_to_string(b.proacl,','), ',', NS.n))::varchar(500) AS aclstring,
            NS.n as grantseq,
            null::text as colname  
            FROM 
            (SELECT oid,generate_series(1,array_upper(proacl,1)) AS n FROM pg_catalog.pg_proc) NS
            INNER JOIN pg_catalog.pg_proc B ON b.oid = ns.oid and NS.n <= array_upper(b.proacl,1)
            INNER JOIN pg_catalog.pg_namespace c on b.pronamespace=c.oid 
            UNION ALL
            -- LANGUAGE privileges
            SELECT null::text AS objowner,
            null::text AS schemaname,
            lanname::varchar(5000) AS objname,
            'language'::text AS objtype,
            TRIM(SPLIT_PART(array_to_string(b.lanacl,','), ',', NS.n))::varchar(500) AS aclstring,
            NS.n as grantseq, 
            null::text as colname
            FROM 
            (SELECT oid,generate_series(1,array_upper(lanacl,1)) AS n FROM pg_catalog.pg_language) NS
            INNER JOIN pg_catalog.pg_language B ON b.oid = ns.oid and NS.n <= array_upper(b.lanacl,1)
            UNION ALL
            -- DEFAULT ACL privileges
            SELECT pg_get_userbyid(b.defacluser)::text AS objowner,
            trim(c.nspname)::text AS schemaname,
            decode(b.defaclobjtype,'r','tables','f','functions','p','procedures')::varchar(5000) AS objname,
            'default acl'::text AS objtype,
            TRIM(SPLIT_PART(array_to_string(b.defaclacl,','), ',', NS.n))::varchar(500) AS aclstring,
            NS.n as grantseq, 
            null::text as colname
            FROM 
            (SELECT oid,generate_series(1,array_upper(defaclacl,1)) AS n FROM pg_catalog.pg_default_acl) NS
            INNER JOIN pg_catalog.pg_default_acl b ON b.oid = ns.oid and NS.n <= array_upper(b.defaclacl,1) 
            LEFT JOIN  pg_catalog.pg_namespace c on b.defaclnamespace=c.oid
      ) 
      where  ( ((split_part(aclstring,'=',1) = split_part(aclstring,'/',2) AND privilege in ('arwdRxtD','a*r*w*d*R*x*t*D*')) OR split_part(aclstring,'=',1) <> split_part(aclstring,'/',2))
      -- split_part(aclstring,'=',1) <> split_part(aclstring,'/',2)
      AND split_part(aclstring,'=',1) <> 'rdsdb'
      AND NOT (split_part(aclstring,'=',1)='' AND split_part(aclstring,'/',2) = 'rdsdb')) 
)
-- Extract object GRANTS
SELECT objowner::text, schemaname::text, objname::varchar(5000), objtype::text, grantor::text, grantee::text, 'grant'::text AS ddltype, grantseq,
decode(objtype,'database',0,'schema',1,'language',1,'table',2,'view',2,'column',2,'function',2,'procedure',2,'default acl',3) AS objseq,
CASE WHEN (grantor <> current_user AND grantor <> 'rdsdb' AND objtype <> 'default acl') 
THEN 'SET SESSION AUTHORIZATION '||QUOTE_IDENT(grantor)||';' ELSE '' END::varchar(5000)||
(CASE WHEN privilege = 'arwdRxtD' OR privilege = 'a*r*w*d*R*x*t*D*' THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT ALL on '||fullobjname||' to '||splitgrantee||
(CASE WHEN privilege = 'a*r*w*d*R*x*t*D*' THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) 
when privilege = 'UC' OR privilege = 'U*C*' THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT ALL on '||objtype||' '||fullobjname||' to '||splitgrantee||
(CASE WHEN privilege = 'U*C*' THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) 
when privilege = 'CT' OR privilege = 'U*C*' THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT ALL on '||objtype||' '||fullobjname||' to '||splitgrantee||
(CASE WHEN privilege = 'C*T*' THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000))
ELSE  
(
CASE WHEN charindex('a',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT INSERT on '||fullobjname||' to '||splitgrantee|| 
(CASE WHEN charindex('a*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('r',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT SELECT '||CASE WHEN objtype='column' then '('||colname||')' else '' END::text||' on '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('r*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('w',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT UPDATE '||CASE WHEN objtype='column' then '('||colname||')' else '' END::text||' on '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('w*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('d',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT DELETE on '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('d*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||

CASE WHEN charindex('D',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN '-- ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT DROP on '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('d*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||


CASE WHEN charindex('R',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT RULE on '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('R*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('x',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT REFERENCES on '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('x*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('t',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT TRIGGER on '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('t*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('U',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT USAGE on '||objtype||' '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('U*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('C',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT CREATE on '||objtype||' '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('C*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('T',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT TEMP on '||objtype||' '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('T*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('X',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT EXECUTE on '||
(CASE WHEN objtype = 'default acl' THEN '' ELSE objtype||' ' END::varchar(5000))||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('X*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)
) END::varchar(5000))|| 
CASE WHEN (grantor <> current_user AND grantor <> 'rdsdb' AND objtype <> 'default acl') THEN 'RESET SESSION AUTHORIZATION;' ELSE '' END::varchar(5000) AS ddl, colname
FROM objprivs
UNION ALL
-- Extract object REVOKES
SELECT objowner::text, schemaname::text, objname::varchar(5000), objtype::text, grantor::text, grantee::text, 'revoke'::text AS ddltype, grantseq,
decode(objtype,'default acl',0,'function',0,'procedure',1,'table',1,'view',1,'column',1,'schema',2,'language',2,'database',3) AS objseq,
CASE WHEN (grantor <> current_user AND grantor <> 'rdsdb' AND objtype <> 'default acl' AND grantor <> objowner) THEN 'SET SESSION AUTHORIZATION '||QUOTE_IDENT(grantor)||';' ELSE '' END::varchar(5000)||
(CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
||'REVOKE ALL on '||fullobjname||' FROM '||splitgrantee||';'
ELSE 'REVOKE ALL on '||(CASE WHEN objtype in ('table', 'view', 'column') THEN '' ELSE objtype||' ' END::varchar(5000))||fullobjname||' FROM '||splitgrantee||';' END::varchar(5000))||
CASE WHEN (grantor <> current_user AND grantor <> 'rdsdb' AND objtype <> 'default acl' AND grantor <> objowner) THEN 'RESET SESSION AUTHORIZATION;' ELSE '' END::varchar(5000) AS ddl, colname
FROM objprivs
WHERE NOT (objtype = 'default acl' AND grantee = 'PUBLIC' and objname in ('functions'))
UNION ALL
-- Eliminate empty default ACLs
SELECT null::text AS objowner, null::text AS schemaname, decode(b.defaclobjtype,'r','tables','f','functions','p','procedures')::varchar(5000) AS objname,
            'default acl'::text AS objtype,  pg_get_userbyid(b.defacluser)::text AS grantor, null::text AS grantee, 'revoke'::text AS ddltype, 5 as grantseq, 5 AS objseq,
  'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(pg_get_userbyid(b.defacluser))||' GRANT ALL on '||decode(b.defaclobjtype,'r','tables','f','functions','p','procedures')||' TO '||QUOTE_IDENT(pg_get_userbyid(b.defacluser))||
CASE WHEN b.defaclobjtype = 'f' THEN ', PUBLIC;' ELSE ';' END::varchar(5000) AS ddl, null::text as colname FROM pg_catalog.pg_default_acl b where b.defaclacl = '{}'::aclitem[] or (defaclnamespace=0 and defaclobjtype='f');

-- ============================================================================
-- Creating view: v_object_dependency
-- Source: v_object_dependency.sql
-- ============================================================================
--DROP VIEW admin.v_object_dependency;
/**********************************************************************************************
Purpose: A view to merge the different dependency views together
History:
2014-02-11 jjschmit Created
**********************************************************************************************/
CREATE OR REPLACE VIEW admin.admin.v_object_dependency
AS
SELECT 'view' AS dependency_type, *, NULL AS constraint_name FROM admin.v_view_dependency
UNION
SELECT 'fkey constraint' AS dependency_type, * FROM admin.v_constraint_dependency
;
;

-- ============================================================================
-- Additional views not in dependency order
-- ============================================================================

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
