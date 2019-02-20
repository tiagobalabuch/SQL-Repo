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
  qp.compatibility_level,
  CAST(qp.query_plan AS XML) query_plan,
  t.query_sql_text,
  t.statement_sql_handle,
  qp.query_id
FROM sys.query_store_query_text t
  JOIN sys.query_store_query    qq
       ON t.query_text_id = qq.query_text_id
  JOIN sys.query_store_plan     qp
       ON qp.query_id = qq.query_id
ORDER BY qq.last_compile_start_time DESC;