-- 10. APPEND PAGE VIEWS

ALTER TABLE {{.output_schema}}.page_views APPEND FROM {{.scratch_schema}}.page_views;
