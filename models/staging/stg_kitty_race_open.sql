{{ create_flatten_table(
    event_name='kitty_race_open',
    event_params=[
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'level', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'}
    ]
) }}
