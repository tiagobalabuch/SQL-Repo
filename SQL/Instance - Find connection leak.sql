/*************************************************************************
Author: Tiago Balabuch
Date : 22/09/2017
Description: Find Database Connection Leaks in Your Application
Original link: https://blog.bertwagner.com/how-to-search-and-destroy-non-sargable-queries-on-your-server-ff9f57c7268e
Obs.: Script was copied from internet and modify 

***************************************************************************/
 /* Given a pool, are there sessions that have been sleeping for a while and, if so, 
	how long have they been sleeping and what was the last SQL statement they executed?
  */
WITH    cte ( sessionCount, hostName, hostProcessId, programName, databaseName )
          AS ( SELECT   COUNT(*) AS sessions
                      , s.host_name
                      , s.host_process_id
                      , s.program_name
                      , DB_NAME(s.database_id) AS database_name
               FROM     sys.dm_exec_sessions s
               WHERE    is_user_process = 1
               GROUP BY host_name
                      , host_process_id
                      , program_name
                      , database_id
             )
     SELECT DATEDIFF(MINUTE , s.last_request_end_time , GETDATE()) AS minutes_asleep
          , s.session_id
          , DB_NAME(s.database_id) AS database_name
          , s.host_name
          , s.host_process_id
          , t.text AS last_sql
          , s.program_name
     FROM   sys.dm_exec_connections c
     INNER JOIN sys.dm_exec_sessions s ON c.session_id = s.session_id
     INNER JOIN cte ON cte.hostProcessId = s.host_process_id AND
                       cte.databaseName = DB_NAME(s.database_id) AND
                       cte.hostName = s.host_name AND
                       s.program_name = cte.programName
     CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) t
     WHERE  s.is_user_process = 1 AND
            s.status = 'sleeping' AND
            DATEDIFF(SECOND , s.last_request_end_time , GETDATE()) > 60
     ORDER BY s.last_request_end_time
          , cte.hostName
          , cte.databaseName;
