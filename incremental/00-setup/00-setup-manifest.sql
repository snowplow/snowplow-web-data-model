-- Create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS scratch.manifest ( -- change to derived.manifest
	etl_tstamp TIMESTAMP ENCODE ZSTD,
  CONSTRAINT scratch_manifest_pk PRIMARY KEY(etl_tstamp)
)
DISTSTYLE ALL
SORTKEY(etl_tstamp);

-- Seed the manifest table
INSERT INTO scratch.manifest(etl_tstamp) -- change to derived.manifest

  SELECT
    MIN(etl_tstamp)
  FROM
    atomic.events
  WHERE
    DATE_TRUNC('day', etl_tstamp) = DATE_TRUNC('day', GETDATE() - INTERVAL '1 week') -- replace GETDATE() - INTERVAL '1 week' with {{.start_date}}::TIMESTAMP
