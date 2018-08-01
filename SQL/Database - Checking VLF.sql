/*************************************************************************
Author: Steve Stedman
Date: 22/09/2017
Description: Checking database VLF
Original link: http://stevestedman.com/2016/10/visualizing-vlfs-updated/
Obs.: Script was copied from internet
  
***************************************************************************/


DECLARE @logInfoResults AS TABLE
(
    [RecoveryUnitId] BIGINT -- only on SQL Server 2012 and newer
  , [FileId]         TINYINT
  , [FileSize]       BIGINT
  , [StartOffset]    BIGINT
  , [FSeqNo]         INTEGER
  , [Status]         TINYINT
  , [Parity]         TINYINT
  , [CreateLSN]      NUMERIC (38, 0)
);

INSERT INTO @logInfoResults
EXEC sp_executesql N'DBCC LOGINFO WITH NO_INFOMSGS';

SELECT  CAST(FileSize / 1024.0 / 1024 AS DECIMAL (20, 1)) AS FileSizeInMB
      , CASE
            WHEN FSeqNo = 0 THEN 'Available - Never Used'
            ELSE ( CASE
                       WHEN Status = 2 THEN 'In Use'
                       ELSE 'Available'
                   END
                 )
        END AS TextStatus
      , [Status]
      , REPLICATE( 'x', FileSize / MIN( FileSize ) OVER ()) AS [BarChart ________________________________________________________________________________________________]
FROM    @logInfoResults;
GO
