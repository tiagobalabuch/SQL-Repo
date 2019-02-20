-- https://blogs.technet.microsoft.com/dataplatform/2017/03/02/query-store-how-it-works-how-to-use-the-new-query-store-dmvs/
-- Liliam Leme
-- Information for troubleshooting 

SELECT
  qq.query_hash,
  qp.is_trivial_plan,
  qp.is_parallel_plan,
  qp.compatibility_level,
  CAST(qp.query_plan AS XML) query_plan,
  t.query_sql_text,
  COUNT (*)
FROM sys.query_store_query_text t
  JOIN sys.query_store_query    qq
       ON t.query_text_id = qq.query_text_id
  JOIN sys.query_store_plan     qp
       ON qp.query_id = qq.query_id
GROUP BY qq.query_hash,
         qp.is_trivial_plan,
         qp.is_parallel_plan,
         qp.compatibility_level,
         query_plan,
         t.query_sql_text;