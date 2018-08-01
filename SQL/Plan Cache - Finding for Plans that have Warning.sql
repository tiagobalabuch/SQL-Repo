/*************************************************************************
Author: Pedro Lopes
Date: 22/09/2017
Description: Finding for plans that have warnings
Original link: http://blogs.msdn.com/b/blogdoezequiel/
Obs.: Script was copied from internet

***************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH XMLNAMESPACES (
                       DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
                   )
, WarningSearch
AS
    (   SELECT  qp.query_plan
              , cp.usecounts
              , cp.objtype
              , wn.query( '.' ) AS StmtSimple
        FROM    sys.dm_exec_cached_plans cp
        CROSS APPLY sys.dm_exec_query_plan( cp.plan_handle ) qp
        CROSS APPLY qp.query_plan.nodes( '//StmtSimple' ) AS p(wn)
        WHERE   wn.exist( '//Warnings' ) = 1
                AND wn.exist( '@QueryHash' ) = 1 )
SELECT  StmtSimple.value( 'StmtSimple[1]/@StatementText', 'VARCHAR(4000)' ) AS sql_text
      , StmtSimple.value( 'StmtSimple[1]/@StatementId', 'int' ) AS StatementId
      , c1.value( '@NodeId', 'int' ) AS node_id
      , c1.value( '@PhysicalOp', 'sysname' ) AS physical_op
      , c1.value( '@LogicalOp', 'sysname' ) AS logical_op
      , CASE
            WHEN c2.exist( '@NoJoinPredicate[. = "1"]' ) = 1 THEN 'NoJoinPredicate'
            WHEN c3.exist( '@Database' ) = 1 THEN 'ColumnsWithNoStatistics'
        END AS warning
      , ws.objtype
      , ws.usecounts
      , ws.query_plan
      , StmtSimple.value( 'StmtSimple[1]/@QueryHash', 'VARCHAR(100)' ) AS query_hash
      , StmtSimple.value( 'StmtSimple[1]/@QueryPlanHash', 'VARCHAR(100)' ) AS query_plan_hash
      , StmtSimple.value( 'StmtSimple[1]/@StatementOptmEarlyAbortReason', 'sysname' ) AS StatementOptmEarlyAbortReason
      , StmtSimple.value( 'StmtSimple[1]/@StatementOptmLevel', 'sysname' ) AS StatementOptmLevel
FROM    WarningSearch ws
CROSS APPLY StmtSimple.nodes( '//RelOp' ) AS q1(c1)
CROSS APPLY c1.nodes( './Warnings' ) AS q2(c2)
OUTER APPLY c2.nodes( './ColumnsWithNoStatistics/ColumnReference' ) AS q3(c3)
UNION ALL
SELECT  StmtSimple.value( 'StmtSimple[1]/@StatementText', 'VARCHAR(4000)' ) AS sql_text
      , StmtSimple.value( 'StmtSimple[1]/@StatementId', 'int' ) AS StatementId
      , c3.value( '@NodeId', 'int' ) AS node_id
      , c3.value( '@PhysicalOp', 'sysname' ) AS physical_op
      , c3.value( '@LogicalOp', 'sysname' ) AS logical_op
      , CASE
            WHEN c2.exist( '@UnmatchedIndexes[. = "1"]' ) = 1 THEN 'UnmatchedIndexes'
            WHEN (
                     c4.exist( '@ConvertIssue[. = "Cardinality Estimate"]' ) = 1
                     OR c4.exist( '@ConvertIssue[. = "Seek Plan"]' ) = 1
                 ) THEN 'ConvertIssue_' + c4.value( '@ConvertIssue', 'sysname' )
        END AS warning
      , ws.objtype
      , ws.usecounts
      , ws.query_plan
      , StmtSimple.value( 'StmtSimple[1]/@QueryHash', 'VARCHAR(100)' ) AS query_hash
      , StmtSimple.value( 'StmtSimple[1]/@QueryPlanHash', 'VARCHAR(100)' ) AS query_plan_hash
      , StmtSimple.value( 'StmtSimple[1]/@StatementOptmEarlyAbortReason', 'sysname' ) AS StatementOptmEarlyAbortReason
      , StmtSimple.value( 'StmtSimple[1]/@StatementOptmLevel', 'sysname' ) AS StatementOptmLevel
FROM    WarningSearch ws
CROSS APPLY StmtSimple.nodes( '//QueryPlan' ) AS q1(c1)
CROSS APPLY c1.nodes( './Warnings' ) AS q2(c2)
CROSS APPLY c1.nodes( './RelOp' ) AS q3(c3)
OUTER APPLY c2.nodes( './PlanAffectingConvert' ) AS q4(c4)
OPTION ( RECOMPILE, MAXDOP 1 );
GO

