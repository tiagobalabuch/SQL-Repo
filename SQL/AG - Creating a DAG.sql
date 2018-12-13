/*************************************************************************
Author: Tiago Balabuch
Date: 13/12/2018
Description:  Creating a new DAG
Original link: 
Obs.: To get LISTENER URL you can use AG - Calculating read only routing.sql
  
***************************************************************************/


-- DROPPING DAG
USE master
GO

DROP AVAILABILITY GROUP [DAG_AG1]   

-- CREATING DAG

CREATE AVAILABILITY GROUP [DAG_AG1]   
   WITH (DISTRIBUTED)   
   AVAILABILITY GROUP ON  
       'AG1'  WITH    
      (   
         LISTENER_URL = 'tcp://lister_name_AG.your_domain:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
         FAILOVER_MODE = MANUAL, -- AUTOMATIC   
         SEEDING_MODE = MANUAL   -- AUTOMATIC
      ),   
      'NEW_AG1' WITH    
      (   
         LISTENER_URL = 'tcp://lister_name_AG.your_domain:5022',   
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
         FAILOVER_MODE = MANUAL, -- AUTOMATIC  
         SEEDING_MODE = MANUAL   -- AUTOMATIC  
      );    
GO 

-- JOINING DAG
ALTER AVAILABILITY GROUP [DAG_UAT_SQL_SERVER_AG]   
JOIN
   AVAILABILITY GROUP ON  
       'UAT_SQL_SERVER_AG'  WITH    
      (   
         LISTENER_URL = 'tcp://lister_name_AG.your_domain:5022',    
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
         FAILOVER_MODE = MANUAL,   -- AUTOMATIC
         SEEDING_MODE = MANUAL     -- AUTOMATIC
      ),   
      'UAT_AG' WITH    
      (   
         LISTENER_URL = 'tcp://lister_name_AG.your_domain:5022',   
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,   
         FAILOVER_MODE = MANUAL,   -- AUTOMATIC
         SEEDING_MODE = MANUAL     -- AUTOMATIC
      );    
GO 

