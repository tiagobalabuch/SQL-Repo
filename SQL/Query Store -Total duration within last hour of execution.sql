--get 25 queries based on total duration within last hour of execution
-- https://azure.microsoft.com/en-us/blog/query-store-a-flight-data-recorder-for-your-database/

WITH AggregatedDurationLastHour
AS
 ( SELECT
     q.query_id,
     SUM (count_executions * avg_duration) AS total_duration,
     COUNT (DISTINCT p.plan_id)            AS number_of_plans
   FROM sys.query_store_query_text               AS qt
     JOIN sys.query_store_query                  AS q
          ON qt.query_text_id = q.query_text_id
     JOIN sys.query_store_plan                   AS p
          ON q.query_id = p.query_id
     JOIN sys.query_store_runtime_stats          AS rs
          ON rs.plan_id = p.plan_id
     JOIN sys.query_store_runtime_stats_interval AS rsi
          ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
   WHERE rsi.start_time >= DATEADD (HOUR, -1, GETUTCDATE ())
         AND rs.execution_type_desc = 'Regular'
   GROUP BY q.query_id ),
     OrderedDuration
AS
 ( SELECT
     query_id,
     total_duration,
     number_of_plans,
     ROW_NUMBER () OVER ( ORDER BY total_duration DESC,
                                   query_id ) AS RN
   FROM AggregatedDurationLastHour )
SELECT
  qt.query_sql_text,
  OBJECT_NAME (q.object_id)    AS containing_object,
  number_of_plans,
  total_duration               AS total_duration_microseconds,
  total_duration / 1000        AS total_duration_milliseconds,
  total_duration / 1000 / 1000 AS total_duration_seconds,
  number_of_plans,
  CONVERT (XML, p.query_plan)  AS query_plan_xml,
  p.is_forced_plan,
  p.last_compile_start_time,
  q.last_execution_time
FROM OrderedDuration              od
  JOIN sys.query_store_query      AS q
       ON q.query_id = od.query_id
  JOIN sys.query_store_query_text qt
       ON q.query_text_id = qt.query_text_id
  JOIN sys.query_store_plan       p
       ON q.query_id = p.query_id
WHERE od.RN <= 25
ORDER BY total_duration DESC;

