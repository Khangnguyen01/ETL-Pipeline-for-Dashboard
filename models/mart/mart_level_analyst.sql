{% set start_date = var('start_date', none) %}
{% set end_date = var('end_date', none) %}
{% set is_backfill = var('is_backfill', 'false') %}

{{
  config(
    materialized='incremental',
    unique_key=['user_pseudo_id_hashed', 'level', 'start_attempt_ts'],
    partition_by={
      'field': 'event_date',
      'data_type': 'date',
      'granularity': 'day'
    },
    incremental_strategy='insert_overwrite',
    cluster_by=['version','platform','country','level'],
    post_hook=[
      "DELETE FROM {{ this }} WHERE event_date < DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)"
    ]
  )
}}

WITH base AS (
  SELECT
    s1.user_pseudo_id_hashed,
    s2.event_date AS login_date,
    s2.country,
    s2.platform,
    s2.mobile_brand_name,
    s2.mobile_model_name,
    s1.version,
    s1.event_date,
    s1.level,
    s1.event_timestamp AS start_attempt_ts,
  FROM {{ ref('stg_start_level') }} s1
  LEFT JOIN {{ ref('stg_first_open') }} s2
    ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
  WHERE 1=1
    {% if is_incremental() %}
        {% if is_backfill == 'true' %}
            {# BACKFILL: Load specific partition #}
            AND s1.event_date BETWEEN DATE('{{ start_date }}') AND DATE('{{ end_date }}')
        {% else %}
            {# SINGLE RUN / SCHEDULED: Incremental from MAX #}
            AND s1.event_date > (SELECT MAX(event_date) FROM {{ this }})
            AND s1.event_date <= CURRENT_DATE()-1
        {% endif %}
    {% endif %}
)
, base1 AS (
    SELECT
        s1.*,
        s2.firebase_exp
    FROM base s1
    LEFT JOIN {{ ref('stg_firebase_exp') }} s2
        ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
        AND s1.event_date = s2.event_date
        AND s1.version = s2.version
)
, base2 AS (
  SELECT
    s1.*,
    LEAD(start_attempt_ts) OVER(PARTITION BY user_pseudo_id_hashed ORDER BY start_attempt_ts ASC) AS end_attempt_ts,
    ROW_NUMBER() OVER(PARTITION BY user_pseudo_id_hashed, level ORDER BY start_attempt_ts ASC) AS attempt_time,
    LEAD(level) OVER(PARTITION BY user_pseudo_id_hashed ORDER BY start_attempt_ts ASC) AS next_attempt_level
  FROM base1 s1
)

{{ generate_mart_level_analyst(base_cte='base2') }}