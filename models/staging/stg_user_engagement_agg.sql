{% set start_date = var('start_date', none) %}
{% set end_date = var('end_date', none) %}
{% set is_backfill = var('is_backfill', 'false') %}

{{ config(
  materialized='incremental',
  partition_by={'field': 'event_date', 'data_type': 'date'},
  cluster_by=['ga_session_id'],
  insert_strategy='insert_overwrite',
  unique_key=['event_date', 'user_pseudo_id_hashed', 'ga_session_id']
) }}

WITH all_time AS (
  SELECT event_date, version, user_pseudo_id_hashed, ga_session_id, engagement_time_msec
  FROM {{ ref('stg_user_engagement') }}
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

  SELECT event_date, version, user_pseudo_id_hashed, ga_session_id, engagement_time_msec
  FROM {{ ref('stg_screen_view') }}
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

  SELECT event_date, version, user_pseudo_id_hashed, ga_session_id, engagement_time_msec
  FROM {{ ref('stg_app_exception') }}
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
)

SELECT
    event_date,
    user_pseudo_id_hashed,
    version,
    ga_session_id,
    SUM(engagement_time_msec) AS engagement_time_msec
FROM all_time
GROUP BY
    event_date,
    version,
    user_pseudo_id_hashed,
    ga_session_id