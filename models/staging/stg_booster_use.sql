{{ create_flatten_table(
    event_name='booster_use',
    event_params=[
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'booster_type', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'level', 'type': 'string_value'}
    ]
) }}
