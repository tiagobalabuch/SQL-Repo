/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: List basic information about databases
Original link: 
Obs.: Script was copied from internet

***************************************************************************/
SELECT  sda.database_id AS databaseID
      , sda.name AS databaseName
      , CONVERT (BIGINT , CASE WHEN CONVERT (INT , SUM(smf.size)) >= 268435456

                                             -- Maior de 2TB, tamanho maximo para INT
                                    THEN SUM(CONVERT (BIGINT , smf.size) * 8 / 1024) 
                                             --NULL
                               ELSE SUM(smf.size) * 8 / 1024
                          END) AS TotalSizeMB
      , sda.create_date
      , sda.compatibility_level
      , sda.collation_name
      , sda.user_access_desc AS AccessType
      , log_reuse_wait_desc
      , CASE sda.is_read_only
          WHEN 0 THEN 'READ_WRITE'
          WHEN 1 THEN 'READ_ONLY'
        END AS ReadOnly
      , CASE sda.is_auto_close_on
          WHEN 0 THEN 'OFF'
          WHEN 1 THEN 'ON'
        END AS AutoClose
      , CASE sda.is_auto_shrink_on
          WHEN 0 THEN 'OFF'
          WHEN 1 THEN 'ON'
        END AS AutoShrink
      , sda.state_desc
      , sda.snapshot_isolation_state_desc
      , CASE sda.is_read_committed_snapshot_on
          WHEN 0 THEN 'OFF'
          WHEN 1 THEN 'ON'
        END AS [Read Committed]
      , sda.recovery_model_desc
      , sda.page_verify_option_desc
FROM    sys.databases sda
INNER JOIN sys.master_files smf ON smf.database_id = sda.database_id
WHERE   HAS_DBACCESS(DB_NAME(smf.database_id)) = 1  -- Only look at databases to which we have access
GROUP BY sda.database_id
      , sda.name
      , sda.create_date
      , sda.compatibility_level
      , sda.collation_name
      , sda.user_access_desc
      , log_reuse_wait_desc
      , CASE sda.is_read_only
          WHEN 0 THEN 'READ_WRITE'
          WHEN 1 THEN 'READ_ONLY'
        END
      , CASE sda.is_auto_close_on
          WHEN 0 THEN 'OFF'
          WHEN 1 THEN 'ON'
        END
      , CASE sda.is_auto_shrink_on
          WHEN 0 THEN 'OFF'
          WHEN 1 THEN 'ON'
        END
      , sda.state_desc
      , sda.snapshot_isolation_state_desc
      , CASE sda.is_read_committed_snapshot_on
          WHEN 0 THEN 'OFF'
          WHEN 1 THEN 'ON'
        END
      , sda.recovery_model_desc
      , sda.page_verify_option_desc
