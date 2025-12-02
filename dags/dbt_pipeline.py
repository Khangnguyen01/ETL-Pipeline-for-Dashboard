"""
DBT Pipeline DAG
Runs dbt models with dynamic variables for date ranges
"""

import json
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.utils import timezone

DEFAULT_ARGS = {
    "owner": "data_team",
    "depends_on_past": False,
    "email": ["admin@example.com"],
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "execution_timeout": timedelta(hours=1),
}


def get_dbt_vars(**context):
    """
    Generate dbt vars from dag_run.conf or use logical date as default.
    Returns JSON string for dbt --vars.
    """
    dag_run = context.get("dag_run")

    # dag_run.conf có thể là None
    if dag_run and dag_run.conf:
        conf = dag_run.conf
    else:
        conf = {}

    # Lấy logical date của run (ổn định hơn datetime.now())
    logical_dt = (
        context.get("data_interval_start")
        or context.get("execution_date")
        or timezone.utcnow()
    )
    default_date = logical_dt.date().strftime("%Y-%m-%d")

    # Nếu không truyền thì default = logical date
    start_date = conf.get("start_date", default_date)
    end_date = conf.get("end_date", default_date)

    # Hỗ trợ cả is_backfill và backfill cho linh hoạt
    raw_is_backfill = conf.get("is_backfill", conf.get("backfill", False))

    # Chuẩn hóa về bool
    if isinstance(raw_is_backfill, str):
        is_backfill_bool = raw_is_backfill.lower() in ("true", "1", "yes", "y")
    else:
        is_backfill_bool = bool(raw_is_backfill)

    # Model đang expect string 'true' / 'false'
    vars_payload = {
        "start_date": start_date,
        "end_date": end_date,
        "is_backfill": "true" if is_backfill_bool else "false",
    }

    # dbt chấp nhận JSON (subset của YAML)
    return json.dumps(vars_payload)


with DAG(
    dag_id="dbt_pipeline",
    default_args=DEFAULT_ARGS,
    description="Run dbt pipeline with staging, silver, and mart models",
    schedule= '0 0 * * *',
    start_date=datetime(2025, 11, 1),
    catchup=False,
    max_active_runs=1,
    dagrun_timeout=timedelta(minutes=60),
    tags=["dbt", "pipeline"],
) as dag:

    # Task 0: Check source data freshness
    dbt_source_freshness = BashOperator(
        task_id="dbt_source_freshness",
        bash_command="""
            cd /opt/airflow/dbt
            dbt source freshness --no-partial-parse
        """,
        retries=1,
    )

    # Task 1: Debug/Parse - Verify dbt setup
    dbt_parse = BashOperator(
        task_id="dbt_parse",
        bash_command="cd /opt/airflow/dbt && dbt parse",
        retries=1,
    )

    # Task 2: Get dbt vars (XCom sẽ trả JSON string)
    get_vars = PythonOperator(
        task_id="get_dbt_vars",
        python_callable=get_dbt_vars,
    )

    # Task 3: Run staging models
    dbt_run_staging = BashOperator(
        task_id="dbt_run_staging",
        bash_command="""
            cd /opt/airflow/dbt
            dbt run --select staging.* --vars '{{ ti.xcom_pull(task_ids="get_dbt_vars") }}'
        """,
    )

    # Task 4: Run mart models
    dbt_run_mart = BashOperator(
        task_id="dbt_run_mart",
        bash_command="""
            cd /opt/airflow/dbt
            dbt run --select mart.* --vars '{{ ti.xcom_pull(task_ids="get_dbt_vars") }}'
        """,
    )

    # Task 5: Run monitoring models
    dbt_run_monitoring = BashOperator(
        task_id="dbt_run_monitoring",
        bash_command="""
            cd /opt/airflow/dbt
            dbt run --select monitoring.* --vars '{{ ti.xcom_pull(task_ids="get_dbt_vars") }}'
        """,
    )
    # Task 6: Run dbt tests
    dbt_run_tests = BashOperator(
        task_id="dbt_run_tests",
        bash_command="cd /opt/airflow/dbt && dbt test -s tag:elementary --no-partial-parse",
    )

    # Define task dependencies (giữ nguyên flow của bạn)
    dbt_source_freshness >> dbt_parse >> get_vars >> dbt_run_staging >> dbt_run_mart >> dbt_run_monitoring >> dbt_run_tests
