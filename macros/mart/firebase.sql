{%- macro generate_wide_table_for_firebase(event_config, source_schema='dev_staging', apply_date_filter=false) -%}
{%- set event_name = event_config.name -%}
{%- set has_pivot = event_config.has_pivot -%}
{%- set pivot_field = event_config.pivot_field | default('') -%}
{%- set value_fields = event_config.value_fields | default(['event_timestamp']) -%}
{%- set agg_functions = event_config.agg_functions | default(['COUNT']) -%}
{%- set where_conditions = event_config.WHERE_conditions | default([]) -%}

{%- if has_pivot and pivot_field -%}
  {# Build WHERE clause for pivot query #}
  {%- set where_clause = '' -%}
  {%- if where_conditions | length > 0 -%}
    {%- set conditions = [] -%}
    {%- for condition in where_conditions -%}
      {%- set _ = conditions.append(condition.field ~ " = '" ~ condition.value ~ "'") -%}
    {%- endfor -%}
    {%- set where_clause = 'WHERE ' ~ conditions | join(' AND ') -%}
  {%- endif -%}

  {# Query to get distinct pivot values #}
  {%- set pivot_query -%}
    SELECT DISTINCT {{ pivot_field }}
    FROM {{ ref('stg_' ~ event_name) }}
    {{ where_clause }}
  {%- endset -%}

  {%- set pivot_values = [] -%}
  {%- if execute -%}
    {%- set pivot_values = run_query(pivot_query).rows -%}
  {%- endif -%}

{# Generate SELECT with pivots #}
SELECT
  user_pseudo_id_hashed,
  event_date,
  version

  {%- for pivot_row in pivot_values -%}
    {%- set pivot_val = pivot_row[0] -%}
    {%- set pivot_suffix = pivot_val | string | lower | replace(' ', '_') | replace('-', '_') | replace(',', '') | replace('.', '_') -%}

    {%- for i in range(value_fields | length) -%}
      {%- set value_field = value_fields[i] -%}
      {%- set agg_func = agg_functions[i] -%}
      {%- set agg_func_lower = agg_func | lower | replace(' ', '_') -%}

      {%- if value_field == "event_timestamp" -%}
        {%- set column_name = event_name ~ '_' ~ pivot_suffix ~ '_' ~ agg_func_lower -%}
      {%- else -%}
        {%- set column_name = event_name ~ '_' ~ pivot_suffix ~ '_' ~ value_field ~ '_' ~ agg_func_lower -%}
      {%- endif -%}

      {# Build condition #}
      {%- set condition_parts = [pivot_field ~ " = '" ~ pivot_val ~ "'"] -%}
      {%- for condition in where_conditions -%}
        {%- set _ = condition_parts.append(condition.field ~ " = '" ~ condition.value ~ "'") -%}
      {%- endfor -%}

      {%- if 'DISTINCT' in agg_func.upper() -%}
        {%- set clean_agg = agg_func.upper().replace('COUNT DISTINCT', 'COUNT').replace('DISTINCT', '').strip() -%}
  ,
  {{ clean_agg }}(DISTINCT CASE WHEN {{ condition_parts | join(' AND ') }} THEN {{ value_field }} END)
    AS {{ column_name }}
      {%- else -%}
  ,
  {{ agg_func }}(CASE WHEN {{ condition_parts | join(' AND ') }} THEN {{ value_field }} END)
    AS {{ column_name }}
      {%- endif -%}
    {%- endfor -%}
  {%- endfor %}

FROM {{ ref('stg_' ~ event_name) }}
{% if apply_date_filter %}
WHERE event_date IN (SELECT DISTINCT event_date FROM active_day)
{% endif %}
GROUP BY user_pseudo_id_hashed, event_date, version

{%- else -%}
  {# NO PIVOT: Simple aggregation with WHERE conditions #}
  SELECT
    user_pseudo_id_hashed,
    event_date,
    version
    {%- for i in range(value_fields | length) -%}
      {%- set value_field = value_fields[i] -%}
      {%- set agg_func = agg_functions[i] -%}
      {%- set agg_func_lower = agg_func | lower | replace(' ', '_') -%}

      {%- if value_field == "event_timestamp" -%}
        {%- set column_name = event_name ~ '_' ~ agg_func_lower -%}
      {%- else -%}
        {%- set column_name = event_name ~ '_' ~ value_field ~ '_' ~ agg_func_lower -%}
      {%- endif -%}

      {# Build WHERE condition if exists #}
      {%- if where_conditions | length > 0 -%}
        {%- set conditions = [] -%}
        {%- for condition in where_conditions -%}
          {%- set _ = conditions.append(condition.field ~ " = '" ~ condition.value ~ "'") -%}
        {%- endfor -%}

        {%- if 'DISTINCT' in agg_func.upper() -%}
          {%- set clean_agg = agg_func.upper().replace('COUNT DISTINCT', 'COUNT').replace('DISTINCT', '').strip() -%}
    ,
    {{ clean_agg }}(DISTINCT CASE WHEN {{ conditions | join(' AND ') }} THEN {{ value_field }} END) AS {{ column_name }}
        {%- else -%}
    ,
    {{ agg_func }}(CASE WHEN {{ conditions | join(' AND ') }} THEN {{ value_field }} END) AS {{ column_name }}
        {%- endif -%}
      {%- else -%}
        {%- if 'DISTINCT' in agg_func.upper() -%}
          {%- set clean_agg = agg_func.upper().replace('COUNT DISTINCT', 'COUNT').replace('DISTINCT', '').strip() -%}
    ,
    {{ clean_agg }}(DISTINCT {{ value_field }}) AS {{ column_name }}
        {%- else -%}
    ,
    {{ agg_func }}({{ value_field }}) AS {{ column_name }}
        {%- endif -%}
      {%- endif -%}
    {%- endfor %}

  FROM {{ ref('stg_' ~ event_name) }}
  {% if apply_date_filter %}
  WHERE event_date IN (SELECT DISTINCT event_date FROM active_day)
  {% endif %}
  GROUP BY user_pseudo_id_hashed, event_date, version

{%- endif -%}
{%- endmacro -%}