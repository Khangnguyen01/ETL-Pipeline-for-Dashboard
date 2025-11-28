{%- macro generate_wide_table_for_event(event_config, source_schema='dev_staging', apply_date_filter=false) -%}
{%- set event_name = event_config.name -%}
{%- set has_pivot = event_config.has_pivot -%}
{%- set pivot_fields = event_config.pivot_fields | default([]) -%}
{%- set pivot_field_types = event_config.pivot_field_types | default([]) -%}
{%- set value_fields = event_config.value_fields | default(['event_timestamp']) -%}
{%- set agg_functions = event_config.agg_functions | default(['COUNT']) -%}

{%- if has_pivot and pivot_fields | length > 0 -%}
  {%- set pivot_query -%}
    SELECT DISTINCT
      {{ pivot_fields | join(', ') }}
    FROM {{ ref('stg_' ~ event_name) }}
  {%- endset -%}

  {%- set pivot_combinations = [] -%}
  {%- if execute -%}
    {%- set pivot_combinations = run_query(pivot_query).rows -%}
  {%- endif -%}

{# Generate SELECT with pivots #}
SELECT
  user_pseudo_id_hashed,
  event_date,
  version
  {%- for i in range(value_fields | length) -%}
    {%- set value_field = value_fields[i] -%}
    {%- set agg_func = agg_functions[i] -%}
    {%- set agg_func_lower = agg_func | lower | replace(' ', '_') -%}

    {%- if value_field == "event_timestamp" -%}
      {%- set total_column_name = event_name ~ '_total_event' -%}
    {%- else -%}
      {%- set total_column_name = event_name ~ '_' ~ value_field ~ '_' ~ agg_func_lower -%}
    {%- endif -%}

    {%- if 'DISTINCT' in agg_func.upper() -%}
      {%- set clean_agg = agg_func.upper().replace('COUNT DISTINCT', 'COUNT').replace('DISTINCT', '').strip() -%}
  ,
  {{ clean_agg }}(DISTINCT {{ value_field }}) AS {{ total_column_name }}
    {%- else -%}
  ,
  {{ agg_func }}({{ value_field }}) AS {{ total_column_name }}
    {%- endif -%}
  {%- endfor -%}

  {%- for row in pivot_combinations -%}
    {%- set pivot_values = [] -%}
    {%- for field in pivot_fields -%}
      {%- set clean_value = row[field] | string | lower | replace(' ', '_') | replace('-', '_') | replace(',', '') | replace('.', '_') -%}
      {%- set _ = pivot_values.append(clean_value) -%}
    {%- endfor -%}
    {%- set pivot_suffix = pivot_values | join('_') -%}

    {%- for i in range(value_fields | length) -%}
      {%- set value_field = value_fields[i] -%}
      {%- set agg_func = agg_functions[i] -%}
      {%- set agg_func_lower = agg_func | lower | replace(' ', '_') -%}

      {%- set conditions = [] -%}
      {%- for j in range(pivot_fields | length) -%}
        {%- set field = pivot_fields[j] -%}
        {%- set field_type = pivot_field_types[j] | default('string') -%}
        {%- if field_type in ['int', 'integer', 'number', 'numeric', 'float'] -%}
          {%- set _ = conditions.append(field ~ " = " ~ row[field]) -%}
        {%- else -%}
          {%- set _ = conditions.append(field ~ " = '" ~ row[field] ~ "'") -%}
        {%- endif -%}
      {%- endfor -%}

      {%- if value_field == "event_timestamp" -%}
        {%- set column_name = event_name ~ '_' ~ pivot_suffix ~ '_' ~ agg_func_lower -%}
      {%- else -%}
        {%- set column_name = event_name ~ '_' ~ pivot_suffix ~ '_' ~ value_field ~ '_' ~ agg_func_lower -%}
      {%- endif -%}

      {%- if 'DISTINCT' in agg_func.upper() -%}
        {%- set clean_agg = agg_func.upper().replace('COUNT DISTINCT', 'COUNT').replace('DISTINCT', '').strip() -%}
  ,
  {{ clean_agg }}(DISTINCT CASE WHEN {{ conditions | join(' AND ') }} THEN {{ value_field }} END)
    AS {{ column_name }}
      {%- else -%}
  ,
  {{ agg_func }}(CASE WHEN {{ conditions | join(' AND ') }} THEN {{ value_field }} END)
    AS {{ column_name }}
      {%- endif -%}
    {%- endfor -%}
  {%- endfor %}

FROM {{ ref('stg_' ~ event_name) }}
{% if apply_date_filter %}
WHERE event_date IN (SELECT DISTINCT event_date FROM base)
{% endif %}
GROUP BY user_pseudo_id_hashed, event_date, version


{%- else -%}
  {# PIVOT = FALSE: Simple aggregation #}
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

      {%- if 'DISTINCT' in agg_func.upper() -%}
        {%- set clean_agg = agg_func.upper().replace('COUNT DISTINCT', 'COUNT').replace('DISTINCT', '').strip() -%}
    ,
    {{ clean_agg }}(DISTINCT {{ value_field }}) AS {{ column_name }}
      {%- else -%}
    ,
    {{ agg_func }}({{ value_field }}) AS {{ column_name }}
      {%- endif -%}
    {%- endfor %}

  FROM {{ ref('stg_' ~ event_name) }}
  {% if apply_date_filter %}
  WHERE event_date IN (SELECT DISTINCT event_date FROM base)
  {% endif %}
  GROUP BY user_pseudo_id_hashed, event_date, version

{%- endif -%}
{%- endmacro -%}