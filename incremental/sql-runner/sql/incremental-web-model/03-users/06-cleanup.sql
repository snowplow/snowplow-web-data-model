-- 6. CLEAN UP

TRUNCATE {{.scratch_schema}}.user_session_ids; -- step 1
TRUNCATE {{.scratch_schema}}.users; -- step 2
