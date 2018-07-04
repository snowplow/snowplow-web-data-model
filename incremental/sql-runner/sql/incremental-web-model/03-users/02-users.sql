-- 2. CALCULATE USERS DATA

-- 2a. create the table if it doesn't exist

CREATE TABLE IF NOT EXISTS {{.scratch_schema}}.users (LIKE {{.output_schema}}.users);

-- 2b. truncate in case the previous run failed

TRUNCATE {{.scratch_schema}}.users;

-- 2c. crunch the data and populate the table

INSERT INTO {{.scratch_schema}}.users (
  WITH prep AS (
    SELECT
      domain_userid,

      -- time
      MIN(session_start_time) AS first_session_start,
      MAX(session_end_time) AS last_session_end,

      -- engagement
      SUM(page_views) AS page_views,
      SUM(time_engaged_in_s) AS time_engaged_in_s,
      COUNT(*) AS sessions

    FROM
      {{.output_schema}}.sessions

    WHERE
      session_id IN (SELECT session_id FROM {{.scratch_schema}}.user_session_ids)

    GROUP BY 1
    ORDER BY 1
  )

  SELECT
    -- user fields
    a.user_id,
    a.domain_userid,
    a.network_userid,

    -- first session fields
    TO_CHAR(b.first_session_start, 'YYYY-MM-DD') AS first_session_start_date,
    b.first_session_start AS first_session_start_time,

    -- last session fields
    TO_CHAR(b.last_session_end, 'YYYY-MM-DD') AS last_session_end_date,
    b.last_session_end AS last_session_end_time,

    -- engagement
    b.page_views,
    b.time_engaged_in_s,
    b.sessions,

    -- first page fields
    a.first_page_title,

    a.first_page_url,

    a.first_page_urlhost,
    a.first_page_urlpath,
    a.first_page_urlquery,

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
    a.channel

  FROM
    {{.output_schema}}.sessions AS a
    INNER JOIN prep AS b
      ON a.domain_userid = b.domain_userid

  WHERE
    a.session_index = 1
);
