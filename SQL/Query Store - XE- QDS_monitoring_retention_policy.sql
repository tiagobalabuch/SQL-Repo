CREATE EVENT SESSION [QDS_monitoring_retention_policy]
ON SERVER
  ADD EVENT qds.query_store_size_retention_cleanup_finished,
  ADD EVENT qds.query_store_size_retention_cleanup_started
  ADD TARGET package0.event_file
  ( SET filename = N'QDS - monitoring retention policy' )
WITH ( STARTUP_STATE = OFF );
GO


