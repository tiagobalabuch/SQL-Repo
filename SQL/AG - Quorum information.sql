/*************************************************************************
Author: Glenn Berry
Date: 22/09/2017
Description:  Get information about any AlwaysOn AG cluster this instance is a part of
Original link: 
Obs.: Script was copied from internet 
Last Modified: September 22, 2014
(Query 17) (AlwaysOn AG Cluster)
  
***************************************************************************/


SELECT  cluster_name
      , quorum_type_desc
      , quorum_state_desc
FROM    sys.dm_hadr_cluster WITH ( NOLOCK )
OPTION ( RECOMPILE );

-- You will see no results if your instance is not using AlwaysOn AGs