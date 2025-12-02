{% set start_date = var('start_date', none) %}
{% set end_date = var('end_date', none) %}
{% set is_backfill = var('is_backfill', 'false') %}

{{
  config(
    materialized='incremental',
    unique_key=['user_pseudo_id_hashed', 'event_name'],
    partition_by={
      'field': 'event_date',
      'data_type': 'date',
      'granularity': 'day'
    },
    cluster_by=['version', 'country', 'platform', 'placement'],
    incremental_strategy='insert_overwrite',
    on_schema_change='append_new_columns',
    post_hook=[
      "DELETE FROM {{ this }} WHERE event_date < DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)"
    ]
  )
}}

WITH iap_event AS (
  SELECT
    user_pseudo_id_hashed,
    event_date,
    event_timestamp,
    'iap_click' AS event_name,
    version,
    placement,
    pack_name,
    trigger_show_type,
    show_type,
    null AS level,
    null AS revenue
  FROM {{ ref('stg_iap_buy_click') }}
  WHERE 1=1
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

  UNION ALL

  SELECT
    user_pseudo_id_hashed,
    event_date,
    event_timestamp,
    'iap_show' AS event_name,
    version,
    placement,
    REPLACE(pack_name, ',', '') AS pack_name,
    trigger_show_type,
    show_type,
    null AS level,
    null AS revenue
  FROM {{ ref('stg_iap_show') }}
  WHERE 1=1
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

  UNION ALL

  SELECT
    s1.user_pseudo_id_hashed,
    s1.event_date,
    s1.event_timestamp,
    'iap_purchased' AS event_name,
    s1.version,
    s1.placement,
    s2.product_name AS pack_name,
    s1.trigger_show_type,
    s1.show_type,
    s1.level,
    s1.revenue
  FROM {{ ref('stg_iap_purchased') }} s1
  LEFT JOIN (
    SELECT DISTINCT product_name, package_id
    FROM {{ ref('stg_iap_purchased') }}
  ) s2
    ON s1.package_id = s2.package_id
  WHERE 1=1
    {% if is_incremental() %}
        {% if is_backfill == 'true' %}
            {# BACKFILL: Load specific partition #}
            AND event_date BETWEEN DATE('{{ start_date }}') AND DATE('{{ end_date }}')
        {% else %}
            {# SINGLE RUN / SCHEDULED: Incremental from MAX #}
            AND s1.event_date > (SELECT MAX(event_date) FROM {{ this }})
            AND s1.event_date <= CURRENT_DATE()-1
        {% endif %}
    {% endif %}
)
, iap_event_group AS (
SELECT
    s1.event_date,
    s1.user_pseudo_id_hashed,
    s1.event_name,
    s1.version,
    s1.placement,
    s1.pack_name,
    s1.trigger_show_type,
    s1.show_type,
    COUNT(s1.event_timestamp) AS event_count,
    SUM(s1.revenue) AS total_revenue,
    MIN(s1.level) OVER(PARTITION BY s1.user_pseudo_id_hashed) AS first_level_purchased
FROM iap_event s1
GROUP BY
    s1.event_date,
    s1.user_pseudo_id_hashed,
    s1.event_name,
    s1.version,
    s1.placement,
    s1.pack_name,
    s1.trigger_show_type,
    s1.show_type,
    s1.level
)

, user_detail AS (
  SELECT
    s1.*,
    s2.event_date AS login_date,
    s2.country,
    s2.platform,
    s2.mobile_brand_name,
    s2.mobile_model_name
  FROM iap_event_group s1
  LEFT JOIN {{ ref('stg_first_open') }} s2
    ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
  QUALIFY ROW_NUMBER() OVER(PARTITION BY s2.user_pseudo_id_hashed ORDER BY s2.event_timestamp DESC) = 1
)

SELECT
  s1.*,
  s2.firebase_exp
FROM user_detail s1
LEFT JOIN {{ ref('stg_firebase_exp') }} s2
  ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
  AND s1.event_date = s2.event_date
  AND s1.version = s2.version