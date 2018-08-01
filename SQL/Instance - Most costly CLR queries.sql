/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Most costly CLR queries
Original link: 
Obs.: Script was copied from internet
  
***************************************************************************/

SELECT TOP 10
    [Average CLR Time] = total_clr_time / execution_count
  , [Total CLR Time] = total_clr_time
  , [Execution count] = qs.execution_count
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
FROM    sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text( qs.sql_handle ) AS qt
WHERE   total_clr_time <> 0
ORDER BY [Average CLR Time] DESC;
