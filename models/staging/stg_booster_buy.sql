{{ create_flatten_table(
    event_name='booster_buy',
    event_params=[
        {'name': 'booster_type', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'buy_type', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'}
    ]
) }}
