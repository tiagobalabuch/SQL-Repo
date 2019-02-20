-- link: https://docs.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store


DECLARE @id INT;
DECLARE adhoc_queries_cursor CURSOR FOR
SELECT
  q.query_id
FROM sys.query_store_query_text      AS qt
  JOIN sys.query_store_query         AS q
       ON q.query_text_id = qt.query_text_id
  JOIN sys.query_store_plan          AS p
       ON p.query_id = q.query_id
  JOIN sys.query_store_runtime_stats AS rs
       ON rs.plan_id = p.plan_id
GROUP BY q.query_id
HAVING SUM (rs.count_executions) < 2
       AND MAX (rs.last_execution_time) < DATEADD (HOUR, -24, GETUTCDATE ()) -- 24 hours
ORDER BY q.query_id;

OPEN adhoc_queries_cursor;
FETCH NEXT FROM adhoc_queries_cursor
INTO
  @id;
WHILE @@FETCH_STATUS = 0
BEGIN
  PRINT @id;
  EXEC sp_query_store_remove_query @id;
  FETCH NEXT FROM adhoc_queries_cursor
  INTO
    @id;
END;
CLOSE adhoc_queries_cursor;
DEALLOCATE adhoc_queries_cursor;