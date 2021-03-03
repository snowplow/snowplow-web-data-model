-- 2. SELECT EVENT ID

-- 2a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS {{.scratch_schema}}.event_ids (
  event_id CHAR(36) ENCODE ZSTD,
  collector_tstamp TIMESTAMP ENCODE ZSTD,
  domain_sessionid CHAR(128) ENCODE ZSTD,
  CONSTRAINT {{.scratch_schema}}_event_ids_pk PRIMARY KEY(event_id)
)
DISTKEY(event_id)
SORTKEY(collector_tstamp);

-- 2b. truncate in case the previous run failed

TRUNCATE {{.scratch_schema}}.event_ids;

-- 2c. insert all event ID and timestamp that have not been processed

INSERT INTO {{.scratch_schema}}.event_ids (
  SELECT
    event_id,
    collector_tstamp,
    domain_sessionid
  FROM
    {{.input_schema}}.events
  WHERE
    etl_tstamp IN (SELECT * FROM {{.scratch_schema}}.etl_tstamps)
    AND event_name = 'page_view' -- restrict to page views for which we have the initial page view event
    AND collector_tstamp > (SELECT MIN(etl_tstamp) FROM {{.scratch_schema}}.etl_tstamps) - INTERVAL '1 week' -- for performance, but also excludes timestamp outliers
    AND collector_tstamp >= '{{.start_date}}'::TIMESTAMP -- excludes timestamp outliers
    AND derived_tstamp >= '{{.start_date}}'::TIMESTAMP -- excludes timestamp outliers
  GROUP BY 1, 2, 3 -- in case of any duplicates
  ORDER BY 1
);
