/*************************************************************************
Author: Glenn Berry
Date : 22/09/2017
Description: Find single-use, ad-hoc and prepared queries that are bloating the plan cache
Original link: 
Obs.: Script was copied from internet 
SQL Server 2012 Diagnostic Information Queries
	Last Modified: September 22, 2014
    (Query 44) (Ad hoc Queries)
***************************************************************************/




SELECT TOP ( 50 )
        text AS QueryText
      , cp.cacheobjtype
      , cp.objtype
      , cp.size_in_bytes / 1024 AS [Plan Size in KB]
    FROM
        sys.dm_exec_cached_plans AS cp WITH ( NOLOCK )
    CROSS APPLY sys.dm_exec_sql_text(plan_handle)
    WHERE
        cp.cacheobjtype = N'Compiled Plan' AND
        cp.objtype IN ( N'Adhoc' , N'Prepared' ) AND
        cp.usecounts = 1
    ORDER BY
        cp.size_in_bytes DESC
    OPTION
    ( RECOMPILE );

-- Gives you the text, type and size of single-use ad-hoc and prepared queries that waste space in the plan cache
-- Enabling 'optimize for ad hoc workloads' for the instance can help (SQL Server 2008 and above only)
-- Running DBCC FREESYSTEMCACHE ('SQL Plans') periodically may be required to better control this.
-- Enabling forced parameterization for the database can help, but test first!
