-- 8. SELECT PAGE VIEW DIMENSIONS (PART 4)

-- 8a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS {{.scratch_schema}}.events_scroll_depth (
  page_view_id CHAR(36) ENCODE ZSTD NOT NULL,

  doc_width INT ENCODE ZSTD,
  doc_height INT ENCODE ZSTD,

  br_viewwidth INT ENCODE ZSTD,
  br_viewheight INT ENCODE ZSTD,

  hmin INT ENCODE ZSTD,
  hmax INT ENCODE ZSTD,
  vmin INT ENCODE ZSTD,
  vmax INT ENCODE ZSTD,

  relative_hmin DOUBLE PRECISION ENCODE ZSTD,
  relative_hmax DOUBLE PRECISION ENCODE ZSTD,
  relative_vmin DOUBLE PRECISION ENCODE ZSTD,
  relative_vmax DOUBLE PRECISION ENCODE ZSTD
)
DISTSTYLE KEY
DISTKEY (page_view_id)
SORTKEY (page_view_id);

-- 8b. truncate in case the previous run failed

TRUNCATE {{.scratch_schema}}.events_scroll_depth;

-- 8c. insert the dimensions

INSERT INTO {{.scratch_schema}}.events_scroll_depth (
  WITH prep AS (
    SELECT
      wp.id,

      MAX(ev.doc_width) AS doc_width,
      MAX(ev.doc_height) AS doc_height,

      MAX(ev.br_viewwidth) AS br_viewwidth,
      MAX(ev.br_viewheight) AS br_viewheight,

      -- NVL replaces NULL with 0 (because the page view event does send an offset)
      -- GREATEST prevents outliers (negative offsets)
      -- LEAST also prevents outliers (offsets greater than the docwidth or docheight)

      LEAST(GREATEST(MIN(NVL(ev.pp_xoffset_min, 0)), 0), MAX(ev.doc_width)) AS hmin, -- should be zero
      LEAST(GREATEST(MAX(NVL(ev.pp_xoffset_max, 0)), 0), MAX(ev.doc_width)) AS hmax,

      LEAST(GREATEST(MIN(NVL(ev.pp_yoffset_min, 0)), 0), MAX(ev.doc_height)) AS vmin, -- should be zero (edge case: not zero because the pv event is missing)
      LEAST(GREATEST(MAX(NVL(ev.pp_yoffset_max, 0)), 0), MAX(ev.doc_height)) AS vmax

    FROM
      {{.input_schema}}.events AS ev
      INNER JOIN {{.input_schema}}.com_snowplowanalytics_snowplow_web_page_1 AS wp
        ON ev.event_id = wp.root_id AND ev.collector_tstamp = wp.root_tstamp

    WHERE
      ev.event_name IN ('page_view', 'page_ping')
      AND ev.doc_height > 0 -- exclude problematic (but rare) edge case
      AND ev.doc_width > 0 -- exclude problematic (but rare) edge case
      AND wp.id || wp.root_tstamp IN (SELECT id || collector_tstamp FROM {{.scratch_schema}}.ids)

    GROUP BY 1
  )

  SELECT
    id AS page_view_id,

    doc_width,
    doc_height,

    br_viewwidth,
    br_viewheight,

    hmin,
    hmax,
    vmin,
    vmax,

    ROUND(100*(GREATEST(hmin, 0)/doc_width::FLOAT))::DOUBLE PRECISION AS relative_hmin, -- brackets matter: because hmin is of type INT, we need to divide before we multiply by 100 or we risk an overflow
    ROUND(100*(LEAST(hmax + br_viewwidth, doc_width)/doc_width::FLOAT))::DOUBLE PRECISION AS relative_hmax,
    ROUND(100*(GREATEST(vmin, 0)/doc_height::FLOAT))::DOUBLE PRECISION AS relative_vmin,
    ROUND(100*(LEAST(vmax + br_viewheight, doc_height)/doc_height::FLOAT))::DOUBLE PRECISION AS relative_vmax -- not zero when a user hasn't scrolled because it includes the non-zero viewheight

  FROM
    prep
);
