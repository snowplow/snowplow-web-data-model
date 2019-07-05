view: sessions {
  derived_table: {
    sql: WITH prep AS (

              SELECT

                session_id,

                -- time
                MIN(page_view_start) AS session_start,
                MAX(page_view_end) AS session_end,
                MIN(page_view_start_local) AS session_start_local,
                MAX(page_view_end_local) AS session_end_local,

                -- engagement
                COUNT(*) AS page_views,
                SUM(time_engaged_in_s) AS time_engaged_in_s

              FROM ${page_views.SQL_TABLE_NAME}

              GROUP BY 1
              ORDER BY 1

            )

            SELECT

              -- user
              a.user_id,
              a.domain_userid,
              a.network_userid,

              -- sesssion
              a.session_id,
              a.session_index,

              -- session: time
              b.session_start,
              b.session_end,

              -- session: time in the user's local timezone
              b.session_start_local,
              b.session_end_local,

              -- engagement
              b.user_bounced,
              b.page_views,
              b.time_engaged_in_s,

              -- first page
              a.page_url AS first_page_url,
              a.page_url_scheme AS first_page_url_scheme,
              a.page_url_host AS first_page_url_host,
              a.page_url_port AS first_page_url_port,
              a.page_url_path AS first_page_url_path,
              a.page_url_query AS first_page_url_query,
              a.page_url_fragment AS first_page_url_fragment,
              a.page_title AS first_page_title,

              -- referrer
              a.referrer_url,
              a.referrer_url_scheme,
              a.referrer_url_host,
              a.referrer_url_port,
              a.referrer_url_path,
              a.referrer_url_query,
              a.referrer_url_fragment,
              a.referrer_medium,
              a.referrer_source,
              a.referrer_term,

              -- marketing
              a.marketing_medium,
              a.marketing_source,
              a.marketing_term,
              a.marketing_content,
              a.marketing_campaign,
              a.marketing_click_id,
              a.marketing_network,

              -- location
              a.geo_country,
              a.geo_region,
              a.geo_region_name,
              a.geo_city,
              a.geo_zipcode,
              a.geo_latitude,
              a.geo_longitude,
              a.geo_timezone, -- can be NULL

              -- IP
              a.ip_address,
              -- a.ip_isp,
              -- a.ip_organization,
              -- a.ip_domain,
              -- a.ip_net_speed,

              -- application
              a.app_id,

              -- browser
              a.browser,
              a.browser_name,
              a.browser_major_version,
              a.browser_minor_version,
              a.browser_build_version,
              a.browser_engine,
              a.browser_language,

              -- OS
              a.os,
              a.os_name,
              a.os_major_version,
              a.os_minor_version,
              a.os_build_version,
              a.os_manufacturer,
              a.os_timezone,

              -- device
              a.device

            FROM ${page_views.SQL_TABLE_NAME} AS a

            INNER JOIN prep AS b
              ON a.session_id = b.session_id

            WHERE a.page_view_in_session_index = 1
             ;;
    sql_trigger_value: SELECT COUNT(*) FROM ${page_views.SQL_TABLE_NAME} ;;
    distribution: "user_snowplow_domain_id"
    sortkeys: ["session_start"]
  }

  # DIMENSIONS

  # User

  dimension: user_id {
    type: string
    sql: ${TABLE}.user_id ;;
    group_label: "User"
  }

  dimension: domain_userid {
    type: string
    sql: ${TABLE}.domain_userid ;;
    group_label: "User"
  }

  dimension: network_userid {
    type: string
    sql: ${TABLE}.network_userid ;;
    group_label: "User"
  }

  # Session

  dimension: session_id {
    type: string
    sql: ${TABLE}.session_id ;;
    group_label: "Session"
  }

  dimension: session_index {
    type: number
    sql: ${TABLE}.session_index ;;
    group_label: "Session"
  }

  dimension: first_or_returning_session {
    type: string

    case: {
      when: {
        sql: ${session_index} = 1 ;;
        label: "First session"
      }

      when: {
        sql: ${session_index} > 1 ;;
        label: "Returning session"
      }

      else: "Error"
    }

    group_label: "Session"
    hidden: yes
  }

  # Session Time

  dimension_group: session_start {
    type: time
    timeframes: [time, minute10, hour, date, week, month, quarter, year]
    sql: ${TABLE}.session_start ;;
    group_label:"Session Time"
  }

  dimension_group: session_end {
    type: time
    timeframes: [time, minute10, hour, date, week, month, quarter, year]
    sql: ${TABLE}.session_end ;;
    group_label:"Session Time"
  }

  # Session Time (User Timezone)

  dimension_group: session_start_local {
    type: time
    timeframes: [time, time_of_day, hour_of_day, day_of_week]
    sql: ${TABLE}.session_start_local ;;
    group_label:"Session Time (User Timezone)"
    convert_tz: no
  }

  dimension_group: session_end_local {
    type: time
    timeframes: [time, time_of_day, hour_of_day, day_of_week]
    sql: ${TABLE}.session_end_local ;;
    group_label:"Session Time (User Timezone)"
    convert_tz: no
  }

  dimension: session_start_window {
    case: {
      when: {
        sql: ${session_start_time} >= DATEADD(day, -28, GETDATE()) ;;
        label: "current_period"
      }
      when: {
        sql: ${session_start_time} >= DATEADD(day, -56, GETDATE()) AND ${session_start_time} < DATEADD(day, -28, GETDATE()) ;;
        label: "previous_period"
      }
      else: "unknown"
    }
    hidden: yes
  }

  # Engagement

  dimension: page_views {
    type: number
    sql: ${TABLE}.page_views ;;
    group_label: "Engagement"
  }

  dimension: time_engaged {
    type: number
    sql: ${TABLE}.time_engaged_in_s ;;
    group_label: "Engagement"
    value_format: "0\"s\""
  }

  dimension: time_engaged_tier {
    type: tier
    tiers: [0, 10, 30, 60, 120, 240]
    style: integer
    sql: ${time_engaged} ;;
    group_label: "Engagement"
    value_format: "0\"s\""
  }

  dimension: user_bounced {
    type: yesno
    sql: ${TABLE}.user_bounced ;;
    group_label: "Engagement"
  }

  dimension: user_engaged {
    type: yesno
    sql: ${TABLE}.time_engaged_in_s >= 60 AND ${TABLE}.page_views >= 3 ;;
    group_label: "Engagement"
  }

  # First Page

  dimension: first_page_url {
    type: string
    sql: ${TABLE}.first_page_url ;;
    group_label: "First Page"
  }

  dimension: first_page_url_scheme {
    type: string
    sql: ${TABLE}.first_page_url_scheme ;;
    group_label: "First Page"
    hidden: yes
  }

  dimension: first_page_url_host {
    type: string
    sql: ${TABLE}.first_page_url_host ;;
    group_label: "First Page"
  }

  dimension: first_page_url_port {
    type: number
    sql: ${TABLE}.first_page_url_port ;;
    group_label: "First Page"
    hidden: yes
  }

  dimension: first_page_url_path {
    type: string
    sql: ${TABLE}.first_page_url_path ;;
    group_label: "First Page"
  }

  dimension: first_page_url_query {
    type: string
    sql: ${TABLE}.first_page_url_query ;;
    group_label: "First Page"
  }

  dimension: first_page_url_fragment {
    type: string
    sql: ${TABLE}.first_page_url_fragment ;;
    group_label: "First Page"
  }

  dimension: first_page_title {
    type: string
    sql: ${TABLE}.first_page_title ;;
    group_label: "First Page"
  }

  # Referrer

  dimension: referrer_url {
    type: string
    sql: ${TABLE}.referrer_url ;;
    group_label: "Referrer"
  }

  dimension: referrer_url_scheme {
    type: string
    sql: ${TABLE}.referrer_url_scheme ;;
    group_label: "Referrer"
    hidden: yes
  }

  dimension: referrer_url_host {
    type: string
    sql: ${TABLE}.referrer_url_host ;;
    group_label: "Referrer"
  }

  dimension: referrer_url_port {
    type: number
    sql: ${TABLE}.referrer_url_port ;;
    group_label: "Referrer"
    hidden: yes
  }

  dimension: referrer_url_path {
    type: string
    sql: ${TABLE}.referrer_url_path ;;
    group_label: "Referrer"
  }

  dimension: referrer_url_query {
    type: string
    sql: ${TABLE}.referrer_url_query ;;
    group_label: "Referrer"
  }

  dimension: referrer_url_fragment {
    type: string
    sql: ${TABLE}.referrer_url_fragment ;;
    group_label: "Referrer"
  }

  dimension: referrer_medium {
    type: string
    sql: ${TABLE}.referrer_medium ;;
    group_label: "Referrer"
  }

  dimension: referrer_source {
    type: string
    sql: ${TABLE}.referrer_source ;;
    group_label: "Referrer"
  }

  dimension: referrer_term {
    type: string
    sql: ${TABLE}.referrer_term ;;
    group_label: "Referrer"
  }

  # Marketing

  dimension: marketing_medium {
    type: string
    sql: ${TABLE}.marketing_medium ;;
    group_label: "Marketing"
  }

  dimension: marketing_source {
    type: string
    sql: ${TABLE}.marketing_source ;;
    group_label: "Marketing"
  }

  dimension: marketing_term {
    type: string
    sql: ${TABLE}.marketing_term ;;
    group_label: "Marketing"
  }

  dimension: marketing_content {
    type: string
    sql: ${TABLE}.marketing_content ;;
    group_label: "Marketing"
  }

  dimension: marketing_campaign {
    type: string
    sql: ${TABLE}.marketing_campaign ;;
    group_label: "Marketing"
  }

  dimension: marketing_click_id {
    type: string
    sql: ${TABLE}.marketing_click_id ;;
    group_label: "Marketing"
  }

  dimension: marketing_network {
    type: string
    sql: ${TABLE}.marketing_network ;;
    group_label: "Marketing"
  }

  # Location

  dimension: geo_country {
    type: string
    sql: ${TABLE}.geo_country ;;
    group_label: "Location"
  }

  dimension: geo_region {
    type: string
    sql: ${TABLE}.geo_region ;;
    group_label: "Location"
  }

  dimension: geo_region_name {
    type: string
    sql: ${TABLE}.geo_region_name ;;
    group_label: "Location"
  }

  dimension: geo_city {
    type: string
    sql: ${TABLE}.geo_city ;;
    group_label: "Location"
  }

  dimension: geo_zipcode {
    type: zipcode
    sql: ${TABLE}.geo_zipcode ;;
    group_label: "Location"
  }

  dimension: geo_latitude {
    type: number
    sql: ${TABLE}.geo_latitude ;;
    group_label: "Location"
    # use geo_location instead
    hidden: yes
  }

  dimension: geo_longitude {
    type: number
    sql: ${TABLE}.geo_longitude ;;
    group_label: "Location"
    # use geo_location instead
    hidden: yes
  }

  dimension: geo_timezone {
    type: string
    sql: ${TABLE}.geo_timezone ;;
    group_label: "Location"
    # use os_timezone instead
    hidden: yes
  }

  dimension: geo_location {
    type: location
    sql_latitude: ${geo_latitude} ;;
    sql_longitude: ${geo_longitude} ;;
    group_label: "Location"
  }

  # IP

  dimension: ip_address {
    type: string
    sql: ${TABLE}.ip_address ;;
    group_label: "IP"
  }

  # dimension: ip_isp {
    # type: string
    # sql: ${TABLE}.ip_isp ;;
    # group_label: "IP"
  # }

  # dimension: ip_organization {
    # type: string
    # sql: ${TABLE}.ip_organization ;;
    # group_label: "IP"
  # }

  # dimension: ip_domain {
    # type: string
    # sql: ${TABLE}.ip_domain ;;
    # group_label: "IP"
  # }

  # dimension: ip_net_speed {
    # type: string
    # sql: ${TABLE}.ip_net_speed ;;
    # group_label: "IP"
  # }

  # Application

  dimension: app_id {
    type: string
    sql: ${TABLE}.app_id ;;
    group_label: "Application"
  }

  # Browser

  dimension: browser {
    type: string
    sql: ${TABLE}.browser ;;
    group_label: "Browser"
  }

  dimension: browser_name {
    type: string
    sql: ${TABLE}.browser_name ;;
    group_label: "Browser"
  }

  dimension: browser_major_version {
    type: string
    sql: ${TABLE}.browser_major_version ;;
    group_label: "Browser"
  }

  dimension: browser_minor_version {
    type: string
    sql: ${TABLE}.browser_minor_version ;;
    group_label: "Browser"
  }

  dimension: browser_build_version {
    type: string
    sql: ${TABLE}.browser_build_version ;;
    group_label: "Browser"
  }

  dimension: browser_engine {
    type: string
    sql: ${TABLE}.browser_engine ;;
    group_label: "Browser"
  }

  dimension: browser_language {
    type: string
    sql: ${TABLE}.browser_language ;;
    group_label: "Browser"
  }

  # OS

  dimension: os {
    type: string
    sql: ${TABLE}.os ;;
    group_label: "OS"
  }

  dimension: os_name {
    type: string
    sql: ${TABLE}.os_name ;;
    group_label: "OS"
  }

  dimension: os_major_version {
    type: string
    sql: ${TABLE}.os_major_version ;;
    group_label: "OS"
  }

  dimension: os_minor_version {
    type: string
    sql: ${TABLE}.os_minor_version ;;
    group_label: "OS"
  }

  dimension: os_build_version {
    type: string
    sql: ${TABLE}.os_build_version ;;
    group_label: "OS"
  }

  dimension: os_manufacturer {
    type: string
    sql: ${TABLE}.os_manufacturer ;;
    group_label: "OS"
  }

  dimension: os_timezone {
    type: string
    sql: ${TABLE}.os_timezone ;;
    group_label: "OS"
  }

  # Device

  dimension: device {
    type: string
    sql: ${TABLE}.device ;;
    group_label: "Device"
  }

  # MEASURES

  measure: row_count {
    type: count
    group_label: "Counts"
  }

  measure: page_view_count {
    type: sum
    sql: ${page_views} ;;
    group_label: "Counts"
  }

  measure: session_count {
    type: count_distinct
    sql: ${session_id} ;;
    group_label: "Counts"
    drill_fields: [session_count]
  }
  set: session_count{
    fields: [session_id, session_start_date, first_page_url, referrer_medium, page_view_count, total_time_engaged]
  }

  measure: user_count {
    type: count_distinct
    sql: ${domain_userid} ;;
    group_label: "Counts"
    drill_fields: [user_count]
  }
  set: user_count{
    fields: [domain_userid, users.first_page_url, session_count, average_time_engaged, total_time_engaged]
  }

  measure: new_user_count {
    type: count_distinct
    sql: ${domain_userid} ;;

    filters: {
      field: session_index
      value: "1"
    }

    group_label: "Counts"
    drill_fields: [new_user_count]
  }
  set: new_user_count{
    fields: [domain_userid, users.first_page_url, session_count, average_time_engaged, total_time_engaged]
  }

  measure: bounced_user_count {
    type: count_distinct
    sql: ${domain_userid} ;;

    filters: {
      field: user_bounced
      value: "yes"
    }

    group_label: "Counts"
  }

  # Engagement

  measure: total_time_engaged {
    type: sum
    sql: ${time_engaged} ;;
    value_format: "#,##0\"s\""
    group_label: "Engagement"
  }

  measure: average_time_engaged {
    type: average
    sql: ${time_engaged} ;;
    value_format: "0.00\"s\""
    group_label: "Engagement"
  }
}
