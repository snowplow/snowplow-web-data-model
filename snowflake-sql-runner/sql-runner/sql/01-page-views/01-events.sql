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

CREATE OR REPLACE TABLE {{.scratch_schema}}.web_events
AS (
WITH step1 AS(
  SELECT
    user_id,
    domain_userid,
    network_userid,

    domain_sessionid,
    domain_sessionidx,

    contexts_com_snowplowanalytics_snowplow_web_page_1[0]:id::STRING AS page_view_id,

    page_title,

    page_urlscheme,
    page_urlhost,
    page_urlport,
    page_urlpath,
    page_urlquery,
    page_urlfragment,

    refr_urlscheme,
    refr_urlhost,
    refr_urlport,
    refr_urlpath,
    refr_urlquery,
    refr_urlfragment,

    refr_medium,
    refr_source,
    refr_term,

    mkt_medium,
    mkt_source,
    mkt_term,
    mkt_content,
    mkt_campaign,
    mkt_clickid,
    mkt_network,

    geo_country,
    geo_region,
    geo_region_name,
    geo_city,
    geo_zipcode,
    geo_latitude,
    geo_longitude,
    geo_timezone,

    user_ipaddress,

    ip_isp,
    ip_organization,
    ip_domain,
    ip_netspeed,

    app_id,

    useragent,
    br_family,
    br_renderengine,
    br_lang,
    dvce_type,
    dvce_ismobile,

    contexts_com_snowplowanalytics_snowplow_ua_parser_context_1[0]:useragentFamily::STRING AS useragent_family,
    contexts_com_snowplowanalytics_snowplow_ua_parser_context_1[0]:useragentMajor::STRING AS useragent_major,
    contexts_com_snowplowanalytics_snowplow_ua_parser_context_1[0]:useragentMinor::STRING AS useragent_minor,
    contexts_com_snowplowanalytics_snowplow_ua_parser_context_1[0]:useragentPatch::STRING AS useragent_patch,
    contexts_com_snowplowanalytics_snowplow_ua_parser_context_1[0]:useragentVersion::STRING AS useragent_version,
    contexts_com_snowplowanalytics_snowplow_ua_parser_context_1[0]:osFamily::STRING AS os_family,
    contexts_com_snowplowanalytics_snowplow_ua_parser_context_1[0]:osMajor::STRING AS os_major,
    contexts_com_snowplowanalytics_snowplow_ua_parser_context_1[0]:osMinor::STRING AS os_minor,
    contexts_com_snowplowanalytics_snowplow_ua_parser_context_1[0]:osPatch::STRING AS os_patch,
    contexts_com_snowplowanalytics_snowplow_ua_parser_context_1[0]:osVersion::STRING AS os_version,
    contexts_com_snowplowanalytics_snowplow_ua_parser_context_1[0]:deviceFamily::STRING AS device_family,

    os_manufacturer,
    os_timezone,

    name_tracker, -- included to filter on
    dvce_created_tstamp, -- included to sort on
    event_id, -- included to dedupe on

    ROW_NUMBER() OVER (PARTITION BY contexts_com_snowplowanalytics_snowplow_web_page_1[0]:id::STRING ORDER BY dvce_created_tstamp) AS n_pvid -- to dedupe on pv_id

  FROM
    {{.input_schema}}.events
  WHERE
    platform = 'web'
    AND event_name = 'page_view' -- filtering on page view events removes the need for a FIRST_VALUE function
)

SELECT * FROM step1 WHERE n_pvid = 1
);
