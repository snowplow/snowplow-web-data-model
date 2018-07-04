-- 4. SELECT EVENT ID (PART 2)

/* Ensure that only events with page_view_id will be processed. */

-- 4a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS {{.scratch_schema}}.ids (
	event_id CHAR(36) ENCODE ZSTD,
	collector_tstamp TIMESTAMP ENCODE ZSTD,
	id CHAR(36) ENCODE ZSTD,
  CONSTRAINT {{.scratch_schema}}_ids_pk PRIMARY KEY(event_id)
)
DISTKEY(event_id)
SORTKEY(collector_tstamp);

-- 4b. truncate in case the previous run failed

TRUNCATE {{.scratch_schema}}.ids;

-- 4c. insert all event ID and timestamp that have to be processed

INSERT INTO {{.scratch_schema}}.ids (
	SELECT
		root_id,
		root_tstamp,
		id
	FROM
    {{.input_schema}}.com_snowplowanalytics_snowplow_web_page_1
	WHERE
    id IN (SELECT id FROM {{.scratch_schema}}.page_view_ids)
    AND root_tstamp <= (SELECT MAX(collector_tstamp) FROM {{.scratch_schema}}.event_ids) + INTERVAL '1 day' -- excludes timestamps "from the future";
    -- Adding 1 day because events_id only contains page_view events but we also want to consider page_pings for the last event in the batch.
    -- However that means that some rare timestamp outliers might get through.
	GROUP BY 1, 2, 3
  ORDER BY 1
);
