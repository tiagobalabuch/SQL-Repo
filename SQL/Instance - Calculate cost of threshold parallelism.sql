/*************************************************************************
Author: Unknown 
Date: 01/08/2018
Description: Calculate cost of threshold parallelism
Original link: 
Obs.: Script was copied from internet 
  
***************************************************************************/
WITH XMLNAMESPACES (
                       DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
                   )
SELECT  query_plan AS CompleteQueryPlan
      , n.value( '(@StatementText)[1]', 'VARCHAR(4000)' ) AS StatementText
      , n.value( '(@StatementOptmLevel)[1]', 'VARCHAR(25)' ) AS StatementOptimizationLevel
      , n.value( '(@StatementSubTreeCost)[1]', 'VARCHAR(128)' ) AS StatementSubTreeCost
      , n.query( '.' ) AS ParallelSubTreeXML
      , ecp.usecounts
      , ecp.size_in_bytes
FROM    sys.dm_exec_cached_plans AS ecp
CROSS APPLY sys.dm_exec_query_plan( plan_handle ) AS eqp
CROSS APPLY query_plan.nodes( '/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple' ) AS qn(n)
WHERE   n.query( '.' ).exist( '//RelOp[@PhysicalOp="Parallelism"]' ) = 1;

--capture
CREATE TABLE #SubtreeCost
(
    StatementSubtreeCost DECIMAL (18, 2)
);

;WITH XMLNAMESPACES (
                        DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
                    )
INSERT INTO #SubtreeCost
SELECT  CAST(n.value( '(@StatementSubTreeCost)[1]', 'VARCHAR(128)' ) AS DECIMAL (18, 2))
FROM    sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_query_plan( plan_handle ) AS qp
CROSS APPLY query_plan.nodes( '/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple' ) AS qn(n)
WHERE   n.query( '.' ).exist( '//RelOp[@PhysicalOp="Parallelism"]' ) = 1;

SELECT  StatementSubtreeCost
FROM    #SubtreeCost
ORDER BY 1;

SELECT  AVG( StatementSubtreeCost ) AS AverageSubtreeCost
FROM    #SubtreeCost;

SELECT  (
            SELECT TOP 1
                StatementSubtreeCost
            FROM    (
                        SELECT TOP 50 PERCENT
                            StatementSubtreeCost
                        FROM    #SubtreeCost
                        ORDER BY StatementSubtreeCost ASC
                    ) AS A
            ORDER BY StatementSubtreeCost DESC
        ) + (
                SELECT TOP 1
                    StatementSubtreeCost
                FROM    (
                            SELECT TOP 50 PERCENT
                                StatementSubtreeCost
                            FROM    #SubtreeCost
                            ORDER BY StatementSubtreeCost DESC
                        ) AS A
                ORDER BY StatementSubtreeCost ASC
            ) / 2 AS MEDIAN;

SELECT TOP 1
    StatementSubtreeCost AS MODE
FROM    #SubtreeCost
GROUP BY StatementSubtreeCost
ORDER BY COUNT( 1 ) DESC;

DROP TABLE #SubtreeCost;