{% macro generate_mart_level_analyst(base_cte='base2', start_ts_column='start_attempt_ts', end_ts_column='end_attempt_ts') %}

{%- set config = var('mart_config')['mart_level_analyst'] -%}
{%- set ns = namespace(prev_cte=base_cte) -%}

{%- for event in config %}
  {%- set event_name = event['name'] %}
  {%- set source_layer = event['source_layer'] %}
  {%- set source_table = ref('stg_' ~ event_name) if source_layer == 'staging' else event_name %}
  {%- set current_cte = event_name ~ '_ts' %}

, {{ current_cte }} AS (
  SELECT
    s1.*,
    {%- if event.get('conditions') %}
      {%- for condition in event['conditions'] %}
        {%- if condition.get('field') %}
        {{ condition['agg_function'] }}(CASE WHEN s2.{{ condition['field'] }} = '{{ condition['value'] }}' THEN s2.{{ condition['agg_field'] }} END) AS {{ condition['alias'] }}
        {%- else %}
        {{ condition['agg_function'] }}(s2.{{ condition['agg_field'] }}) AS {{ condition['alias'] }}
        {%- endif %}
        {%- if not loop.last %},{% endif %}
      {%- endfor %}
    {%- elif event.get('agg_functions') %}
      {%- for agg_func, value_field, alias in zip(event['agg_functions'], event['value_fields'], event.get('aliases', event['value_fields'])) %}
        {{ agg_func }}(s2.{{ value_field }}) AS {{ alias }}
        {%- if not loop.last %},{% endif %}
      {%- endfor %}
    {%- endif %}
  FROM {{ ns.prev_cte }} s1
  LEFT JOIN {{ source_table }} s2
    ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
    AND s2.event_timestamp >= s1.{{ start_ts_column }}
    AND ((s2.event_timestamp < s1.{{ end_ts_column }}) OR (s1.{{ end_ts_column }} IS NULL))
  GROUP BY ALL
)
  {%- set ns.prev_cte = current_cte %}
{%- endfor %}

SELECT * FROM {{ ns.prev_cte }}

{% endmacro %}