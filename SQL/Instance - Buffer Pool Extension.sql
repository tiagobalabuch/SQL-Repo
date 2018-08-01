/*************************************************************************
Author: Ryan Adams
Date: 22/09/2017
Description: Detect blocking (run multiple times) 
Original link: http://www.ryanjadams.com/2017/05/implementing-buffer-pool-extension
Obs.: Script was copied from internet

***************************************************************************/


--Review current BPE configuration
SELECT  [path]
      , state_description
      , current_size_in_kb
      , CAST(current_size_in_kb / 1048576.0 AS DECIMAL(10 , 2)) AS [Size (GB)]
FROM    sys.dm_os_buffer_pool_extension_configuration;

 
--Let's see what went to BPE.  If there are no results then go query more data.
SELECT  DB_NAME(database_id) AS [Database Name]
      , COUNT(page_id) AS [Page Count]
      , CAST(COUNT(*) / 128.0 AS DECIMAL(10 , 2)) AS [Buffer size(MB)]
      , AVG(read_microsec) AS [Avg Read Time (microseconds)]
FROM    sys.dm_os_buffer_descriptors
WHERE   database_id <> 32767 AND
        is_in_bpool_extension = 1
GROUP BY DB_NAME(database_id)
ORDER BY [Buffer size(MB)] DESC;
 