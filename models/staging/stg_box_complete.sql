{{ create_flatten_table(
    event_name='box_complete',
    event_params=[
        {'name': 'level', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'spawn_order', 'type': 'string_value'},
        {'name': 'user_order', 'type': 'string_value'}
    ]
) }}
