
/*************************************************************************
Author: Paul Randal
Data : 22/09/2017
Descrição: Using XE to investigate waits  
Original link: http://www.sqlskills.com/blogs/paul/who-is-overriding-maxdop-1-on-the-instance/
Obs.: Script was copied from internet

***************************************************************************/
IF EXISTS ( SELECT  *
            FROM    sys.server_event_sessions
            WHERE   [name] = N'InvestigateOverrindingMAXDOP' )
    DROP EVENT SESSION [InvestigateOverrindingMAXDOP] ON SERVER;
GO

CREATE EVENT SESSION InvestigateOverrindingMAXDOP ON SERVER
ADD EVENT sqlserver.degree_of_parallelism (
    ACTION ( sqlserver.client_hostname, sqlserver.nt_username,
    sqlserver.sql_text )
    WHERE [dop] > 0 -- parallel plans
)
ADD TARGET [package0].[ring_buffer],
ADD TARGET package0.event_file (  SET filename = N'Trace_Backup_Restore' )
WITH (  MAX_MEMORY = 50 MB ,
        EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS ,
        MAX_DISPATCH_LATENCY = 5 SECONDS ,
        MAX_EVENT_SIZE = 0 KB ,
        MEMORY_PARTITION_MODE = NONE ,
        TRACK_CAUSALITY = OFF ,
        STARTUP_STATE = OFF );


ALTER EVENT SESSION [InvestigateOverrindingMAXDOP] ON SERVER STATE = START;

-- Read from buffer

SELECT  [data1].[value]('(./@timestamp)[1]', 'datetime') AS [Time] ,
        [data1].[value]('(./data[@name="dop"]/value)[1]', 'INT') AS [DOP] ,
        [data1].[value]('(./action[@name="client_hostname"]/value)[1]',
                        'VARCHAR(MAX)') AS [Host] ,
        [data1].[value]('(./action[@name="nt_username"]/value)[1]',
                        'VARCHAR(MAX)') AS [User] ,
        [data1].[value]('(./action[@name="sql_text"]/value)[1]',
                        'VARCHAR(MAX)') AS [Statement]
FROM    ( SELECT    CONVERT (XML, [target_data]) AS data
          FROM      sys.dm_xe_session_targets [xst]
                    INNER JOIN sys.dm_xe_sessions [xs] ON [xst].[event_session_address] = [xs].[address]
          WHERE     [xs].[name] = N'InvestigateOverrindingMAXDOP'
        ) AS t
        CROSS APPLY data.nodes('//event') n ( data1 );
GO


-- Read from file
WITH    cte
          AS ( SELECT   [data1].event_data.value('(event/@timestamp)[1]',
                                                 'datetime') AS [Time] ,
                        [data1].event_data.value('(event/data[@name="dop"]/value)[1]',
                                                 'INT') AS [DOP] ,
                        [data1].event_data.value('(event/action[@name="client_hostname"]/value)[1]',
                                                 'VARCHAR(MAX)') AS [Host] ,
                        [data1].event_data.value('(event/action[@name="nt_username"]/value)[1]',
                                                 'VARCHAR(MAX)') AS [User] ,
                        [data1].event_data.value('(event/action[@name="sql_text"]/value)[1]',
                                                 'VARCHAR(MAX)') AS [Statement]
               FROM     sys.fn_xe_file_target_read_file('Monitoring_Deadlocks*.xel',
                                                        NULL, NULL, NULL) t1
                        CROSS APPLY ( SELECT    CONVERT(XML, t1.event_data)
                                    ) [data1] ( event_data )
             )
    SELECT  cte.Time ,
            cte.DOP ,
            cte.Host ,
            cte.[User] ,
            cte.Statement
    FROM    cte;

