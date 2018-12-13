/*************************************************************************
Author: Tiag Balabuch
Date: 13/12/2018
Description:  Cheking AG seeding
Original link: 
Obs.:  
  
***************************************************************************/

/*
	Getting information about how AG is set up
*/
USE master;
GO

SELECT
    AG.name                AS group_name
  , AR.replica_server_name AS replica_name
  , AR.endpoint_url
  , AR.availability_mode_desc
  , AR.failover_mode_desc
  , AR.seeding_mode_desc   AS seeding_mode
  , AG.is_distributed
FROM
    sys.availability_replicas AS AR
JOIN sys.availability_groups  AS AG
    ON AR.group_id = AG.group_id;

/*
	Seeding history information 
*/
SELECT
    start_time
  , completion_time
  , current_state
  , performed_seeding
  , failure_state_desc
  , error_code
  , number_of_attempts
FROM
    sys.dm_hadr_automatic_seeding
ORDER BY
    completion_time DESC;

/*
	how seeding operationg is performing 
*/
SELECT
    local_database_name
  , remote_machine_name
  , role_desc
  , internal_state_desc
  , transfer_rate_bytes_per_second
  , transferred_size_bytes
  , database_size_bytes
  , estimate_time_complete_utc
  , failure_message
  , failure_time_utc
  , is_compression_enabled
FROM
    sys.dm_hadr_physical_seeding_stats;


/*
	XE can help you monitor 
*/
CREATE EVENT SESSION [AG_autoseed]
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
    (SET filename = N'autoseed.xel', max_file_size = (5), max_rollover_files = (4))
WITH (MAX_MEMORY = 4096KB
    , EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS
    , MAX_DISPATCH_LATENCY = 30 SECONDS
    , MAX_EVENT_SIZE = 0KB
    , MEMORY_PARTITION_MODE = NONE
    , TRACK_CAUSALITY = OFF
    , STARTUP_STATE = ON);
GO

ALTER EVENT SESSION AlwaysOn_autoseed ON SERVER STATE = START;
GO