--Plans per query

SELECT
  qt.query_sql_text,
  q.query_id,
  qt.query_text_id,
  p.plan_id,
  rs.runtime_stats_id,
  rsi.start_time,
  rsi.end_time,
  rs.avg_physical_io_reads,
  rs.avg_rowcount,
  rs.count_executions,
  rs.execution_type_desc,
  p.query_plan,
  so.name,
  so.type
FROM sys.query_store_query_text               qt
  JOIN sys.query_store_query                  q
       ON qt.query_text_id = q.query_text_id
  JOIN sys.query_store_plan                   p
       ON q.query_id = p.query_id
  JOIN sys.query_store_runtime_stats          rs
       ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval rsi
       ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
  JOIN sysobjects                             so
       ON so.id = q.object_id

--where rs.execution_type=4

ORDER BY count_executions DESC;





--Top queries based on Total executions

SELECT
  qt.query_sql_text,
  q.query_id,
  so.name,
  so.type,
  SUM (rs.count_executions) AS 'Total_Executions'
FROM sys.query_store_query_text               qt
  JOIN sys.query_store_query                  q
       ON qt.query_text_id = q.query_text_id
  JOIN sys.query_store_plan                   p
       ON q.query_id = p.query_id
  JOIN sys.query_store_runtime_stats          rs
       ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval rsi
       ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
  JOIN sysobjects                             so
       ON so.id = q.object_id
WHERE rsi.start_time >= DATEADD (DAY, -10, GETUTCDATE ())
GROUP BY qt.query_sql_text,
         q.query_id,
         so.name,
         so.type
ORDER BY SUM (rs.count_executions) DESC;





--Top queries based on Avg. CPU Time

SELECT
  qt.query_sql_text,
  q.query_id,
  so.name,
  so.type,
  AVG (rs.avg_cpu_time) AS 'Avg. CPU Time'
FROM sys.query_store_query_text               qt
  JOIN sys.query_store_query                  q
       ON qt.query_text_id = q.query_text_id
  JOIN sys.query_store_plan                   p
       ON q.query_id = p.query_id
  JOIN sys.query_store_runtime_stats          rs
       ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval rsi
       ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
  JOIN sysobjects                             so
       ON so.id = q.object_id
WHERE rsi.start_time >= DATEADD (DAY, -10, GETUTCDATE ())
GROUP BY qt.query_sql_text,
         q.query_id,
         so.name,
         so.type
ORDER BY AVG (rs.avg_cpu_time) DESC;





--Per Query Detail (Top queries based on Avg. CPU Time)

SELECT
  qt.query_sql_text,
  q.query_id,
  so.name,
  so.type,
  rs.avg_cpu_time,
	p.plan_id
FROM sys.query_store_query_text               qt
  JOIN sys.query_store_query                  q
       ON qt.query_text_id = q.query_text_id
  JOIN sys.query_store_plan                   p
       ON q.query_id = p.query_id
  JOIN sys.query_store_runtime_stats          rs
       ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval rsi
       ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
  JOIN sysobjects                             so
       ON so.id = q.object_id
WHERE rsi.start_time >= DATEADD (DAY, -10, GETUTCDATE ())
ORDER BY rs.avg_cpu_time DESC;





--Top queries based on Avg. Duration

SELECT
  qt.query_sql_text,
  q.query_id,
  so.name,
  so.type,
  AVG (rs.avg_duration) AS 'Avg. Duration'
FROM sys.query_store_query_text               qt
  JOIN sys.query_store_query                  q
       ON qt.query_text_id = q.query_text_id
  JOIN sys.query_store_plan                   p
       ON q.query_id = p.query_id
  JOIN sys.query_store_runtime_stats          rs
       ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval rsi
       ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
  JOIN sysobjects                             so
       ON so.id = q.object_id
WHERE rsi.start_time >= DATEADD (DAY, -10, GETUTCDATE ())
GROUP BY qt.query_sql_text,
         q.query_id,
         so.name,
         so.type
ORDER BY AVG (rs.avg_duration) DESC;





--Per Query Detail (Top queries based on Avg. Duration)

SELECT
  qt.query_sql_text,
  q.query_id,
  so.name,
  so.type,
  rs.avg_duration
FROM sys.query_store_query_text               qt
  JOIN sys.query_store_query                  q
       ON qt.query_text_id = q.query_text_id
  JOIN sys.query_store_plan                   p
       ON q.query_id = p.query_id
  JOIN sys.query_store_runtime_stats          rs
       ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval rsi
       ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
  JOIN sysobjects                             so
       ON so.id = q.object_id
WHERE rsi.start_time >= DATEADD (DAY, -10, GETUTCDATE ())
ORDER BY rs.avg_duration DESC;





--Top queries based on Avg. Logical IO Reads

SELECT
  qt.query_sql_text,
  q.query_id,
  so.name,
  so.type,
  AVG (rs.avg_logical_io_reads) AS 'Avg. Logical IO Reads'
FROM sys.query_store_query_text               qt
  JOIN sys.query_store_query                  q
       ON qt.query_text_id = q.query_text_id
  JOIN sys.query_store_plan                   p
       ON q.query_id = p.query_id
  JOIN sys.query_store_runtime_stats          rs
       ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval rsi
       ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
  JOIN sysobjects                             so
       ON so.id = q.object_id
WHERE rsi.start_time >= DATEADD (DAY, -10, GETUTCDATE ())
GROUP BY qt.query_sql_text,
         q.query_id,
         so.name,
         so.type
ORDER BY AVG (rs.avg_logical_io_reads) DESC;





--Per Query Detail (Top queries based on Avg. Logical IO Reads)

SELECT
  qt.query_sql_text,
  q.query_id,
  so.name,
  so.type,
  rs.avg_logical_io_reads
FROM sys.query_store_query_text               qt
  JOIN sys.query_store_query                  q
       ON qt.query_text_id = q.query_text_id
  JOIN sys.query_store_plan                   p
       ON q.query_id = p.query_id
  JOIN sys.query_store_runtime_stats          rs
       ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval rsi
       ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
  JOIN sysobjects                             so
       ON so.id = q.object_id
WHERE rsi.start_time >= DATEADD (DAY, -10, GETUTCDATE ())
ORDER BY rs.avg_logical_io_reads DESC;





--Top queries based on Avg. Logical IO Writes

SELECT
  qt.query_sql_text,
  q.query_id,
  so.name,
  so.type,
  AVG (rs.avg_logical_io_writes) AS 'Avg. Logical IO Writes'
FROM sys.query_store_query_text               qt
  JOIN sys.query_store_query                  q
       ON qt.query_text_id = q.query_text_id
  JOIN sys.query_store_plan                   p
       ON q.query_id = p.query_id
  JOIN sys.query_store_runtime_stats          rs
       ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval rsi
       ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
  JOIN sysobjects                             so
       ON so.id = q.object_id
WHERE rsi.start_time >= DATEADD (DAY, -10, GETUTCDATE ())
GROUP BY qt.query_sql_text,
         q.query_id,
         so.name,
         so.type
ORDER BY AVG (rs.avg_logical_io_writes) DESC;





--Per Query Detail (Top queries based on Avg. Logical IO Writes)

SELECT
  qt.query_sql_text,
  q.query_id,
  so.name,
  so.type,
  rs.avg_logical_io_writes
FROM sys.query_store_query_text               qt
  JOIN sys.query_store_query                  q
       ON qt.query_text_id = q.query_text_id
  JOIN sys.query_store_plan                   p
       ON q.query_id = p.query_id
  JOIN sys.query_store_runtime_stats          rs
       ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval rsi
       ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
  JOIN sysobjects                             so
       ON so.id = q.object_id
WHERE rsi.start_time >= DATEADD (DAY, -10, GETUTCDATE ())
ORDER BY rs.avg_logical_io_writes DESC;





--Exception Queries

SELECT
  qt.query_sql_text,
  q.query_id,
  qt.query_text_id,
  p.plan_id,
  rs.runtime_stats_id,
  rsi.start_time,
  rsi.end_time,
  rs.avg_physical_io_reads,
  rs.avg_rowcount,
  rs.count_executions,
  rs.execution_type_desc,
  p.query_plan,
  so.name,
  so.type
FROM sys.query_store_query_text               qt
  JOIN sys.query_store_query                  q
       ON qt.query_text_id = q.query_text_id
  JOIN sys.query_store_plan                   p
       ON q.query_id = p.query_id
  JOIN sys.query_store_runtime_stats          rs
       ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval rsi
       ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
  JOIN sys.objects                            so
       ON so.object_id = q.object_id
WHERE rs.execution_type = 4
ORDER BY count_executions DESC;





--Aborted Queries

SELECT
  qt.query_sql_text,
  q.query_id,
  qt.query_text_id,
  p.plan_id,
  rs.runtime_stats_id,
  rsi.start_time,
  rsi.end_time,
  rs.avg_physical_io_reads,
  rs.avg_rowcount,
  rs.count_executions,
  rs.execution_type_desc,
  p.query_plan,
  so.name,
  so.type
FROM sys.query_store_query_text               qt
  JOIN sys.query_store_query                  q
       ON qt.query_text_id = q.query_text_id
  JOIN sys.query_store_plan                   p
       ON q.query_id = p.query_id
  JOIN sys.query_store_runtime_stats          rs
       ON p.plan_id = rs.plan_id
  JOIN sys.query_store_runtime_stats_interval rsi
       ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
  JOIN sys.objects                            so
       ON so.object_id = q.object_id
WHERE rs.execution_type = 3
ORDER BY count_executions DESC;