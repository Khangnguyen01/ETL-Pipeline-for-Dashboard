{{ create_flatten_table(
    event_name='session_start_custom',
    event_params=[
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'level', 'type': 'string_value'},
        {'name': 'day_from_install_date', 'type': 'int_value'},
        {'name': 'level_type', 'type': 'string_value'},
        {'name': 'ingame_login_day', 'type': 'int_value'}
    ]
) }}
