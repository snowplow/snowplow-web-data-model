CREATE TABLE IF NOT EXISTS {{.output_schema}}.sessions (
  -- session fields
  session_id CHAR(128) ENCODE ZSTD,
  session_index INT ENCODE ZSTD,

  session_start_date VARCHAR(18) ENCODE ZSTD,
  session_start_time TIMESTAMP ENCODE ZSTD,
  session_end_time TIMESTAMP ENCODE ZSTD,

  -- user fields
  user_id VARCHAR(255) ENCODE ZSTD,
  domain_userid VARCHAR(128) ENCODE ZSTD,
  network_userid VARCHAR(128) ENCODE ZSTD,

  -- engagement
  page_views INT8 ENCODE ZSTD,
  time_engaged_in_s INT8 ENCODE ZSTD,

  -- first page fields
  first_page_title VARCHAR(2000) ENCODE ZSTD,

  first_page_url VARCHAR(4096) ENCODE ZSTD,

  first_page_urlhost VARCHAR(255) ENCODE ZSTD,
  first_page_urlpath VARCHAR(3000) ENCODE ZSTD,
  first_page_urlquery VARCHAR(6000) ENCODE ZSTD,

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

  -- derived channels
  channel VARCHAR(50) ENCODE ZSTD,

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

  CONSTRAINT sessions_id_pk PRIMARY KEY(session_id)
)
DISTSTYLE KEY
DISTKEY (session_id)
SORTKEY (session_start_time);
