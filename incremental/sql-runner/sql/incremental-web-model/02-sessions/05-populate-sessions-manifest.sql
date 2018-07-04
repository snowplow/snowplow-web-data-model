-- 5. POPULATE MANIFEST

INSERT INTO {{.output_schema}}.sessions_manifest (
  SELECT
    a.page_view_start_time
  FROM
    {{.output_schema}}.page_views AS a
    INNER JOIN {{.scratch_schema}}.session_page_view_ids AS b
      ON a.page_view_id = b.page_view_id
  WHERE
    a.page_view_start_time < (SELECT MAX(page_view_start_time) FROM {{.output_schema}}.sessions_manifest) + INTERVAL '{{.update_cadence}}' -- eliminate outliers
);
