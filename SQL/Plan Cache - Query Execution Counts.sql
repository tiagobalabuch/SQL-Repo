
/*************************************************************************
Author: Glenn Berry
Date : 22/09/2017
Description: Top cached queries by Execution Count
Original link: 
Obs.: Script was copied from internet 
SQL Server 2012 Diagnostic Information Queries
	Last Modified: September 22, 2014
    (Query 47) (Query Execution Counts)
***************************************************************************/

SELECT TOP ( 100 )
    qs.execution_count
  , qs.total_rows
  , qs.last_rows
  , qs.min_rows
  , qs.max_rows
  , qs.last_elapsed_time
  , qs.min_elapsed_time
  , qs.max_elapsed_time
  , total_worker_time
  , total_logical_reads
  , SUBSTRING(
                 qt.text
               , qs.statement_start_offset / 2 + 1
               , ( CASE
                       WHEN qs.statement_end_offset = -1 THEN LEN( CONVERT( NVARCHAR (MAX), qt.text )) * 2
                       ELSE qs.statement_end_offset
                   END - qs.statement_start_offset
                 ) / 2
             ) AS query_text
FROM    sys.dm_exec_query_stats AS qs WITH ( NOLOCK )
CROSS APPLY sys.dm_exec_sql_text( qs.sql_handle ) AS qt
ORDER BY qs.execution_count DESC
OPTION ( RECOMPILE );

-- Uses several new rows returned columns to help troubleshoot performance problems