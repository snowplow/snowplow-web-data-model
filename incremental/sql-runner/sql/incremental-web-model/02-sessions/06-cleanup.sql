-- 6. CLEAN UP

TRUNCATE {{.scratch_schema}}.session_page_view_ids; -- step 1
TRUNCATE {{.scratch_schema}}.sessions; -- step 2
