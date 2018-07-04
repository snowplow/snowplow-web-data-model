-- 12. APPEND MANIFEST

ALTER TABLE {{.output_schema}}.page_views_manifest APPEND FROM {{.scratch_schema}}.etl_tstamps;
