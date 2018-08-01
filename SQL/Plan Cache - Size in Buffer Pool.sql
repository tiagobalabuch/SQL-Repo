/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Buffer Pool for Cached Plan
Original link: 
Obs.: Script was copied from internet 

***************************************************************************/

SELECT  'Buffer Pool Total' AS [Type Buffer]
      , SUM( CAST(size_in_bytes AS BIGINT)) / 1024 / 1024 AS 'Size (MB)'
FROM    sys.dm_exec_cached_plans
UNION
SELECT  'Buffer Pool Adhoc'
      , SUM( CAST(size_in_bytes AS BIGINT)) / 1024 / 1024 
FROM    sys.dm_exec_cached_plans
WHERE   cacheobjtype = 'Compiled Plan'
        AND objtype = 'Adhoc'
        AND usecounts = 1;

--Any memory allocated for execution plans comes from the buffer pool, so the more plans you have then the smaller your buffer pool will be for data and index pages.