/*************************************************************************
Author: Tiago Balabuch
Date: 22/09/2017
Description: Function LEN() does not count trailing spaces 
Original link: 
Obs.: Script was copied from internet

***************************************************************************/

DECLARE @pattern VARCHAR(20) = 'Ted ';
DECLARE @columnToSearch VARCHAR(1000) = 'Ted is Ted because Ted is awesome!';

SELECT  ( DATALENGTH(@columnToSearch) - DATALENGTH(REPLACE(@columnToSearch , @pattern , '')) ) / DATALENGTH(@pattern) DatalengthNumberOfMatches
      , ( LEN(@columnToSearch) - LEN(REPLACE(@columnToSearch , @pattern , '')) ) / LEN(@pattern) AS LenNumberOfMatches
      , ( LEN(@columnToSearch) - LEN(REPLACE(@columnToSearch , @pattern , '')) ) AS LenPattern
      , LEN(@pattern) AS Len@pattern
      , DATALENGTH(@pattern) AS Datalength@pattern;
