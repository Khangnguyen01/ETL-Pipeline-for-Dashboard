{% set start_date = var('start_date', none) %}
{% set end_date = var('end_date', none) %}
{% set is_backfill = var('is_backfill', 'false') %}

{% set end_day = var(
    'end_day',
    (modules.datetime.datetime.utcnow() - modules.datetime.timedelta(days=31)).strftime('%Y%m%d')
) %}

{{ config(
    materialized        = 'incremental',
    incremental_strategy = 'insert_overwrite',
    partition_by        = {'field': 'event_date', 'data_type': 'date'},
    cluster_by          = ['event_name', 'version', 'country', 'platform'],
    description         = 'Silver table containing raw data but clustered and partitioned'
) }}

SELECT
    user_pseudo_id,
    FARM_FINGERPRINT(user_pseudo_id) AS user_pseudo_id_hashed,
    event_name,
    PARSE_DATE('%Y%m%d', event_date) AS event_date,
    event_timestamp,
    event_value_in_usd,
    app_info.version,
    geo.country,
    geo.continent,
    geo.region,
    geo.sub_continent,
    platform,
    device.mobile_brand_name,
    device.mobile_model_name,
    device.advertising_id,
    device.time_zone_offset_seconds,
    event_params,
    user_properties
FROM {{ source('raw_events', 'event_intraday') }}
WHERE 1=1
{% if is_incremental() %}
    {% if is_backfill == 'true' %}
        {# BACKFILL: Load specific partition #}
        AND _TABLE_SUFFIX BETWEEN REPLACE('{{ start_date }}', '-', '')
                              AND REPLACE('{{ end_date }}', '-', '')
    {% else %}
        {# SINGLE RUN / SCHEDULED: Incremental from MAX #}
        AND _TABLE_SUFFIX > FORMAT_DATE('%Y%m%d', (SELECT MAX(event_date) FROM {{ this }}))
        AND _TABLE_SUFFIX <= FORMAT_DATE('%Y%m%d', CURRENT_DATE()-1)
    {% endif %}
{% else %}
    {# FULL REFRESH #}
    AND _TABLE_SUFFIX BETWEEN '{{ end_day }}' AND FORMAT_DATE('%Y%m%d', CURRENT_DATE()-1)
{% endif %}

