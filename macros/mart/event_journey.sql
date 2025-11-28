{% macro format_event_with_filter() %}
  CASE
    {% for event in var('mart_config')['mart_seq_drop'] %}
    WHEN b.event_name = '{{ event.name }}' THEN
      {% if event.event_params | length > 0 %}
        CONCAT(
          b.event_name,
          '/',
          {% set param_values = [] %}
          {% for param in event.event_params %}
            {% set param_value -%}
              COALESCE(
                {% if param in ['level', 'is_load', 'is_show'] %}
                  CAST(
                    (SELECT value.int_value
                     FROM UNNEST(b.event_params)
                     WHERE key = '{{ param }}'
                    ) AS STRING
                  )
                {% else %}
                  (SELECT value.string_value
                   FROM UNNEST(b.event_params)
                   WHERE key = '{{ param }}'
                  )
                {% endif %},
                ''
              )
            {%- endset %}
            {% do param_values.append(param_value) %}
          {% endfor %}
          {{ param_values | join(", '/', ") }}
        )
      {% else %}
        b.event_name
      {% endif %}
    {% endfor %}
    ELSE b.event_name
  END
{% endmacro %}

{% macro event_filter_conditions() %}
  AND (
    -- ad_show chỉ giữ INTER hoặc REWARDED
    (b.event_name = 'ad_show' AND
     (SELECT value.string_value FROM UNNEST(b.event_params) WHERE key = 'ad_format') IN ('INTER', 'REWARDED'))
    OR b.event_name != 'ad_show'
  )
{% endmacro %}