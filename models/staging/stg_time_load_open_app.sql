{{ create_flatten_table(
    event_name='time_load_open_app',
    event_params=[
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'load_time', 'type': 'double_value'}
    ]
) }}
