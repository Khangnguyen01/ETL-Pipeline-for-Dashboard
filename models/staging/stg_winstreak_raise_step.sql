{{ create_flatten_table(
    event_name='winstreak_raise_step',
    event_params=[
        {'name': 'checkpoint', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'}
    ]
) }}
