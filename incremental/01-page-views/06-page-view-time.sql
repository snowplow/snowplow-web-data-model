-- 6. SELECT PAGE VIEW DIMENSIONS (PART 2)

-- 6a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS scratch.page_view_time (

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

-- 6b. change the owner to storageloader in case another user runs this step

--ALTER TABLE scratch.page_view_time OWNER TO storageloader;

-- 6c. truncate in case the previous run failed

TRUNCATE scratch.page_view_time;

-- 6d. insert the dimensions for page views that have not been processed

INSERT INTO scratch.page_view_time (

	SELECT

    id.id AS page_view_id,

    MIN(ev.derived_tstamp) AS min_derived_tstamp,
    MAX(ev.derived_tstamp) AS max_derived_tstamp,

    MIN(ev.dvce_created_tstamp) AS min_dvce_created_tstamp,
    MAX(ev.dvce_created_tstamp) AS max_dvce_created_tstamp,

    30 * COUNT(DISTINCT(FLOOR(EXTRACT(EPOCH FROM ev.derived_tstamp)/30))) - 30 AS time_engaged_in_s -- assumes 30 seconds between page pings

	FROM atomic.events AS ev

	INNER JOIN scratch.ids AS id
		ON ev.event_id = id.event_id AND ev.collector_tstamp = id.collector_tstamp

	WHERE ev.event_name IN ('page_view', 'page_ping')
    AND ev.collector_tstamp >= (SELECT MIN(collector_tstamp) FROM scratch.event_ids) - INTERVAL '1 week' -- for performance

  GROUP BY 1

);
