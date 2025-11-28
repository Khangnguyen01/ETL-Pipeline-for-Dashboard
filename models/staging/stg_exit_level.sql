{{ create_flatten_table(
    event_name='exit_level',
    event_params=[
        {'name': 'action_seq', 'type': 'string_value'},
        {'name': 'loop_by', 'type': 'int_value'},
        {'name': 'play_duration', 'type': 'double_value'},
        {'name': 'cleared_items', 'type': 'int_value'},
        {'name': 'model_type', 'type': 'string_value'},
        {'name': 'percentage', 'type': 'int_value'},
        {'name': 'exit_index', 'type': 'int_value'},
        {'name': 'level', 'type': 'string_value'},
        {'name': 'play_type', 'type': 'string_value'},
        {'name': 'level_type', 'type': 'string_value'},
        {'name': 'play_index', 'type': 'int_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'firebase_error', 'type': 'int_value'},
        {'name': 'revive_count', 'type': 'int_value'},
        {'name': 'error_value', 'type': 'string_value'},
        {'name': 'lose_index', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'total_items', 'type': 'int_value'}
    ]
) }}
