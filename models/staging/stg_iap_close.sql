{{ create_flatten_table(
    event_name='iap_close',
    event_params=[
        {'name': 'iap_duration', 'type': 'string_value'},
        {'name': 'pack_name', 'type': 'string_value'},
        {'name': 'show_type', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'placement', 'type': 'string_value'},
        {'name': 'trigger_show_type', 'type': 'string_value'}
    ]
) }}
