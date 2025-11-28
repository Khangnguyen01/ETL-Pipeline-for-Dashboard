{% macro delete_staging_dates_all(dates_to_delete) %}
{#dbt run-operation delete_staging_dates_all --args '{"dates_to_delete": ["2025-11-14", "2025-11-15", "2025-11-16", "2025-11-17]}'#}

{# Get all models in the staging directory #}
{% set staging_models = [] %}
{% for node in graph.nodes.values() %}
    {% if node.resource_type == 'model'
       and 'staging' in node.fqn
       and 'silver' not in node.path
       and node.name not in ['stg_user_campaign', 'stg_user_demographic'] %}
        {% do staging_models.append(node.name) %}
        {{ log("Found model: " ~ node.name, info=True) }}
    {% endif %}
{% endfor %}

{# Convert dates to list if needed #}
{% set dates_list = [dates_to_delete] if dates_to_delete is string else dates_to_delete %}

{# Loop through each staging model and delete #}
{% for model_name in staging_models %}
    {% set delete_query %}
    DELETE FROM `dev_staging.{{ model_name }}`
    WHERE event_date IN (
        {% for date in dates_list %}
        '{{ date }}'{% if not loop.last %},{% endif %}
        {% endfor %}
    )
    {% endset %}

    {{ log("Deleting dates from dev_staging." ~ model_name, info=True) }}
    {% do run_query(delete_query) %}
{% endfor %}

{{ log("Deleted dates from " ~ staging_models|length ~ " staging models", info=True) }}

{% endmacro %}