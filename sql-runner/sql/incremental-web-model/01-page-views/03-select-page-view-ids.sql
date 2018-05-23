-- 3. SELECT PAGE VIEW ID

-- 3a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS {{.scratch_schema}}.page_view_ids (
	id CHAR(36) ENCODE ZSTD,
  CONSTRAINT {{.scratch_schema}}_page_view_ids_pk PRIMARY KEY(id)
)
DISTSTYLE ALL
SORTKEY(id);

-- 3b. change the owner to {{.datamodeling_user}} in case another user runs this step

ALTER TABLE {{.scratch_schema}}.page_view_ids OWNER TO {{.datamodeling_user}};

-- 3c. truncate in case the previous run failed

TRUNCATE {{.scratch_schema}}.page_view_ids;

-- 3d. insert all page view ID that have not been processed

INSERT INTO {{.scratch_schema}}.page_view_ids (

	SELECT
    id
	FROM
    {{.input_schema}}.com_snowplowanalytics_snowplow_web_page_1
	WHERE
    root_id || root_tstamp IN (SELECT event_id || collector_tstamp FROM {{.scratch_schema}}.event_ids)
		AND root_tstamp >= (SELECT MIN(collector_tstamp) FROM {{.scratch_schema}}.event_ids) -- for performance
  GROUP BY 1
  ORDER BY 1

);
