{{ create_flatten_table(
    event_name='kitty_race_lose_time',
    event_params=[
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'level_complete', 'type': 'string_value'},
        {'name': 'rank', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'}
    ]
) }}
