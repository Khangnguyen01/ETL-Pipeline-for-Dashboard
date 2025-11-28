{{ create_flatten_table(
    event_name='heart_refill',
    event_params=[
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'refill_method', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'}
    ]
) }}
