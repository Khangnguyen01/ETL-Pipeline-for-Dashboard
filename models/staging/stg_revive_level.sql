{{ create_flatten_table(
    event_name='revive_level',
    event_params=[
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'level_type', 'type': 'string_value'},
        {'name': 'play_type', 'type': 'string_value'},
        {'name': 'percentage', 'type': 'int_value'},
        {'name': 'level', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'revive_method', 'type': 'string_value'},
        {'name': 'model_type', 'type': 'string_value'}
    ]
) }}
