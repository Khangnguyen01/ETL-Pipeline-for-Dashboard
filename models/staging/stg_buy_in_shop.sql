{{ create_flatten_table(
    event_name='buy_in_shop',
    event_params=[
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'package_id', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'buy_type', 'type': 'string_value'}
    ]
) }}
