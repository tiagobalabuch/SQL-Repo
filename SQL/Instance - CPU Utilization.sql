/*************************************************************************
Author: Benjamin Nevarez
Date : 22/09/2017
Description: Checking CPU utilization history 
Original link: http://sqlblog.com/blogs/ben_nevarez/archive/2009/07/26/getting-cpu-utilization-data-from-sql-server.aspx
Obs.: Script was copied from internet

***************************************************************************/

DECLARE @ts_now BIGINT;

SELECT
        @ts_now = cpu_ticks / CONVERT(FLOAT , cpu_ticks)
    FROM
        sys.dm_os_sys_info;

SELECT
        record_id
      , DATEADD(ms , -1 * ( @ts_now - [timestamp] ) , GETDATE()) AS EventTime
      , SQLProcessUtilization [SQL Server Process CPU Utilization]
      , SystemIdle [System Idle Process]
      , 100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization]
    FROM
        (
          SELECT
                record.value('(./Record/@id)[1]' , 'int') AS record_id
              , record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]' , 'int') AS [SystemIdle]
              , record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]' , 'int') AS [SQLProcessUtilization]
              , timestamp
            FROM
                (
                  SELECT
                        timestamp
                      , CONVERT(XML , record) AS record
                    FROM
                        sys.dm_os_ring_buffers
                    WHERE
                        ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' AND
                        record LIKE '%<SystemHealth>%'
                ) AS x
        ) AS y
    ORDER BY
        record_id DESC;
