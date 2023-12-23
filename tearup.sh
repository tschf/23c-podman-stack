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
  container-registry.oracle.com/database/free

podman create \
  --name ords \
  --pod dbfree-pod \
  -v "ordsconfig:/etc/ords/config" \
  -v "ordsinit:/ords-entrypoint.d" \
  --restart on-failure:200 \
  container-registry.oracle.com/database/ords:23.4.0

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
# podman cp standalone ords:/etc/ords/config/global/standalone

# Wait for the ords process to exist before stopping the tail process
podman cp scripts/process_waiter.sh ords:/tmp/process_waiter.sh

# We need to allow non-zero exit codes since we force kill the `tail` command
# which results in a non-zero exit code thus killing subsequent script lines.
set +e
podman exec ords /tmp/process_waiter.sh &

podman exec ords tail -f /tmp/install_container.log
set -e
# We don't need that script beyond the initial start up so remove it from the
# container.
podman exec ords rm /tmp/process_waiter.sh

echo "Waiting for ORDS to be fully available"
podman exec -it db bash -c 'sqlplus sys/$ORACLE_PWD@localhost:1521/freepdb1 as sysdba'<<EOF
set serveroutput on

declare
  l_ords_schema_version_table_count number;
begin

  -- First wait for the table to exist
  loop
    select count(1)
    into l_ords_schema_version_table_count
    from all_objects
    where owner = 'ORDS_METADATA'
    and object_name = 'ORDS_SCHEMA_VERSION';

    exit when l_ords_schema_version_table_count = 1;
    dbms_session.sleep(1);
  end loop;
end;
/

declare
  l_install_status ords_metadata.ords_schema_version.status%type;
begin
  -- Wait for status to become available
  loop
    begin
      select status
      into l_install_status
      from ords_metadata.ords_schema_version
      order by version desc
      fetch first row only;
    -- The record hasn't been created yet. That's ok. lets wait a second
    exception when no_data_found then null;
    end;

    exit when l_install_status = 'AVAILABLE';

    dbms_session.sleep(1);
  end loop;
end;
/
exit
EOF

# Now that we know ORDS is available, set up a schema to get going with and REST
# enable it so SQLDevWeb can be used.
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

echo "**Workspace info**" | tee connection_info.txt
echo "WORKSPACE: APP_DEV" | tee --append connection_info.txt
echo "USER: DEVVER" | tee --append connection_info.txt
echo "PASSWORD: $devverPwdSecretDecoded" | tee --append connection_info.txt

echo ""
echo "All Done"