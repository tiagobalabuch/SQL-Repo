/*************************************************************************
Author: Tiago Balabuch
Date: 17/10/2017
Description: Active requests running in parallel
Original link: 
Obs.: Script was copied from internet
  
***************************************************************************/

SELECT  r.session_id
      , r.request_id
      , MAX( ISNULL( exec_context_id, 0 )) AS number_of_workers
      , r.sql_handle
      , r.statement_start_offset
      , r.statement_end_offset
      , r.plan_handle
FROM    sys.dm_exec_requests AS r
JOIN sys.dm_os_tasks AS t ON r.session_id = t.session_id
JOIN sys.dm_exec_sessions AS s ON r.session_id = s.session_id
WHERE   s.is_user_process = 1
GROUP BY r.session_id
       , r.request_id
       , r.sql_handle
       , r.plan_handle
       , r.statement_start_offset
       , r.statement_end_offset
HAVING  MAX( ISNULL( exec_context_id, 0 )) > 0;
