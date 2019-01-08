/*************************************************************************
Author: Tiag Balabuch
Date: 13/12/2018
Description:  Cheking backup preferences
Original link: 
Obs.:  
  
***************************************************************************/

SELECT
    ag.name
  , ar.replica_server_name AS primary_server_role
  , ar.availability_mode_desc
  , ar.failover_mode_desc
  , ar.secondary_role_allow_connections_desc
  , ar.backup_priority
  , ag.automated_backup_preference_desc
  , CASE
        WHEN ar.backup_priority = 0 THEN 'Yes'
        ELSE 'No'
    END                    AS exclude_replica
FROM
    sys.availability_replicas      AS ar
INNER JOIN sys.availability_groups AS ag
    ON ar.group_id = ag.group_id
--WHERE
--    ag.name = 'AG_TEST';