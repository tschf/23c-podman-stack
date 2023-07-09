#!/bin/bash
set -e

export basePath="$HOME/db-free"

mkdir -p "$basePath/ords_secrets"

pwgen 16 1 | tr -d '\n' | podman secret create ORACLE_PWD -

secretInfo=$(podman secret inspect ORACLE_PWD)
secretId=$(echo "$secretInfo" | jq -r '.[0].ID')
secretFilePath=$(echo "$secretInfo" | jq -r '.[0].Spec.Driver.Options.path')/secretsdata.json
secretDecoded=$(jq -r ".[\"$secretId\"]" < "$secretFilePath" | base64 -d)

# This path db-free/ords_secrets is a volume passed to the ORDS container and is
# used only first when establishing the connection and then subsequently removed.
# It's important to also map the /etc/ords/config volume so the connection info
# persists between reboots of the pod-containers.
printf "CONN_STRING=sys/%s@db:1521/FREEPDB1" "$secretDecoded" > "$HOME/db-free/ords_secrets/conn_string.txt"

# Expose an environment variable to use to create an application development schema
pwgen 16 1 | tr -d '\n' | podman secret create DEVVER_PWD -
podman pod create -p 8181:8181 dbfree-pod

podman volume create oradata
podman volume create ordsconfig

podman create \
  --name db \
  --pod dbfree-pod \
  --user oracle \
  --secret ORACLE_PWD,type=env \
  --secret DEVVER_PWD,type=env \
  -v "oradata:/opt/oracle/oradata" \
  database/free

podman create \
  --name ords \
  --pod dbfree-pod \
  -v "$HOME/db-free/ords_secrets/:/opt/oracle/variables:Z" \
  -v "ordsconfig:/etc/ords/config" \
  --restart on-failure:200 \
  container-registry.oracle.com/database/ords:23.2.0

podman container start db

echo "Waiting for DB to become healthy before staring ORDS"

healthStatus=$(curl -s --unix-socket "$XDG_RUNTIME_DIR/podman/podman.sock" http://localhost/v4.0.0/libpod/containers/db/json | jq -r '.State.Health.Status')
while [[ "$healthStatus" != "healthy" ]]
do

  healthStatus=$(curl -s --unix-socket "$XDG_RUNTIME_DIR/podman/podman.sock" http://localhost/v4.0.0/libpod/containers/db/json | jq -r '.State.Health.Status')
  echo "Current status: $healthStatus"
  sleep 30s

done

echo "Database healthy."
echo "Create app dev user"
podman cp scripts/create_user.sh db:/tmp/create_user.sh
podman exec db /tmp/create_user.sh
podman exec db rm /tmp/create_user.sh

echo "Proceeding with ORDS, this will also kick the APEX installation"

podman pod start dbfree-pod
podman exec -it ords tail -f /tmp/install_container.log