{{ create_flatten_table(
    event_name='reward_completed',
    event_params=[
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'level', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'ad_position', 'type': 'string_value'}
    ]
) }}
