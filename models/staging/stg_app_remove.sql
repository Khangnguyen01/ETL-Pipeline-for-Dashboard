{{ create_flatten_table(
    event_name='app_remove',
    event_params=[
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'ga_session_id', 'type': 'int_value'}
    ]
) }}
