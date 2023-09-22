#!/bin/bash
set -e

# Create two random passwords. One for sys/dba account; And another for an initial
# app development schema "devver". Workspace (APP_DEV) will be created and assigned
# a devver user with the same password
pwgen 16 1 | tr -d '\n' | podman secret create ORACLE_PWD -
pwgen 16 1 | tr -d '\n' | podman secret create DEVVER_PWD -

oraclePwdSecretInfo=$(podman secret inspect ORACLE_PWD)
oraclePwdSecretId=$(echo "$oraclePwdSecretInfo" | jq -r '.[0].ID')
oraclePwdSecretFilePath=$(echo "$oraclePwdSecretInfo" | jq -r '.[0].Spec.Driver.Options.path')/secretsdata.json
oraclePwdSecretDecoded=$(jq -r ".[\"$oraclePwdSecretId\"]" < "$oraclePwdSecretFilePath" | base64 -d)

devverPwdSecretInfo=$(podman secret inspect DEVVER_PWD)
devverPwdSecretId=$(echo "$devverPwdSecretInfo" | jq -r '.[0].ID')
devverPwdSecretFilePath=$(echo "$devverPwdSecretInfo" | jq -r '.[0].Spec.Driver.Options.path')/secretsdata.json
devverPwdSecretDecoded=$(jq -r ".[\"$devverPwdSecretId\"]" < "$devverPwdSecretFilePath" | base64 -d)

# This path db-free/ords_secrets is a volume passed to the ORDS container and is
# used only first when establishing the connection and then subsequently removed.
# It's important to also map the /etc/ords/config volume so the connection info
# persists between reboots of the pod-containers.
printf "CONN_STRING=sys/%s@db:1521/FREEPDB1" "$oraclePwdSecretDecoded" > conn_string.txt

podman pod create -p 8181:8181 -p 1521:1521 dbfree-pod

podman volume create oradata
podman volume create ordsconfig
# ordsinit, for scripts that run before the container starts i.e. on boot
podman volume create ordsinit

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
  -v "ordsconfig:/etc/ords/config" \
  -v "ordsinit:/ords-entrypoint.d" \
  --restart on-failure:200 \
  container-registry.oracle.com/database/ords:23.2.0

podman cp conn_string.txt ords:/opt/oracle/variables/conn_string.txt
rm conn_string.txt

podman cp scripts/custom_alias.sh ords:/ords-entrypoint.d
podman cp scripts/ords_config.sh ords:/ords-entrypoint.d

podman container start db

echo "Waiting for DB to become healthy before staring ORDS. We will keep checking every 30secs"

healthStatus=$(curl -s --unix-socket "$XDG_RUNTIME_DIR/podman/podman.sock" http://localhost/v4.0.0/libpod/containers/db/json | jq -r '.State.Health.Status')
healthStatus=$(podman inspect db --format="{{if .Config.Healthcheck}}{{print .State.Health.Status}}{{end}}")
while [[ "$healthStatus" != "healthy" ]]
do
  sleep 30s
  healthStatus=$(podman inspect db --format="{{if .Config.Healthcheck}}{{print .State.Health.Status}}{{end}}")
  # healthStatus=$(curl -s --unix-socket "$XDG_RUNTIME_DIR/podman/podman.sock" http://localhost/v4.0.0/libpod/containers/db/json | jq -r '.State.Health.Status')
  echo "Current status: $healthStatus"
done

echo "Database healthy."
echo "Create app dev user"
podman cp scripts/create_user.sh db:/tmp/create_user.sh
podman exec db /tmp/create_user.sh
podman exec db rm /tmp/create_user.sh

echo "Starting ORDS container. On first run, this installs APEX"

podman pod start dbfree-pod

podman exec ords mkdir -p /etc/ords/config/global
podman cp standalone ords:/etc/ords/config/global/standalone

# Watch the logs. I set up a script to monitor when no new content comes through
# in a time threshold. Once no new content is read it is set up to kill the `tail`
# process. I set it up this way (rather than just doing it all in log_watcher) as
# I wanted the log to stream in realtime.
podman cp scripts/log_watcher.sh ords:/tmp/log_watcher.sh

# We need to allow non-zero exit codes since we force kill the `tail` command
# which results in a non-zero exit code thus killing subsequent script lines.
set +e
podman exec ords /tmp/log_watcher.sh &

podman exec ords tail -f /tmp/install_container.log
set -e
podman exec ords rm /tmp/log_watcher.sh

echo "Create APEX Workspace and REST enable schema"
podman exec -it db bash -c 'sqlplus sys/$ORACLE_PWD@localhost:1521/freepdb1 as sysdba'<<EOF
begin
  ords_admin.enable_schema(
    p_schema => 'DEVVER'
  );

  apex_instance_admin.add_workspace(
    p_workspace_id => 10000,
    p_workspace => 'APP_DEV',
    p_primary_schema => 'DEVVER'
  );

  apex_util.set_workspace('APP_DEV');

  apex_util.create_user(
    p_user_name => 'DEVVER',
    p_web_password => '$devverPwdSecretDecoded',
    p_developer_privs => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
    p_change_password_on_first_use => 'N'
  );
end;
/

exit
EOF

echo "**Workspace info**"
echo "WORKSPACE: APP_DEV"
echo "USER: DEVVER"
echo "PASSWORD: $devverPwdSecretDecoded"

echo ""
echo "All Done"