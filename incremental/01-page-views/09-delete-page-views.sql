-- 9. DELETE PAGE VIEWS

/* This step only deletes events for which we have recomputed data. The new data will be inserted in the next step. */

DELETE FROM scratch.page_views_test WHERE page_view_id IN (SELECT page_view_id FROM scratch.page_views); -- change to derived.page_views
