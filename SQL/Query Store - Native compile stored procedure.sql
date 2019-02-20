-- https://blogs.technet.microsoft.com/dataplatform/2017/03/02/query-store-how-it-works-how-to-use-the-new-query-store-dmvs/
-- Liliam Leme
-- Information for troubleshooting 


-- Note: For Query Store track native compile stored procedure you need to enable it: use the procedure to enable [sys].[sp_xtp_control_query_exec_stats]
-- https://msdn.microsoft.com/en-us/library/dn435917.aspx

SELECT
  qq.query_hash,
  qp.last_force_failure_reason,
  qp.last_force_failure_reason,
  CAST(qp.query_plan AS XML) query_plan,
  t.query_sql_text
FROM sys.query_store_query_text t
  JOIN sys.query_store_query    qq
       ON t.query_text_id = qq.query_text_id
  JOIN sys.query_store_plan     qp
       ON qp.query_id = qq.query_id
WHERE qp.is_natively_compiled = 1;