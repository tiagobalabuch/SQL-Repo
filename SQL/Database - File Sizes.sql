/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Individual File Sizes and space available for current database
Original link: 
Obs.: Script was copied from internet

***************************************************************************/

SELECT  f.name AS FileName
      , f.physical_name AS PhysicalName
      , f.type_desc
      , CAST (f.size / 128.0 AS DECIMAL(15 , 2)) AS TotalSizeInMB
      , CAST (f.size / 128.0 - CAST (FILEPROPERTY(f.name , 'SpaceUsed') AS INT) / 128.0 AS DECIMAL(15 , 2)) AS [Available Space In MB]
      , CAST (FILEPROPERTY(f.name , 'SpaceUsed') AS INT) / 128.0 AS SpaceUsedInMB
      , state_desc StateDesc
      , f.file_id
      , fg.name AS FilegroupName
      , CASE WHEN max_size = 0 THEN 'No growth is allowed'
             WHEN max_size = -1 THEN 'File will grow until the disk is full'
             WHEN max_size = 268435456 THEN 'Log file will grow to a maximum size of 2 TB'
             ELSE CONVERT (NVARCHAR , max_size * 8 / 1024)
        END MaxSizeMB
      , CASE WHEN growth = 0 AND
                  f.type <> 2 THEN 'File is fixed size and will not grow'
             ELSE 'File will grow automatically'
        END AS AutomaticOrFixed
      , CASE WHEN is_percent_growth = 0 THEN 'File will grow in MB'
             ELSE 'File will grow in %'
        END AS TypeGrowth
      , CASE WHEN is_percent_growth = 0 THEN growth * 8 / 1024
             ELSE growth
        END AS GrowthSize
FROM    sys.database_files AS f
LEFT OUTER JOIN sys.data_spaces AS fg WITH ( NOLOCK ) ON f.data_space_id = fg.data_space_id
OPTION  ( RECOMPILE );

-- Look at how large and how full the files are and where they are located
-- Make sure the transaction log is not full!!