{{ create_flatten_table(
    event_name='tutorial_complete',
    event_params=[
        {'name': 'tutorial_name', 'type': 'string_value'},
        {'name': 'tutorial_index', 'type': 'int_value'},
        {'name': 'tutorial_type', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'level', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'}
    ]
) }}
