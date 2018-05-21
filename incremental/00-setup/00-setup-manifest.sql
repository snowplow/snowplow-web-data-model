-- Create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS scratch.manifest ( -- change to derived.manifest
	etl_tstamp TIMESTAMP ENCODE ZSTD,
  CONSTRAINT scratch_etl_tstamps_pk PRIMARY KEY(etl_tstamp)
)
DISTSTYLE ALL
SORTKEY(etl_tstamp);

-- Seed the manifest table
INSERT INTO scratch.manifest(etl_tstamp) VALUES(DATE_TRUNC('day', GETDATE() - INTERVAL '1 week')); -- change to derived.manifest and {{.start_date}}::TIMESTAMP
