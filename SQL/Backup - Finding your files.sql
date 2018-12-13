/*************************************************************************
Author: Paul S. Randal
Date: 22/09/2017
Description:  Finding backup 
Original link: 
Obs.: Script was copied from internet 
  
***************************************************************************/
USE msdb;
GO

SELECT
    CONVERT( CHAR (100), SERVERPROPERTY( 'Servername' )) AS Server
  , bs.database_name
  , bs.backup_start_date
  , bs.backup_finish_date
  , bs.expiration_date
  , CASE bs.type
        WHEN 'D' THEN 'Database'
        WHEN 'L' THEN 'Log'
    END                                                  AS backup_type
  , bs.backup_size
  , bmf.logical_device_name
  , bmf.physical_device_name
  , bs.name                                              AS backupset_name
  , bs.description
FROM
    dbo.backupmediafamily bmf
INNER JOIN dbo.backupset  bs
    ON bmf.media_set_id = bs.media_set_id
WHERE
    (CONVERT( DATETIME, bs.backup_start_date, 102 ) >= GETDATE() - 80)
    AND bs.database_name = 'your_database'
ORDER BY
    bs.database_name
  , bs.backup_finish_date DESC;