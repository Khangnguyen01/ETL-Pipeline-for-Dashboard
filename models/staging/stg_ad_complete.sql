{{ create_flatten_table(
    event_name='ad_complete',
    event_params=[
        {'name': 'ad_format', 'type': 'string_value'},
        {'name': 'end_type', 'type': 'string_value'},
        {'name': 'ad_duration', 'type': 'double_value'},
        {'name': 'ad_network', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'ad_platform', 'type': 'string_value'},
        {'name': 'placement', 'type': 'string_value'}
    ]
) }}
