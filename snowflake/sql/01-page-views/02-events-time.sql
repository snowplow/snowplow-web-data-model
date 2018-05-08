-- Copyright (c) 2016 Snowplow Analytics Ltd. All rights reserved.
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

CREATE OR REPLACE TABLE scratch.web_events_time
AS (
SELECT
  contexts_com_snowplowanalytics_snowplow_web_page_1[0]:id::STRING AS page_view_id,

  MIN(derived_tstamp) AS min_tstamp, -- requires the derived timestamp (JS tracker 2.6.0+ and Snowplow 71+)
  MAX(derived_tstamp) AS max_tstamp, -- requires the derived timestamp (JS tracker 2.6.0+ and Snowplow 71+)

  SUM(CASE WHEN event_name = 'page_view' THEN 1 ELSE 0 END) AS pv_count, -- for debugging
  SUM(CASE WHEN event_name = 'page_ping' THEN 1 ELSE 0 END) AS pp_count, -- for debugging

  10 * COUNT(DISTINCT(FLOOR(EXTRACT(EPOCH FROM derived_tstamp)/10))) - 10 AS time_engaged_in_s -- assumes 10 seconds between subsequent page pings

FROM
  atomic.events
WHERE
  event_name IN ('page_view', 'page_ping')
GROUP BY 1
);
