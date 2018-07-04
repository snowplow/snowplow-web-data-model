-- 1. SELECT PAGE VIEWS TO BE PROCESSED

-- 1a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS {{.scratch_schema}}.session_page_view_ids (
  page_view_id CHAR(36) ENCODE ZSTD NOT NULL,
  CONSTRAINT {{.scratch_schema}}_session_page_view_ids_pk PRIMARY KEY(page_view_id)
)
DISTKEY(page_view_id)
SORTKEY(page_view_id);

-- 1b. truncate in case the previous run failed

TRUNCATE {{.scratch_schema}}.session_page_view_ids;

-- 1c. insert all page view ids that are not in the manifest (i.e. have not been processed),
-- as well as all previously processed page view ids that belong to sessions that have page views in the current batch

INSERT INTO {{.scratch_schema}}.session_page_view_ids (
  WITH current_batch AS (
    SELECT
      page_view_id,
      session_id
    FROM
      {{.output_schema}}.page_views
    WHERE
      page_view_start_time NOT IN (SELECT page_view_start_time FROM {{.output_schema}}.sessions_manifest)
      AND page_view_start_time < (SELECT MAX(page_view_start_time) FROM {{.output_schema}}.sessions_manifest) + INTERVAL '{{.update_cadence}}'
    GROUP BY 1, 2
    ORDER BY 1
  ),

    updated_sessions AS (
    SELECT
      page_view_id,
      session_id
    FROM
      {{.output_schema}}.page_views
    WHERE
      page_view_id NOT IN (SELECT page_view_id FROM current_batch)
      AND session_id IN (SELECT session_id FROM current_batch)
  )

  SELECT page_view_id FROM current_batch
    UNION
  SELECT page_view_id FROM updated_sessions
);
