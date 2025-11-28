{{ create_flatten_table(
    event_name='winstreak_chest_claim',
    event_params=[
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'chest', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'}
    ]
) }}
