{{ create_flatten_table(
    event_name='queue_danger',
    event_params=[
        {'name': 'model_type', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'level', 'type': 'string_value'},
        {'name': 'level_type', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'}
    ]
) }}
