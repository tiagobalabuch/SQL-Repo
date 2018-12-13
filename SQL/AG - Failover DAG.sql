 -- both the global primary and the forwarder
 
 ALTER AVAILABILITY GROUP [DAG_AG1] 
 MODIFY 
 AVAILABILITY GROUP ON
 'AG1' WITH 
  ( 
  AVAILABILITY_MODE = SYNCHRONOUS_COMMIT 
  ), 
  'NEW_AG1' WITH  
  ( 
  
  AVAILABILITY_MODE = SYNCHRONOUS_COMMIT );


-- verifies the commit state of the distributed availability group
SELECT
    ag.name
  , ag.is_distributed
  , ar.replica_server_name
  , ar.availability_mode_desc
  , ars.connected_state_desc
  , ars.role_desc
  , ars.operational_state_desc
  , ars.synchronization_health_desc
FROM
    sys.availability_groups                       ag
JOIN sys.availability_replicas                    ar
    ON ag.group_id = ar.group_id
LEFT JOIN sys.dm_hadr_availability_replica_states ars
    ON ars.replica_id = ar.replica_id
WHERE
    ag.is_distributed = 1;
GO

 -- Wait until the status of the distributed availability group has changed to SYNCHRONIZED
 -- If synchronization_state_desc is not SYNCHRONIZED, run the command every five seconds until it changes. 
 -- Do not proceed until the synchronization_state_desc = SYNCHRONIZED
 
SELECT
    ag.name
  , drs.database_id
  , drs.group_id
  , drs.replica_id
  , drs.synchronization_state_desc
  , drs.end_of_log_lsn
FROM
    sys.dm_hadr_database_replica_states drs
INNER JOIN sys.availability_groups      ag
    ON drs.group_id = ag.group_id;

/**********************************

On the global primary, set the distributed availability group role to SECONDARY
At this point, the distributed availability group is not available.
************************************/

ALTER AVAILABILITY GROUP [DAG_AG1] SET (ROLE = SECONDARY);

--Test the failover readiness
SELECT
    ag.name
  , drs.database_id
  , drs.group_id
  , drs.replica_id
  , drs.synchronization_state_desc
  , drs.end_of_log_lsn
FROM
    sys.dm_hadr_database_replica_states drs
INNER JOIN sys.availability_groups      ag
    ON drs.group_id = ag.group_id;

/**********************************

Fail over from the primary availability group to the secondary availability group
Run it from corp server

************************************/

ALTER AVAILABILITY GROUP [DAG_AG1] FORCE_FAILOVER_ALLOW_DATA_LOSS;


 -- both the global primary and the forwarder

 ALTER AVAILABILITY GROUP [DAG_AG1] 
 MODIFY 
 AVAILABILITY GROUP ON
 'AG1' WITH 
  ( 
  AVAILABILITY_MODE = SYNCHRONOUS_COMMIT 
  ), 
  'NEW_AG1' WITH  
  ( 
  
  AVAILABILITY_MODE = SYNCHRONOUS_COMMIT );