#!/usr/bin/env bash
set -e

pwgen -s 16 1 | tr -d '\n' | podman secret create EXPORTER_PWD -

podman volume create grafana_vol

exporter_pwd_secret_info=$(podman secret inspect EXPORTER_PWD)
exporter_pwd_secret_id=$(echo "$exporter_pwd_secret_info" | jq -r '.[0].ID')
exporter_pwd_secret_file_path=$(echo "$exporter_pwd_secret_info" | jq -r '.[0].Spec.Driver.Options.path')/secretsdata.json
exporter_pwd_secret_decoded=$(jq -r ".[\"$exporter_pwd_secret_id\"] | @base64d" < "$exporter_pwd_secret_file_path")

podman exec -it db bash<<EOF
  sqlplus sys/\$ORACLE_PWD@localhost:1521/freepdb1 as sysdba<<EOF2
  create user exporter identified by $exporter_pwd_secret_decoded;
  grant select_catalog_role to exporter;
  grant apex_administrator_read_role to exporter;
  grant create session to exporter;
EOF2
exit
EOF

podman create \
  --name exporter \
  --pod dbfree-pod \
  -e DB_USERNAME=exporter \
  --secret EXPORTER_PWD,type=env,target=DB_PASSWORD \
  -e DB_CONNECT_STRING=db:1521/freepdb1 \
  -e CUSTOM_METRICS=/apex_metrics.toml \
  -v "$(pwd)"/monitoring/apex_metrics.toml:/apex_metrics.toml \
  container-registry.oracle.com/database/observability-exporter:1.1.1

podman create \
  --name prometheus \
  --pod dbfree-pod \
  -v "$(pwd)"/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml \
  quay.io/prometheus/prometheus:latest

podman create \
  --name grafana \
  --pod dbfree-pod \
  -e GF_AUTH_ANONYMOUS_ENABLED=true \
  -e GF_AUTH_ANONYMOUS_ORG_ROLE=Admin \
  -e GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/home/grafana/dashboards/oracledb.json \
  -v "$(pwd)"/monitoring/grafana_datasources.yml:/etc/grafana/provisioning/datasources/datasources.yaml \
  -v "$(pwd)"/monitoring/dashboards:/home/grafana/dashboards \
  -v "$(pwd)"/monitoring/grafana_dashboard.yml:/etc/grafana/provisioning/dashboards/main.yaml \
  -v grafana_vol:/var/lib/grafana \
  grafana-oss:latest

podman container start exporter
podman container start prometheus
podman container start grafana

echo "Oracle metrics data exporter is set up and running at http://localhost:9161/metrics"
echo "Prometheus is up an running at http://localhost:9090"
echo "Grafana is up an running at http://localhost:3000"
