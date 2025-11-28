{{ create_flatten_table(
    event_name='all_play_level_time',
    event_params=[
        {'name': 'level', 'type': 'string_value'},
        {'name': 'ga_session_id', 'type': 'int_value'},
        {'name': 'ga_session_number', 'type': 'int_value'},
        {'name': 'game_time', 'type': 'double_value'}
    ]
) }}
