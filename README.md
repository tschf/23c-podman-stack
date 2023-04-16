# README

[23c Docs Home](https://docs.oracle.com/en/database/oracle/oracle-database/23/index.html)

## Pre-requisites

This assumes you're on linux - some of the scripts might not work for you.

* Uses curl
* Uses pwgen

## Initial Setup

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

In the future if you want to spin up or down the containers just run:

```sh
podman pod stop dbfree-pod 
podman pod start dbfree-pod 
```

## Post Set-Up

After APEX and the DB has been provisioned, some additional things you will want to do.

Find the password for the devver use

```sh
podman exec db bash -c 'echo $DEVVER_PWD'
```

Connect to SQLcl or plus:

I didn't expose 1521 but you can connect by one of the following 2 methods:

```sh
podman exec -it db sqlplus devver/PASSWORD@localhost:1521/freepdb1
podman exec -it ords sql devver/PASSWORD@localhost:1521/freepdb1
```

REST Enable the schema

With one of the above connections execute the following code:

```sql
begin
  ords.enable_schema;
end;
/
```

Then you can get access to SQL Developer Web by the URL: http://localhost:8181/ords/devver/sign-in/?username=devver&r=_sdw%2F%3Fnav%3Dworksheet

Create an APEX Workspace:

```sql
begin 
  apex_instance_admin.add_workspace(
    p_workspace => 'DEVVER',
    p_primary_schema => 'DEVVER',
    p_workspace_id   => 100000
  );
    
  apex_util.set_workspace('DEVVER');
  apex_util.create_user(
    p_user_name                    => 'trent',
    p_web_password                 => 'Welcome_123!',
    p_developer_privs              => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL'
  );
end;
/
```
