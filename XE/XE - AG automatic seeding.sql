/*************************************************************************
Author: Tiago Balabuch
Date : 22/09/2017
Description: Using XE to capture events related to automatic seeding 
Original link: https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/automatically-initialize-always-on-availability-group
Obs.: Script was copied from internet

***************************************************************************/



IF EXISTS (
              SELECT    *
              FROM  sys.server_event_sessions
              WHERE [name] = N'AlwaysOn_autoseed'
          )
    DROP EVENT SESSION [AlwaysOn_autoseed] ON SERVER;
GO


CREATE EVENT SESSION [AlwaysOn_autoseed]
    ON SERVER
    ADD EVENT sqlserver.hadr_automatic_seeding_state_transition
  , ADD EVENT sqlserver.hadr_automatic_seeding_timeout
  , ADD EVENT sqlserver.hadr_db_manager_seeding_request_msg
  , ADD EVENT sqlserver.hadr_physical_seeding_backup_state_change
  , ADD EVENT sqlserver.hadr_physical_seeding_failure
  , ADD EVENT sqlserver.hadr_physical_seeding_forwarder_state_change
  , ADD EVENT sqlserver.hadr_physical_seeding_forwarder_target_state_change
  , ADD EVENT sqlserver.hadr_physical_seeding_progress
  , ADD EVENT sqlserver.hadr_physical_seeding_restore_state_change
  , ADD EVENT sqlserver.hadr_physical_seeding_submit_callback
    ADD TARGET package0.event_file
    ( SET filename = N'autoseed.xel', max_file_size = ( 5 ), max_rollover_files = ( 4 ))
    WITH (
             MAX_MEMORY = 4096KB
           , EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS
           , MAX_DISPATCH_LATENCY = 30 SECONDS
           , MAX_EVENT_SIZE = 0KB
           , MEMORY_PARTITION_MODE = NONE
           , TRACK_CAUSALITY = OFF
           , STARTUP_STATE = OFF
         );


ALTER EVENT SESSION AlwaysOn_autoseed ON SERVER STATE = START;