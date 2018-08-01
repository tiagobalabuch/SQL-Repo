/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Get SQL Server Agent jobs status
Original link: 
Obs.: 
  
***************************************************************************/

SELECT  sjo.name
      , CASE
            WHEN run_status = 0 THEN 'Failed'
            WHEN run_status = 1 THEN 'Succeeded'
            WHEN run_status = 2 THEN 'Retry'
            WHEN run_status = 3 THEN 'Canceled'
            WHEN run_status = 4 THEN 'Running'
        END Status
      , sjo.enabled
      , sjo.description
      , sjo.date_created
      , sjo.date_modified
      , MAX( run_requested_date ) [RunDate]
      , MAX( start_execution_date ) [StartedDate]
      , MAX( stop_execution_date ) [EndedDate]
      , MAX( next_scheduled_run_date ) [NextRun]
FROM    dbo.sysjobs sjo
INNER JOIN dbo.sysjobactivity sja ON sjo.job_id = sja.job_id
INNER JOIN dbo.sysjobhistory sjh ON sjo.job_id = sjh.job_id
GROUP BY sjo.name
       , sjo.enabled
       , sjo.description
       , sjo.date_created
       , sjo.date_modified
       , CASE
             WHEN run_status = 0 THEN 'Failed'
             WHEN run_status = 1 THEN 'Succeeded'
             WHEN run_status = 2 THEN 'Retry'
             WHEN run_status = 3 THEN 'Canceled'
             WHEN run_status = 4 THEN 'Running'
         END;
