-- link: https://docs.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store

WITH Query_MultPlans
AS
 ( SELECT
     COUNT (*) AS cnt,
     q.query_id
   FROM sys.query_store_query_text AS qt
     JOIN sys.query_store_query    AS q
          ON qt.query_text_id = q.query_text_id
     JOIN sys.query_store_plan     AS p
          ON p.query_id = q.query_id
   GROUP BY q.query_id
   HAVING COUNT (DISTINCT plan_id) > 1 )
SELECT
  q.query_id,
  OBJECT_NAME (object_id) AS ContainingObject,
  query_sql_text,
  plan_id,
  p.query_plan            AS plan_xml,
  p.last_compile_start_time,
  p.last_execution_time
FROM Query_MultPlans              AS qm
  JOIN sys.query_store_query      AS q
       ON qm.query_id = q.query_id
  JOIN sys.query_store_plan       AS p
       ON q.query_id = p.query_id
  JOIN sys.query_store_query_text qt
       ON qt.query_text_id = q.query_text_id
ORDER BY query_id,
         plan_id;