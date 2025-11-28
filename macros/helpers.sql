{% macro dbt_posthook_marker() %}
/* dbt_posthook */
{% endmacro %}

-- macros/query_comment.sql
{% macro query_comment(node) %}
  {%- set comment_dict = {} -%}
  {%- do comment_dict.update(
    app='dbt',
    dbt_version=(dbt_version | string),
    profile_name=(target.get('profile_name', '') | string),
    target_name=(target.get('target_name', '') | string),
  ) -%}
  {%- if node is not none -%}
    {%- do comment_dict.update(
      file=(node.original_file_path | string),
      node_id=(node.unique_id | string),
      node_name=(node.name | string),
      resource_type=(node.resource_type | string),
      package_name=(node.package_name | string),
      relation_database=(node.database | default('', true) | string),
      relation_schema=(node.schema | default('', true) | string),
      relation_identifier=(node.identifier | default('', true) | string)
    ) -%}
    {#- Merge labels from node config, ensuring all values are strings -#}
    {%- for key, value in node.config.get("labels", {}).items() -%}
      {%- do comment_dict.update({key: (value | string)}) -%}
    {%- endfor -%}
  {% else %}
    {%- do comment_dict.update(node_id='internal') -%}
  {%- endif -%}
  {% do return(tojson(comment_dict)) %}
{% endmacro %}