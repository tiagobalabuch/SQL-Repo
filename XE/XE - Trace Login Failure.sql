
/*************************************************************************
Author: Tiago Balabuch
Data : 22/09/2017
Descrição: Using XE to trace Login Failure 
Original link: https://blogs.msdn.microsoft.com/sql_pfe_blog/2017/05/04/login-failed-for-xxx-whos-keeps-trying-to-connect-to-my-server/
Obs.: Script was copied from internet

***************************************************************************/


IF EXISTS ( SELECT  *
            FROM    sys.server_event_sessions
            WHERE   [name] = N'Trace_LoginFailure' )
    DROP EVENT SESSION [Trace_LoginFailure] ON SERVER;
GO

CREATE EVENT SESSION [Trace_LoginFailure] ON SERVER
ADD EVENT sqlserver.errorlog_written (
    ACTION ( sqlserver.client_app_name, sqlserver.client_hostname,
    sqlserver.client_pid ) )
ADD TARGET package0.event_file (  SET filename = N'Trace_LoginFailure' ,
                                  max_file_size = ( 128 ) )
WITH (  MAX_MEMORY = 4096 KB ,
        EVENT_RETENTION_MODE = ALLOW_MULTIPLE_EVENT_LOSS ,
        MAX_DISPATCH_LATENCY = 30 SECONDS ,
        MAX_EVENT_SIZE = 0 KB ,
        MEMORY_PARTITION_MODE = NONE ,
        TRACK_CAUSALITY = OFF ,
        STARTUP_STATE = OFF ); 
GO


ALTER EVENT SESSION [Trace_LoginFailure] ON SERVER STATE = START;