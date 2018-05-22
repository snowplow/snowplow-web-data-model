-- 2. SELECT EVENT ID

-- 2a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS scratch.event_ids (
	event_id CHAR(36) ENCODE ZSTD,
	collector_tstamp TIMESTAMP ENCODE ZSTD,
  CONSTRAINT scratch_event_ids_pk PRIMARY KEY(event_id)
)
DISTKEY(event_id)
SORTKEY(collector_tstamp);

-- 2b. change the owner to storageloader in case another user runs this step

--ALTER TABLE scratch.event_ids OWNER TO storageloader;

-- 2c. truncate in case the previous run failed

TRUNCATE scratch.event_ids;

-- 2d. insert all event ID and timestamp that have not been processed

INSERT INTO scratch.event_ids (

	SELECT
		event_id,
		collector_tstamp
	FROM
    atomic.events
	WHERE
    etl_tstamp IN (SELECT * FROM scratch.etl_tstamps)
		AND event_name = 'page_view' -- restrict to page views for which we have the initial page view event
    AND collector_tstamp > (SELECT MIN(etl_tstamp) FROM scratch.etl_tstamps) - INTERVAL '1 week' -- for performance, but also excludes timestamp outliers
  GROUP BY 1, 2 -- in case of any duplicates
  ORDER BY 1

);
