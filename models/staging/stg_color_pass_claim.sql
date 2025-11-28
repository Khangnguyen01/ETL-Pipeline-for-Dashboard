{{ create_flatten_table(
    event_name='color_pass_claim',
    event_params=[
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'pass_checkpoint', 'type': 'string_value'}
    ]
) }}
