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
    cluster_by=['version', 'platform', 'country'],
    incremental_strategy='insert_overwrite'
  )
}}

{%- set event_configs = var('mart_config').mart_overview -%}

WITH base AS (
  SELECT DISTINCT
    s1.event_date,
    s1.user_pseudo_id_hashed,
    s2.event_date AS login_date,
    s2.country,
    s2.platform,
    s2.mobile_brand_name,
    s2.mobile_model_name,
    s1.version
  FROM {{ ref('silver') }} s1
  LEFT JOIN {{ ref('stg_first_open') }} s2
    ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
    AND s1.event_date >= s2.event_date
  WHERE event_name IN ('session_start', 'start_level', 'first_open')
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
, base2 AS (
    SELECT
        s1.*,
        s2.firebase_exp
    FROM base s1
    LEFT JOIN {{ ref('stg_firebase_exp') }} s2
        ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
        AND s1.event_date = s2.event_date
        AND s1.version = s2.version
)
{%- for event_config in event_configs -%}
, {{ event_config.name }}_wide AS (
  {{ generate_wide_table_for_event(event_config, event_config.source_layer, apply_date_filter=is_incremental()) }}
)
{%- endfor %}

SELECT
  s1.*
  {%- for event_config in event_configs -%}
  , {{ event_config.name }}_wide.* EXCEPT (user_pseudo_id_hashed, event_date, version)
  {%- endfor %}
FROM base2 s1
{%- for event_config in event_configs %}
LEFT JOIN {{ event_config.name }}_wide
  ON s1.user_pseudo_id_hashed = {{ event_config.name }}_wide.user_pseudo_id_hashed
  AND s1.event_date = {{ event_config.name }}_wide.event_date
  AND s1.version = {{ event_config.name }}_wide.version
{%- endfor %}