-- 3. DELETE SESSIONS

/* This step only deletes sessions for which we have recomputed data.
** The new data will be inserted in the next step.
*/

DELETE FROM {{.output_schema}}.sessions WHERE session_id IN (SELECT session_id FROM {{.scratch_schema}}.sessions);
