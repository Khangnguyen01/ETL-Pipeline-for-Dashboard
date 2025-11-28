{{ create_flatten_table(
    event_name='resource_gain',
    event_params=[
        {'name': 'error_value', 'type': 'string_value'},
        {'name': 'firebase_error', 'type': 'int_value'},
        {'name': 'resource_gain_source', 'type': 'string_value'},
        {'name': 'resource_type', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'level', 'type': 'string_value'},
        {'name': 'resource_name', 'type': 'string_value'},
        {'name': 'resource_balance', 'type': 'string_value'},
        {'name': 'resource_amount', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'reason', 'type': 'string_value'},
        {'name': 'placement', 'type': 'string_value'}
    ]
) }}
