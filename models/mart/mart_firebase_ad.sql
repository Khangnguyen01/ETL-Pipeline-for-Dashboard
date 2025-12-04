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
    fe.key AS firebase_exp,
    fe.value AS variant
FROM {{ ref('stg_firebase_exp') }},
UNNEST(firebase_exp) AS fe
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY user_pseudo_id_hashed, fe.key ORDER BY event_date ASC) = 1
)
, login_date AS (
SELECT
    s1.event_date AS date_join_test,
    s1.user_pseudo_id_hashed,
    s1.firebase_exp,
    s1.variant,
    s2.event_date AS login_date,
    s2.country,
    s2.platform,
    s2.mobile_brand_name,
    s2.mobile_model_name
FROM unnest_data AS s1
LEFT JOIN (
    SELECT DISTINCT
        user_pseudo_id_hashed,
        event_date,
        country,
        platform,
        mobile_brand_name,
        mobile_model_name
    FROM {{ ref('stg_first_open') }} AS s2
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY user_pseudo_id_hashed ORDER BY event_timestamp DESC) = 1
    ) s2
    ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
    AND s1.event_date >= s2.event_date
)
SELECT
    s1.*,
    s2.event_date,
    s2.placement,
    s2.version,
    COUNT(s2.event_timestamp) AS ad_count
FROM login_date AS s1
LEFT JOIN {{ ref('stg_ad_show') }} AS s2
    ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
WHERE s2.ad_format = 'REWARDED'
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
GROUP BY ALL