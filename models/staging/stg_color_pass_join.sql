{{ create_flatten_table(
    event_name='color_pass_join',
    event_params=[
        {'name': 'free_checkpoint_', 'type': 'string_value'},
        {'name': 'gold_checkpoint_', 'type': 'string_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'ga_session_id', 'type': 'int_value'}
    ]
) }}
