-- 7. SELECT PAGE VIEW DIMENSIONS (PART 3)

-- 7a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS {{.scratch_schema}}.page_view_rank (

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

-- 7b. truncate in case the previous run failed

TRUNCATE {{.scratch_schema}}.page_view_rank;

-- 7c. insert the dimensions

INSERT INTO {{.scratch_schema}}.page_view_rank (
  WITH prep AS (
    SELECT
      ev.session_id,
      ev.session_index,
      ev.page_view_id,
      et.min_derived_tstamp AS derived_tstamp,
      ROW_NUMBER() OVER (PARTITION BY ev.session_id ORDER BY et.min_derived_tstamp) AS page_view_in_session_index,
      COUNT(*) OVER (PARTITION BY ev.session_id) AS page_views_in_session
    FROM
      {{.scratch_schema}}.page_view_events AS ev
      INNER JOIN {{.scratch_schema}}.page_view_time AS et
        ON ev.page_view_id = et.page_view_id
    WHERE
      ev.row = 1
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
    prep
);
