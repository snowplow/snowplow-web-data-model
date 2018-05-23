-- 8. COMBINE INTO A SINGLE TABLE

-- 8a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS scratch.page_views (LIKE scratch.page_views_test); -- change to derived.page_views

-- 8b. change the owner to storageloader in case another user runs this step

--ALTER TABLE scratch.page_views OWNER TO storageloader;

-- 8c. truncate in case the previous run failed

TRUNCATE scratch.page_views;

-- 8d. combine the part table into a single view

INSERT INTO scratch.page_views (

  SELECT

    ev.page_view_id,

    -- ID fields
    ev.user_id,
    ev.domain_userid,
    ev.network_userid,

    -- session fields
    ev.session_id,
    ev.session_index,

    -- timestamp fields
    ev.dvce_created_tstamp,
    ev.collector_tstamp,
    ev.derived_tstamp,

    -- page fields
    ev.page_title,

    ev.page_url,

    ev.page_urlhost,
    ev.page_urlpath,
    ev.page_urlquery,

    -- referrer fields
    ev.page_referrer,

    ev.refr_urlscheme,
    ev.refr_urlhost,
    ev.refr_urlpath,
    ev.refr_urlquery,

    ev.refr_medium,
    ev.refr_source,
    ev.refr_term,

    -- marketing fields
    ev.mkt_source,
    ev.mkt_medium,
    ev.mkt_term,
    ev.mkt_content,
    ev.mkt_campaign,
    ev.mkt_clickid,
    ev.mkt_network,

    -- derived channels
    CASE

      WHEN ev.refr_medium IS NULL AND ev.page_url NOT ILIKE '%utm_%' THEN 'Direct'
      WHEN (ev.refr_medium = 'search' AND ev.mkt_medium IS NULL) OR (ev.refr_medium = 'search' AND ev.mkt_medium = 'organic') THEN 'Organic search'
      WHEN ev.refr_medium = 'social' OR ev.mkt_medium SIMILAR TO '%(social|social-network|social-media|sm|social network|social media)%' THEN 'Social'
      WHEN ev.refr_medium = 'email' OR ev.mkt_medium ILIKE 'email' THEN 'Email'
      WHEN ev.mkt_medium ILIKE 'affilliate' THEN 'Affilliate'
      WHEN ev.refr_medium = 'unknown' OR ev.mkt_medium ILIKE 'referral' THEN 'Referral'
      WHEN ev.refr_medium = 'search' AND ev.mkt_medium SIMILAR TO '%(cpc|ppc|paidsearch)%' THEN 'Paid search'
      WHEN ev.mkt_medium SIMILAR TO '%(cpv|cpa|cpp|content-text)%' THEN 'Other advertising'
      WHEN ev.mkt_medium SIMILAR TO '%(display|cpm|banner)%' THEN 'Display'
      ELSE 'Other'

    END AS channel,

    -- geo fields
    ev.geo_country,
    ev.geo_region,
    ev.geo_region_name,
    ev.geo_city,
    ev.geo_zipcode,
    ev.geo_latitude,
    ev.geo_longitude,
    ev.geo_timezone,

    -- IP address
    ev.user_ipaddress,

    -- user agent
    ev.useragent,

    -- browser fields
    --ev.br_name,
    ev.br_family,
    ev.br_version,
    --ev.br_type,
    --ev.br_renderengine,
    ev.br_lang,

    -- device fields
    ev.dvce_type,
    ev.dvce_ismobile,

    -- OS fields
    ev.os_name,
    ev.os_family,
    --ev.os_manufacturer,
    --ev.os_timezone,

    -- timestamp fields
    et.min_derived_tstamp AS page_view_start_time,
    et.max_derived_tstamp AS page_view_end_time,
    et.min_dvce_created_tstamp AS page_view_min_dvce_created_tstamp,
    et.max_dvce_created_tstamp AS page_view_max_dvce_created_tstamp,

    -- calculated fields
    er.page_view_in_session_index,

    et.time_engaged_in_s,

    er.bounce,
    er.entrance,
    er.exit,
    er.new_user

  FROM scratch.page_view_events AS ev

  LEFT JOIN scratch.page_view_time AS et
    ON ev.page_view_id = et.page_view_id

  LEFT JOIN scratch.page_view_rank AS er
    ON ev.page_view_id = er.page_view_id

  WHERE ev.useragent NOT SIMILAR TO '%(bot|crawl|slurp|spider|archiv|spinn|sniff|seo|audit|survey|pingdom|worm|capture|(browser|screen)shots|analyz|index|thumb|check|facebook|PingdomBot|PhantomJS|YandexBot|Twitterbot|a_archiver|facebookexternalhit|Bingbot|BingPreview|Googlebot|Baiduspider|360(Spider|User-agent)|semalt)%'
    AND ev.br_family != 'Robot/Spider'
    AND ev.domain_userid IS NOT NULL  -- rare edge case
    AND ev.session_index > 0 -- rare edge case
    AND ev.row = 1

);
