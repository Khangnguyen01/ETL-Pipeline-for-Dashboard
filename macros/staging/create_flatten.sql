{% macro create_flatten_table(event_name, event_params, cluster_by=['version', 'country', 'platform']) %}

{# Check if 'level' exists in event_params #}
{% set start_date = var('start_date', none) %}
{% set end_date = var('end_date', none) %}
{% set is_backfill = var('is_backfill', 'false') %}
{% set end_date = var('end_date', none) %}
{% set has_level = namespace(value=false) %}
{% for param in event_params %}
    {% if param.name == 'level' %}
        {% set has_level.value = true %}
    {% endif %}
{% endfor %}

{# Add 'level' to cluster_by if it exists #}
{% if has_level.value %}
    {% set cluster_by = cluster_by + ['level'] %}
{% endif %}

{{ config(
    materialized='incremental',
    unique_key='event_timestamp',
    partition_by={'field': 'event_date', 'data_type': 'date'},
    cluster_by=cluster_by,
    incremental_strategy='insert_overwrite',
    on_schema_change='append_new_columns'
) }}

SELECT
    user_pseudo_id_hashed,
    event_date,
    event_timestamp,
    version,
    country,
    platform,
    {% for param in event_params %}
    {% if param.name == 'level' %}
    CAST((SELECT value.{{ param.type }} FROM UNNEST(event_params) WHERE key = '{{ param.name }}') AS INT64) AS {{ param.name }}
    {% else %}
    (SELECT value.{{ param.type }} FROM UNNEST(event_params) WHERE key = '{{ param.name }}') AS {{ param.name }}
    {% endif %}
    {%- if not loop.last %},{% endif %}
    {% endfor %}
    {# Thêm event_value_in_usd nếu là in_app_purchase #}
    {% if event_name == 'in_app_purchase' %},
    event_value_in_usd
    {% endif %}
    {% if event_name == 'first_open' %},
    mobile_brand_name,
    mobile_model_name,
    MAX((SELECT CAST(REGEXP_EXTRACT(value.string_value, r'(\d+)') AS INT64) FROM UNNEST(user_properties) WHERE key = 'device_ram_user')) AS device_ram_user,
    MAX((SELECT value.string_value FROM UNNEST(user_properties) WHERE key = 'device_chip_user')) AS device_chip_user,
    MAX((SELECT CASE WHEN value.string_value = 'False' THEN 0 ELSE 1 END FROM UNNEST(user_properties) WHERE key = 'is_developer')) AS is_developer
    {% endif %}
FROM {{ ref('silver') }}
WHERE event_name = '{{ event_name }}'
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
{% if event_name == 'first_open' %}
GROUP BY ALL
{% endif %}
{% endmacro %}