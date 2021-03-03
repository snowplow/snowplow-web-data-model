-- 1. SELECT SESSIONS TO BE PROCESSED

-- 1a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS {{.scratch_schema}}.user_session_ids (
  session_id CHAR(128) ENCODE ZSTD NOT NULL,
  CONSTRAINT {{.scratch_schema}}_user_session_ids_pk PRIMARY KEY(session_id)
)
DISTKEY(session_id)
SORTKEY(session_id);

-- 1b. truncate in case the previous run failed

TRUNCATE {{.scratch_schema}}.user_session_ids;

-- 1c. insert all session ids for sessions whose start time is not in the manifest (i.e. have not been processed),
-- as well as all previously processed sessions that belong to users who have sessions in the current batch (as those will have to be recalculated)

INSERT INTO {{.scratch_schema}}.user_session_ids (
  WITH current_batch AS (
    SELECT
      session_id,
      domain_userid
    FROM
      {{.output_schema}}.sessions
    WHERE
      session_start_time NOT IN (SELECT session_start_time FROM {{.output_schema}}.users_manifest)
      AND session_start_time < (SELECT MAX(session_start_time) FROM {{.output_schema}}.users_manifest) + INTERVAL '{{.update_cadence}}'
    GROUP BY 1, 2
    ORDER BY 1
  ),

    updated_sessions AS (
    SELECT
      session_id,
      domain_userid
    FROM
      {{.output_schema}}.sessions
    WHERE
      session_id NOT IN (SELECT session_id FROM current_batch)
      AND domain_userid IN (SELECT domain_userid FROM current_batch)
  )

  SELECT session_id FROM current_batch
    UNION
  SELECT session_id FROM updated_sessions
);
