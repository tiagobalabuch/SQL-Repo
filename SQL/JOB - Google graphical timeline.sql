/*************************************************************************
Author: Theo Ekelmans
Date: 22/09/2017
Description: This script returns a (graphical) timeline for all SQL jobs using google graph
Original link: http://www.sqlservercentral.com/articles/Agent+jobs/127346/
Obs.: Script was copied from internet
  
***************************************************************************/

SET NOCOUNT ON;

DECLARE @DT DATETIME;
DECLARE @StartDT DATETIME;
DECLARE @EndDT DATETIME;
DECLARE @MinRuntimeInSec INT;
DECLARE @SendMail INT;
DECLARE @ReturnRecocordset INT;
DECLARE @Emailprofilename VARCHAR (50);
DECLARE @EmailRecipients VARCHAR (50);

--***************************************************************************************
-- Set variables
--***************************************************************************************
SET @StartDT = GETDATE() - 30;
SET @EndDT = GETDATE();
SET @MinRuntimeInSec = 1; --Ignore jobs with runtime smaller then this

SET @ReturnRecocordset = 0;
SET @SendMail = 1;
SET @Emailprofilename = '<ProfileName>';
SET @EmailRecipients = '<email>';

--***************************************************************************************
-- Pre-run cleanup (just in case)
--***************************************************************************************
IF OBJECT_ID( 'tempdb..#JobRuntime' ) IS NOT NULL
    DROP TABLE #JobRuntime;
IF OBJECT_ID( 'tempdb..##GoogleGraph' ) IS NOT NULL
    DROP TABLE ##GoogleGraph;

--***************************************************************************************
-- Create a table for HTML assembly
--***************************************************************************************
CREATE TABLE ##GoogleGraph
(
    [ID]   [INT]            IDENTITY (1, 1) NOT NULL
  , [HTML] [VARCHAR] (8000) NULL
);

--***************************************************************************************
-- Create the Job Runtime information table
--***************************************************************************************
SELECT  job.name AS JobName
      , cat.name AS CatName
      , CONVERT(
                   DATETIME
                 , CONVERT( CHAR (8), run_date, 112 ) + ' ' + STUFF( STUFF( RIGHT('000000' + CONVERT( VARCHAR (8), run_time ), 6), 5, 0, ':' ), 3, 0, ':' )
                 , 120
               ) AS SDT
      , DATEADD(
                   s
                 , (( run_duration / 10000 ) % 100 * 3600 ) + (( run_duration / 100 ) % 100 * 60 ) + run_duration % 100
                 , CONVERT(
                              DATETIME
                            , CONVERT( CHAR (8), run_date, 112 ) + ' '
                              + STUFF( STUFF( RIGHT('000000' + CONVERT( VARCHAR (8), run_time ), 6), 5, 0, ':' ), 3, 0, ':' )
                            , 120
                          )
               ) AS EDT
INTO    #JobRuntime
FROM    msdb.dbo.sysjobs job
LEFT JOIN msdb.dbo.sysjobhistory his ON his.job_id = job.job_id
INNER JOIN msdb.dbo.syscategories cat ON job.category_id = cat.category_id
WHERE   CONVERT(
                   DATETIME
                 , CONVERT( CHAR (8), run_date, 112 ) + ' ' + STUFF( STUFF( RIGHT('000000' + CONVERT( VARCHAR (8), run_time ), 6), 5, 0, ':' ), 3, 0, ':' )
                 , 120
               ) BETWEEN @StartDT AND @EndDT
        AND step_id = 0 -- step_id = 0 is the entire job, step_id > 0 is actual step number
        AND (( run_duration / 10000 ) % 100 * 3600 ) + (( run_duration / 100 ) % 100 * 60 ) + run_duration % 100 > @MinRuntimeInSec -- Ignore trivial runtimes
ORDER BY SDT;

IF NOT EXISTS (
                  SELECT    1
                  FROM  #JobRuntime
              )
    GOTO NothingToDo;

--***************************************************************************************
-- Format for google graph - Header 
-- (Split into multiple inserts because the default text result setting is 256 chars)
--***************************************************************************************
INSERT INTO ##GoogleGraph (
                              HTML
                          )
SELECT  '<html>
	<head>
	<!--<META HTTP-EQUIV="refresh" CONTENT="3">-->
	<script type="text/javascript" src="https://www.google.com/jsapi?autoload={''modules'':[{''name'':''visualization'', ''version'':''1'',''packages'':[''timeline'']}]}"></script>';
INSERT INTO ##GoogleGraph (
                              HTML
                          )
SELECT  '    <script type="text/javascript">
	google.setOnLoadCallback(drawChart);
	function drawChart() {';
INSERT INTO ##GoogleGraph (
                              HTML
                          )
SELECT  '	var container = document.getElementById(''JobTimeline'');
	var chart = new google.visualization.Timeline(container);
	var dataTable = new google.visualization.DataTable();';
INSERT INTO ##GoogleGraph (
                              HTML
                          )
SELECT  '	dataTable.addColumn({ type: ''string'', id: ''Position'' });
	dataTable.addColumn({ type: ''string'', id: ''Name'' });
	dataTable.addColumn({ type: ''date'', id: ''Start'' });
	dataTable.addColumn({ type: ''date'', id: ''End'' });
	dataTable.addRows([
';

--***************************************************************************************
-- Format for google graph - Data
--***************************************************************************************
INSERT INTO ##GoogleGraph (
                              HTML
                          )
SELECT  '		[ ' + '''' + CatName + ''', ' + '''' + JobName + ''', ' + 'new Date(' + CAST(DATEPART( YEAR, SDT ) AS VARCHAR (4)) + ', '
        + CAST(DATEPART( MONTH, SDT ) - 1 AS VARCHAR (4)) --Java months count from 0
        + ', ' + CAST(DATEPART( DAY, SDT ) AS VARCHAR (4)) + ', ' + CAST(DATEPART( HOUR, SDT ) AS VARCHAR (4)) + ', '
        + CAST(DATEPART( MINUTE, SDT ) AS VARCHAR (4)) + ', ' + CAST(DATEPART( SECOND, SDT ) AS VARCHAR (4)) + '), ' + 'new Date('
        + CAST(DATEPART( YEAR, EDT ) AS VARCHAR (4)) + ', ' + CAST(DATEPART( MONTH, EDT ) - 1 AS VARCHAR (4)) --Java months count from 0
        + ', ' + CAST(DATEPART( DAY, EDT ) AS VARCHAR (4)) + ', ' + CAST(DATEPART( HOUR, EDT ) AS VARCHAR (4)) + ', '
        + CAST(DATEPART( MINUTE, EDT ) AS VARCHAR (4)) + ', ' + CAST(DATEPART( SECOND, EDT ) AS VARCHAR (4)) + ') ],' --+ char(10)
FROM    #JobRuntime;

--***************************************************************************************
-- Format for google graph - Footer
--***************************************************************************************
INSERT INTO ##GoogleGraph (
                              HTML
                          )
SELECT  '	]);

	var options = 
	{
		timeline: 	{ 
					groupByRowLabel: true,
					colorByRowLabel: false,
					singleColor: false,
					rowLabelStyle: {fontName: ''Helvetica'', fontSize: 14 },
					barLabelStyle: {fontName: ''Helvetica'', fontSize: 14 }					
					}
	};

	chart.draw(dataTable, options);

}';
INSERT INTO ##GoogleGraph (
                              HTML
                          )
SELECT  '
	</script>
	</head>
	<body>' + '<font face="Helvetica" size="3" >' + 'Job timeline on: ' + @@servername + ' from ' + CONVERT( VARCHAR (20), @StartDT, 120 ) + ' until '
        + CONVERT( VARCHAR (20), @EndDT, 120 ) + CASE
                                                     WHEN @MinRuntimeInSec = 0 THEN ''
                                                     ELSE ' (hiding jobs with runtime < ' + CAST(@MinRuntimeInSec AS VARCHAR (10)) + ' seconds)'
                                                 END + '</font>
		<div id="JobTimeline" style="width: 1885px; height: 900px;"></div>
	</body>
</html>';

--***************************************************************************************
-- Output HTML page - copy output & paste to a .HTML file and open with google chrome
--***************************************************************************************
IF @ReturnRecocordset = 1
    SELECT  HTML
    FROM    ##GoogleGraph
    ORDER BY ID;

--***************************************************************************************
-- Send Email - 
--***************************************************************************************
IF @SendMail = 1
    EXECUTE msdb.dbo.sp_send_dbmail @profile_name = @Emailprofilename
                                  , @recipients = @EmailRecipients
                                  , @subject = 'JobTimeline'
                                  , @body = 'See attachment for JobTimeline, open with Google Chrome!'
                                  , @body_format = 'HTML'           -- or TEXT
                                  , @importance = 'Normal'          --Low Normal High
                                  , @sensitivity = 'Normal'         --Normal Personal Private Confidential
                                  , @execute_query_database = 'master'
                                  , @query_result_header = 1
                                  , @query = 'set nocount on; SELECT HTML FROM ##GoogleGraph'
                                  , @query_result_no_padding = 1    -- prevent SQL adding padding spaces in the result
                                                                    --,@query_no_truncate= 1       -- mutually exclusive with @query_result_no_padding 
                                  , @attach_query_result_as_file = 1
                                  , @query_attachment_filename = 'JobTimeline.HTML';


GOTO Cleanup;

--***************************************************************************************
-- Just in case....
--***************************************************************************************
NothingToDo:

PRINT 'No job runtime info found....';

--***************************************************************************************
-- Cleanup
--***************************************************************************************
Cleanup:
IF OBJECT_ID( 'tempdb..#JobRuntime' ) IS NOT NULL
    DROP TABLE #JobRuntime;
IF OBJECT_ID( 'tempdb..##GoogleGraph' ) IS NOT NULL
    DROP TABLE ##GoogleGraph;
