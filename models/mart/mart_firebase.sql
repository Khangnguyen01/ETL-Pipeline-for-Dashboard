{% set start_date = var('start_date', none) %}
{% set end_date = var('end_date', none) %}
{% set is_backfill = var('is_backfill', 'false') %}

{{
  config(
    materialized='incremental',
    unique_key=['user_pseudo_id_hashed', 'event_date'],
    partition_by={
      'field': 'event_date',
      'data_type': 'date',
      'granularity': 'day'
    },
    cluster_by=['version', 'platform', 'country', 'firebase_exp'],
    incremental_strategy='insert_overwrite'
  )
}}

WITH unnest_data AS (
SELECT
    event_date,
    user_pseudo_id_hashed,
    version,
    fe.key AS firebase_exp,
    fe.value AS variant
FROM {{ ref('stg_firebase_exp') }},
UNNEST(firebase_exp) AS fe
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY user_pseudo_id_hashed, fe.key ORDER BY event_date ASC) = 1
)
, active_day AS (
SELECT
    s1.event_date AS date_join_test,
    s1.user_pseudo_id_hashed,
    s2.event_date,
    s2.login_date,
    s2.country,
    s2.platform,
    s2.version,
    s2.mobile_brand_name,
    s2.mobile_model_name,
    s1.firebase_exp,
    s1.variant,
    s2.ad_impression_count,
    s2.ad_impression_value_sum,
    s2.af_rewarded_count,
    s2.af_inters_count,
    s2.in_app_purchase_count,
    s2.in_app_purchase_event_value_in_usd_sum,
    DATE_DIFF(s2.event_date, s1.event_date, DAY) AS day_since_join_test,
FROM unnest_data AS s1
LEFT JOIN {{ ref('mart_overview') }} AS s2
    ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
    AND s2.event_date >= s1.event_date
WHERE 1=1
    {% if is_incremental() %}
        {% if is_backfill == 'true' %}
            {# BACKFILL: Load specific partition #}
            AND s2.event_date BETWEEN DATE('{{ start_date }}') AND DATE('{{ end_date }}')
        {% else %}
            {# SINGLE RUN / SCHEDULED: Incremental from MAX #}
            AND s2.event_date > (SELECT MAX(event_date) FROM {{ this }})
            AND s2.event_date <= CURRENT_DATE()-1
        {% endif %}
    {% endif %}
)
SELECT
    s1.*,
    COUNT(s2.event_timestamp) AS total_attempts,
    COUNT(DISTINCT s2.level) AS level_start
FROM active_day AS s1
LEFT JOIN {{ ref('stg_start_level') }} AS s2
    ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
    AND s1.event_date = s2.event_date
WHERE 1=1
    {% if is_incremental() %}
        {% if is_backfill == 'true' %}
            {# BACKFILL: Load specific partition #}
            AND s2.event_date BETWEEN DATE('{{ start_date }}') AND DATE('{{ end_date }}')
        {% else %}
            {# SINGLE RUN / SCHEDULED: Incremental from MAX #}
            AND s2.event_date > (SELECT MAX(event_date) FROM {{ this }})
            AND s2.event_date <= CURRENT_DATE()-1
        {% endif %}
    {% endif %}
GROUP BY ALL