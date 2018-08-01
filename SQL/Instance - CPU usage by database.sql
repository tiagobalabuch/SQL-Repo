/*************************************************************************
Author: Glenn Berry
Date: 22/09/2017
Description: Get CPU utilization by database
Original link: 
Obs.: Script was copied from internet
	  SQL Server 2012 Diagnostic Information Queries
	  Last Modified: September 22, 2014
	  (Query 29) (CPU Usage by Database)
***************************************************************************/


WITH DB_CPU_Stats
AS
    (   SELECT  F_DB.DatabaseID
              , DB_NAME( F_DB.DatabaseID ) AS [Database Name]
              , SUM( total_worker_time ) AS CPU_Time_Ms
        FROM    sys.dm_exec_query_stats AS qs
        CROSS APPLY (
                        SELECT  CONVERT( INT, value ) AS DatabaseID
                        FROM    sys.dm_exec_plan_attributes( qs.plan_handle )
                        WHERE   attribute = N'dbid'
                    ) AS F_DB
        GROUP BY F_DB.DatabaseID )
SELECT  ROW_NUMBER() OVER ( ORDER BY DB_CPU_Stats.CPU_Time_Ms DESC ) AS [CPU Rank]
      , DB_CPU_Stats.[Database Name]
      , DB_CPU_Stats.CPU_Time_Ms AS [CPU Time (ms)]
      , CAST(DB_CPU_Stats.CPU_Time_Ms * 1.0 / SUM( DB_CPU_Stats.CPU_Time_Ms ) OVER () * 100.0 AS DECIMAL (5, 2)) AS [CPU Percent]
FROM    DB_CPU_Stats
WHERE   DB_CPU_Stats.DatabaseID <> 32767 -- ResourceDB
ORDER BY [CPU Rank]
OPTION ( RECOMPILE );

-- Helps determine which database is using the most CPU resources on the instance