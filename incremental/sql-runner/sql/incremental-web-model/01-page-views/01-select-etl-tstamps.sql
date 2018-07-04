-- 1. SELECT ETL TIMESTAMPS

-- 1a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS {{.scratch_schema}}.etl_tstamps (
	etl_tstamp TIMESTAMP ENCODE ZSTD,
  CONSTRAINT {{.scratch_schema}}_etl_tstamps_pk PRIMARY KEY(etl_tstamp)
)
DISTSTYLE ALL
SORTKEY(etl_tstamp);

-- 1b. truncate in case the previous run failed

TRUNCATE {{.scratch_schema}}.etl_tstamps;

-- 1c. insert all ETL timestamps that are not in the manifest (i.e. have not been processed)

INSERT INTO {{.scratch_schema}}.etl_tstamps (
  SELECT
    etl_tstamp
	FROM
    {{.input_schema}}.events
  WHERE
    etl_tstamp NOT IN (SELECT etl_tstamp FROM {{.output_schema}}.page_views_manifest ORDER BY 1)
		AND etl_tstamp BETWEEN
      (SELECT MAX(etl_tstamp) FROM {{.output_schema}}.page_views_manifest) - INTERVAL '1 week' -- to ensure that any quarantined data is not missed
      AND
      (SELECT MAX(etl_tstamp) FROM {{.output_schema}}.page_views_manifest) + INTERVAL '{{.update_cadence}}'
    AND etl_tstamp > '{{.start_date}}'
  GROUP BY 1
  ORDER BY 1
);
