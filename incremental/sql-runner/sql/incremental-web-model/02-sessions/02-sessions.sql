-- 2. CALCULATE SESSIONS DATA

-- 2a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS {{.scratch_schema}}.sessions (LIKE {{.output_schema}}.sessions);

-- 2b. truncate in case the previous run failed

TRUNCATE {{.scratch_schema}}.sessions;

-- 2c. crunch the data and populate the table

INSERT INTO {{.scratch_schema}}.sessions (
  WITH prep AS (
    SELECT
      session_id,

      -- time
      MIN(page_view_start_time) AS session_start,
      MAX(page_view_end_time) AS session_end,

      -- engagement
      COUNT(*) AS page_views,
      SUM(time_engaged_in_s) AS time_engaged_in_s

    FROM
      {{.output_schema}}.page_views

    WHERE
      page_view_id IN (SELECT page_view_id FROM {{.scratch_schema}}.session_page_view_ids)

    GROUP BY 1
    ORDER BY 1
  )

  SELECT
    -- session fields
    a.session_id,
    a.session_index,

    TO_CHAR(b.session_start, 'YYYY-MM-DD') AS session_start_date,
    b.session_start AS session_start_time,
    b.session_end AS session_end_time,

    -- user fields
    a.user_id,
    a.domain_userid,
    a.network_userid,

    -- engagement fields
    b.page_views,
    b.time_engaged_in_s,

    -- first page fields
    a.page_title AS first_page_title,

    a.page_url AS first_page_url,

    a.page_urlhost AS first_page_urlhost,
    a.page_urlpath AS first_page_urlpath,
    a.page_urlquery AS first_page_urlquery,

    -- referrer fields
    a.page_referrer,

    a.refr_urlscheme,
    a.refr_urlhost,
    a.refr_urlpath,
    a.refr_urlquery,

    a.refr_medium,
    a.refr_source,
    a.refr_term,

    -- marketing fields
    a.mkt_medium,
    a.mkt_source,
    a.mkt_term,
    a.mkt_content,
    a.mkt_campaign,
    a.mkt_clickid,
    a.mkt_network,

    -- derived channels
    a.channel,

    -- geo fields
    a.geo_country,
    a.geo_region,
    a.geo_region_name,
    a.geo_city,
    a.geo_zipcode,
    a.geo_latitude,
    a.geo_longitude,
    a.geo_timezone,

    -- IP address
    a.user_ipaddress,

    -- user agent
    a.useragent,

    -- browser fields
    --a.br_name,
    a.br_family,
    a.br_version,
    --a.br_type,
    --a.br_renderengine,
    a.br_lang,

    -- device fields
    a.dvce_type,
    a.dvce_ismobile,

    -- OS fields
    a.os_name,
    a.os_family
    --a.os_manufacturer,
    --a.os_timezone

  FROM
    {{.output_schema}}.page_views AS a
    INNER JOIN prep AS b
      ON a.session_id = b.session_id

  WHERE
    a.page_view_in_session_index = 1
);
