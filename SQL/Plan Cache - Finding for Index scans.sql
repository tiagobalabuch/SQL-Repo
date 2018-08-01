/*************************************************************************
Author: Pedro Lopes
Date: 22/09/2017
Description: Finding index scan
Original link: http://blogs.msdn.com/b/blogdoezequiel/
Obs.: Script was copied from internet

***************************************************************************/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
WITH XMLNAMESPACES (
                       DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
                   )
, Scansearch
AS
    (   SELECT  qp.query_plan
              , cp.usecounts
              , ss.query( '.' ) AS StmtSimple
        FROM    sys.dm_exec_cached_plans cp
        CROSS APPLY sys.dm_exec_query_plan( cp.plan_handle ) qp
        CROSS APPLY qp.query_plan.nodes( '//StmtSimple' ) AS p(ss)
        WHERE   cp.cacheobjtype = 'Compiled Plan'
                AND (
                        ss.exist( '//RelOp[@PhysicalOp = "Index Scan"]' ) = 1
                        OR  ss.exist( '//RelOp[@PhysicalOp = "Clustered Index Scan"]' ) = 1
                    )
                AND ss.exist( '@QueryHash' ) = 1 )
SELECT  StmtSimple.value( 'StmtSimple[1]/@StatementText', 'VARCHAR(4000)' ) AS sql_text
      , StmtSimple.value( 'StmtSimple[1]/@StatementId', 'int' ) AS StatementId
      , c1.value( '@NodeId', 'int' ) AS node_id
      , c2.value( '@Database', 'sysname' ) AS database_name
      , c2.value( '@Schema', 'sysname' ) AS [schema_name]
      , c2.value( '@Table', 'sysname' ) AS table_name
      , c1.value( '@PhysicalOp', 'sysname' ) AS physical_operator
      , c2.value( '@Index', 'sysname' ) AS index_name
      , c3.value( '@ScalarString[1]', 'VARCHAR(4000)' ) AS predicate
      , c1.value( '@TableCardinality', 'sysname' ) AS table_cardinality
      , ss.usecounts
      , ss.query_plan
      , StmtSimple.value( 'StmtSimple[1]/@QueryHash', 'VARCHAR(100)' ) AS query_hash
      , StmtSimple.value( 'StmtSimple[1]/@QueryPlanHash', 'VARCHAR(100)' ) AS query_plan_hash
      , StmtSimple.value( 'StmtSimple[1]/@StatementOptmEarlyAbortReason', 'sysname' ) AS StatementOptmEarlyAbortReason
      , StmtSimple.value( 'StmtSimple[1]/@StatementOptmLevel', 'sysname' ) AS StatementOptmLevel
FROM    Scansearch ss
CROSS APPLY query_plan.nodes( '//RelOp' ) AS q1(c1)
CROSS APPLY c1.nodes( './IndexScan/Object' ) AS q2(c2)
OUTER APPLY c1.nodes( './IndexScan/Predicate/ScalarOperator[1]' ) AS q3(c3)
WHERE   (
            c1.exist( '@PhysicalOp[. = "Index Scan"]' ) = 1
            OR  c1.exist( '@PhysicalOp[. = "Clustered Index Scan"]' ) = 1
        )
        AND c2.value( '@Schema', 'sysname' ) <> '[sys]'
OPTION ( RECOMPILE, MAXDOP 1 );
GO

