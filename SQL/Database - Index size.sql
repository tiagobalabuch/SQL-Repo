/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Get table size from heap or clustered index and modified
Original link: 
Obs.: Script was copied from internet

***************************************************************************/
SELECT  t.name AS TableName
      , s.name AS SchemaName
      , i.name AS IndexName
      , i.type_desc
      , SUM( p.rows ) AS RowCounts
      , p.data_compression_desc AS CompressionType
      , SUM( a.total_pages ) * 8 AS TotalSpaceKB
      , CAST(ROUND((( SUM( a.total_pages ) * 8 ) / 1024.00 ), 2 ) AS NUMERIC (36, 2)) AS TotalSpaceMB
      , SUM( a.used_pages ) * 8 AS UsedSpaceKB
      , CAST(ROUND((( SUM( a.used_pages ) * 8 ) / 1024.00 ), 2 ) AS NUMERIC (36, 2)) AS UsedSpaceMB
      , ( SUM( a.total_pages ) - SUM( a.used_pages )) * 8 AS UnusedSpaceKB
      , CAST(ROUND((( SUM( a.total_pages ) - SUM( a.used_pages )) * 8 ) / 1024.00, 2 ) AS NUMERIC (36, 2)) AS UnusedSpaceMB
FROM    sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id
                               AND  i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE   t.name NOT LIKE 'dt%'
        AND t.is_ms_shipped = 0
        AND i.object_id > 255
        AND a.type IN ( 1, 3 )
GROUP BY t.name
       , s.name
       , i.name
       , i.type_desc
       , data_compression_desc
ORDER BY t.name;