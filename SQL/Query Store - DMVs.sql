USE celtrak_data;
GO

SELECT * FROM sys.query_store_query_text;

SELECT * FROM sys.query_store_query;
SELECT * FROM sys.query_store_plan;
SELECT * FROM sys.query_context_settings;
SELECT * FROM sys.query_store_runtime_stats;
SELECT * FROM sys.query_store_runtime_stats_interval;

SELECT
  actual_state_desc,
  readonly_reason,
  desired_state_desc,
  current_storage_size_mb,
  max_storage_size_mb,
  flush_interval_seconds,
  interval_length_minutes,
  stale_query_threshold_days,
  size_based_cleanup_mode_desc,
  query_capture_mode_desc,
  max_plans_per_query
FROM sys.database_query_store_options;
GO