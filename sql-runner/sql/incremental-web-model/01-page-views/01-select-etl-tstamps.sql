-- 1. SELECT ETL TIMESTAMPS

-- 1a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS {{.scratch_schema}}.etl_tstamps (
	etl_tstamp TIMESTAMP ENCODE ZSTD,
  CONSTRAINT {{.scratch_schema}}_etl_tstamps_pk PRIMARY KEY(etl_tstamp)
)
DISTSTYLE ALL
SORTKEY(etl_tstamp);

-- 1b. change the owner to {{.datamodeling_user}} in case another user runs this step

ALTER TABLE {{.scratch_schema}}.etl_tstamps OWNER TO {{.datamodeling_user}};

-- 1c. truncate in case the previous run failed

TRUNCATE {{.scratch_schema}}.etl_tstamps;

-- 1d. insert all ETL timestamps that are not in the manifest (i.e. have not been processed)

INSERT INTO {{.scratch_schema}}.etl_tstamps (

  SELECT
    etl_tstamp
	FROM
    {{.input_schema}}.events
  WHERE
    etl_tstamp NOT IN (SELECT etl_tstamp FROM {{.output_schema}}.manifest ORDER BY 1)
		AND etl_tstamp BETWEEN
      (SELECT MAX(etl_tstamp) FROM {{.output_schema}}.manifest) - INTERVAL '1 week' -- to ensure that any quarantined data is not missed
      AND
      (SELECT MAX(etl_tstamp) FROM {{.output_schema}}.manifest) + INTERVAL '{{.update_cadence}}'
  GROUP BY 1
  ORDER BY 1

);
