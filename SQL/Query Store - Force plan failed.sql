-- https://blogs.technet.microsoft.com/dataplatform/2017/03/02/query-store-how-it-works-how-to-use-the-new-query-store-dmvs/
-- Liliam Leme
-- Information for troubleshooting 

SELECT
  qq.query_hash,
  qp.last_force_failure_reason,
  -- qp.last_force_failure_reason,
	qp.force_failure_count,
	qp.last_force_failure_reason_desc,
	qp.is_forced_plan,
	qp.plan_id,
	qq.query_id,
  CAST(qp.query_plan AS XML) query_plan,
  t.query_sql_text
FROM sys.query_store_query_text t
  JOIN sys.query_store_query    qq
       ON t.query_text_id = qq.query_text_id
  JOIN sys.query_store_plan     qp
       ON qp.query_id = qq.query_id
WHERE qp.force_failure_count > 0;