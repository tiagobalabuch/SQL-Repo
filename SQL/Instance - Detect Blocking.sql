
/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Detect blocking (run multiple times) 
Original link:
Obs.: Script was copied from internet

***************************************************************************/
-- Helps troubleshoot blocking and deadlocking issues
-- The results will change from second to second on a busy system
-- You should run this query multiple times when you see signs of blocking

SELECT  [er].[wait_time] AS [Wait time in ms] ,
        [er].[session_id] AS [Blocked session] ,
        [ces].[login_name] AS [Login name] ,
        [ces].[nt_domain] AS [Windows domain] ,
        LEFT([ces].[nt_user_name], 30) AS [Windows login] ,
        LEFT([ces].[program_name], 40) AS [Program name] ,
        [er].[blocking_session_id] AS [Lead session] ,
        DB_NAME([er].[database_id]) AS [Database] ,
        CAST ([csql].text AS VARCHAR(255)) AS [TSQL waiting] ,
        [clck].[CallingResourceId] AS [Resource ID waiting] ,
        [clck].[CallingResourceType] AS [Resource Type waiting] ,
        [clck].[CallingRequestMode] AS [Resource Type waiting] ,
        CAST ([bsql].text AS VARCHAR(255)) AS [TSQL Blocking] ,
        [blck].[BlockingResourceType] AS [Resource Type] ,
        [blck].[BlockingRequestMode] AS [Resource Type]
FROM    [master].[sys].[dm_exec_requests] [er]
        JOIN [master].[sys].[dm_exec_sessions] [ces] ON [er].[session_id] = [ces].[session_id]
        CROSS APPLY [fn_get_sql]([er].[sql_handle]) [csql]
        JOIN ( SELECT   [cl].[request_session_id] AS [CallingSpId] ,
                        MIN([cl].[resource_associated_entity_id]) AS [CallingResourceId] ,
                        MIN(LEFT([cl].[resource_type], 30)) AS [CallingResourceType] ,
                        MIN(LEFT([cl].[request_mode], 30)) AS [CallingRequestMode]
               FROM     [master].[sys].[dm_tran_locks] [cl]
               WHERE    [cl].[request_status] = 'WAIT'
               GROUP BY [cl].[request_session_id]
             ) AS [clck] ON [er].[session_id] = [clck].[CallingSpId]
        JOIN ( SELECT   [bl].[request_session_id] AS [BlockingSpId] ,
                        [bl].[resource_associated_entity_id] AS [BlockingResourceId] ,
                        MIN(LEFT([bl].[resource_type], 30)) AS [BlockingResourceType] ,
                        MIN(LEFT([bl].[request_mode], 30)) AS [BlockingRequestMode]
               FROM     [master].[sys].[dm_tran_locks] [bl] WITH ( NOLOCK )
               GROUP BY [bl].[request_session_id] ,
                        [bl].[resource_associated_entity_id]
             ) AS [blck] ON [er].[blocking_session_id] = [blck].[BlockingSpId]
                            AND [clck].[CallingResourceId] = [blck].[BlockingResourceId]
        JOIN [master].[sys].[dm_exec_connections] [ber] ON [er].[blocking_session_id] = [ber].[session_id]
        CROSS APPLY [fn_get_sql]([ber].[most_recent_sql_handle]) [bsql]
WHERE   [ces].[is_user_process] = 1
        AND [er].[wait_time] > 0;

GO
