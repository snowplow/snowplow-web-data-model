-- 4. SELECT EVENT ID (PART 2)

/* Ensure that only events with page_view_id will be processed. */

-- 4a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS scratch.ids (
	event_id CHAR(36) ENCODE ZSTD,
	collector_tstamp TIMESTAMP ENCODE ZSTD,
	id CHAR(36) ENCODE ZSTD,
  CONSTRAINT scratch_ids_pk PRIMARY KEY(event_id)
)
DISTKEY(event_id)
SORTKEY(collector_tstamp);

-- 4b. change the owner to storageloader in case another user runs this step

--ALTER TABLE scratch.ids OWNER TO storageloader;

-- 4c. truncate in case the previous run failed

TRUNCATE scratch.ids;

-- 4d. insert all event ID and timestamp that have not been processed

INSERT INTO scratch.ids (

		SELECT
			root_id,
			root_tstamp,
			id
		FROM
      atomic.com_snowplowanalytics_snowplow_web_page_1
		WHERE
      id IN (SELECT id FROM scratch.page_view_ids)
			AND root_tstamp >= (SELECT MIN(collector_tstamp) FROM scratch.event_ids) -- for performance
		GROUP BY 1, 2, 3
	  ORDER BY 1

);
