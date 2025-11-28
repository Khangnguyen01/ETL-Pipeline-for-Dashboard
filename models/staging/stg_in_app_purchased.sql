{{ create_flatten_table(
    event_name='in_app_purchased',
    event_params=[
        {'name': 'product_name', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'package_id', 'type': 'string_value'},
        {'name': 'revenue', 'type': 'double_value'},
        {'name': 'trigger_show_type', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'show_type', 'type': 'string_value'},
        {'name': 'level', 'type': 'string_value'},
        {'name': 'value', 'type': 'double_value'},
        {'name': 'placement', 'type': 'string_value'}
    ]
) }}
