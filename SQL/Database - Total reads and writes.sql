/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Total reads and writes 
Original link: 
Obs.: Script was copied from internet
***************************************************************************/

SELECT  SUM( qs.total_logical_reads ) AS [Total Reads]
      , SUM( qs.total_logical_writes ) AS [Total Writes]
      , DB_NAME( qt.dbid ) AS DatabaseName
FROM    sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text( qs.sql_handle ) AS qt
--WHERE DB_NAME(qt.dbid) = DB_NAME(DB_ID())
GROUP BY DB_NAME( qt.dbid )
ORDER BY DatabaseName;