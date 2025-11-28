{{ create_flatten_table(
    event_name='lava_step',
    event_params=[
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'step', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'}
    ]
) }}
