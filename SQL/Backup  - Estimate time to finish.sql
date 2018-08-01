
/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Estimate time to finish Backup/Restore 
Original link:
Obs.: Script was copied from internet

***************************************************************************/


--By checking only for the restore and backup command lines you will be able to quickly identify your session id
--and get an  approximate ETA and percentage complete. you can tinker of course with the estimations
--if you’d like or pull back more fields. This is just a simple technique in utilizing a helpful DMV to provide info quickly.

SELECT  [command] ,
        [s].text ,
        [start_time] ,
        [percent_complete] ,
        CAST (DATEDIFF([s], [start_time], GETDATE()) / 3600 AS VARCHAR) + ' hour(s), '
			+ CAST (DATEDIFF([s], [start_time], GETDATE()) % 3600 / 60 AS VARCHAR)  + 'min, ' 
			+ CAST (DATEDIFF([s], [start_time], GETDATE()) % 60 AS VARCHAR) + ' sec' AS [running_time] ,
        CAST ([estimated_completion_time] / 3600000 AS VARCHAR) + ' hour(s), '
			+ CAST ([estimated_completion_time] % 3600000 / 60000 AS VARCHAR) + 'min, '
			+ CAST ([estimated_completion_time] % 60000 / 1000 AS VARCHAR) + ' sec' AS [est_time_to_go] ,
        DATEADD([second], [estimated_completion_time] / 1000, GETDATE()) AS [est_completion_time]
FROM    [sys].[dm_exec_requests] [r]
        CROSS APPLY [sys].[dm_exec_sql_text]([r].[sql_handle]) [s]
WHERE   [r].[command] IN ( 'RESTORE DATABASE', 'BACKUP DATABASE',
                           'RESTORE LOG', 'BACKUP LOG' );

