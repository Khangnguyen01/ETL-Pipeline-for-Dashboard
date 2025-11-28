{{ create_flatten_table(
    event_name='win_level',
    event_params=[
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'level', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'}
    ]
) }}
