{{ create_flatten_table(
    event_name='ad_reward',
    event_params=[
        {'name': 'reward_type', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'reward_value', 'type': 'int_value'}
    ]
) }}
