{{ create_flatten_table(
    event_name='start_level',
    event_params=[
        {'name': 'model_type', 'type': 'string_value'},
        {'name': 'loop_by', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'lose_index', 'type': 'int_value'},
        {'name': 'play_type', 'type': 'string_value'},
        {'name': 'play_index', 'type': 'int_value'},
        {'name': 'level', 'type': 'string_value'},
        {'name': 'level_type', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'}
    ]
) }}
