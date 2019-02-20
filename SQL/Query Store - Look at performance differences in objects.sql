-- erin stellato
-- pluralsight


-- Look at performance differences in objects
/*
	And compare...
*/
WITH PrevData
AS
(
	SELECT 
		qsq.object_id,
		OBJECT_NAME(qsq.object_id) AS ObjectName,
		AVG(rs.avg_cpu_time) AS PrevAvgCPUTime,
		AVG(rs.avg_logical_io_reads) AS PrevAvgLogicalIO,
		AVG(rs.avg_duration) AS PrevAvgDuration,
		AVG(rs.count_executions) AS PrevAvgExecutionCount
	FROM sys.query_store_query qsq
	JOIN sys.query_store_query_text qst
		ON qsq.query_text_id = qst.query_text_id
	JOIN sys.query_store_plan qsp 
		ON qsq.query_id = qsp.query_id
	JOIN sys.query_store_runtime_stats rs
		ON qsp.plan_id = rs.plan_id
	JOIN sys.query_store_runtime_stats_interval rsi
			ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
	WHERE 
	--[qsq].[object_id] = OBJECT_ID(N'Sales.usp_GetFullProductInfo')
	--	AND 
		rs.execution_type = 0
		AND rsi.end_time <= '2017-11-17 23:59:00.0000000'
	GROUP BY qsq.object_id, OBJECT_NAME(qsq.object_id)
)
SELECT 
	OBJECT_NAME(qsq.object_id) AS ObjectName,
	PrevData.PrevAvgCPUTime,
	AVG(rs.avg_cpu_time) AS ActualAvgCPUTime,
	PrevData.PrevAvgLogicalIO,
	AVG(rs.avg_logical_io_reads) AS ActualAvgLogicalIO,
	PrevData.PrevAvgDuration,
	AVG(rs.avg_duration) AS ActualAvgDuration,
	PrevData.PrevAvgExecutionCount,
	AVG(rs.count_executions) AS ActualAvgExecutionCount
FROM sys.query_store_query qsq
JOIN sys.query_store_query_text qst
	ON qsq.query_text_id = qst.query_text_id
JOIN sys.query_store_plan qsp 
	ON qsq.query_id = qsp.query_id
JOIN sys.query_store_runtime_stats rs
	ON qsp.plan_id = rs.plan_id
JOIN sys.query_store_runtime_stats_interval rsi
		ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
JOIN PrevData
	ON qsq.object_id = PrevData.object_id
WHERE 
  --[qsq].[object_id] = OBJECT_ID(N'Sales.usp_GetFullProductInfo')
	-- AND 
	rs.execution_type = 0
	AND rsi.start_time >= '2017-11-18 00:00:00.0000000'
GROUP BY OBJECT_NAME(qsq.object_id), PrevData.PrevAvgCPUTime,
	PrevData.PrevAvgLogicalIO, PrevData.PrevAvgDuration,PrevData.PrevAvgExecutionCount;
GO

