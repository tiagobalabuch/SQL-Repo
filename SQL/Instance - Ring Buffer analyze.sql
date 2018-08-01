/*************************************************************************
Author: Dmitriy Ivanov
Date: 22/09/2017
Description: Using Ring Buffer to monitor instance
Original link: https://t.me/sqlcom
Obs.: Script was copied from internet

***************************************************************************/

WITH RingBufferXML
AS
    (   SELECT  CAST(record AS XML) AS RBR
        FROM    sys.dm_os_ring_buffers
        WHERE   ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR' )
SELECT DISTINCT
    'Problems' = CASE
                     WHEN XMLRecord.value( '(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint' ) = 0
                          AND   XMLRecord.value( '(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint' ) = 2 THEN 'Insufficient physical memory for the system'
                     WHEN XMLRecord.value( '(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint' ) = 0
                          AND   XMLRecord.value( '(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint' ) = 4 THEN 'Insufficient virtual memory for the system'
                     WHEN XMLRecord.value( '(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint' ) = 2
                          AND   XMLRecord.value( '(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint' ) = 0 THEN 'Insufficient physical memory for queries'
                     WHEN XMLRecord.value( '(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint' ) = 4
                          AND   XMLRecord.value( '(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint' ) = 4 THEN
                         'Insufficient virtual memory for queries and system'
                     WHEN XMLRecord.value( '(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint' ) = 2
                          AND   XMLRecord.value( '(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint' ) = 4 THEN
                         'Insufficient virtual memory for the system and physical for queries'
                     WHEN XMLRecord.value( '(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint' ) = 2
                          AND   XMLRecord.value( '(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint' ) = 2 THEN
                         'There is not enough physical memory for the system and requests'
                 END
FROM    RingBufferXML
CROSS APPLY RingBufferXML.RBR.nodes( 'Record' ) Record(XMLRecord)
WHERE   XMLRecord.value( '(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint' ) IN ( 0, 2, 4 )
        AND XMLRecord.value( '(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint' ) IN ( 0, 2, 4 )
        AND XMLRecord.value( '(ResourceMonitor/IndicatorsProcess)[1]', 'tinyint' ) + XMLRecord.value( '(ResourceMonitor/IndicatorsSystem)[1]', 'tinyint' ) > 0;


/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Using Ring Buffer to monitor
Original link:
Obs.: Script was copied from internet

***************************************************************************/ 

SELECT  CONVERT( VARCHAR (30), GETDATE(), 121 ) AS runtime
      , DATEADD( ms, -1 * ( sys.ms_ticks - a.[Record Time] ), GETDATE()) AS Notification_time
      , a.*
      , sys.ms_ticks AS [Current Time]
FROM    (
            SELECT  x.value( '(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)' ) AS Notification_type
                  , x.value( '(//Record/MemoryRecord/MemoryUtilization)[1]', 'bigint' ) AS [MemoryUtilization %]
                  , x.value( '(//Record/MemoryRecord/TotalPhysicalMemory)[1]', 'bigint' ) AS TotalPhysicalMemory_KB
                  , x.value( '(//Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint' ) AS AvailablePhysicalMemory_KB
                  , x.value( '(//Record/MemoryRecord/TotalPageFile)[1]', 'bigint' ) AS TotalPageFile_KB
                  , x.value( '(//Record/MemoryRecord/AvailablePageFile)[1]', 'bigint' ) AS AvailablePageFile_KB
                  , x.value( '(//Record/MemoryRecord/TotalVirtualAddressSpace)[1]', 'bigint' ) AS TotalVirtualAddressSpace_KB
                  , x.value( '(//Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint' ) AS AvailableVirtualAddressSpace_KB
                  , x.value( '(//Record/MemoryNode/@id)[1]', 'bigint' ) AS [Node Id]
                  , x.value( '(//Record/MemoryNode/ReservedMemory)[1]', 'bigint' ) AS SQL_ReservedMemory_KB
                  , x.value( '(//Record/MemoryNode/CommittedMemory)[1]', 'bigint' ) AS SQL_CommittedMemory_KB
                  , x.value( '(//Record/@id)[1]', 'bigint' ) AS [Record Id]
                  , x.value( '(//Record/@type)[1]', 'varchar(30)' ) AS Type
                  , x.value( '(//Record/ResourceMonitor/Indicators)[1]', 'bigint' ) AS Indicators
                  , x.value( '(//Record/@time)[1]', 'bigint' ) AS [Record Time]
            FROM    (
                        SELECT  CAST(record AS XML)
                        FROM    sys.dm_os_ring_buffers
                        WHERE   ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR'
                    ) AS R(x)
        ) a
CROSS JOIN sys.dm_os_sys_info sys
ORDER BY a.[Record Time] ASC;
