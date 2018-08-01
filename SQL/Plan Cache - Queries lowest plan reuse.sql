/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Queries lowest plan reuse
Original link: 
Obs.: Script was copied from internet
  
***************************************************************************/

SELECT  [Plan usage] = cp.usecounts
      , [Individual Query] = SUBSTRING(
                                          qt.text
                                        , qs.statement_start_offset / 2
                                        , ( CASE
                                                WHEN qs.statement_end_offset = -1 THEN LEN( CONVERT( NVARCHAR (MAX), qt.text )) * 2
                                                ELSE qs.statement_end_offset
                                            END - qs.statement_start_offset
                                          ) / 2
                                      )
      , [Parent Query] = qt.text
      , DatabaseName = DB_NAME( qt.dbid )
      , cp.cacheobjtype
FROM    sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text( qs.sql_handle ) AS qt
INNER JOIN sys.dm_exec_cached_plans AS cp ON qs.plan_handle = cp.plan_handle
WHERE   cp.plan_handle = qs.plan_handle
ORDER BY [Plan usage] ASC;

-- Queries compiled and plans not reused
-- Another view 

WITH cached_plans
   ( cacheobjtype, objtype, usecounts, size_in_bytes, dbid, objectid, short_qry_text )
AS
    (   SELECT  p.cacheobjtype
              , p.objtype
              , p.usecounts
              , size_in_bytes
              , s.dbid
              , s.objectid
              , CONVERT(
                           NVARCHAR (4000)
                         , REPLACE(
                                      REPLACE(
                                                 CASE -- Special cases: handle NULL s.[text] and 'SET NOEXEC'
                                                     WHEN s.text IS NULL THEN NULL
                                                     WHEN CHARINDEX( 'noexec', SUBSTRING( s.text, 1, 200 )) > 0 THEN SUBSTRING( s.text, 1, 40 )
                                                     -- CASE #1: sp_executesql (query text passed in as 1st parameter) 
                                                     WHEN CHARINDEX( 'sp_executesql', SUBSTRING( s.text, 1, 200 )) > 0 THEN
                                                         SUBSTRING( s.text, CHARINDEX( 'exec', SUBSTRING( s.text, 1, 200 )), 60 )
                                                     -- CASE #3: any other stored proc -- strip off any parameters
                                                     WHEN CHARINDEX( 'exec ', SUBSTRING( s.text, 1, 200 )) > 0 THEN
                                                         SUBSTRING(
                                                                      s.text
                                                                    , CHARINDEX( 'exec', SUBSTRING( s.text, 1, 4000 ))
                                                                    , CHARINDEX(
                                                                                   ' '
                                                                                 , SUBSTRING(
                                                                                                SUBSTRING( s.text, 1, 200 ) + '   '
                                                                                              , CHARINDEX( 'exec', SUBSTRING( s.text, 1, 500 ))
                                                                                              , 200
                                                                                            )
                                                                                 , 9
                                                                               )
                                                                  )
                                                     -- CASE #4: stored proc that starts with common prefix 'sp%' instead of 'exec'
                                                     WHEN SUBSTRING( s.text, 1, 2 ) IN ( 'sp', 'xp', 'usp' ) THEN
                                                         SUBSTRING( s.text, 1, CHARINDEX( ' ', SUBSTRING( s.text, 1, 200 ) + ' ' ))
                                                     -- CASE #5: ad hoc UPD/INS/DEL query (on average, updates/inserts/deletes usually 
                                                     -- need a shorter substring to avoid hitting parameters)
                                                     WHEN SUBSTRING( s.text, 1, 30 ) LIKE '%UPDATE %'
                                                          OR   SUBSTRING( s.text, 1, 30 ) LIKE '%INSERT %'
                                                          OR   SUBSTRING( s.text, 1, 30 ) LIKE '%DELETE %' THEN SUBSTRING( s.text, 1, 30 )
                                                     -- CASE #6: other ad hoc query
                                                     ELSE SUBSTRING( s.text, 1, 45 )
                                                 END
                                               , CHAR( 10 )
                                               , ' '
                                             )
                                    , CHAR( 13 )
                                    , ' '
                                  )
                       ) AS short_qry_text
        FROM    sys.dm_exec_cached_plans p
        CROSS APPLY sys.dm_exec_sql_text( p.plan_handle ) s )
SELECT  COUNT( * ) AS plan_count
      , SUM( size_in_bytes ) AS total_size_in_bytes
      , cacheobjtype
      , objtype
      , usecounts
      , dbid
      , objectid
      , short_qry_text
FROM    cached_plans
GROUP BY cacheobjtype
       , objtype
       , usecounts
       , dbid
       , objectid
       , short_qry_text
HAVING  COUNT( * ) > 100
ORDER BY COUNT( * ) DESC;
RAISERROR( '', 0, 1 ) WITH NOWAIT;
