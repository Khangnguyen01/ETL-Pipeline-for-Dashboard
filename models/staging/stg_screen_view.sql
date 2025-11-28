{{ create_flatten_table(
    event_name='screen_view',
    event_params=[
        {'name': 'engagement_time_msec', 'type': 'int_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'}
    ]
) }}
