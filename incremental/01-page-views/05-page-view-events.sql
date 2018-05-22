-- 5. SELECT PAGE VIEW DIMENSIONS (PART 1)

-- 5a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS scratch.page_view_events (

  page_view_id CHAR(36) ENCODE ZSTD NOT NULL,

  -- user fields
  user_id VARCHAR(255) ENCODE ZSTD,
  domain_userid VARCHAR(128) ENCODE ZSTD,
  network_userid VARCHAR(128) ENCODE ZSTD,

  -- session fields
  session_id CHAR(128) ENCODE ZSTD,
  session_index INT ENCODE ZSTD,

  -- timestamp fields
  dvce_created_tstamp TIMESTAMP ENCODE ZSTD,
  collector_tstamp TIMESTAMP ENCODE ZSTD,
  derived_tstamp TIMESTAMP ENCODE ZSTD,

  -- page fields
  page_title VARCHAR(2000) ENCODE ZSTD,

  page_url VARCHAR(4096) ENCODE ZSTD,

  page_urlhost VARCHAR(255) ENCODE ZSTD,
  page_urlpath VARCHAR(3000) ENCODE ZSTD,
  page_urlquery VARCHAR(6000) ENCODE ZSTD,

  -- referrer fields
  page_referrer VARCHAR(4096) ENCODE ZSTD,

  refr_urlscheme VARCHAR(16) ENCODE ZSTD,
  refr_urlhost VARCHAR(255) ENCODE ZSTD,
  refr_urlpath VARCHAR(6000) ENCODE ZSTD,
  refr_urlquery VARCHAR(6000) ENCODE ZSTD,

  refr_medium VARCHAR(25) ENCODE ZSTD,
  refr_source VARCHAR(50) ENCODE ZSTD,
  refr_term VARCHAR(255) ENCODE ZSTD,

  -- marketing fields
  mkt_medium VARCHAR(255) ENCODE ZSTD,
  mkt_source VARCHAR(255) ENCODE ZSTD,
  mkt_term VARCHAR(255) ENCODE ZSTD,
  mkt_content VARCHAR(500) ENCODE ZSTD,
  mkt_campaign VARCHAR(255) ENCODE ZSTD,
  mkt_clickid VARCHAR(128) ENCODE ZSTD,
  mkt_network VARCHAR(64) ENCODE ZSTD,

  -- geo fields
  geo_country CHAR(2) ENCODE ZSTD,
  geo_region CHAR(2) ENCODE ZSTD,
  geo_region_name VARCHAR(100) ENCODE ZSTD,
  geo_city VARCHAR(75) ENCODE ZSTD,
  geo_zipcode VARCHAR(15) ENCODE ZSTD,
  geo_latitude DOUBLE PRECISION ENCODE ZSTD,
	geo_longitude DOUBLE PRECISION ENCODE ZSTD,
  geo_timezone VARCHAR(64) ENCODE ZSTD,

  -- IP address
  user_ipaddress VARCHAR(128) ENCODE ZSTD,

  -- user agent
  useragent VARCHAR(1000) ENCODE ZSTD,

  -- browser fields
  --br_name VARCHAR(50) ENCODE ZSTD,
  br_family VARCHAR(50) ENCODE ZSTD,
  br_version VARCHAR(50) ENCODE ZSTD,
  --br_type VARCHAR(50) ENCODE ZSTD,
  --br_renderengine VARCHAR(50) ENCODE ZSTD,
  br_lang VARCHAR(255) ENCODE ZSTD,

  -- device fields
  dvce_type VARCHAR(50) ENCODE ZSTD,
  dvce_ismobile BOOLEAN ENCODE ZSTD,

  -- OS fields
  os_name VARCHAR(50) ENCODE ZSTD,
  os_family VARCHAR(50) ENCODE ZSTD,
  --os_manufacturer VARCHAR(50) ENCODE ZSTD,
  --os_timezone VARCHAR(255) ENCODE ZSTD,

  -- row number
  row INT8 ENCODE ZSTD
)
DISTSTYLE KEY
DISTKEY (page_view_id)
SORTKEY (page_view_id, row);

-- 5b. change the owner to storageloader in case another user runs this step

--ALTER TABLE scratch.page_view_events OWNER TO storageloader;

-- 5c. truncate in case the previous run failed

TRUNCATE scratch.page_view_events;

-- 5d. insert the dimensions for page views that have not been processed

INSERT INTO scratch.page_view_events (

  SELECT

    id.id,

    -- user fields
    ev.user_id,
    ev.domain_userid,
    ev.network_userid,

    -- session fields
    ev.domain_sessionid,
    ev.domain_sessionidx,

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

    ev.refr_source,
    ev.refr_medium,
    ev.refr_term,

    -- marketing fields
    ev.mkt_source,
    ev.mkt_medium,
    ev.mkt_term,
    ev.mkt_content,
    ev.mkt_campaign,
    ev.mkt_clickid,
    ev.mkt_network,

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

    -- row number
    ROW_NUMBER() OVER (PARTITION BY id.id ORDER BY ev.dvce_created_tstamp) AS row

  FROM atomic.events AS ev

  INNER JOIN scratch.ids AS id
    ON ev.event_id = id.event_id AND ev.collector_tstamp = id.collector_tstamp

  WHERE ev.event_name = 'page_view'
    AND ev.collector_tstamp >= (SELECT MIN(collector_tstamp) FROM scratch.event_ids) - INTERVAL '1 week' -- for performance

);
