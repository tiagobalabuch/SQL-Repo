/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Total cached pages by object
Original link: 
Obs.: Script was copied from internet
***************************************************************************/

SELECT  COUNT( * ) AS cached_pages_count
      , obj.name
      , obj.index_id
      , ind.name
FROM    sys.dm_os_buffer_descriptors AS bd
INNER JOIN (
               SELECT   OBJECT_NAME( object_id ) AS name
                      , index_id
                      , allocation_unit_id
               FROM sys.allocation_units AS au
               INNER JOIN sys.partitions AS p ON au.container_id = p.hobt_id
                                                 AND (
                                                         au.type = 1
                                                         OR au.type = 3
                                                     )
               UNION ALL
               SELECT   OBJECT_NAME( object_id ) AS name
                      , index_id
                      , allocation_unit_id
               FROM sys.allocation_units AS au
               INNER JOIN sys.partitions AS p ON au.container_id = p.partition_id
                                                 AND au.type = 2
           ) AS obj ON bd.allocation_unit_id = obj.allocation_unit_id
INNER JOIN sys.indexes ind ON ind.index_id = obj.index_id
WHERE   database_id = DB_ID()
GROUP BY obj.name
       , obj.index_id
       , ind.name
ORDER BY cached_pages_count DESC;