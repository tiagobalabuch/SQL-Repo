/*************************************************************************
Author: Pedro Lopes
Date: 22/09/2017
Description: Finding implicit conversions in the Plan Cache
Original link: http://blogs.msdn.com/b/blogdoezequiel/
Obs.: Script was copied from internet

***************************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH XMLNAMESPACES ( DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') ,
        Convertsearch
          AS (
               SELECT
                    qp.query_plan
                  , cp.usecounts
                  , cp.objtype
                  , cp.plan_handle
                  , cs.query('.') AS StmtSimple
                FROM
                    sys.dm_exec_cached_plans cp
                CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
                CROSS APPLY qp.query_plan.nodes('//StmtSimple') AS p ( cs )
                WHERE
                    cp.cacheobjtype = 'Compiled Plan' AND
                    cs.exist('@QueryHash') = 1 AND
                    cs.exist('.//ScalarOperator[contains(@ScalarString, "CONVERT_IMPLICIT")]') = 1 AND
                    cs.exist('.[contains(@StatementText, "Convertsearch")]') = 0
             )
     SELECT
            c2.value('@StatementText' , 'VARCHAR(4000)') AS sql_text
          , c2.value('@StatementId' , 'int') AS StatementId
          , c3.value('@ScalarString[1]' , 'VARCHAR(4000)') AS expression
          , ss.usecounts
          , ss.query_plan
          , StmtSimple.value('StmtSimple[1]/@QueryHash' , 'VARCHAR(100)') AS query_hash
          , StmtSimple.value('StmtSimple[1]/@QueryPlanHash' , 'VARCHAR(100)') AS query_plan_hash
          , StmtSimple.value('StmtSimple[1]/@StatementOptmEarlyAbortReason' , 'sysname') AS StatementOptmEarlyAbortReason
          , StmtSimple.value('StmtSimple[1]/@StatementOptmLevel' , 'sysname') AS StatementOptmLevel
        FROM
            Convertsearch ss
        CROSS APPLY query_plan.nodes('//StmtSimple') AS q2 ( c2 )
        CROSS APPLY c2.nodes('.//ScalarOperator[contains(@ScalarString, "CONVERT_IMPLICIT")]') AS q3 ( c3 )
    OPTION
        ( RECOMPILE, MAXDOP 1 );

GO