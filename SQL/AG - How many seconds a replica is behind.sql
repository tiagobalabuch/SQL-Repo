/*************************************************************************
Author: Tiag Balabuch
Date: 13/12/2018
Description:  Following is the script to find out how many seconds a SYNCHRONIZING replica is behind the primary replica.
Original link: 
Obs.:  Script was copied from internet
  
***************************************************************************/


-- 

WITH PR (database_id, last_commit_time)
AS
    (
    SELECT
        dr_state.database_id AS database_id
      , dr_state.last_commit_time
    FROM((sys.availability_groups  AS ag
    JOIN sys.availability_replicas AS ar
        ON ag.group_id = ar.group_id)
    JOIN sys.dm_hadr_availability_replica_states AS ar_state
        ON ar.replica_id = ar_state.replica_id)
    JOIN sys.dm_hadr_database_replica_states dr_state
        ON ag.group_id = dr_state.group_id
           AND dr_state.replica_id = ar_state.replica_id
    WHERE
        ar_state.role = 1
    )
SELECT
    ar.replica_server_name                                        AS ReplicaInstance
  , dr_state.database_id                                          AS DatabaseID
  , DATEDIFF( s, dr_state.last_commit_time, PR.last_commit_time ) AS SecondsBehindPrimary
FROM((sys.availability_groups  AS ag
JOIN sys.availability_replicas AS ar
    ON ag.group_id = ar.group_id)
JOIN sys.dm_hadr_availability_replica_states AS ar_state
    ON ar.replica_id = ar_state.replica_id)
JOIN sys.dm_hadr_database_replica_states dr_state
    ON ag.group_id = dr_state.group_id
       AND dr_state.replica_id = ar_state.replica_id
JOIN PR
    ON PR.database_id = dr_state.database_id
WHERE
    ar_state.role <> 1
    AND dr_state.synchronization_state = 1;


SELECT
    rs.replica_server_name
  , r.role_desc
  , s.database_name
  , s.is_failover_ready
FROM
    sys.dm_hadr_database_replica_cluster_states            s
INNER JOIN sys.dm_hadr_availability_replica_states         r
    ON s.replica_id = r.replica_id
INNER JOIN sys.dm_hadr_availability_replica_cluster_states rs
    ON rs.replica_id = s.replica_id;