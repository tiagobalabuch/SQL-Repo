
/*************************************************************************
Autor: Tiago Balabuch
Data : 03/09/2014
Descrição: Look at recent Full backups for the current database  
Obs: SQL Server 2012 Diagnostic Information Queries

***************************************************************************/
/*************************************************************************
Author: Glenn Berry 
Date: 22/09/2017
Description: Look at recent Full backups for the current database
Original link: 
Obs.: Script was copied from internet
  Last Modified: September 22, 2014  
 (Query 69) (Recent Full Backups)
***************************************************************************/

--  (Query 69) (Recent Full Backups)

SELECT TOP ( 30 )
    bs.machine_name
  , bs.server_name
  , bs.database_name AS [Database Name]
  , bs.recovery_model
  , CASE bs.type
        WHEN 'D' THEN 'Database'
        WHEN 'L' THEN 'Log'
    END AS backup_type
  , CONVERT( BIGINT, bs.backup_size / 1048576 ) AS [Uncompressed Backup Size (MB)]
  , CONVERT( BIGINT, bs.compressed_backup_size / 1048576 ) AS [Compressed Backup Size (MB)]
  , CONVERT( NUMERIC (20, 2), CONVERT( FLOAT, bs.backup_size ) / CONVERT( FLOAT, bs.compressed_backup_size )) AS [Compression Ratio]
  , DATEDIFF( SECOND, bs.backup_start_date, bs.backup_finish_date ) AS [Backup Elapsed Time (sec)]
  , DATEDIFF( MINUTE, bs.backup_start_date, bs.backup_finish_date ) AS [Backup Elapsed Time (min)]
  , bs.backup_start_date AS [Backup Start Date]
  , bs.backup_finish_date AS [Backup Finish Date]
  , bf.logical_device_name AS [Logical Device]
  , bf.physical_device_name AS [Physical Device]
  , bs.name AS backupset_name
  , bs.description
FROM    msdb.dbo.backupset AS bs WITH ( NOLOCK )
INNER JOIN msdb.dbo.backupmediafamily bf ON bf.media_set_id = bs.media_set_id
WHERE   DATEDIFF( SECOND, bs.backup_start_date, bs.backup_finish_date ) > 0
        AND bs.backup_size > 0
        AND bs.type IN ( 'D', 'I' )
        -- Change to L if you want Log backups
        AND database_name = DB_NAME( DB_ID())
ORDER BY bs.backup_finish_date DESC
OPTION ( RECOMPILE );