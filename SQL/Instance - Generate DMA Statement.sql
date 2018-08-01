
/*************************************************************************
Author: Kenneth Fisher
Date : 22/09/2017
Description: Dynamically generate the command line DMA statement for each database
Original link: https://sqlstudies.com/2017/06/21/query-to-run-command-line-dma-on-each-database
Obs.: Script was copied from internet

***************************************************************************/
SELECT  name
      , '"C:\Program Files\Microsoft Data Migration Assistant\DmaCmd.exe" ' + '/AssessmentName="DMA_Output" ' + '/AssessmentDatabases="Server=' + @@ServerName +
        ';Initial Catalog=' + sys.databases.name + ';Integrated Security=true" ' + '/AssessmentEvaluateCompatibilityIssues /AssessmentOverwriteResult ' +
        '/AssessmentResultCSV="\\PathToSaveTo\' + REPLACE(@@ServerName , '\' , '_') + '\' + sys.databases.name + '.CSV"' + ' > "\\PathToSaveTo\' +
        REPLACE(@@ServerName , '\' , '_') + '\' + sys.databases.name + '.LOG"'
FROM    sys.databases
WHERE   state <> 6 -- exclude offline databases
        AND
        database_id > 4; -- Exclude system databases
  