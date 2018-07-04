-- 10. DELETE PAGE VIEWS

/* This step only deletes events for which we have recomputed data.
** The new data will be inserted in the next step.
*/

DELETE FROM {{.output_schema}}.page_views WHERE page_view_id IN (SELECT page_view_id FROM {{.scratch_schema}}.page_views);
