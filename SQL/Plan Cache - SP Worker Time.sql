/*************************************************************************
Author: Glenn Berry 
Date: 22/09/2017
Description: Top Cached SPs By Total Worker time
Original link: 
Obs.: Script was copied from internet
	  SQL Server 2012 Diagnostic Information Queries
	  Last Modified: September 22, 2014
	  Worker time relates to CPU cost
	  (Query 51) (SP Worker Time)
***************************************************************************/

SELECT TOP ( 25 )
    p.name AS [SPName]
  , qs.total_worker_time AS TotalWorkerTime
  , qs.total_worker_time / qs.execution_count AS AvgWorkerTime
  , qs.execution_count
  , ISNULL( qs.execution_count / DATEDIFF( MINUTE, qs.cached_time, GETDATE()), 0 ) AS [Calls/Minute]
  , qs.total_elapsed_time
  , qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time
  , qs.cached_time
FROM    sys.procedures AS p WITH ( NOLOCK )
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH ( NOLOCK ) ON p.object_id = qs.object_id
WHERE   qs.database_id = DB_ID()
ORDER BY qs.total_worker_time DESC
OPTION ( RECOMPILE );


-- This helps you find the most expensive cached stored procedures from a CPU perspective
-- You should look at this if you see signs of CPU pressure

