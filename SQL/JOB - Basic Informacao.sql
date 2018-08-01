/*************************************************************************
Author: Glenn Berry 
Date: 22/09/2017
Description: Get SQL Server Agent jobs and Category information
Original link: 
Obs.: Script was copied from internet
	  SQL Server 2012 Diagnostic Information Queries
	  Last Modified: September 22, 2014
	  
***************************************************************************/

SELECT  sj.name AS JobName
      , sj.description AS JobDescription
      , SUSER_SNAME( sj.owner_sid ) AS JobOwner
      , sj.date_created
      , sj.enabled
      , sj.notify_email_operator_id
      , sc.name AS CategoryName
FROM    msdb.dbo.sysjobs AS sj WITH ( NOLOCK )
INNER JOIN msdb.dbo.syscategories AS sc WITH ( NOLOCK ) ON sj.category_id = sc.category_id
ORDER BY sj.name
OPTION ( RECOMPILE );