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

CREATE OR REPLACE TABLE scratch.web_timing_context
AS (
WITH prep AS (
  SELECT
    contexts_com_snowplowanalytics_snowplow_web_page_1[0]:id::STRING AS page_view_id,

    contexts_org_w3_performance_timing_1[0]:navigationStart AS navigation_start,
    contexts_org_w3_performance_timing_1[0]:redirectStart AS redirect_start,
    contexts_org_w3_performance_timing_1[0]:redirectEnd AS redirect_end,
    contexts_org_w3_performance_timing_1[0]:fetchStart AS fetch_start,
    contexts_org_w3_performance_timing_1[0]:domainLookupStart AS domain_lookup_start,
    contexts_org_w3_performance_timing_1[0]:domainLookupEnd AS domain_lookup_end,
    contexts_org_w3_performance_timing_1[0]:secureConnectionStart AS secure_connection_start,
    contexts_org_w3_performance_timing_1[0]:connectStart AS connect_start,
    contexts_org_w3_performance_timing_1[0]:connectEnd AS connect_end,
    contexts_org_w3_performance_timing_1[0]:requestStart AS request_start,
    contexts_org_w3_performance_timing_1[0]:responseStart AS response_start,
    contexts_org_w3_performance_timing_1[0]:responseEnd AS response_end,
    contexts_org_w3_performance_timing_1[0]:unloadEventStart AS unload_event_start,
    contexts_org_w3_performance_timing_1[0]:unloadEventEnd AS unload_event_end,
    contexts_org_w3_performance_timing_1[0]:domLoading AS dom_loading,
    contexts_org_w3_performance_timing_1[0]:domInteractive AS dom_interactive,
    contexts_org_w3_performance_timing_1[0]:domContentLoadedEventStart AS dom_content_loaded_event_start,
    contexts_org_w3_performance_timing_1[0]:domContentLoadedEventEnd AS dom_content_loaded_event_end,
    contexts_org_w3_performance_timing_1[0]:domComplete AS dom_complete,
    contexts_org_w3_performance_timing_1[0]:loadEventStart AS load_event_start,
    contexts_org_w3_performance_timing_1[0]:loadEventEnd AS load_event_end
  FROM
    atomic.events
  WHERE   -- all values should be set and some have to be greater than 0 (not the case in about 1% of events)
    contexts_org_w3_performance_timing_1[0]:navigationStart IS NOT NULL AND contexts_org_w3_performance_timing_1[0]:navigationStart > 0
    AND contexts_org_w3_performance_timing_1[0]:redirectStart IS NOT NULL -- zero is acceptable
    AND contexts_org_w3_performance_timing_1[0]:redirectEnd IS NOT NULL -- zero is acceptable
    AND contexts_org_w3_performance_timing_1[0]:fetchStart IS NOT NULL AND contexts_org_w3_performance_timing_1[0]:fetchStart > 0
    AND contexts_org_w3_performance_timing_1[0]:domainLookupStart IS NOT NULL AND contexts_org_w3_performance_timing_1[0]:domainLookupStart > 0
    AND contexts_org_w3_performance_timing_1[0]:domainLookupEnd IS NOT NULL AND contexts_org_w3_performance_timing_1[0]:domainLookupEnd > 0
    AND contexts_org_w3_performance_timing_1[0]:secureConnectionStart IS NOT NULL AND contexts_org_w3_performance_timing_1[0]:secureConnectionStart > 0
    -- connect_start is either 0 or NULL
    AND contexts_org_w3_performance_timing_1[0]:connectEnd IS NOT NULL AND contexts_org_w3_performance_timing_1[0]:connectEnd > 0
    AND contexts_org_w3_performance_timing_1[0]:requestStart IS NOT NULL AND contexts_org_w3_performance_timing_1[0]:requestStart > 0
    AND contexts_org_w3_performance_timing_1[0]:responseStart IS NOT NULL AND contexts_org_w3_performance_timing_1[0]:responseStart > 0
    AND contexts_org_w3_performance_timing_1[0]:responseEnd IS NOT NULL AND contexts_org_w3_performance_timing_1[0]:responseEnd > 0
    AND contexts_org_w3_performance_timing_1[0]:unloadEventStart IS NOT NULL -- zero is acceptable
    AND contexts_org_w3_performance_timing_1[0]:unloadEventEnd IS NOT NULL -- zero is acceptable
    AND contexts_org_w3_performance_timing_1[0]:domLoading IS NOT NULL AND contexts_org_w3_performance_timing_1[0]:domLoading > 0
    AND contexts_org_w3_performance_timing_1[0]:domInteractive IS NOT NULL AND contexts_org_w3_performance_timing_1[0]:domInteractive > 0
    AND contexts_org_w3_performance_timing_1[0]:domContentLoadedEventStart IS NOT NULL AND contexts_org_w3_performance_timing_1[0]:domContentLoadedEventStart > 0
    AND contexts_org_w3_performance_timing_1[0]:domContentLoadedEventEnd IS NOT NULL AND contexts_org_w3_performance_timing_1[0]:domContentLoadedEventEnd > 0
    AND contexts_org_w3_performance_timing_1[0]:domComplete IS NOT NULL -- zero is acceptable
    AND contexts_org_w3_performance_timing_1[0]:loadEventStart IS NOT NULL -- zero is acceptable
    AND contexts_org_w3_performance_timing_1[0]:loadEventEnd IS NOT NULL -- zero is acceptable

        -- remove rare outliers (Unix timestamp is more than twice what it should be)

    AND DATEDIFF(d, collector_tstamp, TO_TIMESTAMP_NTZ(contexts_org_w3_performance_timing_1[0]:responseEnd::number, 3)) < 365
    AND DATEDIFF(d, collector_tstamp, TO_TIMESTAMP_NTZ(contexts_org_w3_performance_timing_1[0]:unloadEventStart::number, 3)) < 365
    AND DATEDIFF(d, collector_tstamp, TO_TIMESTAMP_NTZ(contexts_org_w3_performance_timing_1[0]:unloadEventEnd::number, 3)) < 365
),

rolledup AS (
  SELECT
    page_view_id,

    -- select the first non-zero value

    MIN(NULLIF(navigation_start, 0)) AS navigation_start,
    MIN(NULLIF(redirect_start, 0)) AS redirect_start,
    MIN(NULLIF(redirect_end, 0)) AS redirect_end,
    MIN(NULLIF(fetch_start, 0)) AS fetch_start,
    MIN(NULLIF(domain_lookup_start, 0)) AS domain_lookup_start,
    MIN(NULLIF(domain_lookup_end, 0)) AS domain_lookup_end,
    MIN(NULLIF(secure_connection_start, 0)) AS secure_connection_start,
    MIN(NULLIF(connect_start, 0)) AS connect_start,
    MIN(NULLIF(connect_end, 0)) AS connect_end,
    MIN(NULLIF(request_start, 0)) AS request_start,
    MIN(NULLIF(response_start, 0)) AS response_start,
    MIN(NULLIF(response_end, 0)) AS response_end,
    MIN(NULLIF(unload_event_start, 0)) AS unload_event_start,
    MIN(NULLIF(unload_event_end, 0)) AS unload_event_end,
    MIN(NULLIF(dom_loading, 0)) AS dom_loading,
    MIN(NULLIF(dom_interactive, 0)) AS dom_interactive,
    MIN(NULLIF(dom_content_loaded_event_start, 0)) AS dom_content_loaded_event_start,
    MIN(NULLIF(dom_content_loaded_event_end, 0)) AS dom_content_loaded_event_end,
    MIN(NULLIF(dom_complete, 0)) AS dom_complete,
    MIN(NULLIF(load_event_start, 0)) AS load_event_start,
    MIN(NULLIF(load_event_end, 0)) AS load_event_end
  FROM prep
  GROUP BY 1

)

SELECT
  page_view_id,

  CASE
    WHEN ((redirect_start IS NOT NULL) AND (redirect_end IS NOT NULL) AND (redirect_end >= redirect_start)) THEN (redirect_end - redirect_start)
    ELSE NULL
  END AS redirect_time_in_ms,

  CASE
    WHEN ((unload_event_start IS NOT NULL) AND (unload_event_end IS NOT NULL) AND (unload_event_end >= unload_event_start)) THEN (unload_event_end - unload_event_start)
    ELSE NULL
  END AS unload_time_in_ms,

  CASE
    WHEN ((fetch_start IS NOT NULL) AND (domain_lookup_start IS NOT NULL) AND (domain_lookup_start >= fetch_start)) THEN (domain_lookup_start - fetch_start)
    ELSE NULL
  END AS app_cache_time_in_ms,

  CASE
    WHEN ((domain_lookup_start IS NOT NULL) AND (domain_lookup_end IS NOT NULL) AND (domain_lookup_end >= domain_lookup_start)) THEN (domain_lookup_end - domain_lookup_start)
    ELSE NULL
  END AS dns_time_in_ms,

  CASE
    WHEN ((connect_start IS NOT NULL) AND (connect_end IS NOT NULL) AND (connect_end >= connect_start)) THEN (connect_end - connect_start)
    ELSE NULL
  END AS tcp_time_in_ms,

  CASE
    WHEN ((request_start IS NOT NULL) AND (response_start IS NOT NULL) AND (response_start >= request_start)) THEN (response_start - request_start)
    ELSE NULL
  END AS request_time_in_ms,

  CASE
    WHEN ((response_start IS NOT NULL) AND (response_end IS NOT NULL) AND (response_end >= response_start)) THEN (response_end - response_start)
    ELSE NULL
  END AS response_time_in_ms,

  CASE
    WHEN ((dom_loading IS NOT NULL) AND (dom_complete IS NOT NULL) AND (dom_complete >= dom_loading)) THEN (dom_complete - dom_loading)
    ELSE NULL
  END AS processing_time_in_ms,

  CASE
    WHEN ((dom_loading IS NOT NULL) AND (dom_interactive IS NOT NULL) AND (dom_interactive >= dom_loading)) THEN (dom_interactive - dom_loading)
    ELSE NULL
  END AS dom_loading_to_interactive_time_in_ms,

  CASE
    WHEN ((dom_interactive IS NOT NULL) AND (dom_complete IS NOT NULL) AND (dom_complete >= dom_interactive)) THEN (dom_complete - dom_interactive)
    ELSE NULL
  END AS dom_interactive_to_complete_time_in_ms,

  CASE
    WHEN ((load_event_start IS NOT NULL) AND (load_event_end IS NOT NULL) AND (load_event_end >= load_event_start)) THEN (load_event_end - load_event_start)
    ELSE NULL
  END AS onload_time_in_ms,

  CASE
    WHEN ((navigation_start IS NOT NULL) AND (load_event_end IS NOT NULL) AND (load_event_end >= navigation_start)) THEN (load_event_end - navigation_start)
    ELSE NULL
  END AS total_time_in_ms

FROM rolledup
);
