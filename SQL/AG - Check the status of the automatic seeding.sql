/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Database that is in an AG configured for automatic seeding and check the status of the automatic seeding 
Original link: https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/automatically-initialize-always-on-availability-group
Obs.: Script was copied from internet 
  
***************************************************************************/

SELECT  start_time
      , ag.name
      , db.database_name
      , current_state
      , completion_time
      , performed_seeding
      , failure_state
      , failure_state_desc
FROM    sys.dm_hadr_automatic_seeding autos
JOIN sys.availability_databases_cluster db ON autos.ag_db_id = db.group_database_id
JOIN sys.availability_groups ag ON autos.ag_id = ag.group_id;


SELECT  local_database_name
      , role_desc
      , internal_state_desc
      , transfer_rate_bytes_per_second
      , transferred_size_bytes
      , database_size_bytes
      , start_time_utc
      , end_time_utc
      , estimate_time_complete_utc
      , total_disk_io_wait_time_ms
      , total_network_wait_time_ms
      , is_compression_enabled
FROM    sys.dm_hadr_physical_seeding_stats;