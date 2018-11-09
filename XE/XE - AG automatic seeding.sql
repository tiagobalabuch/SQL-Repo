/*************************************************************************
Author: Erik Darling
Date: 09/11/2018
Description:  Automatic Seeding XE
Original link: https://www.brentozar.com/archive/2016/06/availability-group-direct-seeding-extended-events-and-dmvs/
Obs.: Script was copied from internet 
  
***************************************************************************/

-- Creating XE
CREATE EVENT SESSION [DirectSeed]
ON SERVER
    ADD EVENT sqlserver.hadr_ar_controller_debug
    (ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.tsql_stack))
  , ADD EVENT sqlserver.hadr_automatic_seeding_failure
    (ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.tsql_stack))
  , ADD EVENT sqlserver.hadr_automatic_seeding_start
    (ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.tsql_stack))
  , ADD EVENT sqlserver.hadr_automatic_seeding_state_transition
    (ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.tsql_stack))
  , ADD EVENT sqlserver.hadr_automatic_seeding_success
    (ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.tsql_stack))
  , ADD EVENT sqlserver.hadr_automatic_seeding_timeout
    (ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.tsql_stack))
    ADD TARGET package0.event_file
    (SET filename = N'C:\Temp\XE\DirectSeed.xel', max_rollover_files = (10))
WITH (MAX_MEMORY = 4096KB
    , EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS
    , MAX_DISPATCH_LATENCY = 30 SECONDS
    , MAX_EVENT_SIZE = 0KB
    , MEMORY_PARTITION_MODE = NONE
    , TRACK_CAUSALITY = OFF
    , STARTUP_STATE = OFF);
GO


CREATE EVENT SESSION [PhysicalSeed]
ON SERVER
    ADD EVENT sqlserver.hadr_physical_seeding_backup_state_change
    (ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.tsql_stack))
  , ADD EVENT sqlserver.hadr_physical_seeding_failure
    (ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.tsql_stack))
  , ADD EVENT sqlserver.hadr_physical_seeding_forwarder_state_change
    (ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.tsql_stack))
  , ADD EVENT sqlserver.hadr_physical_seeding_forwarder_target_state_change
    (ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.tsql_stack))
  , ADD EVENT sqlserver.hadr_physical_seeding_progress
    (ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.tsql_stack))
  , ADD EVENT sqlserver.hadr_physical_seeding_restore_state_change
    (ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.tsql_stack))
  , ADD EVENT sqlserver.hadr_physical_seeding_schedule_long_task_failure
    (ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.tsql_stack))
  , ADD EVENT sqlserver.hadr_physical_seeding_submit_callback
    (ACTION (sqlserver.database_id, sqlserver.sql_text, sqlserver.tsql_stack))
    ADD TARGET package0.event_file
    (SET filename = N'C:\XE\PhysicalSeed', max_rollover_files = (10));
GO

ALTER EVENT SESSION [DirectSeed]
ON SERVER STATE = START;
ALTER EVENT SESSION [PhysicalSeed] ON SERVER STATE = START;


-- Getting data from XML

IF OBJECT_ID( 'tempdb..#DirectSeed' ) IS NOT NULL
    BEGIN
        DROP TABLE [#DirectSeed];
    END;

CREATE TABLE [#DirectSeed]
    (
        [ID] INT IDENTITY (1, 1) NOT NULL
      , [EventXML] XML
      , CONSTRAINT [PK_DirectSeed]
            PRIMARY KEY CLUSTERED ([ID])
    );

INSERT [#DirectSeed] ([EventXML])
SELECT
    CONVERT( XML, [event_data] ) AS [EventXML]
FROM
    [sys].[fn_xe_file_target_read_file]( 'C:\TEMP\XE\DirectSeed*.xel', NULL, NULL, NULL );

CREATE PRIMARY XML INDEX [DirectSeedXML] ON [#DirectSeed] ([EventXML]);

CREATE XML INDEX [DirectSeedXMLPath]
ON [#DirectSeed] ([EventXML])
USING XML INDEX [DirectSeedXML] FOR VALUE;

SELECT
    [ds].[EventXML].[value]( '(/event/@name)[1]', 'VARCHAR(MAX)' )                                     AS [event_name]
  , [ds].[EventXML].[value]( '(/event/@timestamp)[1]', 'DATETIME2(7)' )                                AS [event_time]
  , [ds].[EventXML].[value]( '(/event/data[@name="debug_message"]/value)[1]', 'VARCHAR(8000)' )        AS [debug_message]
  /*hadr_automatic_seeding_state_transition*/
  , [ds].[EventXML].[value]( '(/event/data[@name="previous_state"]/value)[1]', 'VARCHAR(8000)' )       AS [previous_state]
  , [ds].[EventXML].[value]( '(/event/data[@name="current_state"]/value)[1]', 'VARCHAR(8000)' )        AS [current_state]
  /*hadr_automatic_seeding_start*/
  , [ds].[EventXML].[value]( '(/event/data[@name="operation_attempt_number"]/value)[1]', 'BIGINT' )    AS [operation_attempt_number]
  , [ds].[EventXML].[value]( '(/event/data[@name="ag_id"]/value)[1]', 'VARCHAR(8000)' )                AS [ag_id]
  , [ds].[EventXML].[value]( '(/event/data[@name="ag_db_id"]/value)[1]', 'VARCHAR(8000)' )             AS [ag_id]
  , [ds].[EventXML].[value]( '(/event/data[@name="ag_remote_replica_id"]/value)[1]', 'VARCHAR(8000)' ) AS [ag_remote_replica_id]
  /*hadr_automatic_seeding_success*/
  , [ds].[EventXML].[value]( '(/event/data[@name="required_seeding"]/value)[1]', 'VARCHAR(8000)' )     AS [required_seeding]
  /*hadr_automatic_seeding_timeout*/
  , [ds].[EventXML].[value]( '(/event/data[@name="timeout_ms"]/value)[1]', 'BIGINT' )                  AS [timeout_ms]
  /*hadr_automatic_seeding_failure*/
  , [ds].[EventXML].[value]( '(/event/data[@name="failure_state"]/value)[1]', 'BIGINT' )               AS [failure_state]
  , [ds].[EventXML].[value]( '(/event/data[@name="failure_state_desc"]/value)[1]', 'VARCHAR(8000)' )   AS [failure_state_desc]
FROM
    [#DirectSeed] AS [ds]
ORDER BY
    [ds].[EventXML].[value]( '(/event/@timestamp)[1]', 'DATETIME2(7)' ) DESC;

-- Physical Seed

IF OBJECT_ID( 'tempdb..#PhysicalSeed' ) IS NOT NULL
    DROP TABLE [#PhysicalSeed];

CREATE TABLE [#PhysicalSeed]
    (
        [ID] INT IDENTITY (1, 1)
            NOT NULL
      ,
      [EventXML] XML
      ,
      CONSTRAINT [PK_PhysicalSeed]
          PRIMARY KEY CLUSTERED ([ID])
    );

INSERT [#PhysicalSeed]
    ([EventXML])
SELECT
    CONVERT( XML, [event_data] ) AS [EventXML]
FROM
    [sys].[fn_xe_file_target_read_file]( 'C:\XE\PhysicalSeed*.xel', NULL, NULL, NULL );

CREATE PRIMARY XML INDEX [PhysicalSeedXML]
ON [#PhysicalSeed] ([EventXML]);

CREATE XML INDEX [PhysicalSeedXMLPath]
ON [#PhysicalSeed] ([EventXML])
USING XML INDEX [PhysicalSeedXML] FOR VALUE;

SELECT
    [ds].[EventXML].[value]( '(/event/@name)[1]', 'VARCHAR(MAX)' )                                                          AS [event_name]
  , [ds].[EventXML].[value]( '(/event/@timestamp)[1]', 'DATETIME2(7)' )                                                     AS [event_time]
  , [ds].[EventXML].[value]( '(/event/data[@name="old_state"]/text)[1]', 'VARCHAR(8000)' )                                  AS [old_state]
  , [ds].[EventXML].[value]( '(/event/data[@name="new_state"]/text)[1]', 'VARCHAR(8000)' )                                  AS [new_state]
  , [ds].[EventXML].[value]( '(/event/data[@name="seeding_start_time"]/value)[1]', 'DATETIME2(7)' )                         AS [seeding_start_time]
  , [ds].[EventXML].[value]( '(/event/data[@name="seeding_end_time"]/value)[1]', 'DATETIME2(7)' )                           AS [seeding_end_time]
  , [ds].[EventXML].[value]( '(/event/data[@name="estimated_completion_time"]/value)[1]', 'DATETIME2(7)' )                  AS [estimated_completion_time]
  , [ds].[EventXML].[value]( '(/event/data[@name="transferred_size_bytes"]/value)[1]', 'BIGINT' ) / (1024. * 1024.)         AS [transferred_size_mb]
  , [ds].[EventXML].[value]( '(/event/data[@name="transfer_rate_bytes_per_second"]/value)[1]', 'BIGINT' ) / (1024. * 1024.) AS [transfer_rate_mb_per_second]
  , [ds].[EventXML].[value]( '(/event/data[@name="database_size_bytes"]/value)[1]', 'BIGINT' ) / (1024. * 1024.)            AS [database_size_mb]
  , [ds].[EventXML].[value]( '(/event/data[@name="total_disk_io_wait_time_ms"]/value)[1]', 'BIGINT' )                       AS [total_disk_io_wait_time_ms]
  , [ds].[EventXML].[value]( '(/event/data[@name="total_network_wait_time_ms"]/value)[1]', 'BIGINT' )                       AS [total_network_wait_time_ms]
  , [ds].[EventXML].[value]( '(/event/data[@name="is_compression_enabled"]/value)[1]', 'VARCHAR(8000)' )                    AS [is_compression_enabled]
  , [ds].[EventXML].[value]( '(/event/data[@name="failure_code"]/value)[1]', 'BIGINT' )                                     AS [failure_code]
FROM
    [#PhysicalSeed] AS [ds]
ORDER BY
    [ds].[EventXML].[value]( '(/event/@timestamp)[1]', 'DATETIME2(7)' ) DESC;
