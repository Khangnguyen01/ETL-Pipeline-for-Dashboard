{{ create_flatten_table(
    event_name='ad_impression',
    event_params=[
        {'name': 'currency', 'type': 'string_value'},
        {'name': 'value', 'type': 'double_value'},
        {'name': 'ad_format', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'ad_source', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ad_platform', 'type': 'string_value'}
    ]
) }}
