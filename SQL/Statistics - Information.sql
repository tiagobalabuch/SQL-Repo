/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Get statistics details on SQL Server 2008 R2 and higher
Original link: 
Obs.: Script was copied from internet and modified
  
***************************************************************************/

SELECT  SCHEMA_NAME( o.schema_id ) [Schema Name]
      , OBJECT_NAME( s.object_id ) [Table Name]
      , s.name [Statistics Name]
      , STUFF((
                  SELECT    ', ' + cols.name
                  FROM  sys.stats_columns AS statcols
                  JOIN sys.columns AS cols ON statcols.column_id = cols.column_id
                                              AND   statcols.object_id = cols.object_id
                  WHERE statcols.stats_id = s.stats_id
                        AND statcols.object_id = s.object_id
                  ORDER BY statcols.stats_column_id
                  FOR XML PATH( '' ), TYPE
              ).value( '.', 'NVARCHAR(MAX)' )
            , 1
            , 2
            , ''
             ) AS [Stats Columns]

        --     , [s].[stats_id] [ID of the statistics]

      , sp.last_updated [Last Updated]
      , sp.modification_counter
      , sp.rows Rows
      , sp.rows_sampled [Rows Sampled]
      , sp.steps [Steps in the Histogram]
      , sp.unfiltered_rows [Unfiltered Rows]
      , CASE
            WHEN auto_created = 1 THEN 'Statistics were automatically created by SQL Server'
            ELSE 'Statistics were not automatically created by SQL Server'
        END [Auto Created]
      , CASE
            WHEN user_created = 1 THEN ' Statistics were created by a user'
            ELSE 'Statistics were not created by a user'
        END [User Created]
      , CASE
            WHEN no_recompute = 1 THEN 'Statistics were created with the NORECOMPUTE option.'
            ELSE 'Statistics were not created with the NORECOMPUTE option'
        END [No Recompute]

        -- SQL 2008

      , CASE
            WHEN has_filter = 1 THEN 'Statistics have a filter and are computed only on rows that satisfy the filter definition'
            ELSE 'Statistics do not have a filter and are computed on all rows'
        END [Has Filter]
      , filter_definition [Filter Definition]

        -- SQL 2012 or higher

      , CASE
            WHEN is_temporary = 1 THEN 'The statistics is temporary'
            ELSE 'The statistics is not temporary'
        END [Tempory statistics]
FROM    sys.stats s
INNER JOIN sys.objects AS o ON s.object_id = o.object_id
CROSS APPLY sys.dm_db_stats_properties( s.object_id, s.stats_id ) AS sp
WHERE   o.type_desc NOT IN ( N'SYSTEM_TABLE', N'INTERNAL_TABLE' )
--      AND o.object_id IN ( OBJECT_ID( 'invoice' ), OBJECT_ID( 'invoice1' )); -- put here your table name
ORDER BY sp.modification_counter DESC
       , o.name;
-- Helps discover possible problems with out-of-date statistics
-- Also gives you an idea which indexes are the most active



