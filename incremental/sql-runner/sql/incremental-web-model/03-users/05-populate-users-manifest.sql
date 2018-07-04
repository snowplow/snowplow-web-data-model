-- 5. POPULATE MANIFEST

INSERT INTO {{.output_schema}}.users_manifest (
  SELECT
    a.session_start_time
  FROM
    {{.output_schema}}.sessions AS a
    INNER JOIN {{.scratch_schema}}.user_session_ids AS b
      ON a.session_id = b.session_id
  WHERE
    a.session_start_time  < (SELECT MAX(session_start_time) FROM {{.output_schema}}.users_manifest) + INTERVAL '{{.update_cadence}}' -- eliminate outliers
);
