/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Backup size information
Original link: 
Obs.:
  
***************************************************************************/
SELECT  database_name
      , backup_size / compressed_backup_size AS Ratio
      , backup_size / 1024 / 1024 / 1024 AS backup_size_GB
      , compressed_backup_size / 1024 / 1024 / 1024 AS compressed_backup_size_MB
FROM    msdb..backupset
WHERE   type = 'D'
        --AND database_name = 'yourd db'
ORDER BY backup_start_date DESC;
