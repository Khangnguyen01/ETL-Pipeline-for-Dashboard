{{ create_flatten_table(
    event_name='loading_start',
    event_params=[
        {'name': 'placement', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'ga_session_id', 'type': 'int_value'}
    ]
) }}
