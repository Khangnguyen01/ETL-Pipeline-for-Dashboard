{{ create_flatten_table(
    event_name='session_start',
    event_params=[
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'}
    ]
) }}
