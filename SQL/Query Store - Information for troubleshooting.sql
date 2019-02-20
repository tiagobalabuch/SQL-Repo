-- https://blogs.technet.microsoft.com/dataplatform/2017/03/02/query-store-how-it-works-how-to-use-the-new-query-store-dmvs/
-- Liliam Leme
-- Information for troubleshooting 
SELECT
  qq.query_hash,
  qq.initial_compile_start_time,
  qq.last_compile_start_time,
  qq.last_execution_time,
  qq.avg_compile_memory_kb,
  qq.last_compile_memory_kb,
  qq.max_compile_memory_kb,
  t.query_sql_text,
  t.statement_sql_handle,
  qq.query_parameterization_type,
  qs.total_logical_reads,
  qs.total_logical_writes,
  qs.execution_count,
  ( qs.total_logical_reads / qs.execution_count ) avg_logical
FROM sys.query_store_query_text t
  JOIN sys.query_store_query    qq
       ON t.query_text_id = qq.query_text_id
  JOIN sys.dm_exec_query_stats  qs
       ON t.statement_sql_handle = qs.statement_sql_handle;