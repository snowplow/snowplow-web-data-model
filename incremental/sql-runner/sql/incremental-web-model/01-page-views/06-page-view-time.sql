-- 6. SELECT PAGE VIEW DIMENSIONS (PART 2)

-- 6a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS {{.scratch_schema}}.page_view_time (

  page_view_id CHAR(36) ENCODE ZSTD NOT NULL,

  min_derived_tstamp TIMESTAMP ENCODE ZSTD,
  max_derived_tstamp TIMESTAMP ENCODE ZSTD,

  min_dvce_created_tstamp TIMESTAMP ENCODE ZSTD,
  max_dvce_created_tstamp TIMESTAMP ENCODE ZSTD,

  time_engaged_in_s INT8 ENCODE ZSTD

)
DISTSTYLE KEY
DISTKEY (page_view_id)
SORTKEY (page_view_id);

-- 6b. truncate in case the previous run failed

TRUNCATE {{.scratch_schema}}.page_view_time;

-- 6c. insert the dimensions

INSERT INTO {{.scratch_schema}}.page_view_time (

	SELECT

    id.id AS page_view_id,

    MIN(ev.derived_tstamp) AS min_derived_tstamp,
    MAX(ev.derived_tstamp) AS max_derived_tstamp,

    MIN(ev.dvce_created_tstamp) AS min_dvce_created_tstamp,
    MAX(ev.dvce_created_tstamp) AS max_dvce_created_tstamp,

    30 * COUNT(DISTINCT(FLOOR(EXTRACT(EPOCH FROM ev.derived_tstamp)/30))) - 30 AS time_engaged_in_s -- assumes 30 seconds between page pings

	FROM
    {{.input_schema}}.events AS ev
    INNER JOIN {{.scratch_schema}}.ids AS id
		  ON ev.event_id = id.event_id AND ev.collector_tstamp = id.collector_tstamp

	WHERE
    ev.event_name IN ('page_view', 'page_ping')

  GROUP BY 1

);
