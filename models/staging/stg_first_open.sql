{{ create_flatten_table(
    event_name='first_open',
    event_params=[
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'engagement_time_msec', 'type': 'int_value'},
        {'name': 'previous_first_open_count', 'type': 'int_value'}
    ]
) }}
