import os
from google.cloud import bigquery
import pandas as pd
from datetime import datetime

# Configuration
INTRADAY = input('Enter your intraday date (e.g: 20250805): ')
SOURCE_TABLE = input('Enter your full source table: ')
OUTPUT_DIR = input('Enter your destination output folder: ')

# Default Firebase params to exclude
DEFAULT_PARAMS_FIREBASE = ['ad_unit_code', 'ad_unit_name', 'campaign_info_source',
                           'click_timestamp', 'engaged_session_event', 'entrances',
                           'error_message', 'firebase_conversion', 'firebase_event_origin',
                           'firebase_previous_class', 'firebase_previous_id',
                           'firebase_previous_screen', 'firebase_screen',
                           'firebase_screen_class', 'firebase_screen_id', 'gclid',
                           'gad_source', 'ga_dedupe_id', 'load_config_failed_message',
                           'medium', 'message_device_time', 'message_time',
                           'session_engaged', 'source', 'system_app',
                           'system_app_update', 'timestamp', 'update_with_analytics',
                           'validated']

DEFAULT_EVENTS_FIREBASE = ['app_clear_data', 'app_update', 'firebase_campaign',
                           'inter_attempt', 'os_update',
                           'reward_attempt']

client = bigquery.Client()

# Get all events
events_query = f"""
SELECT DISTINCT event_name
FROM `{SOURCE_TABLE}`
ORDER BY event_name
"""
events = client.query(events_query).to_dataframe()
events_list = events['event_name'].tolist()

# Filter out invalid events
invalid_events = [event for event in events_list if event.split('_')[-1].isdigit()]
events_list = [event for event in events_list
               if event not in invalid_events
               and event not in DEFAULT_EVENTS_FIREBASE]

# Get event parameters for each event
DATE = pd.to_datetime(INTRADAY, format='%Y%m%d').strftime('%Y-%m-%d')
events_params_dict = {}

for event in events_list:
    query = f"""
    SELECT
        ep.key AS key,
        ep.value.int_value AS int_value,
        ep.value.string_value AS string_value,
        ep.value.double_value AS double_value
    FROM `{SOURCE_TABLE}`,
        UNNEST(event_params) ep
    WHERE event_date = '{DATE}'
        AND event_name = '{event}'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ep.key ORDER BY event_timestamp) = 1
    """

    event_df = client.query(query).to_dataframe()
    events_params_dict[event] = {}

    for index, row in event_df.iterrows():
        if row['key'] not in DEFAULT_PARAMS_FIREBASE:
            if not pd.isna(row['string_value']):
                try:
                    int(row['string_value'])
                    events_params_dict[event][row['key']] = 'string_value'
                except:
                    events_params_dict[event][row['key']] = 'string_value'
            elif not pd.isna(row['int_value']):
                events_params_dict[event][row['key']] = 'int_value'
            elif not pd.isna(row['double_value']):
                events_params_dict[event][row['key']] = 'double_value'

# Remove events with no parameters
events_params_dict = {k: v for k, v in events_params_dict.items() if v}

# Generate SQL files
os.makedirs(OUTPUT_DIR, exist_ok=True)

for event_name, params in events_params_dict.items():
    # Format event_name for filename
    file_name = event_name.replace('.', '_').lower()

    # Build event_params array
    params_list = []
    for key, value_type in params.items():
        params_list.append(f"        {{'name': '{key}', 'type': '{value_type}'}}")

    params_string = ',\n'.join(params_list)

    # Generate SQL content
    sql_content = f"""{{{{ create_flatten_table(
    event_name='{event_name}',
    event_params=[
{params_string}
    ]
) }}}}
"""

    # Write to file
    file_path = os.path.join(OUTPUT_DIR, f'stg_{file_name}.sql')
    with open(file_path, 'w') as f:
        f.write(sql_content)

    print(f'Created: {file_path}')

print(f'\nTotal events generated: {len(events_params_dict)}')