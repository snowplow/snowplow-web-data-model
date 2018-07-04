-- 4. APPEND USERS

ALTER TABLE {{.output_schema}}.users APPEND FROM {{.scratch_schema}}.users;
