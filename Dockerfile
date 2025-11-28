FROM apache/airflow:3.1.2

# root để cài package hệ thống
USER root

# package hệ thống tối thiểu
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# binary uv trong PATH chung
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# requirements cho dbt/uv
COPY requirements.txt /tmp/requirements.txt

# dùng user airflow cho uv, dbt
USER airflow

# thêm local bin của airflow vào PATH
ENV PATH="/home/airflow/.local/bin:${PATH}"

# cài dbt-core, dbt-bigquery,... từ requirements.txt
RUN uv pip install --no-cache -r /tmp/requirements.txt

# vị trí profiles và project dbt
ENV DBT_PROFILES_DIR=/opt/airflow/dbt
ENV DBT_PROJECT_DIR=/opt/airflow/dbt

# backup dbt-core binary trước khi cài Fusion
RUN cp /home/airflow/.local/bin/dbt /home/airflow/.local/bin/dbt-core-wrapper

# cài Fusion CLI (ghi đè dbt hiện tại)
RUN SHELL=/bin/bash curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh \
    | SHELL=/bin/bash sh -s -- --update

# đổi tên Fusion CLI thành dbtf, phục hồi dbt-core wrapper
RUN mv /home/airflow/.local/bin/dbt /home/airflow/.local/bin/dbtf && \
    mv /home/airflow/.local/bin/dbt-core-wrapper /home/airflow/.local/bin/dbt

# gỡ alias dbtf khỏi .bashrc (tránh override dbtf binary)
RUN sed -i '/alias dbtf=/d' /home/airflow/.bashrc

WORKDIR /opt/airflow
