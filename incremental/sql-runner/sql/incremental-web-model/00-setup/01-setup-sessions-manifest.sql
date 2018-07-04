/* Create and seed a manifest table for the sessions
** job.
*/

-- Create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS {{.output_schema}}.sessions_manifest (
  page_view_start_time TIMESTAMP ENCODE ZSTD,
  CONSTRAINT {{.output_schema}}_sessions_manifest_pk PRIMARY KEY(page_view_start_time)
)
DISTKEY(page_view_start_time)
SORTKEY(page_view_start_time);

-- Seed the manifest table
INSERT INTO {{.output_schema}}.sessions_manifest (
  SELECT
    MIN(page_view_start_time)
  FROM
    {{.output_schema}}.page_views
  WHERE
    DATE_TRUNC('day', page_view_start_time) = DATE_TRUNC('day', '{{.start_date}}'::TIMESTAMP)
);
