{{ create_flatten_table(
    event_name='IAP_home_click',
    event_params=[
        {'name': 'popup_type', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'}
    ]
) }}
