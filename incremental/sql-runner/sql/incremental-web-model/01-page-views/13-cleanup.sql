-- 13. CLEAN UP

TRUNCATE {{.scratch_schema}}.etl_tstamps; -- step 1
TRUNCATE {{.scratch_schema}}.event_ids; -- step 2
TRUNCATE {{.scratch_schema}}.page_view_ids; -- step 3
TRUNCATE {{.scratch_schema}}.ids; -- step 4
TRUNCATE {{.scratch_schema}}.page_view_events; -- step 5
TRUNCATE {{.scratch_schema}}.page_view_time; -- step 6
TRUNCATE {{.scratch_schema}}.page_view_rank; -- step 7
TRUNCATE {{.scratch_schema}}.events_scroll_depth; -- step 8
TRUNCATE {{.scratch_schema}}.page_views; -- step 9
