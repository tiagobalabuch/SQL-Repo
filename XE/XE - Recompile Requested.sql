
/*************************************************************************
Author: Tiago Balabuch
Data : 22/09/2017
Descrição: Using XE to find cause of recompilation 
Obs.: Script was copied from internet

***************************************************************************/

IF EXISTS ( SELECT  *
            FROM    sys.server_event_sessions
            WHERE   [name] = N'Recompile_Requested' )
    DROP EVENT SESSION Recompile_Requested ON SERVER;
GO

CREATE EVENT SESSION [Recompile_Requested] ON SERVER
ADD EVENT sqlserver.sql_statement_recompile (
    ACTION ( sqlserver.database_id, sqlserver.sql_text )
    WHERE ( [recompile_cause] = ( 11 ) ) ) -- Option (RECOMPILE) Requested
ADD TARGET package0.event_file ( SET filename = N'Recompile_Requested' )
WITH (  MAX_MEMORY = 4096 KB ,
        EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS ,
        MAX_DISPATCH_LATENCY = 5 SECONDS ,
        MAX_EVENT_SIZE = 0 KB ,
        MEMORY_PARTITION_MODE = NONE ,
        TRACK_CAUSALITY = OFF ,
        STARTUP_STATE = OFF );
  
ALTER EVENT SESSION [Recompile_Requested] ON SERVER STATE = START;

SELECT  t1.eventDate ,
        DB_NAME(t1.database_id) AS DatabaseName ,
        t1.object_type ,
        COALESCE(t1.sql_text,
                 OBJECT_NAME(t1.object_id, t1.database_id)) command ,
        t1.recompile_cause,
		t1.recompile_count
FROM    sys.fn_xe_file_target_read_file('DarkQueries*xel', NULL, NULL, NULL) event_file_value
        CROSS APPLY ( SELECT    CAST(event_file_value.[event_data] AS XML)
                    ) event_file_value_xml ( [xml] )
        CROSS APPLY ( SELECT    event_file_value_xml.[xml].value('(event/@timestamp)[1]',
                                                              'datetime') AS eventDate ,
                                event_file_value_xml.[xml].value('(event/action[@name="sql_text"]/value)[1]',
                                                              'nvarchar(max)') AS sql_text ,
                                event_file_value_xml.[xml].value('(event/data[@name="object_type"]/text)[1]',
                                                              'nvarchar(100)') AS object_type ,
                                event_file_value_xml.[xml].value('(event/data[@name="object_id"]/value)[1]',
                                                              'bigint') AS object_id ,
                                event_file_value_xml.[xml].value('(event/data[@name="source_database_id"]/value)[1]',
                                                              'bigint') AS database_id ,
                                event_file_value_xml.[xml].value('(event/data[@name="recompile_cause"]/text)[1]',
                                                              'nvarchar(100)') AS recompile_cause,


event_file_value_xml.[xml].value('(event/data[@name="recompile_count"]/text)[1]',
                                                              'nvarchar(100)') AS recompile_count

                    ) AS t1
ORDER BY eventDate DESC;
