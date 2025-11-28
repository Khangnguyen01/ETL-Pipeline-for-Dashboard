{{ create_flatten_table(
    event_name='kitty_race_lose',
    event_params=[
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'rank', 'type': 'string_value'},
        {'name': 'level_complete', 'type': 'string_value'}
    ]
) }}
