{{ create_flatten_table(
    event_name='loading_finish',
    event_params=[
        {'name': 'is_load', 'type': 'int_value'},
        {'name': 'placement', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'load_time', 'type': 'double_value'}
    ]
) }}
