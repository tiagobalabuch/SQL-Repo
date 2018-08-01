/*************************************************************************
Author: Jonathan Kehayias
Data : 22/09/2017
Descrição: Using XE to track page split 
Original link: http://sqlblog.com/blogs/jonathan_kehayias/archive/2010/10/17/tracking-page-splits-in-sql-server-denali-ctp1.aspx
			   https://www.sqlskills.com/blogs/jonathan/tracking-problematic-pages-splits-in-sql-server-2012-extended-events-no-really-this-time/
Obs.: Script was copied from internet
I merged those two scripts
***************************************************************************/

IF EXISTS ( SELECT  1
            FROM    sys.server_event_sessions
            WHERE   name = 'MonitorPageSplits' )
    DROP EVENT SESSION MonitorPageSplits ON SERVER; 
GO

CREATE EVENT SESSION MonitorPageSplits ON SERVER
ADD EVENT sqlserver.page_split (
    ACTION ( sqlserver.database_id, sqlserver.sql_text )),
 --   WHERE sqlserver.database_id = 2  -- choose your database to track
ADD EVENT sqlserver.transaction_log(
    WHERE operation = 11 ) -- LOP_DELETE_SPLIT 

ADD TARGET package0.histogram(
    SET filtering_event_name = 'sqlserver.transaction_log',
        source_type = 0, -- Event Column
        source = 'database_id'),
ADD TARGET package0.ring_buffer
WITH (  MAX_MEMORY = 4096 KB ,
        EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS ,
        MAX_DISPATCH_LATENCY = 1 SECONDS ,
        MAX_EVENT_SIZE = 0 KB ,
        MEMORY_PARTITION_MODE = NONE ,
        TRACK_CAUSALITY = OFF ,
        STARTUP_STATE = OFF );

ALTER EVENT SESSION MonitorPageSplits ON SERVER STATE = START;
GO

-- General information

SELECT  event_time = XEvent.value('(@timestamp)[1]', 'datetime') ,
        orig_file_id = XEvent.value('(data[@name=''file_id'']/value)[1]',
                                    'int') ,
        orig_page_id = XEvent.value('(data[@name=''page_id'']/value)[1]',
                                    'int') ,
        database_id = XEvent.value('(data[@name=''database_id'']/value)[1]',
                                   'int') ,
        OBJECT_ID = p.object_id ,
        index_id = p.index_id ,
        OBJECT_NAME = OBJECT_NAME(p.object_id) ,
        index_name = i.name ,
        rowset_id = XEvent.value('(data[@name=''rowset_id'']/value)[1]',
                                 'bigint') ,
        splitOperation = XEvent.value('(data[@name=''splitOperation'']/text)[1]',
                                      'varchar(255)') ,
        new_page_file_id = XEvent.value('(data[@name=''new_page_file_id'']/value)[1]',
                                        'int') ,
        new_page_page_id = XEvent.value('(data[@name=''new_page_page_id'']/value)[1]',
                                        'int') ,
        sql_text = XEvent.value('(action[@name=''sql_text'']/value)[1]',
                                'varchar(max)')
FROM    ( SELECT    CAST(target_data AS XML) AS target_data
          FROM      sys.dm_xe_session_targets xst
                    JOIN sys.dm_xe_sessions xs ON xs.address = xst.event_session_address
          WHERE     xs.name = 'MonitorPageSplits'
        ) AS tab ( target_data )
        CROSS APPLY target_data.nodes('/RingBufferTarget/event') AS EventNodes ( XEvent )
        LEFT JOIN sys.allocation_units au ON au.container_id = XEvent.value('(data[@name=''rowset_id'']/value)[1]',
                                                              'bigint')
        LEFT JOIN sys.partitions p ON p.partition_id = au.container_id
        LEFT JOIN sys.indexes i ON p.object_id = i.object_id
                                   AND p.index_id = i.index_id;


-- Query the target data to identify the worst splitting database_id
SELECT  n.value('(value)[1]', 'bigint') AS database_id ,
        DB_NAME(n.value('(value)[1]', 'bigint')) AS database_name ,
        n.value('(@count)[1]', 'bigint') AS split_count
FROM    ( SELECT    CAST(target_data AS XML) target_data
          FROM      sys.dm_xe_sessions AS s
                    JOIN sys.dm_xe_session_targets t ON s.address = t.event_session_address
          WHERE     s.name = 'MonitorPageSplits'
                    AND t.target_name = 'histogram'
        ) AS tab
        CROSS APPLY target_data.nodes('HistogramTarget/Slot') AS q ( n );


-- Query Target Data to get the top splitting objects in the database:
SELECT  o.name AS table_name ,
        i.name AS index_name ,
        tab.split_count ,
        i.fill_factor
FROM    ( SELECT    n.value('(value)[1]', 'bigint') AS alloc_unit_id ,
                    n.value('(@count)[1]', 'bigint') AS split_count
          FROM      ( SELECT    CAST(target_data AS XML) target_data
                      FROM      sys.dm_xe_sessions AS s
                                JOIN sys.dm_xe_session_targets t ON s.address = t.event_session_address
                      WHERE     s.name = 'TrackPageSplits'
                                AND t.target_name = 'histogram'
                    ) AS tab
                    CROSS APPLY target_data.nodes('HistogramTarget/Slot') AS q ( n )
        ) AS tab
        JOIN sys.allocation_units AS au ON tab.alloc_unit_id = au.allocation_unit_id
        JOIN sys.partitions AS p ON au.container_id = p.partition_id
        JOIN sys.indexes AS i ON p.object_id = i.object_id
                                 AND p.index_id = i.index_id
        JOIN sys.objects AS o ON p.object_id = o.object_id
WHERE   o.is_ms_shipped = 0;