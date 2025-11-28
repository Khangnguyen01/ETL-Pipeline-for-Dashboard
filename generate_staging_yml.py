from pathlib import Path
import re
from typing import List, Dict, Optional, Union

# Thư mục chứa các model flatten
STAGING_DIR = Path("models/staging")
# File YAML auto-gen
OUTPUT_PATH = STAGING_DIR / "_staging.generated.yml"

# Các model KHÔNG muốn generate Elementary config/tests
EXCLUDED_MODELS = {
    "stg_user_engagement_agg",
    "stg_firebase_exp",
    "silver"
}

# Regex bắt event_name='something' trong macro create_flatten_table
EVENT_NAME_PATTERN = re.compile(r"event_name\s*=\s*['\"]([^'\"]+)['\"]")


def find_models_and_events() -> List[Dict[str, Optional[str]]]:
    """
    Quét models/staging, lấy tên model + event_name (nếu có).
    """
    if not STAGING_DIR.exists():
        raise SystemExit(f"Không tìm thấy thư mục {STAGING_DIR}")

    models: List[Dict[str, Optional[str]]] = []
    for sql_path in sorted(STAGING_DIR.glob("*.sql")):
        model_name = sql_path.stem  # stg_ad_clicked.sql -> stg_ad_clicked
        sql_text = sql_path.read_text(encoding="utf-8")

        m = EVENT_NAME_PATTERN.search(sql_text)
        event_name = m.group(1) if m else None

        models.append(
            {
                "model_name": model_name,
                "event_name": event_name,
            }
        )
    return models


def get_columns_for_event(event_name: Optional[str]) -> List[str]:
    """
    Theo macro flatten:
    Luôn có:
      user_pseudo_id_hashed, event_date, event_timestamp,
      version, country, platform

    Nếu event_name == 'in_app_purchase' -> thêm event_value_in_usd
    Nếu event_name == 'first_open'       -> thêm bộ cột device_*
    """
    columns = [
        "user_pseudo_id_hashed",
        "event_date",
        "event_timestamp",
        "version",
        "country",
        "platform",
    ]

    if event_name == "in_app_purchase":
        columns.append("event_value_in_usd")

    if event_name == "first_open":
        columns.extend(
            [
                "mobile_brand_name",
                "mobile_model_name",
                "device_ram_user",
                "device_chip_user",
                "is_developer",
            ]
        )

    return columns


def build_yaml(models: List[Dict[str, Optional[str]]]) -> str:
    """
    Sinh nội dung YAML cho _staging.generated.yml:

    - Mỗi model:
        + config.elementary.timestamp_column = "event_date"
        + columns: auto từ macro + schema tests + column_anomalies (full metric)
        + tests model-level: volume_anomalies
    """
    lines: List[str] = []
    lines.append("version: 2")
    lines.append("")
    lines.append("models:")

    for m in models:
        model_name = m["model_name"]

        # skip các model trong blacklist
        if model_name in EXCLUDED_MODELS:
            continue

        event_name = m["event_name"]
        cols = get_columns_for_event(event_name)

        # ----- MODEL HEADER -----
        lines.append(f"  - name: {model_name}")
        desc = f"Auto generated config for {model_name}"
        if event_name:
            desc += f" (event_name = {event_name})"
        lines.append(f"    description: \"{desc}\"")

        # ----- CONFIG -----
        lines.append("    config:")
        lines.append("      elementary:")
        lines.append("        timestamp_column: \"event_date\"")
        lines.append("")

        # ----- COLUMNS -----
        if cols:
            lines.append("    columns:")
            for col in cols:
                lines.append(f"      - name: {col}")
                lines.append("        description: \"Auto generated from flatten macro\"")

                column_tests: List[Union[str, Dict]] = []

                # Schema tests cơ bản
                if col in ("user_pseudo_id_hashed", "event_date", "event_timestamp"):
                    column_tests.append("not_null")
                if col in ("country", "platform"):
                    column_tests.append("not_null")

                # Column anomalies full metric
                if col == "event_value_in_usd":
                    # Rule business: không được âm
                    column_tests.append(
                        {
                            "type": "expression_is_true",
                            "expression": "event_value_in_usd >= 0",
                        }
                    )
                    # Numeric metrics + 'any' metrics
                    column_tests.append(
                        {
                            "type": "column_anomalies",
                            "metrics": [
                                # any
                                "null_count",
                                "null_percent",
                                # numeric
                                "min",
                                "max",
                                "average",
                                "zero_count",
                                "zero_percent",
                                "standard_deviation",
                                "variance",
                            ],
                        }
                    )

                elif col in ("country", "platform"):
                    # String metrics + 'any' metrics
                    column_tests.append(
                        {
                            "type": "column_anomalies",
                            "metrics": [
                                # any
                                "null_count",
                                "null_percent",
                                # string
                                "min_length",
                                "max_length",
                                "average_length",
                                "missing_count",
                                "missing_percent",
                            ],
                        }
                    )

                if column_tests:
                    lines.append("        tests:")
                    for t in column_tests:
                        if isinstance(t, str):
                            lines.append(f"          - {t}")
                        else:
                            if t["type"] == "expression_is_true":
                                lines.append("          - dbt_utils.expression_is_true:")
                                lines.append("              arguments:")
                                lines.append(f"                expression: \"{t['expression']}\"")
                            elif t["type"] == "column_anomalies":
                                lines.append("          - elementary.column_anomalies:")
                                lines.append("              arguments:")
                                lines.append("                column_anomalies:")
                                for metric in t["metrics"]:
                                    lines.append(f"                  - {metric}")
                                lines.append("                time_bucket:")
                                lines.append("                  period: day")
                                lines.append("                  count: 1")
                                lines.append("                training_period:")
                                lines.append("                  period: day")
                                lines.append("                  count: 10")
                                lines.append("                detection_period:")
                                lines.append("                  period: day")
                                lines.append("                  count: 1")

            lines.append("")

        # ----- MODEL-LEVEL TESTS: chỉ volume_anomalies -----
        lines.append("    tests:")

        lines.append("      - elementary.volume_anomalies:")
        lines.append("          arguments:")
        lines.append("            time_bucket:")
        lines.append("              period: day")
        lines.append("              count: 1")
        lines.append("            training_period:")
        lines.append("              period: day")
        lines.append("              count: 10")
        lines.append("            detection_period:")
        lines.append("              period: day")
        lines.append("              count: 1")
        lines.append("            anomaly_direction: both")
        lines.append("            ignore_small_changes:")
        lines.append("              drop_failure_percent_threshold: 30")
        lines.append("              spike_failure_percent_threshold: 30")
        lines.append("          tags: [\"elementary\", \"auto\", \"volume\"]")

        lines.append("")  # dòng trống giữa các model

    return "\n".join(lines)


def main() -> None:
    models = find_models_and_events()
    if not models:
        raise SystemExit(f"Không tìm thấy file .sql nào trong {STAGING_DIR}")

    yaml_text = build_yaml(models)
    OUTPUT_PATH.write_text(yaml_text, encoding="utf-8")
    print(f"Đã generate xong: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
