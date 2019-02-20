-- link: https://docs.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store

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
