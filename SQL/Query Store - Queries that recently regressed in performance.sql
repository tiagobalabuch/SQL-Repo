-- link: https://docs.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store
--(comparing different point in time)
SELECT
  qt.query_sql_text,
  q.query_id,
  qt.query_text_id,
  rs1.runtime_stats_id AS runtime_stats_id_1,
  rsi1.start_time      AS interval_1,
  p1.plan_id           AS plan_1,
  rs1.avg_duration     AS avg_duration_1,
  rs2.avg_duration     AS avg_duration_2,
  p2.plan_id           AS plan_2,
  rsi2.start_time      AS interval_2,
  rs2.runtime_stats_id AS runtime_stats_id_2
FROM sys.query_store_query_text               AS qt
  JOIN sys.query_store_query                  AS q
       ON qt.query_text_id = q.query_text_id
  JOIN sys.query_store_plan                   AS p1
       ON q.query_id = p1.query_id
  JOIN sys.query_store_runtime_stats          AS rs1
       ON p1.plan_id = rs1.plan_id
  JOIN sys.query_store_runtime_stats_interval AS rsi1
       ON rsi1.runtime_stats_interval_id = rs1.runtime_stats_interval_id
  JOIN sys.query_store_plan                   AS p2
       ON q.query_id = p2.query_id
  JOIN sys.query_store_runtime_stats          AS rs2
       ON p2.plan_id = rs2.plan_id
  JOIN sys.query_store_runtime_stats_interval AS rsi2
       ON rsi2.runtime_stats_interval_id = rs2.runtime_stats_interval_id
WHERE rsi1.start_time > DATEADD (HOUR, -48, GETUTCDATE ())
      AND rsi2.start_time > rsi1.start_time
      AND p1.plan_id <> p2.plan_id
      AND rs2.avg_duration > 2 * rs1.avg_duration
ORDER BY q.query_id,
         rsi1.start_time,
         rsi2.start_time;

-- comparing recent vs. history execution

--- "Recent" workload - last 1 hour  
DECLARE @recent_start_time DATETIMEOFFSET;
DECLARE @recent_end_time DATETIMEOFFSET;
SET @recent_start_time ='2017-11-29 14:15:00' --DATEADD (HOUR, -1, SYSUTCDATETIME ());
SET @recent_end_time = '2017-11-29 15:15:00'-- SYSUTCDATETIME ();

--- "History" workload  
DECLARE @history_start_time DATETIMEOFFSET;
DECLARE @history_end_time DATETIMEOFFSET;
SET @history_start_time = '2017-11-28 14:15:00' --DATEADD (HOUR, -24, SYSUTCDATETIME ());
SET @history_end_time = '2017-11-28 15:15:00'; --SYSUTCDATETIME ();

WITH hist
AS
 ( SELECT
     p.query_id                                                   query_id,
     CONVERT (FLOAT, SUM (rs.avg_duration * rs.count_executions)) total_duration,
     SUM (rs.count_executions)                                    count_executions,
     COUNT (DISTINCT p.plan_id)                                   num_plans
   FROM sys.query_store_runtime_stats AS rs
     JOIN sys.query_store_plan        p
          ON p.plan_id = rs.plan_id
   WHERE ( rs.first_execution_time >= @history_start_time
           AND rs.last_execution_time < @history_end_time )
         OR ( rs.first_execution_time <= @history_start_time
              AND rs.last_execution_time > @history_start_time )
         OR ( rs.first_execution_time <= @history_end_time
              AND rs.last_execution_time > @history_end_time )
   GROUP BY p.query_id ),
     recent
AS
 ( SELECT
     p.query_id                                                   query_id,
     CONVERT (FLOAT, SUM (rs.avg_duration * rs.count_executions)) total_duration,
     SUM (rs.count_executions)                                    count_executions,
     COUNT (DISTINCT p.plan_id)                                   num_plans
   FROM sys.query_store_runtime_stats AS rs
     JOIN sys.query_store_plan        p
          ON p.plan_id = rs.plan_id
   WHERE ( rs.first_execution_time >= @recent_start_time
           AND rs.last_execution_time < @recent_end_time )
         OR ( rs.first_execution_time <= @recent_start_time
              AND rs.last_execution_time > @recent_start_time )
         OR ( rs.first_execution_time <= @recent_end_time
              AND rs.last_execution_time > @recent_end_time )
   GROUP BY p.query_id )
SELECT
  results.query_id                            query_id,
  results.query_text                          query_text,
  results.additional_duration_workload        additional_duration_workload,
  results.total_duration_recent               total_duration_recent,
  results.total_duration_hist                 total_duration_hist,
  ISNULL (results.count_executions_recent, 0) count_executions_recent,
  ISNULL (results.count_executions_hist, 0)   count_executions_hist
FROM
( SELECT
    hist.query_id                    query_id,
    qt.query_sql_text                query_text,
    ROUND (
      CONVERT (FLOAT, recent.total_duration / recent.count_executions - hist.total_duration / hist.count_executions)
      * ( recent.count_executions ),
      2)                             AS additional_duration_workload,
    ROUND (recent.total_duration, 2) total_duration_recent,
    ROUND (hist.total_duration, 2)   total_duration_hist,
    recent.count_executions          count_executions_recent,
    hist.count_executions            count_executions_hist
  FROM hist
    JOIN recent
         ON hist.query_id = recent.query_id
    JOIN sys.query_store_query      AS q
         ON q.query_id = hist.query_id
    JOIN sys.query_store_query_text AS qt
         ON q.query_text_id = qt.query_text_id ) AS results
WHERE additional_duration_workload > 0
ORDER BY additional_duration_workload DESC
OPTION ( MERGE JOIN );

SELECT CONVERT(XML, query_plan),* FROM sys.query_store_plan WHERE query_id = 130
