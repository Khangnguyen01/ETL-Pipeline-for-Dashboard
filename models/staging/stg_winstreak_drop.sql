{{ create_flatten_table(
    event_name='winstreak_drop',
    event_params=[
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'checkpoint', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'}
    ]
) }}
