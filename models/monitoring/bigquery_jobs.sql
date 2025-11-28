{% set start_date = var('start_date', none) %}
{% set end_date = var('end_date', none) %}
{% set is_backfill = var('is_backfill', 'false') %}

{{
  config(
    materialized='incremental',
    unique_key='job_id',
    partition_by={
      'field': 'creation_date',
      'data_type': 'date',
      'granularity': 'day'
    },
    cluster_by=['query_source', 'target_layer', 'target_table'],
    incremental_strategy='insert_overwrite',
    on_schema_change='append_new_columns'
  )
}}

WITH jobs_raw AS (
  SELECT
    job_id,
    project_id,
    user_email,
    creation_time,
    start_time,
    end_time,
    total_bytes_processed,
    total_bytes_billed,
    statement_type,
    priority,
    destination_table,
    total_slot_ms,
    state,
    error_result,
    query,
    labels,
    cache_hit,
    referenced_tables
  FROM
    `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
  WHERE
    state = 'DONE'
    AND job_type = 'QUERY'
    {% if is_incremental() %}
        {% if is_backfill == 'true' %}
            {# BACKFILL: Load specific partition #}
            AND start_time BETWEEN DATE('{{ start_date }}') AND DATE('{{ end_date }}')
        {% else %}
            {# SINGLE RUN / SCHEDULED: Incremental from MAX #}
            AND start_time > (SELECT MAX(start_time) FROM {{ this }})
            AND DATE(start_time) <= CURRENT_DATE()-1
        {% endif %}
    {% endif %}
),
intermediate AS (
  SELECT
    -- Job identifiers
    job_id,
    project_id,
    user_email,
    -- Timing
    DATE(creation_time) as creation_date,
    creation_time,
    start_time,
    end_time,
    ROUND(TIMESTAMP_DIFF(end_time, start_time, MILLISECOND) / 1000.0, 2) as duration_seconds,
    -- Cost calculation (On-demand pricing: $6.25 per TB as of 2024)
    total_bytes_processed,
    ROUND(total_bytes_processed / POW(10, 6), 2) as mb_processed,
    ROUND(total_bytes_processed / POW(10, 9), 2) as gb_processed,
    ROUND(total_bytes_processed / POW(10, 12), 6) as tb_processed,
    total_bytes_billed,
    ROUND(total_bytes_billed / POW(10, 6), 2) as mb_billed,
    ROUND(total_bytes_billed / POW(10, 9), 2) as gb_billed,
    ROUND(total_bytes_billed / POW(10, 12), 6) as tb_billed,
    ROUND((total_bytes_billed / POW(10, 12)) * 6.25, 4) as estimated_cost_usd,
    -- Query details
    statement_type,
    priority,
    COALESCE(destination_table.project_id, project_id) as destination_project,
    destination_table.dataset_id as destination_dataset,
    destination_table.table_id as destination_table,
    -- Performance metrics
    total_slot_ms,
    ROUND(total_slot_ms / 1000.0 / GREATEST(TIMESTAMP_DIFF(end_time, start_time, SECOND), 1), 2) as avg_slots,
    -- Status
    state,
    error_result.reason as error_reason,
    error_result.message as error_message,
    -- Query text
    SUBSTR(query, 1, 1000) as query_preview,
    -- Cache usage
    CASE WHEN cache_hit THEN 1 ELSE 0 END as cache_hit,
    -- Referenced tables count
    ARRAY_LENGTH(referenced_tables) as referenced_tables_count,
    -- Categorization
    CASE
      -- Check labels for Looker Studio
      WHEN EXISTS (
        SELECT 1
        FROM UNNEST(labels) AS label
        WHERE label.key = 'looker_studio_datasource_id'
      ) THEN 'looker'
      -- Check query for dbt JSON comment or posthook marker
      WHEN REGEXP_CONTAINS(query, r'/\*\s*\{[^}]*"app"\s*:\s*"dbt"') THEN 'dbt'
      WHEN REGEXP_CONTAINS(query, r'/\*\s*dbt_posthook\s*\*/') THEN 'dbt_posthook'
      ELSE user_email
    END as query_source,

    -- Target layer
    CASE
      -- Looker queries
      WHEN EXISTS (
        SELECT 1
        FROM UNNEST(labels) AS label
        WHERE label.key = 'looker_studio_datasource_id'
      ) THEN 'looker'
      -- dbt queries - check node_id pattern in JSON comment
      WHEN NOT REGEXP_CONTAINS(query, r'/\*\s*dbt_posthook\s*\*/') AND REGEXP_CONTAINS(query, r'/\*\s*\{[^}]*"app"\s*:\s*"dbt"') THEN
        CASE
          WHEN REGEXP_CONTAINS(query, r'"node_id"\s*:\s*"model\..*\.stg_') THEN 'staging_event'
          WHEN REGEXP_CONTAINS(query, r'"node_id"\s*:\s*"model\..*\.(mart_|agg_)') THEN 'mart'
        END
      -- dbt posthook
      WHEN REGEXP_CONTAINS(query, r'/\*\s*dbt_posthook\s*\*/') THEN
        CASE
          WHEN REGEXP_CONTAINS(query, r'INTO.*\.stg_') THEN 'staging_event'
          WHEN REGEXP_CONTAINS(query, r'INTO.*\.dev_marts') THEN 'mart'
        END
      -- Other dbt queries without clear layer identifier
    END as target_layer,

    -- Target table
    CASE
      -- Looker queries
      WHEN EXISTS (
        SELECT 1
        FROM UNNEST(labels) AS label
        WHERE label.key = 'looker_studio_datasource_id'
      ) THEN 
        REGEXP_EXTRACT(query, r'dev_marts\.`?([A-Za-z0-9_]+)`?')
      -- dbt queries - check node_id pattern in JSON comment
      WHEN NOT REGEXP_CONTAINS(query, r'/\*\s*dbt_posthook\s*\*/') AND REGEXP_CONTAINS(query, r'/\*\s*\{[^}]*"app"\s*:\s*"dbt"') THEN
        REGEXP_EXTRACT(query, r'"node_id"\s*:\s*"model\..*\.([a-zA-Z0-9_]+)"')
      -- dbt posthook
      WHEN REGEXP_CONTAINS(query, r'/\*\s*dbt_posthook\s*\*/') THEN
        REGEXP_EXTRACT(query, r'INTO\s+[^.]*\.`?dev_[^.`\s]*`?\.\s*`?([A-Za-z0-9_]+)`?')
      -- Other dbt queries without clear layer identifier
    END as target_table,

    (SELECT value FROM UNNEST(labels) AS label WHERE label.key = 'dbt_layer') AS dbt_layer_label,
    (SELECT value FROM UNNEST(labels) AS label WHERE label.key = 'etl_type') as etl_type_label,
    (SELECT value FROM UNNEST(labels) AS label WHERE label.key = 'job_type') as job_type_label

  FROM jobs_raw
)
SELECT 
  * EXCEPT(target_layer),
  COALESCE(target_layer, dbt_layer_label, 'other') as target_layer
FROM intermediate