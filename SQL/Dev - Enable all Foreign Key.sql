/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Enable all FK constraint
Original link: 
Obs.: Script was copied from internet

***************************************************************************/

DECLARE @sql NVARCHAR (MAX) = N'';

;
WITH x
AS
    (   SELECT DISTINCT
            obj = QUOTENAME( OBJECT_SCHEMA_NAME( parent_object_id )) + '.' + QUOTENAME( OBJECT_NAME( parent_object_id ))
        FROM    sys.foreign_keys )
SELECT  @sql += N'ALTER TABLE ' + obj + ' WITH CHECK CHECK CONSTRAINT ALL;
'
FROM    x;
-- PRINT @sql
EXEC sp_executesql @sql;