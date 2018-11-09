
/*************************************************************************
Author: Louis Davidson and Tim Ford
Date: 09/11/2018
Description:  Tune your Indexes Strategy
Original link: https://www.red-gate.com/simple-talk/sql/performance/tune-your-indexing-strategy-with-sql-server-dmvs/
Obs.: Scrip was copied from internet
  
***************************************************************************/

-- How old are the index usage stats?
SELECT
    DATEDIFF( DAY, si.sqlserver_start_time, GETDATE()) AS days_history
FROM
    sys.dm_os_sys_info si;

-- Usage stats for indexes used to resolve a query
SELECT
    OBJECT_NAME( ddius.object_id )                           AS table_name
  , ddius.index_id
  , i.name                                                   AS index_name
  , i.type_desc                                              AS index_type
  , ddius.user_seeks
  , ddius.user_scans
  , ddius.user_lookups
  , ddius.user_seeks + ddius.user_scans + ddius.user_lookups AS user_reads
  , ddius.user_updates                                       AS user_writes
  , CASE
        WHEN (ddius.user_seeks > 0 OR ddius.user_scans > 0 OR ddius.user_lookups > 0)
             AND ddius.user_updates > 0 THEN 'USED AND UPDATED'
        WHEN (ddius.user_seeks > 0 OR ddius.user_scans > 0 OR ddius.user_lookups > 0)
             AND ddius.user_updates = 0 THEN 'USED AND NOT UPDATED'
        WHEN ddius.user_seeks IS NULL
             AND ddius.user_scans IS NULL
             AND ddius.user_lookups IS NULL
             AND ddius.user_updates IS NULL THEN 'NOT USED AND NOT UPDATED'
        WHEN (ddius.user_seeks = 0 AND ddius.user_scans = 0 AND ddius.user_lookups = 0)
             AND ddius.user_updates > 0 THEN 'NOT USED AND UPDATED'
        ELSE 'NONE OF THE ABOVE'
    END                                                      AS Usage_Info
  , ddius.last_user_scan
  , ddius.last_user_update
FROM
    sys.dm_db_index_usage_stats ddius
INNER JOIN sys.indexes          i
    ON i.index_id = ddius.index_id
       AND i.object_id = ddius.object_id
WHERE
    ddius.database_id > 4 -- filter out system tables
    AND OBJECTPROPERTY( ddius.object_id, 'IsUserTable' ) = 1
	AND ddius.index_id > 0 -- filter out heaps
--AND ddius.object_id IN ( OBJECT_ID( 'your table' ))
ORDER BY
    OBJECT_NAME( ddius.object_id, ddius.database_id )
  , ddius.index_id;

-- Potentially inefficent non-clustered indexes (writes > reads)
SELECT
    OBJECT_NAME( ddius.object_id )                                                  AS [Table Name]
  , i.name                                                                          AS [Index Name]
  , i.index_id
  , ddius.user_updates                                                              AS [Total Writes]
  , ddius.user_seeks + ddius.user_scans + ddius.user_lookups                        AS [Total Reads]
  , ddius.user_updates - (ddius.user_seeks + ddius.user_scans + ddius.user_lookups) AS Difference
FROM
    sys.dm_db_index_usage_stats AS ddius
INNER JOIN sys.indexes          AS i
    ON ddius.object_id = i.object_id
       AND i.index_id = ddius.index_id
WHERE
    OBJECTPROPERTY( ddius.object_id, 'IsUserTable' ) = 1
    AND ddius.database_id = DB_ID()
    AND ddius.user_updates > (ddius.user_seeks + ddius.user_scans + ddius.user_lookups)
    AND i.index_id > 1
    AND i.object_id IN ( OBJECT_ID( 'your table' ))
ORDER BY
    OBJECT_NAME( ddius.object_id )
  , Difference DESC
  , [Total Writes] DESC
  , [Total Reads] ASC;


-- Detailed activity information for indexes not used for user reads
SELECT
    o.name
  , i.name                                                   AS index_name
  , ddios.partition_number                                   AS partition_number
  , ddius.user_seeks + ddius.user_scans + ddius.user_lookups AS user_reads
  , ddius.user_updates                                       AS user_writes
  , ddios.leaf_insert_count
  , ddios.leaf_delete_count
  , ddios.leaf_update_count
  , ddios.leaf_ghost_count
  , ddios.leaf_page_merge_count
  , ddios.nonleaf_page_merge_count
  , ddios.nonleaf_insert_count
  , ddios.nonleaf_delete_count
  , ddios.nonleaf_update_count
  , ddios.leaf_allocation_count
  , ddios.nonleaf_allocation_count
  , ddios.singleton_lookup_count
  , ddios.page_compression_attempt_count
  , ddios.page_compression_success_count
FROM
    sys.dm_db_index_usage_stats                                           ddius
INNER JOIN sys.indexes                                                    i
    ON ddius.object_id = i.object_id
       AND i.index_id = ddius.index_id
INNER JOIN sys.partitions                                                 SP
    ON ddius.object_id = SP.object_id
       AND SP.index_id = ddius.index_id
INNER JOIN sys.objects                                                    o
    ON ddius.object_id = o.object_id
INNER JOIN sys.dm_db_index_operational_stats( DB_ID(), NULL, NULL, NULL ) AS ddios
    ON ddius.index_id = ddios.index_id
       AND ddius.object_id = ddios.object_id
       AND SP.partition_number = ddios.partition_number
       AND ddius.database_id = ddios.database_id
WHERE
    OBJECTPROPERTY( ddius.object_id, 'IsUserTable' ) = 1
    AND ddius.index_id > 0
    AND ddius.user_seeks + ddius.user_scans + ddius.user_lookups = 0
    AND i.object_id IN ( OBJECT_ID( 'your table' ))
ORDER BY
    o.name
  , ddius.user_updates DESC
  , i.name;

-- Indexes fragmentation

SELECT
    OBJECT_NAME( i.object_id )                     AS table_name
  , i.name                                         AS index_name
  , i.type_desc                                    AS index_type
  , ips.partition_number                           AS partition_number
  , ROUND( ips.avg_fragmentation_in_percent, 2 )   AS total_fragmentation
  , ROUND( ips.avg_page_space_used_in_percent, 2 ) AS page_fullness
  , ROUND( ips.avg_record_size_in_bytes, 0 )       AS average_row_size
  , ips.index_depth                                AS depth
  , ips.ghost_record_count                         AS ghost_rows
  , ips.version_ghost_record_count                 AS version_ghost_rows
  , ips.forwarded_record_count                     AS forwarded_record
  , ips.record_count                               AS leaf_level_rows
  , ips.min_record_size_in_bytes                   AS min_row_size
  , ips.max_record_size_in_bytes                   AS max_row_size
  , ips.page_count                                 AS page_count
  , ips.alloc_unit_type_desc                       AS alloc_unit_type
FROM
    sys.dm_db_index_physical_stats( DB_ID(), OBJECT_ID( 'controller_block' ), NULL, NULL, 'DETAILED' ) AS ips
INNER JOIN sys.indexes                                                                                 AS i
    ON i.object_id = ips.object_id
       AND ips.index_id = i.index_id
WHERE
    ips.index_level = 0;

-- Retrieving locking and blocking details for each index
SELECT
    o.name                                                                               AS table_name
  , i.name                                                                               AS index_name
  , ddios.partition_number
  , ddios.row_lock_count
  , ddios.row_lock_wait_count
  , CAST(100.0 * ddios.row_lock_wait_count / (ddios.row_lock_count) AS DECIMAL (5, 2))   AS [%_times_blocked]
  , ddios.row_lock_wait_in_ms
  , CAST(1.0 * ddios.row_lock_wait_in_ms / ddios.row_lock_wait_count AS DECIMAL (15, 2)) AS avg_row_lock_wait_in_ms
FROM
    sys.dm_db_index_operational_stats( DB_ID(), NULL, NULL, NULL ) ddios
INNER JOIN sys.indexes                                             i
    ON ddios.object_id = i.object_id
       AND i.index_id = ddios.index_id
INNER JOIN sys.objects                                             o
    ON ddios.object_id = o.object_id
WHERE
    ddios.row_lock_wait_count > 0
    AND OBJECTPROPERTY( ddios.object_id, 'IsUserTable' ) = 1
    AND i.index_id > 0
    AND i.object_id IN ( OBJECT_ID( 'your table' ))
ORDER BY
    ddios.row_lock_wait_count DESC
  , o.name
  , i.name;

-- Investigating latch waits
SELECT
    OBJECT_NAME( i.object_id )                                        AS table_name
  , i.name                                                            AS index_name
  , ddios.page_io_latch_wait_count
  , ddios.page_io_latch_wait_in_ms
  , (ddios.page_io_latch_wait_in_ms / ddios.page_io_latch_wait_count) AS avg_page_io_latch_wait_in_ms
FROM
    sys.dm_db_index_operational_stats( DB_ID(), NULL, NULL, NULL ) ddios
INNER JOIN sys.indexes                                             i
    ON ddios.object_id = i.object_id
       AND i.index_id = ddios.index_id
WHERE
    ddios.page_io_latch_wait_count > 0
    AND OBJECTPROPERTY( i.object_id, 'IsUserTable' ) = 1
    AND i.object_id IN ( OBJECT_ID( 'your table' ))
ORDER BY
    OBJECT_NAME( i.object_id )
  , ddios.page_io_latch_wait_count DESC
  , avg_page_io_latch_wait_in_ms DESC;


-- Identify lock escalations
SELECT
    OBJECT_NAME( ddios.object_id, ddios.database_id )                                     AS object_name
  , i.name                                                                                AS index_name
  , ddios.index_id
  , ddios.partition_number
  , ddios.index_lock_promotion_attempt_count
  , ddios.index_lock_promotion_count
  , ((ddios.index_lock_promotion_count * 100) / ddios.index_lock_promotion_attempt_count) AS percent_success
FROM
    sys.dm_db_index_operational_stats( DB_ID(), NULL, NULL, NULL ) ddios
INNER JOIN sys.indexes                                             i
    ON ddios.object_id = i.object_id
       AND ddios.index_id = i.index_id
WHERE
    ddios.index_lock_promotion_count > 0
    AND i.object_id IN ( OBJECT_ID( 'your table' ))
ORDER BY
    OBJECT_NAME( ddios.object_id, ddios.database_id );

-- Finding the most beneficial missing indexes
SELECT
    dbmigs.user_seeks * dbmigs.avg_total_user_cost * (dbmigs.avg_user_impact * 0.01) AS index_advantage
  , dbmigs.last_user_seek
  , OBJECT_NAME( dbmid.object_id )                                                   AS table_name
  , dbmid.equality_columns
  , dbmid.inequality_columns
  , dbmid.included_columns
  , dbmigs.unique_compiles
  , dbmigs.user_seeks
  , dbmigs.avg_total_user_cost
  , dbmigs.avg_user_impact
FROM
    sys.dm_db_missing_index_group_stats    AS dbmigs
INNER JOIN sys.dm_db_missing_index_groups  AS dbmig
    ON dbmigs.group_handle = dbmig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS dbmid
    ON dbmig.index_handle = dbmid.index_handle
WHERE
    dbmid.database_id = DB_ID()
    AND dbmid.object_id IN ( OBJECT_ID( 'your table' ))
ORDER BY
    dbmid.object_id
  , index_advantage DESC;

-- Index Fragmentation information
SELECT
    OBJECT_NAME( i.object_id )                     AS table_name
  , i.name                                         AS index_name
  , i.type_desc                                    AS index_type
  , ROUND( ips.avg_fragmentation_in_percent, 2 )   AS total_fragmentation
  , ROUND( ips.avg_page_space_used_in_percent, 2 ) AS page_fullness
  , ROUND( ips.avg_record_size_in_bytes, 0 )       AS average_row_size
  , ips.index_depth                                AS depth
  , ips.ghost_record_count                         AS ghost_rows
  , ips.version_ghost_record_count                 AS version_ghost_rows
  , ips.forwarded_record_count                     AS forwarded_record
  , ips.record_count                               AS leaf_level_rows
  , ips.min_record_size_in_bytes                   AS min_row_size
  , ips.max_record_size_in_bytes                   AS max_row_size
  , ips.page_count                                 AS page_count
  , ips.alloc_unit_type_desc                       AS alloc_unit_type
FROM
    sys.dm_db_index_physical_stats( DB_ID(), OBJECT_ID( 'your table' ), NULL, NULL, 'DETAILED' ) AS ips
INNER JOIN sys.indexes                                                                           AS i
    ON i.object_id = ips.object_id
       AND ips.index_id = i.index_id
WHERE
    ips.index_level = 0;
