CREATE TABLE IF NOT EXISTS {{.output_schema}}.users (
  -- user fields
  user_id VARCHAR(255) ENCODE ZSTD,
  domain_userid VARCHAR(128) ENCODE ZSTD,
  network_userid VARCHAR(128) ENCODE ZSTD,

  -- first session fields
  first_session_start_date VARCHAR(18) ENCODE ZSTD,
  first_session_start_time TIMESTAMP ENCODE ZSTD,

  -- last session fields
  last_session_end_date VARCHAR(18) ENCODE ZSTD,
  last_session_end_time TIMESTAMP ENCODE ZSTD,

  -- engagement
  page_views INT8 ENCODE ZSTD,
  time_engaged_in_s INT8 ENCODE ZSTD,
  sessions INT8 ENCODE ZSTD,

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

  CONSTRAINT users_id_pk PRIMARY KEY(domain_userid)
)
DISTSTYLE KEY
DISTKEY (domain_userid)
SORTKEY (first_session_start_time);
