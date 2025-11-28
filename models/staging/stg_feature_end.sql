{{ create_flatten_table(
    event_name='feature_end',
    event_params=[
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'index', 'type': 'int_value'},
        {'name': 'level', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'playtime', 'type': 'double_value'},
        {'name': 'feature_name', 'type': 'string_value'},
        {'name': 'feature_result', 'type': 'string_value'},
        {'name': 'feature_mode', 'type': 'string_value'}
    ]
) }}
