{{ create_flatten_table(
    event_name='ad_request',
    event_params=[
        {'name': 'placement', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'ad_network', 'type': 'string_value'},
        {'name': 'ad_format', 'type': 'string_value'},
        {'name': 'is_load', 'type': 'int_value'},
        {'name': 'ad_platform', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'load_time', 'type': 'double_value'}
    ]
) }}
