/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Partition Schema & Function information 
Original link: 
Obs.: I created this script
  
***************************************************************************/

SELECT  p.partition_number AS PartitionNumber
      , OBJECT_NAME( p.object_id ) AS TableName
      , i.name AS IndexName
      , c.name AS PartitionColumn
      , p.rows
      , p.data_compression_desc
      , ps.name AS PartitionScheme
      , pf.name AS PartitionFunction
      , fg.name AS FileGroupName
      , prv.value AS PartitionValueBoundary
      , CASE pf.boundary_value_on_right
            WHEN 1 THEN 'RIGHT / Lower'
            ELSE 'LEFT / Upper'
        END AS SideBoundary
      , df.physical_name AS DatabaseFileName
      , au.total_pages / 128.0 AS TotalTableSizeInMB
      , au.used_pages / 128.0 AS UsedSizeInMB
      , au.data_pages / 128.0 AS DataSizeInMB
      , stat.in_row_reserved_page_count * 8. / 1024. / 1024.0 AS [In-Row GB]
      , stat.lob_reserved_page_count * 8. / 1024. / 1024.0 AS [LOB GB]
FROM    sys.indexes i
INNER JOIN sys.index_columns ic ON ic.partition_ordinal > 0
                                   AND  ic.index_id = i.index_id
                                   AND  ic.object_id = i.object_id
INNER JOIN sys.columns c ON c.object_id = ic.object_id
                            AND c.column_id = ic.column_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id
                               AND  i.index_id = p.index_id
                               AND  p.index_id = ic.index_id
                               AND  p.object_id = c.object_id
                               AND  p.object_id = ic.object_id
INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
INNER JOIN sys.partition_functions pf ON pf.function_id = ps.function_id
LEFT JOIN sys.partition_range_values prv ON prv.function_id = pf.function_id
                                            AND prv.boundary_id = p.partition_number
                                            AND prv.function_id = ps.function_id
INNER JOIN sys.allocation_units au ON au.container_id = p.hobt_id --AND au.data_space_id = i.data_space_id
INNER JOIN sys.filegroups fg ON fg.data_space_id = au.data_space_id
INNER JOIN sys.database_files df ON fg.data_space_id = df.data_space_id
INNER JOIN sys.data_spaces ds ON fg.data_space_id = ds.data_space_id
INNER JOIN sys.dm_db_partition_stats AS stat ON stat.object_id = p.object_id
                                                AND stat.index_id = p.index_id
                                                AND stat.index_id = p.index_id
                                                AND stat.partition_id = p.partition_id
                                                AND stat.partition_number = p.partition_number
WHERE   OBJECTPROPERTY( i.object_id, 'IsUserTable' ) = 1
        -- AND i.object_id = OBJECT_ID( 'table name' )
        AND au.type IN ( 1, 3 );

