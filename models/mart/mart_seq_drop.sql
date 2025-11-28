{% set start_date = var('start_date', none) %}
{% set end_date = var('end_date', none) %}
{% set is_backfill = var('is_backfill', 'false') %}

{{ config(
  materialized='incremental',
  partition_by={'field': 'event_date', 'data_type': 'date'},
  cluster_by=['version','platform','country','drop_time'],
  incremental_strategy='insert_overwrite',
  unique_key=['user_pseudo_id_hashed', 'event_date', 'session_end_ts'],
  post_hook=[
    "DELETE FROM {{ this }} WHERE event_date < DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)"
  ]
) }}

WITH base AS (
  SELECT
    event_date,
    event_timestamp,
    user_pseudo_id_hashed,
    event_name,
    version,
    country,
    platform,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') as ga_session_id,
    MAX(event_timestamp) OVER (
      PARTITION BY event_date, user_pseudo_id_hashed,
      (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id')
    ) AS session_end_ts,
    event_params
  FROM `wool-away.dev_staging.silver`
  WHERE 1=1
    AND event_name IN (
    {% for event in var('mart_config')['mart_seq_drop'] %}
    '{{ event.name }}'{% if not loop.last %}
      , {% endif %}
    {% endfor %}
    )
    {% if is_incremental() %}
        {% if is_backfill == 'true' %}
            {# BACKFILL: Load specific partition #}
            AND event_date BETWEEN DATE('{{ start_date }}') AND DATE('{{ end_date }}')
        {% else %}
            {# SINGLE RUN / SCHEDULED: Incremental from MAX #}
            AND event_date > (SELECT MAX(event_date) FROM {{ this }})
            AND event_date <= CURRENT_DATE()-1
        {% endif %}
    {% endif %}
),

enriched_events AS (
  SELECT
    b.*,
    {{ format_event_with_filter() }} AS formatted_event,
    ROW_NUMBER() OVER(PARTITION BY user_pseudo_id_hashed ORDER BY event_timestamp DESC) AS step_rank
  FROM base b
  WHERE 1=1
    {{ event_filter_conditions() }}
  QUALIFY DENSE_RANK() OVER(PARTITION BY event_date, user_pseudo_id_hashed ORDER BY session_end_ts DESC) = 1
    AND ROW_NUMBER() OVER(PARTITION BY user_pseudo_id_hashed ORDER BY event_timestamp DESC) <= 30
)
, add_login_ts AS (
SELECT
  s1.event_date,
  s1.user_pseudo_id_hashed,
  s2.event_timestamp AS login_ts,
  s1.session_end_ts,
  s1.version,
  s1.platform,
  s1.country,
  s1.ga_session_id,
  ARRAY_TO_STRING(ARRAY_AGG(s1.formatted_event ORDER BY s1.step_rank LIMIT 10), ' > ') AS journey_10,
  ARRAY_TO_STRING(ARRAY_AGG(s1.formatted_event ORDER BY s1.step_rank LIMIT 15), ' > ') AS journey_15,
  ARRAY_TO_STRING(ARRAY_AGG(s1.formatted_event ORDER BY s1.step_rank LIMIT 20), ' > ') AS journey_20,
  ARRAY_TO_STRING(ARRAY_AGG(s1.formatted_event ORDER BY s1.step_rank LIMIT 25), ' > ') AS journey_25,
  ARRAY_TO_STRING(ARRAY_AGG(s1.formatted_event ORDER BY s1.step_rank LIMIT 30), ' > ') AS journey_30
FROM enriched_events s1
LEFT JOIN (
  SELECT
    user_pseudo_id_hashed,
    event_timestamp
  FROM `wool-away`.`dev_staging`.`stg_first_open`
  QUALIFY ROW_NUMBER() OVER(PARTITION BY user_pseudo_id_hashed ORDER BY event_timestamp DESC) = 1
  ) AS s2
  ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
GROUP BY
  s1.event_date,
  s2.event_timestamp,
  s1.session_end_ts,
  s1.user_pseudo_id_hashed,
  s1.version,
  s1.platform,
  s1.country,
  s1.ga_session_id
)
, total_session AS (
SELECT
    s1.*,
    COUNT(DISTINCT s2.ga_session_id) AS total_sessions,
    TIMESTAMP_DIFF(TIMESTAMP_MICROS(session_end_ts), TIMESTAMP_MICROS(login_ts), DAY) AS cohort_day_drop,
    TIMESTAMP_DIFF(TIMESTAMP_MICROS(UNIX_MICROS(TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), DAY))), TIMESTAMP_MICROS(session_end_ts), DAY) AS drop_time
FROM add_login_ts s1
LEFT JOIN `wool-away`.`dev_staging`.`stg_session_start` s2
    ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
GROUP BY ALL
)
, count_level_played AS (
SELECT
    s1.*,
    COUNT(DISTINCT level) AS levels_played
FROM total_session s1
LEFT JOIN {{ ref('stg_start_level') }} s2
    ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
    AND s1.event_date = s2.event_date
GROUP BY ALL
)
, add_last_session_duration AS (
SELECT
    s1.*,
    SUM(s2.engagement_time_msec) AS last_session_duration_msec
FROM count_level_played s1
LEFT JOIN {{ ref('stg_user_engagement_agg') }} s2
    ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
    AND s1.event_date = s2.event_date
    AND s1.ga_session_id = s2.ga_session_id
GROUP BY ALL
)
SELECT
  s1.*,
  s2.firebase_exp
FROM add_last_session_duration s1
LEFT JOIN {{ ref('stg_firebase_exp') }} s2
  ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
  AND s1.event_date = s2.event_date