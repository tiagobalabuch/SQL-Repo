/*************************************************************************
Author: Tiag Balabuch
Date: 13/12/2018
Description:  Cheking listener
Original link: 
Obs.:  
  
***************************************************************************/

USE master;
GO

SELECT
    agl.dns_name
  , aglip.state_desc
  , aglip.state
  , aglip.ip_address
  , aglip.ip_subnet_mask
  , aglip.is_dhcp
  , aglip.network_subnet_ip
  , aglip.network_subnet_ipv4_mask
  , agl.port
  , agl.is_conformant
  , agl.ip_configuration_string_from_cluster
  , tls.ip_address
  , tls.is_ipv4
  , tls.type
  , tls.type_desc
  , tls.start_time
FROM
    sys.availability_group_listener_ip_addresses aglip
JOIN sys.availability_group_listeners            agl
    ON agl.listener_id = aglip.listener_id
JOIN sys.dm_tcp_listener_states                  tls
    ON tls.ip_address = aglip.ip_address;


SELECT
    ag.name                             AS [AG Name]
  , ar.replica_server_name              AS [Replica Instance]
  , dr_state.database_id                AS [Database ID]
  , Location                            = CASE
                                              WHEN ar_state.is_local = 1 THEN N'LOCAL'
                                              ELSE 'REMOTE'
                                          END
  , Role                                = CASE
                                              WHEN ar_state.role_desc IS NULL THEN N'DISCONNECTED'
                                              ELSE ar_state.role_desc
                                          END
  , ar_state.connected_state_desc       AS [Connection State]
  , ar.availability_mode_desc           AS Mode
  , dr_state.synchronization_state_desc AS State
  , ar.secondary_role_allow_connections_desc
FROM
    sys.availability_groups                  AS ag
JOIN sys.availability_replicas               AS ar
    ON ag.group_id = ar.group_id
JOIN sys.dm_hadr_availability_replica_states AS ar_state
    ON ar.replica_id = ar_state.replica_id
JOIN sys.dm_hadr_database_replica_states     dr_state
    ON ag.group_id = dr_state.group_id
       AND dr_state.replica_id = ar_state.replica_id;

SELECT
    ag.name
  , ar.replica_server_name                         AS primary_server_role
  , (   SELECT
            b.replica_server_name
        FROM
            sys.availability_replicas AS b
        WHERE
            b.replica_id = a.read_only_replica_id) AS secondary_route_reader_server
  , a.routing_priority
  , ar.availability_mode_desc
  , ar.failover_mode_desc
  , ar.secondary_role_allow_connections_desc
FROM
    sys.availability_read_only_routing_lists AS a
RIGHT JOIN sys.availability_replicas         AS ar
    ON a.replica_id = ar.replica_id
INNER JOIN sys.availability_groups           AS ag
    ON ar.group_id = ag.group_id
WHERE
    ag.name = 'AG1';