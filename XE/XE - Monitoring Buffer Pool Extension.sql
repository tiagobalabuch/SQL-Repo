/*************************************************************************
Author: Tiago Balabuch
Data : 22/09/2017
Description: Monitoring Buffer Pool Extension 
Original link:
Obs.: 

***************************************************************************/

IF EXISTS ( SELECT  *
            FROM    sys.server_event_sessions
            WHERE   [name] = N'MonitoringBufferPoolExtension' )
   DROP EVENT SESSION Trace_Backup_Restore ON SERVER;
GO

CREATE EVENT SESSION [MonitoringBufferPoolExtension] ON SERVER
ADD EVENT sqlserver.buffer_pool_eviction_thresholds_recalculated (
    ACTION ( sqlos.system_thread_id , sqlos.task_resource_pool_id , sqlserver.database_id )
    WHERE ( [sqlserver].[database_id] > ( 4 ) ) ) ,
ADD EVENT sqlserver.buffer_pool_extension_pages_evicted (
    ACTION ( sqlos.system_thread_id , sqlos.task_resource_pool_id , sqlserver.database_id )
    WHERE ( [sqlserver].[database_id] > ( 4 ) ) ) ,
ADD EVENT sqlserver.buffer_pool_extension_pages_read (
    ACTION ( sqlos.system_thread_id , sqlos.task_resource_pool_id , sqlserver.database_id )
    WHERE ( [sqlserver].[database_id] > ( 4 ) ) ) ,
ADD EVENT sqlserver.buffer_pool_extension_pages_written (
    ACTION ( sqlos.system_thread_id , sqlos.task_resource_pool_id , sqlserver.database_id )
    WHERE ( [sqlserver].[database_id] > ( 4 ) ) ) ,
ADD EVENT sqlserver.buffer_pool_page_allocated (
    ACTION ( sqlos.system_thread_id , sqlos.task_resource_pool_id , sqlserver.database_id )
    WHERE ( [sqlserver].[database_id] > ( 4 ) ) ) ,
ADD EVENT sqlserver.buffer_pool_page_freed (
    ACTION ( sqlos.system_thread_id , sqlos.task_resource_pool_id , sqlserver.database_id )
    WHERE ( [sqlserver].[database_id] > ( 4 ) ) )
ADD TARGET package0.event_file (  SET filename = N'MonitoringBufferPoolExtension' )
WITH (  MAX_MEMORY = 4096 KB
      , EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS
      , MAX_DISPATCH_LATENCY = 5 SECONDS
      , MAX_EVENT_SIZE = 0 KB
      , MEMORY_PARTITION_MODE = NONE
      , TRACK_CAUSALITY = OFF
      , STARTUP_STATE = OFF );

ALTER EVENT SESSION [MonitoringBufferPoolExtension] ON SERVER STATE = START;


