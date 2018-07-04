-- 3. SELECT PAGE VIEW ID

-- 3a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS {{.scratch_schema}}.page_view_ids (
  id CHAR(36) ENCODE ZSTD,
  CONSTRAINT {{.scratch_schema}}_page_view_ids_pk PRIMARY KEY(id)
)
DISTSTYLE ALL
SORTKEY(id);

-- 3b. truncate in case the previous run failed

TRUNCATE {{.scratch_schema}}.page_view_ids;

-- 3c. insert all page view ID that have not been processed

INSERT INTO {{.scratch_schema}}.page_view_ids (
  WITH new_batch AS ( -- Select the page view IDs of all events that are in the current batch
    SELECT
      id
    FROM
      {{.input_schema}}.com_snowplowanalytics_snowplow_web_page_1
    WHERE
      root_id || root_tstamp IN (SELECT event_id || collector_tstamp FROM {{.scratch_schema}}.event_ids)
      AND root_tstamp >= (SELECT MIN(collector_tstamp) FROM {{.scratch_schema}}.event_ids) -- for performance
    GROUP BY 1
    ORDER BY 1
  ),

  running_sessions AS ( -- Select all page view IDs from already processed sessions, if there are new events for those sessions
    SELECT
      page_view_id AS id
    FROM
      {{.output_schema}}.page_views
    WHERE
      session_id IN (SELECT domain_sessionid FROM {{.scratch_schema}}.event_ids)
  )

  SELECT * FROM new_batch
    UNION
  SELECT * FROM running_sessions
);
