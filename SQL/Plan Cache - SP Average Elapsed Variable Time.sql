/*************************************************************************
Author: Glenn Berry 
Date: 22/09/2017
Description: Top Cached SPs By Avg Elapsed Time with execution time variability
Original link: 
Obs.: Script was copied from internet
	  SQL Server 2012 Diagnostic Information Queries
	  Last Modified: September 22, 2014
	  (Query 50) (SP Avg Elapsed Variable Time)
***************************************************************************/


SELECT TOP ( 25 )
    p.name AS [SPName]
  , qs.execution_count
  , qs.min_elapsed_time
  , qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time
  , qs.max_elapsed_time
  , qs.last_elapsed_time
  , qs.cached_time
FROM    sys.procedures AS p WITH ( NOLOCK )
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH ( NOLOCK ) ON p.object_id = qs.object_id
WHERE   qs.database_id = DB_ID()
ORDER BY avg_elapsed_time DESC
OPTION ( RECOMPILE );

-- This gives you some interesting information about the variability in the
-- execution time of your cached stored procedures, which is useful for tuning
