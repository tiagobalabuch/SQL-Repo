/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Using Ring Buffer to check connectivity
Original link: 
Obs.: Script was copied from internet

***************************************************************************/
SELECT  DATEADD( [ms]
               , timestamp - (
                                 SELECT     [ms_ticks]
                                 FROM   [sys].[dm_os_sys_info]
                             )
               , GETDATE()
               ) AS timestamp
      , CONVERT( XML, [record] )
      , *
FROM    [sys].[dm_os_ring_buffers]
WHERE   [ring_buffer_type] = 'RING_BUFFER_CONNECTIVITY';
