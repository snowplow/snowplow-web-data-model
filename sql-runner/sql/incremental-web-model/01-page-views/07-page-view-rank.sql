-- 7. SELECT PAGE VIEW DIMENSIONS (PART 3)

-- 7a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS scratch.page_view_rank (

  session_id CHAR(36) ENCODE ZSTD,
  session_index INT ENCODE ZSTD,

  page_view_id CHAR(36) ENCODE ZSTD NOT NULL,
  derived_tstamp TIMESTAMP ENCODE ZSTD,

  page_view_in_session_index INT8 ENCODE ZSTD,
  page_views_in_session INT8 ENCODE ZSTD,

  bounce INT4 ENCODE ZSTD,
  entrance INT4 ENCODE ZSTD,
  exit INT4 ENCODE ZSTD,
  new_user INT4 ENCODE ZSTD
)
DISTSTYLE KEY
DISTKEY (page_view_id)
SORTKEY (page_view_id);

-- 7b. change the owner to storageloader in case another user runs this step

--ALTER TABLE scratch.page_view_rank OWNER TO storageloader;

-- 7c. truncate in case the previous run failed

TRUNCATE scratch.page_view_rank;

-- 7d. insert the dimensions for page views that have not been processed

INSERT INTO scratch.page_view_rank (

  WITH new_page_views AS (

    -- select all page views in the current processing batch

    SELECT
      session_id,
      session_index,
      page_view_id,
      derived_tstamp
    FROM
      scratch.page_view_events
    WHERE
      row = 1

  ),

  remaining_page_views AS (

  -- select all page views that belong to sessions that are being
  -- processed in the current batch, but have no new events in
  -- this batch (i.e. are complete)

  SELECT
    session_id,
    session_index,
    page_view_id,
    derived_tstamp
  FROM
    scratch.page_views_test -- change to derived.page_views
  WHERE
    session_id IN (SELECT DISTINCT session_id FROM new_page_views)
    AND page_view_id NOT IN (SELECT page_view_id FROM new_page_views)

  ),

  sessions AS (

  -- union both views to get all page views for the sessions
  -- with at least one page view in the current batch

  SELECT * FROM new_page_views
    UNION
  SELECT * FROM remaining_page_views

  ),

  rank_page_views AS (

  SELECT
    session_id,
    session_index,
    page_view_id,
    derived_tstamp,
    ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY derived_tstamp) AS page_view_in_session_index,
    COUNT(*) OVER (PARTITION BY session_id) AS page_views_in_session
  FROM
    sessions

  )

SELECT
  session_id,
  session_index,
  page_view_id,
  derived_tstamp,
  page_view_in_session_index,
  page_views_in_session,
  CASE WHEN page_view_in_session_index = 1 AND page_views_in_session = 1 THEN 1 ELSE 0 END AS bounce,
  CASE WHEN page_view_in_session_index = 1 THEN 1 ELSE 0 END AS entrance,
  CASE WHEN page_view_in_session_index = page_views_in_session THEN 1 ELSE 0 END AS exit,
  CASE WHEN session_index = 1 AND page_view_in_session_index = 1 THEN 1 ELSE 0 END AS new_user
FROM
  rank_page_views

);
