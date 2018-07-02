-- Copyright (c) 2018 Snowplow Analytics Ltd. All rights reserved.
--
-- This program is licensed to you under the Apache License Version 2.0,
-- and you may not use this file except in compliance with the Apache License Version 2.0.
-- You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the Apache License Version 2.0 is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.
--
-- Version:     0.1.0
--
-- Authors:     Christophe Bogaert, Colm O Griobhtha
-- Copyright:   Copyright (c) 2018 Snowplow Analytics Ltd
-- License:     Apache License Version 2.0

CREATE OR REPLACE TABLE {{.scratch_schema}}.web_events_scroll_depth
AS (
WITH step1 AS (
  SELECT
    contexts_com_snowplowanalytics_snowplow_web_page_1[0]:id::STRING AS page_view_id,

    MAX(doc_width) AS doc_width,
    MAX(doc_height) AS doc_height,

    MAX(br_viewwidth) AS br_viewwidth,
    MAX(br_viewheight) AS br_viewheight,

    -- NVL replaces NULL with 0 (because the page view event does send an offset)
    -- GREATEST prevents outliers (negative offsets)
    -- LEAST also prevents outliers (offsets greater than the docwidth or docheight)

    LEAST(GREATEST(MIN(NVL(pp_xoffset_min, 0)), 0), MAX(doc_width)) AS hmin, -- should be zero
    LEAST(GREATEST(MAX(NVL(pp_xoffset_max, 0)), 0), MAX(doc_width)) AS hmax,

    LEAST(GREATEST(MIN(NVL(pp_yoffset_min, 0)), 0), MAX(doc_height)) AS vmin, -- should be zero (edge case: not zero because the pv event is missing - but these are not in {{.scratch_schema}}.dev_pv_01 so not an issue)
    LEAST(GREATEST(MAX(NVL(pp_yoffset_max, 0)), 0), MAX(doc_height)) AS vmax
  FROM
    {{.input_schema}}.events
  WHERE
    event_name IN ('page_view', 'page_ping')
    AND doc_height > 0 -- exclude problematic (but rare) edge case
    AND doc_width > 0 -- exclude problematic (but rare) edge case
  GROUP BY 1
)

SELECT
  page_view_id,

  doc_width,
  doc_height,

  br_viewwidth,
  br_viewheight,

  hmin,
  hmax,
  vmin,
  vmax, -- zero when a user hasn't scrolled

  ROUND(100*(GREATEST(hmin, 0)/doc_width::FLOAT)) AS relative_hmin, -- brackets matter: because hmin is of type INT, we need to divide before we multiply by 100 or we risk an overflow
  ROUND(100*(LEAST(hmax + br_viewwidth, doc_width)/doc_width::FLOAT)) AS relative_hmax,
  ROUND(100*(GREATEST(vmin, 0)/doc_height::FLOAT)) AS relative_vmin,
  ROUND(100*(LEAST(vmax + br_viewheight, doc_height)/doc_height::FLOAT)) AS relative_vmax -- not zero when a user hasn't scrolled because it includes the non-zero viewheight
FROM
  step1
);
