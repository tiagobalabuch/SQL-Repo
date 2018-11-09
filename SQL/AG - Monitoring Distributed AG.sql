/*************************************************************************
Author: Tiago
Date: 09/11/2018
Description:  Monitoring Distribuited Availability Groups
Original link: 
Obs.: 
  
***************************************************************************/
-- Show AG basic information
SELECT
    ag.name                AS group_name
  , ar.replica_server_name AS replica_name
  , ar.endpoint_url
  , ar.availability_mode_desc
  , ar.failover_mode_desc
  , ar.seeding_mode_desc   AS seeding_mode
FROM
    sys.availability_replicas AS ar
JOIN sys.availability_groups  AS ag
    ON ag.group_id = ar.group_id;

-- Permission Check
SELECT
    ep.name
  , sp.state
  , CONVERT( NVARCHAR (38), SUSER_NAME( sp.grantor_principal_id )) AS Grantor 
  , sp.type                                                        AS Permission
  , CONVERT( NVARCHAR (46), SUSER_NAME( sp.grantee_principal_id )) AS Grantee
FROM
    sys.server_permissions AS sp
JOIN sys.endpoints         AS ep
    ON sp.major_id = ep.endpoint_id
ORDER BY
    Permission
  , Grantor
  , Grantee;

  -- Should be CONNECTED and HEALTHY (It might be in NOT HEALTHY while you are restoring/synchronizing databases but must be CONNECTED)
SELECT
    r.replica_server_name
  , r.endpoint_url
  , rs.connected_state_desc
  , rs.role_desc
  , rs.operational_state_desc
  , rs.recovery_health_desc
  , rs.synchronization_health_desc
  , r.availability_mode_desc
  , r.failover_mode_desc
FROM
    sys.dm_hadr_availability_replica_states rs
INNER JOIN sys.availability_replicas        r
    ON rs.replica_id = r.replica_id
ORDER BY
    r.replica_server_name;

-- Author:  Tracy Boggiano
-- https://tracyboggiano.com/archive/2017/11/distributed-availability-groups-setup-and-monitoring/
-- shows current_state of distributed AG
SELECT
    ag.name                AS Distributed_AG
  , ar.replica_server_name AS AvailabilityGroup
  , dbs.name               AS DatabaseName
  , ars.role_desc
  , drs.synchronization_health_desc
  , drs.log_send_queue_size
  , drs.log_send_rate
  , drs.redo_queue_size
  , drs.redo_rate
  , drs.suspend_reason_desc
  , drs.last_sent_time
  , drs.last_received_time
  , drs.last_hardened_time
  , drs.last_redone_time
  , drs.last_commit_time
  , drs.secondary_lag_seconds
FROM
    sys.databases                                  dbs
INNER JOIN sys.dm_hadr_database_replica_states     drs
    ON dbs.database_id = drs.database_id
INNER JOIN sys.availability_groups                 ag
    ON drs.group_id = ag.group_id
INNER JOIN sys.dm_hadr_availability_replica_states ars
    ON ars.replica_id = drs.replica_id
INNER JOIN sys.availability_replicas               ar
    ON ar.replica_id = ars.replica_id
WHERE
    ag.is_distributed = 1;

-- shows current_state of seeding 
SELECT
    ag.name                AS Distributed_AG
  , ar.replica_server_name AS AvailabilityGroup
  , d.name                 AS DatabaseName
  , has.current_state
  , has.failure_state_desc
  , has.error_code
  , has.performed_seeding
  , has.start_time
  , has.completion_time
  , has.number_of_attempts
FROM
    sys.dm_hadr_automatic_seeding AS has
JOIN sys.availability_groups      AS ag
    ON ag.group_id = has.ag_id
JOIN sys.availability_replicas    AS ar
    ON ar.replica_id = has.ag_remote_replica_id
JOIN sys.databases                AS d
    ON d.group_database_id = has.ag_db_id
ORDER BY
    has.start_time DESC;

-- While seeding process is happing this DMV shows good information about it
SELECT
    database_size_bytes / 1024 / 1024 / 1024     AS DatabaseSizeGB
  , transferred_size_bytes / 1024 / 1024 / 1024  AS TranseferedSizeGB
  , transfer_rate_bytes_per_second / 1024 / 1024 AS transferRateMB -- Keep eyes on it 
  , local_database_name
  , remote_machine_name
  , role_desc
  , internal_state_desc
  , transfer_rate_bytes_per_second
  , transferred_size_bytes
  , database_size_bytes
  , estimate_time_complete_utc
  , failure_message
  , failure_code
  , failure_time_utc
  , is_compression_enabled
FROM
    sys.dm_hadr_physical_seeding_stats;


-- Backup/Restore Throughput/sec

IF OBJECT_ID( 'tempdb..#Seeding' ) IS NOT NULL
    BEGIN
        DROP TABLE #Seeding;
    END;

SELECT
    GETDATE() AS CollectionTime
  , instance_name
  , cntr_value
INTO
    #Seeding
FROM
    sys.dm_os_performance_counters
WHERE
    counter_name = 'Backup/Restore Throughput/sec';

WAITFOR DELAY '00:00:05';

SELECT
    LTRIM( RTRIM( p2.instance_name ))                                                                   AS DatabaseName
  , (p2.cntr_value - p1.cntr_value) / (DATEDIFF( SECOND, p1.CollectionTime, GETDATE()))                 AS ThroughputBytesSec
  , ((p2.cntr_value - p1.cntr_value) / (DATEDIFF( SECOND, p1.CollectionTime, GETDATE()))) / 1024 / 1024 AS ThroughputMBSec
FROM
    sys.dm_os_performance_counters AS p2
INNER JOIN #Seeding                AS p1
    ON p2.instance_name = p1.instance_name
WHERE
    p2.counter_name LIKE 'Backup/Restore Throughput/sec%';


-- Checking seeding failures (most cases I've seen they are running this command)
SELECT
    r.command
  , r.wait_type
  , r.wait_resource
  , r.scheduler_id
FROM
    sys.dm_exec_requests  AS r
JOIN sys.dm_os_schedulers AS s
    ON s.scheduler_id = r.scheduler_id
WHERE
    r.command = 'VDI_CLIENT_WORKER'
    AND s.status = 'VISIBLE ONLINE';


-- Checking REDO threads
SELECT
    r.command
  , r.status
  , r.wait_type
  , r.wait_time
  , r.last_wait_type
  , r.scheduler_id
FROM
    sys.dm_exec_requests AS r
WHERE
    r.command LIKE '%REDO%'
ORDER BY
    r.scheduler_id;