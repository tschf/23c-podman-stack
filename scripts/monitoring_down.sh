#!/usr/bin/env bash
podman container stop prometheus grafana exporter
podman secret rm EXPORTER_PWD
podman container rm prometheus grafana exporter
podman volume rm grafana_vol