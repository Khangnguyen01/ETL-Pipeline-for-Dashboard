{{ create_flatten_table(
    event_name='unlimited_heart',
    event_params=[
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'time_unlimited_heart', 'type': 'string_value'}
    ]
) }}
