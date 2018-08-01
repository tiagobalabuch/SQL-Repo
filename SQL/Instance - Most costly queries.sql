/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Most costly CPU queries
Original link: 
Obs.: Script was copied from internet
  
***************************************************************************/

SELECT TOP 10
    [Average CPU used] = total_worker_time / qs.execution_count
  , [Total CPU used] = total_worker_time
  , [Execution count] = qs.execution_count
  , [Individual Query] = SUBSTRING(
                                      qt.text
                                    , qs.statement_start_offset / 2 + 1
                                    , CASE
                                          WHEN qs.statement_end_offset = -1 THEN LEN( CONVERT( NVARCHAR (MAX), qt.text )) * 2 + 1
                                          ELSE qs.statement_end_offset
                                      END - qs.statement_start_offset / 2 + 1
                                  )
  , [Parent Query] = qt.text
  , qt.dbid
  , DatabaseName = DB_NAME( qt.dbid )
  , qs.plan_handle
FROM    sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text( qs.sql_handle ) AS qt
ORDER BY [Average CPU used] DESC;

-- Agreggation  
SELECT TOP 50
    SUM( qs.total_worker_time / qs.execution_count ) AS total_cpu_time
  , SUM( qs.execution_count ) AS total_execution_count
  , COUNT( * ) AS number_of_statements
  , qs.plan_handle
FROM    sys.dm_exec_query_stats qs
GROUP BY qs.plan_handle
ORDER BY SUM( qs.total_worker_time / qs.execution_count ) DESC;