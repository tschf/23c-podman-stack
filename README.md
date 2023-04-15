# README

Set up instructions:

Grab the images if you don't already have them. I like to do this is an independent
step rather than letting the container engine pull them in a "run" operation.

```sh
./images.sh
```

Provision all the pieces - this script does the following tasks:

* Makes a folder in your HOME - $HOME/db-free
* Creates 2 secrets - 1 for sys and 1 for a app dev user which I've called "devver".

```sh
./tearup.sh
```

## Database

### Run 23c container

podman run -d \
  --name db-free \
  --user oracle \
  --net 23cnetwork \
  --secret ORACLE_PWD,type=env \
  --secret DEVVER_PWD,type=env \
  -v $HOME/db-free/oradata:/opt/oracle/oradata:z \
  -v $HOME/db-free/dbInstallInit:/opt/oracle/scripts/setup:Z \
  database/free

If you want a volume for logs, add:

  -v $HOME/db-free/dbca:/opt/oracle/cfgtoollogs/dbca

### Test in OL8 container

dnf install oracle-instantclient-release-el8
dnf install oracle-instantclient-sqlplus

Once sqlplus is installed, verify connection:

sqlplus foo/foo@db-free:1521/FREEPDB1

## ORDS
### Run ORDS

podman run -d \
  --name ords \
  --net 23cnetwork \
  -v $HOME/db-free/ords_secrets/:/opt/oracle/variables:U \
  -p 8181:8181 \
  container-registry.oracle.com/database/ords:23.1.0
