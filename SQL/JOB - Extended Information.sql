/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Get SQL Server Agent jobs extra information
Original link: 
Obs.: Script was copied from internet
  
***************************************************************************/
USE msdb;

GO

SELECT  sjo.job_id
      , sjo.name
      , CASE
            WHEN sjo.enabled = 1 THEN 'Habilitado'
            WHEN sjo.enabled = 0 THEN 'Desabilitado'
        END AS [enable]
      , sjo.description
      , sjo.date_created
      , sjo.date_modified
        --, CASE
        --      WHEN [run_status] = 0 THEN 'Falha'
        --      WHEN [run_status] = 1 THEN 'Êxito'
        --      WHEN [run_status] = 2 THEN 'Repetir'
        --      WHEN [run_status] = 3 THEN 'Cancelado'
        --      WHEN [run_status] = 4 THEN 'Em andamento'
        --  END AS [Status]
      , MAX( sja.run_requested_date ) AS [Executada em]
      , MAX( sja.start_execution_date ) AS [Iniciou em]
      , MAX( sja.stop_execution_date ) AS [Terminou em]
      , MAX( sja.next_scheduled_run_date ) AS [Proxima execução]
      , CASE ss.freq_type
            WHEN 1 THEN
                'Occurs on ' + STUFF( RIGHT(ss.active_start_date, 4), 3, 0, '/' ) + '/' + LEFT(ss.active_start_date, 4) + ' at '
                + REPLACE(
                             RIGHT(CONVERT(
                                              VARCHAR (30)
                                            , CAST(CONVERT(
                                                              VARCHAR (8)
                                                            , STUFF(
                                                                       STUFF( RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6), 3, 0, ':' )
                                                                     , 6
                                                                     , 0
                                                                     , ':'
                                                                   )
                                                            , 8
                                                          ) AS DATETIME)

                                            /*************
 hh:mm:ss 24H 
*************/
                                            , 9
                                          ), 14)
                           , ':000'
                           , ' '
                         )

            /***************************************************
 HH:mm:ss:000AM/PM then replace the :000 with space.
***************************************************/
            WHEN 4 THEN
                'Occurs every ' + CAST(ss.freq_interval AS VARCHAR (10)) + ' day(s) '
                + CASE ss.freq_subday_type
                      WHEN 1 THEN
                          'at '
                          + LTRIM( REPLACE(
                                              RIGHT(CONVERT(
                                                               VARCHAR (30)
                                                             , CAST(CONVERT(
                                                                               VARCHAR (8)
                                                                             , STUFF(
                                                                                        STUFF(
                                                                                                 RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                               , 3
                                                                                               , 0
                                                                                               , ':'
                                                                                             )
                                                                                      , 6
                                                                                      , 0
                                                                                      , ':'
                                                                                    )
                                                                             , 8
                                                                           ) AS DATETIME)
                                                             , 9
                                                           ), 14)
                                            , ':000'
                                            , ' '
                                          )
                                 )
                      WHEN 2 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' second(s)'
                      WHEN 4 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' minute(s)'
                      WHEN 8 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' hour(s)'
                      ELSE ''
                  END
                + CASE
                      WHEN ss.freq_subday_type IN ( 2, 4, 8 )

      /**************************
 repeat seconds/mins/hours 
**************************/
      THEN
                          ' between '
                          + LTRIM( REPLACE(
                                              RIGHT(CONVERT(
                                                               VARCHAR (30)
                                                             , CAST(CONVERT(
                                                                               VARCHAR (8)
                                                                             , STUFF(
                                                                                        STUFF(
                                                                                                 RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                               , 3
                                                                                               , 0
                                                                                               , ':'
                                                                                             )
                                                                                      , 6
                                                                                      , 0
                                                                                      , ':'
                                                                                    )
                                                                             , 8
                                                                           ) AS DATETIME)
                                                             , 9
                                                           ), 14)
                                            , ':000'
                                            , ' '
                                          )
                                 ) + ' and '
                          + LTRIM( REPLACE(
                                              RIGHT(CONVERT(
                                                               VARCHAR (30)
                                                             , CAST(CONVERT(
                                                                               VARCHAR (8)
                                                                             , STUFF(
                                                                                        STUFF(
                                                                                                 RIGHT('000000' + CAST(ss.active_end_time AS VARCHAR (10)), 6)
                                                                                               , 3
                                                                                               , 0
                                                                                               , ':'
                                                                                             )
                                                                                      , 6
                                                                                      , 0
                                                                                      , ':'
                                                                                    )
                                                                             , 8
                                                                           ) AS DATETIME)
                                                             , 9
                                                           ), 14)
                                            , ':000'
                                            , ' '
                                          )
                                 )
                      ELSE ''
                  END
            WHEN 8 THEN
                'Occurs every ' + CAST(ss.freq_recurrence_factor AS VARCHAR (10)) + ' week(s) on '
                + REPLACE(   CASE
                                 WHEN ss.freq_interval & 1 = 1 THEN 'Sunday, '
                                 ELSE ''
                             END + CASE
                                       WHEN ss.freq_interval & 2 = 2 THEN 'Monday, '
                                       ELSE ''
                                   END + CASE
                                             WHEN ss.freq_interval & 4 = 4 THEN 'Tuesday, '
                                             ELSE ''
                                         END + CASE
                                                   WHEN ss.freq_interval & 8 = 8 THEN 'Wednesday, '
                                                   ELSE ''
                                               END + CASE
                                                         WHEN ss.freq_interval & 16 = 16 THEN 'Thursday, '
                                                         ELSE ''
                                                     END + CASE
                                                               WHEN ss.freq_interval & 32 = 32 THEN 'Friday, '
                                                               ELSE ''
                                                           END + CASE
                                                                     WHEN ss.freq_interval & 64 = 64 THEN 'Saturday, '
                                                                     ELSE ''
                                                                 END + '|'
                           , ', |'
                           , ' '
                         )

                /**************************
 get rid of trailing comma 
**************************/
                + CASE ss.freq_subday_type
                      WHEN 1 THEN
                          'at '
                          + LTRIM( REPLACE(
                                              RIGHT(CONVERT(
                                                               VARCHAR (30)
                                                             , CAST(CONVERT(
                                                                               VARCHAR (8)
                                                                             , STUFF(
                                                                                        STUFF(
                                                                                                 RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                               , 3
                                                                                               , 0
                                                                                               , ':'
                                                                                             )
                                                                                      , 6
                                                                                      , 0
                                                                                      , ':'
                                                                                    )
                                                                             , 8
                                                                           ) AS DATETIME)
                                                             , 9
                                                           ), 14)
                                            , ':000'
                                            , ' '
                                          )
                                 )
                      WHEN 2 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' second(s)'
                      WHEN 4 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' minute(s)'
                      WHEN 8 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' hour(s)'
                      ELSE ''
                  END
                + CASE
                      WHEN ss.freq_subday_type IN ( 2, 4, 8 )

      /**************************
 repeat seconds/mins/hours 
**************************/
      THEN
                          ' between '
                          + LTRIM( REPLACE(
                                              RIGHT(CONVERT(
                                                               VARCHAR (30)
                                                             , CAST(CONVERT(
                                                                               VARCHAR (8)
                                                                             , STUFF(
                                                                                        STUFF(
                                                                                                 RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                               , 3
                                                                                               , 0
                                                                                               , ':'
                                                                                             )
                                                                                      , 6
                                                                                      , 0
                                                                                      , ':'
                                                                                    )
                                                                             , 8
                                                                           ) AS DATETIME)
                                                             , 9
                                                           ), 14)
                                            , ':000'
                                            , ' '
                                          )
                                 ) + ' and '
                          + LTRIM( REPLACE(
                                              RIGHT(CONVERT(
                                                               VARCHAR (30)
                                                             , CAST(CONVERT(
                                                                               VARCHAR (8)
                                                                             , STUFF(
                                                                                        STUFF(
                                                                                                 RIGHT('000000' + CAST(ss.active_end_time AS VARCHAR (10)), 6)
                                                                                               , 3
                                                                                               , 0
                                                                                               , ':'
                                                                                             )
                                                                                      , 6
                                                                                      , 0
                                                                                      , ':'
                                                                                    )
                                                                             , 8
                                                                           ) AS DATETIME)
                                                             , 9
                                                           ), 14)
                                            , ':000'
                                            , ' '
                                          )
                                 )
                      ELSE ''
                  END
            WHEN 16 THEN
                'Occurs every ' + CAST(ss.freq_recurrence_factor AS VARCHAR (10)) + ' month(s) on ' + 'day ' + CAST(ss.freq_interval AS VARCHAR (10))
                + ' of that month '
                + CASE ss.freq_subday_type
                      WHEN 1 THEN
                          'at '
                          + LTRIM( REPLACE(
                                              RIGHT(CONVERT(
                                                               VARCHAR (30)
                                                             , CAST(CONVERT(
                                                                               VARCHAR (8)
                                                                             , STUFF(
                                                                                        STUFF(
                                                                                                 RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                               , 3
                                                                                               , 0
                                                                                               , ':'
                                                                                             )
                                                                                      , 6
                                                                                      , 0
                                                                                      , ':'
                                                                                    )
                                                                             , 8
                                                                           ) AS DATETIME)
                                                             , 9
                                                           ), 14)
                                            , ':000'
                                            , ' '
                                          )
                                 )
                      WHEN 2 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' second(s)'
                      WHEN 4 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' minute(s)'
                      WHEN 8 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' hour(s)'
                      ELSE ''
                  END
                + CASE
                      WHEN ss.freq_subday_type IN ( 2, 4, 8 )

      /**************************
 repeat seconds/mins/hours 
**************************/
      THEN
                          ' between '
                          + LTRIM( REPLACE(
                                              RIGHT(CONVERT(
                                                               VARCHAR (30)
                                                             , CAST(CONVERT(
                                                                               VARCHAR (8)
                                                                             , STUFF(
                                                                                        STUFF(
                                                                                                 RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                               , 3
                                                                                               , 0
                                                                                               , ':'
                                                                                             )
                                                                                      , 6
                                                                                      , 0
                                                                                      , ':'
                                                                                    )
                                                                             , 8
                                                                           ) AS DATETIME)
                                                             , 9
                                                           ), 14)
                                            , ':000'
                                            , ' '
                                          )
                                 ) + ' and '
                          + LTRIM( REPLACE(
                                              RIGHT(CONVERT(
                                                               VARCHAR (30)
                                                             , CAST(CONVERT(
                                                                               VARCHAR (8)
                                                                             , STUFF(
                                                                                        STUFF(
                                                                                                 RIGHT('000000' + CAST(ss.active_end_time AS VARCHAR (10)), 6)
                                                                                               , 3
                                                                                               , 0
                                                                                               , ':'
                                                                                             )
                                                                                      , 6
                                                                                      , 0
                                                                                      , ':'
                                                                                    )
                                                                             , 8
                                                                           ) AS DATETIME)
                                                             , 9
                                                           ), 14)
                                            , ':000'
                                            , ' '
                                          )
                                 )
                      ELSE ''
                  END
            WHEN 32 THEN
                'Occurs ' + CASE ss.freq_relative_interval
                                WHEN 1 THEN 'every first '
                                WHEN 2 THEN 'every second '
                                WHEN 4 THEN 'every third '
                                WHEN 8 THEN 'every fourth '
                                WHEN 16 THEN 'on the last '
                            END + CASE ss.freq_interval
                                      WHEN 1 THEN 'Sunday'
                                      WHEN 2 THEN 'Monday'
                                      WHEN 3 THEN 'Tuesday'
                                      WHEN 4 THEN 'Wednesday'
                                      WHEN 5 THEN 'Thursday'
                                      WHEN 6 THEN 'Friday'
                                      WHEN 7 THEN 'Saturday'
                                      WHEN 8 THEN 'day'
                                      WHEN 9 THEN 'weekday'
                                      WHEN 10 THEN 'weekend'
                                  END + ' of every ' + CAST(ss.freq_recurrence_factor AS VARCHAR (10)) + ' month(s) '
                + CASE ss.freq_subday_type
                      WHEN 1 THEN
                          'at '
                          + LTRIM( REPLACE(
                                              RIGHT(CONVERT(
                                                               VARCHAR (30)
                                                             , CAST(CONVERT(
                                                                               VARCHAR (8)
                                                                             , STUFF(
                                                                                        STUFF(
                                                                                                 RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                               , 3
                                                                                               , 0
                                                                                               , ':'
                                                                                             )
                                                                                      , 6
                                                                                      , 0
                                                                                      , ':'
                                                                                    )
                                                                             , 8
                                                                           ) AS DATETIME)
                                                             , 9
                                                           ), 14)
                                            , ':000'
                                            , ' '
                                          )
                                 )
                      WHEN 2 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' second(s)'
                      WHEN 4 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' minute(s)'
                      WHEN 8 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' hour(s)'
                      ELSE ''
                  END
                + CASE
                      WHEN ss.freq_subday_type IN ( 2, 4, 8 )

      /**************************
 repeat seconds/mins/hours 
**************************/
      THEN
                          ' between '
                          + LTRIM( REPLACE(
                                              RIGHT(CONVERT(
                                                               VARCHAR (30)
                                                             , CAST(CONVERT(
                                                                               VARCHAR (8)
                                                                             , STUFF(
                                                                                        STUFF(
                                                                                                 RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                               , 3
                                                                                               , 0
                                                                                               , ':'
                                                                                             )
                                                                                      , 6
                                                                                      , 0
                                                                                      , ':'
                                                                                    )
                                                                             , 8
                                                                           ) AS DATETIME)
                                                             , 9
                                                           ), 14)
                                            , ':000'
                                            , ' '
                                          )
                                 ) + ' and '
                          + LTRIM( REPLACE(
                                              RIGHT(CONVERT(
                                                               VARCHAR (30)
                                                             , CAST(CONVERT(
                                                                               VARCHAR (8)
                                                                             , STUFF(
                                                                                        STUFF(
                                                                                                 RIGHT('000000' + CAST(ss.active_end_time AS VARCHAR (10)), 6)
                                                                                               , 3
                                                                                               , 0
                                                                                               , ':'
                                                                                             )
                                                                                      , 6
                                                                                      , 0
                                                                                      , ':'
                                                                                    )
                                                                             , 8
                                                                           ) AS DATETIME)
                                                             , 9
                                                           ), 14)
                                            , ':000'
                                            , ' '
                                          )
                                 )
                      ELSE ''
                  END
            WHEN 64 THEN 'Runs when the SQL Server Agent service starts'
            WHEN 128 THEN 'Runs when the computer is idle'
        END AS [Description]
      , CASE ss.freq_type
            WHEN 1 THEN 'One Time'
            WHEN 4 THEN CASE ss.freq_subday_type
                            WHEN 1 THEN 'Daily'
                            WHEN 2 THEN 'Second-ly'
                            WHEN 4 THEN 'Minutely'
                            WHEN 8 THEN 'Hourly'
                            ELSE ''
                        END
            WHEN 8 THEN 'Weekly'
            WHEN 16 THEN 'Monthly'
            WHEN 32 THEN 'Monthly, relative to freq_interval'
            WHEN 64 THEN 'Runs when the SQL Server Agent service starts'
            WHEN 128 THEN 'Runs when the computer is idle'
        END AS freq_type
      , CASE ss.freq_subday_type
            WHEN 1 THEN 'At the specified time'
            WHEN 2 THEN 'Every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' Second(s)'
            WHEN 4 THEN 'Every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' Minute(s)'
            WHEN 8 THEN 'Every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' Hour(s)'
            ELSE ''
        END AS [freq_subday_type]
      , CASE
            WHEN ss.freq_type = 4

      /********
 (daily) 
********/
      THEN      'Every ' + CAST(ss.freq_interval AS VARCHAR (10)) + ' Day(s)'
            WHEN ss.freq_type = 8

      /*********
 (weekly) 
*********/
      THEN      REPLACE(   CASE
                               WHEN ss.freq_interval & 1 = 1 THEN 'Sunday, '
                               ELSE ''
                           END + CASE
                                     WHEN ss.freq_interval & 2 = 2 THEN 'Monday, '
                                     ELSE ''
                                 END + CASE
                                           WHEN ss.freq_interval & 4 = 4 THEN 'Tuesday, '
                                           ELSE ''
                                       END + CASE
                                                 WHEN ss.freq_interval & 8 = 8 THEN 'Wednesday, '
                                                 ELSE ''
                                             END + CASE
                                                       WHEN ss.freq_interval & 16 = 16 THEN 'Thursday, '
                                                       ELSE ''
                                                   END + CASE
                                                             WHEN ss.freq_interval & 32 = 32 THEN 'Friday, '
                                                             ELSE ''
                                                         END + CASE
                                                                   WHEN ss.freq_interval & 64 = 64 THEN 'Saturday, '
                                                                   ELSE ''
                                                               END + '|'
                         , ', |'
                         , ' '
                       )

            /**************************
 get rid of trailing comma 
**************************/
            WHEN ss.freq_type = 16 THEN 'On Day ' + CAST(ss.freq_interval AS VARCHAR (10)) + ' of Every Month'
            WHEN ss.freq_type = 32

      /**********
 (monthly) 
**********/
      THEN      'Every ' + CASE ss.freq_interval
                               WHEN 1 THEN 'Sunday'
                               WHEN 2 THEN 'Monday'
                               WHEN 3 THEN 'Tuesday'
                               WHEN 4 THEN 'Wednesday'
                               WHEN 5 THEN 'Thursday'
                               WHEN 6 THEN 'Friday'
                               WHEN 7 THEN 'Saturday'
                               WHEN 8 THEN 'Day'
                               WHEN 9 THEN 'Weekday'
                               WHEN 10 THEN 'Weekend day'
                           END
            ELSE ''
        END AS [freq_interval]
FROM    msdb.dbo.sysjobs AS [sjo]
LEFT JOIN msdb.dbo.sysjobactivity AS [sja] ON sjo.job_id = sja.job_id
LEFT JOIN msdb.dbo.sysjobhistory AS [sjh] ON sjo.job_id = sjh.job_id
LEFT JOIN msdb.dbo.sysjobschedules AS [sjs] ON sjo.job_id = sjs.job_id

--and sjh.job_id = sjs.job_id and sja.job_id = sjs.job_id
LEFT JOIN msdb.dbo.sysschedules AS [ss] ON sjs.schedule_id = ss.schedule_id
WHERE   sjo.name <> 'syspolicy_purge_history'
GROUP BY sjo.job_id
       , sjo.name
       , CASE
             WHEN sjo.enabled = 1 THEN 'Habilitado'
             WHEN sjo.enabled = 0 THEN 'Desabilitado'
         END
       , sjo.description
       , sjo.date_created
       , sjo.date_modified
        --, CASE
        --      WHEN
        --  [run_status] = 0 THEN 'Falha'
        --      WHEN
        --  [run_status] = 1 THEN 'Êxito'
        --      WHEN
        --  [run_status] = 2 THEN 'Repetir'
        --      WHEN
        --  [run_status] = 3 THEN 'Cancelado'
        --      WHEN
        --  [run_status] = 4 THEN 'Em andamento'
        --  END
       , CASE ss.freq_type
             WHEN 1 THEN
                 'Occurs on ' + STUFF( RIGHT(ss.active_start_date, 4), 3, 0, '/' ) + '/' + LEFT(ss.active_start_date, 4) + ' at '
                 + REPLACE(
                              RIGHT(CONVERT(
                                               VARCHAR (30)
                                             , CAST(CONVERT(
                                                               VARCHAR (8)
                                                             , STUFF(
                                                                        STUFF( RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6), 3, 0, ':' )
                                                                      , 6
                                                                      , 0
                                                                      , ':'
                                                                    )
                                                             , 8
                                                           ) AS DATETIME)

                                                /*************
 hh:mm:ss 24H 
*************/
                                             , 9
                                           ), 14)
                            , ':000'
                            , ' '
                          )

             /***************************************************
 HH:mm:ss:000AM/PM then replace the :000 with space.
***************************************************/
             WHEN 4 THEN
                 'Occurs every ' + CAST([freq_interval] AS VARCHAR (10)) + ' day(s) '
                 + CASE [freq_subday_type]
                       WHEN 1 THEN
                           'at '
                           + LTRIM( REPLACE(
                                               RIGHT(CONVERT(
                                                                VARCHAR (30)
                                                              , CAST(CONVERT(
                                                                                VARCHAR (8)
                                                                              , STUFF(
                                                                                         STUFF(
                                                                                                  RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                                , 3
                                                                                                , 0
                                                                                                , ':'
                                                                                              )
                                                                                       , 6
                                                                                       , 0
                                                                                       , ':'
                                                                                     )
                                                                              , 8
                                                                            ) AS DATETIME)
                                                              , 9
                                                            ), 14)
                                             , ':000'
                                             , ' '
                                           )
                                  )
                       WHEN 2 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' second(s)'
                       WHEN 4 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' minute(s)'
                       WHEN 8 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' hour(s)'
                       ELSE ''
                   END
                 + CASE
                       WHEN [freq_subday_type] IN ( 2, 4, 8 )

       /**************************
 repeat seconds/mins/hours 
**************************/
       THEN
                           ' between '
                           + LTRIM( REPLACE(
                                               RIGHT(CONVERT(
                                                                VARCHAR (30)
                                                              , CAST(CONVERT(
                                                                                VARCHAR (8)
                                                                              , STUFF(
                                                                                         STUFF(
                                                                                                  RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                                , 3
                                                                                                , 0
                                                                                                , ':'
                                                                                              )
                                                                                       , 6
                                                                                       , 0
                                                                                       , ':'
                                                                                     )
                                                                              , 8
                                                                            ) AS DATETIME)
                                                              , 9
                                                            ), 14)
                                             , ':000'
                                             , ' '
                                           )
                                  ) + ' and '
                           + LTRIM( REPLACE(
                                               RIGHT(CONVERT(
                                                                VARCHAR (30)
                                                              , CAST(CONVERT(
                                                                                VARCHAR (8)
                                                                              , STUFF(
                                                                                         STUFF(
                                                                                                  RIGHT('000000' + CAST(ss.active_end_time AS VARCHAR (10)), 6)
                                                                                                , 3
                                                                                                , 0
                                                                                                , ':'
                                                                                              )
                                                                                       , 6
                                                                                       , 0
                                                                                       , ':'
                                                                                     )
                                                                              , 8
                                                                            ) AS DATETIME)
                                                              , 9
                                                            ), 14)
                                             , ':000'
                                             , ' '
                                           )
                                  )
                       ELSE ''
                   END
             WHEN 8 THEN
                 'Occurs every ' + CAST(ss.freq_recurrence_factor AS VARCHAR (10)) + ' week(s) on '
                 + REPLACE(   CASE
                                  WHEN [freq_interval] & 1 = 1 THEN 'Sunday, '
                                  ELSE ''
                              END + CASE
                                        WHEN [freq_interval] & 2 = 2 THEN 'Monday, '
                                        ELSE ''
                                    END + CASE
                                              WHEN [freq_interval] & 4 = 4 THEN 'Tuesday, '
                                              ELSE ''
                                          END + CASE
                                                    WHEN [freq_interval] & 8 = 8 THEN 'Wednesday, '
                                                    ELSE ''
                                                END + CASE
                                                          WHEN [freq_interval] & 16 = 16 THEN 'Thursday, '
                                                          ELSE ''
                                                      END + CASE
                                                                WHEN [freq_interval] & 32 = 32 THEN 'Friday, '
                                                                ELSE ''
                                                            END + CASE
                                                                      WHEN [freq_interval] & 64 = 64 THEN 'Saturday, '
                                                                      ELSE ''
                                                                  END + '|'
                            , ', |'
                            , ' '
                          )

                 /**************************
 get rid of trailing comma 
**************************/
                 + CASE [freq_subday_type]
                       WHEN 1 THEN
                           'at '
                           + LTRIM( REPLACE(
                                               RIGHT(CONVERT(
                                                                VARCHAR (30)
                                                              , CAST(CONVERT(
                                                                                VARCHAR (8)
                                                                              , STUFF(
                                                                                         STUFF(
                                                                                                  RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                                , 3
                                                                                                , 0
                                                                                                , ':'
                                                                                              )
                                                                                       , 6
                                                                                       , 0
                                                                                       , ':'
                                                                                     )
                                                                              , 8
                                                                            ) AS DATETIME)
                                                              , 9
                                                            ), 14)
                                             , ':000'
                                             , ' '
                                           )
                                  )
                       WHEN 2 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' second(s)'
                       WHEN 4 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' minute(s)'
                       WHEN 8 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' hour(s)'
                       ELSE ''
                   END
                 + CASE
                       WHEN [freq_subday_type] IN ( 2, 4, 8 )

       /**************************
 repeat seconds/mins/hours 
**************************/
       THEN
                           ' between '
                           + LTRIM( REPLACE(
                                               RIGHT(CONVERT(
                                                                VARCHAR (30)
                                                              , CAST(CONVERT(
                                                                                VARCHAR (8)
                                                                              , STUFF(
                                                                                         STUFF(
                                                                                                  RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                                , 3
                                                                                                , 0
                                                                                                , ':'
                                                                                              )
                                                                                       , 6
                                                                                       , 0
                                                                                       , ':'
                                                                                     )
                                                                              , 8
                                                                            ) AS DATETIME)
                                                              , 9
                                                            ), 14)
                                             , ':000'
                                             , ' '
                                           )
                                  ) + ' and '
                           + LTRIM( REPLACE(
                                               RIGHT(CONVERT(
                                                                VARCHAR (30)
                                                              , CAST(CONVERT(
                                                                                VARCHAR (8)
                                                                              , STUFF(
                                                                                         STUFF(
                                                                                                  RIGHT('000000' + CAST(ss.active_end_time AS VARCHAR (10)), 6)
                                                                                                , 3
                                                                                                , 0
                                                                                                , ':'
                                                                                              )
                                                                                       , 6
                                                                                       , 0
                                                                                       , ':'
                                                                                     )
                                                                              , 8
                                                                            ) AS DATETIME)
                                                              , 9
                                                            ), 14)
                                             , ':000'
                                             , ' '
                                           )
                                  )
                       ELSE ''
                   END
             WHEN 16 THEN
                 'Occurs every ' + CAST(ss.freq_recurrence_factor AS VARCHAR (10)) + ' month(s) on ' + 'day ' + CAST([freq_interval] AS VARCHAR (10))
                 + ' of that month '
                 + CASE [freq_subday_type]
                       WHEN 1 THEN
                           'at '
                           + LTRIM( REPLACE(
                                               RIGHT(CONVERT(
                                                                VARCHAR (30)
                                                              , CAST(CONVERT(
                                                                                VARCHAR (8)
                                                                              , STUFF(
                                                                                         STUFF(
                                                                                                  RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                                , 3
                                                                                                , 0
                                                                                                , ':'
                                                                                              )
                                                                                       , 6
                                                                                       , 0
                                                                                       , ':'
                                                                                     )
                                                                              , 8
                                                                            ) AS DATETIME)
                                                              , 9
                                                            ), 14)
                                             , ':000'
                                             , ' '
                                           )
                                  )
                       WHEN 2 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' second(s)'
                       WHEN 4 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' minute(s)'
                       WHEN 8 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' hour(s)'
                       ELSE ''
                   END
                 + CASE
                       WHEN [freq_subday_type] IN ( 2, 4, 8 )

       /**************************
 repeat seconds/mins/hours 
**************************/
       THEN
                           ' between '
                           + LTRIM( REPLACE(
                                               RIGHT(CONVERT(
                                                                VARCHAR (30)
                                                              , CAST(CONVERT(
                                                                                VARCHAR (8)
                                                                              , STUFF(
                                                                                         STUFF(
                                                                                                  RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                                , 3
                                                                                                , 0
                                                                                                , ':'
                                                                                              )
                                                                                       , 6
                                                                                       , 0
                                                                                       , ':'
                                                                                     )
                                                                              , 8
                                                                            ) AS DATETIME)
                                                              , 9
                                                            ), 14)
                                             , ':000'
                                             , ' '
                                           )
                                  ) + ' and '
                           + LTRIM( REPLACE(
                                               RIGHT(CONVERT(
                                                                VARCHAR (30)
                                                              , CAST(CONVERT(
                                                                                VARCHAR (8)
                                                                              , STUFF(
                                                                                         STUFF(
                                                                                                  RIGHT('000000' + CAST(ss.active_end_time AS VARCHAR (10)), 6)
                                                                                                , 3
                                                                                                , 0
                                                                                                , ':'
                                                                                              )
                                                                                       , 6
                                                                                       , 0
                                                                                       , ':'
                                                                                     )
                                                                              , 8
                                                                            ) AS DATETIME)
                                                              , 9
                                                            ), 14)
                                             , ':000'
                                             , ' '
                                           )
                                  )
                       ELSE ''
                   END
             WHEN 32 THEN
                 'Occurs ' + CASE ss.freq_relative_interval
                                 WHEN 1 THEN 'every first '
                                 WHEN 2 THEN 'every second '
                                 WHEN 4 THEN 'every third '
                                 WHEN 8 THEN 'every fourth '
                                 WHEN 16 THEN 'on the last '
                             END + CASE [freq_interval]
                                       WHEN 1 THEN 'Sunday'
                                       WHEN 2 THEN 'Monday'
                                       WHEN 3 THEN 'Tuesday'
                                       WHEN 4 THEN 'Wednesday'
                                       WHEN 5 THEN 'Thursday'
                                       WHEN 6 THEN 'Friday'
                                       WHEN 7 THEN 'Saturday'
                                       WHEN 8 THEN 'day'
                                       WHEN 9 THEN 'weekday'
                                       WHEN 10 THEN 'weekend'
                                   END + ' of every ' + CAST(ss.freq_recurrence_factor AS VARCHAR (10)) + ' month(s) '
                 + CASE [freq_subday_type]
                       WHEN 1 THEN
                           'at '
                           + LTRIM( REPLACE(
                                               RIGHT(CONVERT(
                                                                VARCHAR (30)
                                                              , CAST(CONVERT(
                                                                                VARCHAR (8)
                                                                              , STUFF(
                                                                                         STUFF(
                                                                                                  RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                                , 3
                                                                                                , 0
                                                                                                , ':'
                                                                                              )
                                                                                       , 6
                                                                                       , 0
                                                                                       , ':'
                                                                                     )
                                                                              , 8
                                                                            ) AS DATETIME)
                                                              , 9
                                                            ), 14)
                                             , ':000'
                                             , ' '
                                           )
                                  )
                       WHEN 2 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' second(s)'
                       WHEN 4 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' minute(s)'
                       WHEN 8 THEN 'every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' hour(s)'
                       ELSE ''
                   END
                 + CASE
                       WHEN [freq_subday_type] IN ( 2, 4, 8 )

       /**************************
 repeat seconds/mins/hours 
**************************/
       THEN
                           ' between '
                           + LTRIM( REPLACE(
                                               RIGHT(CONVERT(
                                                                VARCHAR (30)
                                                              , CAST(CONVERT(
                                                                                VARCHAR (8)
                                                                              , STUFF(
                                                                                         STUFF(
                                                                                                  RIGHT('000000' + CAST(ss.active_start_time AS VARCHAR (10)), 6)
                                                                                                , 3
                                                                                                , 0
                                                                                                , ':'
                                                                                              )
                                                                                       , 6
                                                                                       , 0
                                                                                       , ':'
                                                                                     )
                                                                              , 8
                                                                            ) AS DATETIME)
                                                              , 9
                                                            ), 14)
                                             , ':000'
                                             , ' '
                                           )
                                  ) + ' and '
                           + LTRIM( REPLACE(
                                               RIGHT(CONVERT(
                                                                VARCHAR (30)
                                                              , CAST(CONVERT(
                                                                                VARCHAR (8)
                                                                              , STUFF(
                                                                                         STUFF(
                                                                                                  RIGHT('000000' + CAST(ss.active_end_time AS VARCHAR (10)), 6)
                                                                                                , 3
                                                                                                , 0
                                                                                                , ':'
                                                                                              )
                                                                                       , 6
                                                                                       , 0
                                                                                       , ':'
                                                                                     )
                                                                              , 8
                                                                            ) AS DATETIME)
                                                              , 9
                                                            ), 14)
                                             , ':000'
                                             , ' '
                                           )
                                  )
                       ELSE ''
                   END
             WHEN 64 THEN 'Runs when the SQL Server Agent service starts'
             WHEN 128 THEN 'Runs when the computer is idle'
         END
       , CASE ss.freq_type
             WHEN 1 THEN 'One Time'
             WHEN 4 THEN CASE [freq_subday_type]
                             WHEN 1 THEN 'Daily'
                             WHEN 2 THEN 'Second-ly'
                             WHEN 4 THEN 'Minutely'
                             WHEN 8 THEN 'Hourly'
                             ELSE ''
                         END
             WHEN 8 THEN 'Weekly'
             WHEN 16 THEN 'Monthly'
             WHEN 32 THEN 'Monthly, relative to freq_interval'
             WHEN 64 THEN 'Runs when the SQL Server Agent service starts'
             WHEN 128 THEN 'Runs when the computer is idle'
         END
       , CASE [freq_subday_type]
             WHEN 1 THEN 'At the specified time'
             WHEN 2 THEN 'Every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' Second(s)'
             WHEN 4 THEN 'Every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' Minute(s)'
             WHEN 8 THEN 'Every ' + CAST(ss.freq_subday_interval AS VARCHAR (10)) + ' Hour(s)'
             ELSE ''
         END
       , CASE
             WHEN ss.freq_type = 4

       /********
 (daily) 
********/
       THEN      'Every ' + CAST([freq_interval] AS VARCHAR (10)) + ' Day(s)'
             WHEN ss.freq_type = 8

       /*********
 (weekly) 
*********/
       THEN      REPLACE(   CASE
                                WHEN [freq_interval] & 1 = 1 THEN 'Sunday, '
                                ELSE ''
                            END + CASE
                                      WHEN [freq_interval] & 2 = 2 THEN 'Monday, '
                                      ELSE ''
                                  END + CASE
                                            WHEN [freq_interval] & 4 = 4 THEN 'Tuesday, '
                                            ELSE ''
                                        END + CASE
                                                  WHEN [freq_interval] & 8 = 8 THEN 'Wednesday, '
                                                  ELSE ''
                                              END + CASE
                                                        WHEN [freq_interval] & 16 = 16 THEN 'Thursday, '
                                                        ELSE ''
                                                    END + CASE
                                                              WHEN [freq_interval] & 32 = 32 THEN 'Friday, '
                                                              ELSE ''
                                                          END + CASE
                                                                    WHEN [freq_interval] & 64 = 64 THEN 'Saturday, '
                                                                    ELSE ''
                                                                END + '|'
                          , ', |'
                          , ' '
                        )

             /**************************
 get rid of trailing comma 
**************************/
             WHEN ss.freq_type = 16 THEN 'On Day ' + CAST([freq_interval] AS VARCHAR (10)) + ' of Every Month'
             WHEN ss.freq_type = 32

       /**********
 (monthly) 
**********/
       THEN      'Every ' + CASE [freq_interval]
                                WHEN 1 THEN 'Sunday'
                                WHEN 2 THEN 'Monday'
                                WHEN 3 THEN 'Tuesday'
                                WHEN 4 THEN 'Wednesday'
                                WHEN 5 THEN 'Thursday'
                                WHEN 6 THEN 'Friday'
                                WHEN 7 THEN 'Saturday'
                                WHEN 8 THEN 'Day'
                                WHEN 9 THEN 'Weekday'
                                WHEN 10 THEN 'Weekend day'
                            END
             ELSE ''
         END
ORDER BY sjo.name;

-- Historico de execuçao

USE msdb;

GO
