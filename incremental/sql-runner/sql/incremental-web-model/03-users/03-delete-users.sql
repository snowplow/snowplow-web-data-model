-- 3. DELETE USERS

/* This step only deletes users for which we have recomputed data.
** The new data will be inserted in the next step.
*/

DELETE FROM {{.output_schema}}.users WHERE domain_userid IN (SELECT domain_userid FROM {{.scratch_schema}}.users);
