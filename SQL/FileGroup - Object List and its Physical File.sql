/*************************************************************************
Author: Unknown
Date : 22/09/2017
Description: Object List and its File Groups and Physical File
Original link: 
Obs.: Script was copied from internet

***************************************************************************/

SELECT  fg.name Filegroup
      , OBJECT_NAME( i.object_id ) AS TableName
      , o.type_desc AS Type
      , SCHEMA_NAME( o.schema_id ) AS SchemaName
      , i.name AS IndexName
      , df.physical_name AS PhysicalFile
FROM    sys.indexes i
INNER JOIN sys.partitions p ON i.object_id = p.object_id
                               AND  i.index_id = p.index_id
INNER JOIN sys.allocation_units au ON p.hobt_id = au.container_id
INNER JOIN sys.filegroups fg ON au.data_space_id = fg.data_space_id
INNER JOIN sys.database_files df ON fg.data_space_id = df.data_space_id
INNER JOIN sys.objects o ON i.object_id = o.object_id
WHERE   o.type <> 'IT'
        AND o.type <> 'S';
