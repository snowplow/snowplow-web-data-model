-- 1. SELECT ETL TIMESTAMPS

-- 1a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS scratch.etl_tstamps (
	etl_tstamp TIMESTAMP ENCODE ZSTD,
  CONSTRAINT scratch_etl_tstamps_pk PRIMARY KEY(etl_tstamp)
)
DISTSTYLE ALL
SORTKEY(etl_tstamp);

-- 1b. change the owner to storageloader in case another user runs this step

--ALTER TABLE scratch.etl_tstamps OWNER TO storageloader;

-- 1c. truncate in case the previous run failed

TRUNCATE scratch.etl_tstamps;

-- 1d. insert all ETL timestamps that are not in the manifest (i.e. have not been processed)

INSERT INTO scratch.etl_tstamps (

  SELECT
    etl_tstamp
	FROM
    atomic.events
  WHERE
    etl_tstamp NOT IN (SELECT etl_tstamp FROM scratch.manifest ORDER BY 1) -- change to derived.manifest
		AND etl_tstamp BETWEEN
      (SELECT MAX(etl_tstamp) FROM scratch.manifest) - INTERVAL '1 week' -- to ensure that any quarantined data is not missed
      AND
      (SELECT MAX(etl_tstamp) FROM scratch.manifest) + INTERVAL '1 week' -- change to derived.manifest and to INTERVAL '{{.run_cadence}}'
  GROUP BY 1
  ORDER BY 1

);
