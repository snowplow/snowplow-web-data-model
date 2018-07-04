/* Create and seed a manifest table for the users
** job.
*/

-- Create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS {{.output_schema}}.users_manifest (
  session_start_time TIMESTAMP ENCODE ZSTD,
  CONSTRAINT {{.output_schema}}_users_manifest_pk PRIMARY KEY(session_start_time)
)
DISTKEY(session_start_time)
SORTKEY(session_start_time);

-- Seed the manifest table
INSERT INTO {{.output_schema}}.users_manifest (
  SELECT
    MIN(session_start_time)
  FROM
    {{.output_schema}}.sessions
  WHERE
    DATE_TRUNC('day', session_start_time) = DATE_TRUNC('day', '{{.start_date}}'::TIMESTAMP)
);
