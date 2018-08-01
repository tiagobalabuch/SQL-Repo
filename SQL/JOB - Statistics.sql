/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Get SQL Server Agent jobs statistics
Original link: 
Obs.: Script was copied from internet
  
***************************************************************************/

SELECT  j.name Job_Name
      , RTRIM( CAST(CONVERT(
                               CHAR (2)
                             , DATEADD(
                                          ss
                                        , MAX( CAST(SUBSTRING( CAST(jh.run_duration + 1000000 AS VARCHAR (7)), 2, 2 ) AS INT) * 60 * 60
                                               + CAST(SUBSTRING( CAST(jh.run_duration + 1000000 AS VARCHAR (7)), 4, 2 ) AS INT) * 60
                                               + CAST(SUBSTRING( CAST(jh.run_duration + 1000000 AS VARCHAR (7)), 6, 2 ) AS INT)
                                             )
                                        , 0
                                      )
                             , 13
                           ) - 1 AS CHAR (2))
             ) + '.'
        + CONVERT(
                     CHAR (8)
                   , DATEADD(
                                ss
                              , MAX( CAST(SUBSTRING( CAST(jh.run_duration + 1000000 AS VARCHAR (7)), 2, 2 ) AS BIGINT) * 60 * 60
                                     + CAST(SUBSTRING( CAST(jh.run_duration + 1000000 AS VARCHAR (7)), 4, 2 ) AS INT) * 60
                                     + CAST(SUBSTRING( CAST(jh.run_duration + 1000000 AS VARCHAR (7)), 6, 2 ) AS BIGINT)
                                   )
                              , 0
                            )
                   , 14
                 ) Max_Duration
      , RTRIM( CAST(CONVERT(
                               CHAR (2)
                             , DATEADD(
                                          ms
                                        , AVG(( CAST(SUBSTRING( CAST(jh.run_duration + 1000000 AS VARCHAR (7)), 2, 2 ) AS BIGINT) * 60 * 60
                                                + CAST(SUBSTRING( CAST(jh.run_duration + 1000000 AS VARCHAR (7)), 4, 2 ) AS BIGINT) * 60
                                                + CAST(SUBSTRING( CAST(jh.run_duration + 1000000 AS VARCHAR (7)), 6, 2 ) AS BIGINT)
                                              ) * 1000
                                             )
                                        , 0
                                      )
                             , 13
                           ) - 1 AS CHAR (2))
             ) + '.'
        + CONVERT(
                     CHAR (12)
                   , DATEADD(
                                ms
                              , AVG(( CAST(SUBSTRING( CAST(jh.run_duration + 1000000 AS VARCHAR (7)), 2, 2 ) AS INT) * 60 * 60
                                      + CAST(SUBSTRING( CAST(jh.run_duration + 1000000 AS VARCHAR (7)), 4, 2 ) AS INT) * 60
                                      + CAST(SUBSTRING( CAST(jh.run_duration + 1000000 AS VARCHAR (7)), 6, 2 ) AS BIGINT)
                                    ) * 1000
                                   )
                              , 0
                            )
                   , 14
                 ) Avg_Duration
      , COUNT( * ) Num_of_Executions
FROM    msdb.dbo.sysjobhistory jh
JOIN msdb.dbo.sysjobs j ON jh.job_id = j.job_id
WHERE   jh.step_id = 0
GROUP BY j.name;