{{ create_flatten_table(
    event_name='in_app_rating',
    event_params=[
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'star', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'}
    ]
) }}
