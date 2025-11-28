{{ create_flatten_table(
    event_name='popup_show',
    event_params=[
        {'name': 'level', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'popup_name', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'popup_type', 'type': 'string_value'},
        {'name': 'level_type', 'type': 'string_value'},
        {'name': 'trigger_show_type', 'type': 'string_value'}
    ]
) }}
