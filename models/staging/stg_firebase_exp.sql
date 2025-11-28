{{
    config(
        materialized='incremental',
        unique_key=['event_date', 'user_pseudo_id_hashed'],
        partition_by={
          'field': 'event_date',
          'data_type': 'date',
          'granularity': 'day'
        },
        cluster_by=['version'],
        on_schema_change='fail'
    )
}}

WITH base AS (
  SELECT
    user_pseudo_id_hashed,
    event_date,
    version,
    up.key AS firebase_exp,
    up.value.string_value AS variant
  FROM {{ source('silver', 'silver') }},
  UNNEST(user_properties) AS up
  WHERE up.key LIKE 'firebase_exp%'
    AND event_name IN ('session_start', 'start_level', 'user_engagement')
  {% if is_incremental() %}
    AND event_date > (SELECT MAX(event_date) FROM {{ this }})
  {% endif %}
    AND event_date <= CURRENT_DATE()
),
dedup AS (
  SELECT DISTINCT
    user_pseudo_id_hashed,
    event_date,
    version,
    firebase_exp,
    variant
  FROM base
)
SELECT
  event_date,
  user_pseudo_id_hashed,
  version,
  ARRAY_AGG(STRUCT(firebase_exp AS key, variant AS value) ORDER BY firebase_exp) AS firebase_exp
FROM dedup
GROUP BY event_date, user_pseudo_id_hashed, version