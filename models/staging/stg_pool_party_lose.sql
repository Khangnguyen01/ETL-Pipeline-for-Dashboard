{{ create_flatten_table(
    event_name='pool_party_lose',
    event_params=[
        {'name': 'step', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'}
    ]
) }}
