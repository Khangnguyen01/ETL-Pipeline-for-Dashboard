{{ create_flatten_table(
    event_name='tutorial_show',
    event_params=[
        {'name': 'level', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'tutorial_index', 'type': 'int_value'},
        {'name': 'tutorial_name', 'type': 'string_value'},
        {'name': 'tutorial_type', 'type': 'string_value'}
    ]
) }}
