/*************************************************************************
Author: Tiago Balabuch
Date : 22/09/2017
Description: Current running requests 
Original link: 
Obs.: Script was copied from internet

***************************************************************************/

SELECT
        CURRENT_TIMESTAMP AS curruntDate
      , ses.session_id
      , DB_NAME(req.database_id) AS databaseName
      , req.status AS requestStatus
      , ses.login_name
      , con.client_net_address
      , ses.program_name
      , req.open_transaction_count
      , req.blocking_session_id
      , ses.host_name
      , ses.client_interface_name
      , qpl.[query_plan] AS queryPlan
      , SUBSTRING(sqltxt.text , ( req.statement_start_offset / 2 ) + 1 ,
                  CASE WHEN req.statement_end_offset = -1 OR
                            req.statement_end_offset = 0 THEN ( DATALENGTH(sqltxt.text) - req.statement_start_offset / 2 ) + 1
                       ELSE ( req.statement_end_offset - req.statement_start_offset ) / 2 + 1
                  END) AS statementTSQL
      , req.granted_query_memory
      , req.logical_reads
      , req.cpu_time
      , req.reads
      , req.row_count
      , req.scheduler_id
      , req.total_elapsed_time
      , req.start_time
      , req.percent_complete
      , req.wait_resource
      , req.wait_type
      , req.wait_time
      , wtk.wait_duration_ms AS blocking_time_ms
      , lck.resource_associated_entity_id
      , lck.request_status AS lock_request_status
      , lck.request_mode AS lock_mode
      , req.writes
      , req.last_wait_type
      , fn_sql.text AS sessionTSQL
      , ses.status AS sessionStatus
      , ses.cpu_time AS sessionCPUtime
      , ses.reads AS sessionReads
      , ses.writes AS sessionWrites
      , ses.logical_reads AS sessionLogicalRreads
      , ses.memory_usage AS sessionMemoryUsage
      , ses.last_request_start_time
      , ses.last_request_end_time
      , ses.total_scheduled_time AS sessionScheduledTime
      , ses.total_elapsed_time AS sessionElpasedTime
      , ses.row_count AS sessionRowcount
    FROM
        sys.dm_exec_sessions ses
    INNER JOIN sys.dm_exec_connections con ON ses.session_id = con.session_id
    OUTER APPLY dbo.fn_get_sql(con.most_recent_sql_handle) AS fn_sql
    LEFT OUTER JOIN sys.dm_exec_requests req ON req.session_id = ses.session_id
    OUTER APPLY sys.dm_exec_sql_text(req.[sql_handle]) sqltxt
    OUTER APPLY sys.dm_exec_query_plan(req.[plan_handle]) qpl
    LEFT OUTER JOIN sys.dm_os_waiting_tasks wtk ON req.session_id = wtk.session_id AND
                                                   wtk.wait_type LIKE 'LCK%' AND
                                                   req.blocking_session_id = wtk.blocking_session_id
    LEFT OUTER JOIN sys.dm_tran_locks lck ON lck.lock_owner_address = wtk.resource_address AND
                                             lck.request_session_id = req.blocking_session_id
    WHERE
        ses.status != 'sleeping';
