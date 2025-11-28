{{ create_flatten_table(
    event_name='in_app_purchase',
    event_params=[
        {'name': 'quantity', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'product_name', 'type': 'string_value'},
        {'name': 'price', 'type': 'int_value'},
        {'name': 'value', 'type': 'int_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'product_id', 'type': 'string_value'},
        {'name': 'currency', 'type': 'string_value'}
    ]
) }}
