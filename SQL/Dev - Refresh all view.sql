/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Refresh all views in a database
Original link: 
Obs.: Script was copied from internet
***************************************************************************/

SELECT DISTINCT
    'EXEC sp_refreshview ''' + name + ''''
FROM    sys.objects AS so
INNER JOIN sys.sql_expression_dependencies AS sed ON so.object_id = sed.referencing_id
WHERE   so.type = 'V'
        AND is_schema_bound_reference = 0;