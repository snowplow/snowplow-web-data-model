-- 3. SELECT PAGE VIEW ID

-- 3a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS scratch.page_view_ids (
	id CHAR(36) ENCODE ZSTD,
  CONSTRAINT scratch_page_view_ids_pk PRIMARY KEY(id)
)
DISTSTYLE ALL
SORTKEY(id);

-- 3b. change the owner to storageloader in case another user runs this step

--ALTER TABLE scratch.page_view_ids OWNER TO storageloader;

-- 3c. truncate in case the previous run failed

TRUNCATE scratch.page_view_ids;

-- 3d. insert all page view ID that have not been processed

INSERT INTO scratch.page_view_ids (

	SELECT
    id
	FROM
    atomic.com_snowplowanalytics_snowplow_web_page_1
	WHERE
    root_id || root_tstamp IN (SELECT event_id || collector_tstamp FROM scratch.event_ids)
		AND root_tstamp >= (SELECT MIN(collector_tstamp) FROM scratch.event_ids) -- for performance
  GROUP BY 1
  ORDER BY 1

);
