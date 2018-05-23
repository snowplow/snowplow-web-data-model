-- 11. APPEND MANIFEST

ALTER TABLE {{.output_schema}}.manifest APPEND FROM {{.scratch_schema}}.etl_tstamps;
