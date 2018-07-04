-- 4. APPEND SESSIONS

ALTER TABLE {{.output_schema}}.sessions APPEND FROM {{.scratch_schema}}.sessions;
