/*************************************************************************
Author: Glenn Berry 
Date: 22/09/2017
Description: Top Cached SPs By Total Logical Writes
Original link: 
Obs.: Script was copied from internet
	  SQL Server 2012 Diagnostic Information Queries
	  Last Modified: September 22, 2014
	  Logical writes relate to both memory and disk I/O pressure
	  (Query 54) (SP Logical Writes)
***************************************************************************/

SELECT TOP ( 25 )
    p.name AS [SP Name]
  , qs.total_logical_writes AS TotalLogicalWrites
  , qs.total_logical_writes / qs.execution_count AS AvgLogicalWrites
  , qs.execution_count
  , ISNULL( qs.execution_count / DATEDIFF( MINUTE, qs.cached_time, GETDATE()), 0 ) AS [Calls/Minute]
  , qs.total_elapsed_time
  , qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time
  , qs.cached_time
FROM    sys.procedures AS p WITH ( NOLOCK )
INNER JOIN sys.dm_exec_procedure_stats AS qs WITH ( NOLOCK ) ON p.object_id = qs.object_id
WHERE   qs.database_id = DB_ID()
        AND qs.total_logical_writes > 0
ORDER BY qs.total_logical_writes DESC
OPTION ( RECOMPILE );

-- This helps you find the most expensive cached stored procedures from a write I/O perspective
-- You should look at this if you see signs of I/O pressure or of memory pressure