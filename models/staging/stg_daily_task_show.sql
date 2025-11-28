{{ create_flatten_table(
    event_name='daily_task_show',
    event_params=[
        {'name': 'task_number', 'type': 'int_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'}
    ]
) }}
