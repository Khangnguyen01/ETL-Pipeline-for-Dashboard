{{ create_flatten_table(
    event_name='weekly_mission_chest_claim',
    event_params=[
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'task_number', 'type': 'string_value'}
    ]
) }}
