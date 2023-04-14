# README

## Database

### Install software

Plugins are required to enable name resolution between containers.

dnf install podman podman-plugins
mkdir -p $HOME/db-free/oradata

### Set up network

podman network create 23cnetwork

### Create an admin password/secret

pwgen 16 1 | tr -d '\n' | podman secret create ORACLE_PWD -

### Run 23c container

podman run -d \
  --name db-free \
  --net 23cnetwork \
  --secret ORACLE_PWD,type=env \
  -v $HOME/db-free/oradata:/opt/oracle/oradata \
  database/free

If you want a volume for logs, add:

  -v $HOME/db-free/dbca:/opt/oracle/cfgtoollogs/dbca

### Test in OL8 container

dnf install oracle-instantclient-release-el8
dnf install oracle-instantclient-sqlplus

Once sqlplus is installed, verify connection:

sqlplus foo/foo@db-free:1521/FREEPDB1

## ORDS

### Config

mkdir -p $HOME/db-free/ords_secrets
mkdir -p $HOME/db-free/ords_config

cd $HOME/db-free/ords_secrets
nb: the connection string gets removed after the connection is established
printf "CONN_STRING=sys/%s@db-free:1521/FREEPDB1" "$(cat $(podman secret inspect ORACLE_PWD | jq -r '.[0].Spec.Driver.Options.path')/secretsdata.json | jq -r '. | .[]' | base64 -d)" > ords_secrets/conn_string.txt

### Run ORDS

podman run -d \
  --name ords \
  --net 23cnetwork \
  -v $HOME/db-free/ords_secrets/:/opt/oracle/variables:U \
  -p 8181:8181 \
  container-registry.oracle.com/database/ords:23.1.0