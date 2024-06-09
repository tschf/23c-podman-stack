#!/bin/bash
set -e

# If a password for devver user wasn't provided, just exit the script
[[ "$DEVVER_PWD" == "" ]] && exit 0

sqlplus sys/$ORACLE_PWD@localhost:1521/FREEPDB1 as sysdba <<EOF

PRO create tablespace DATA
create tablespace data
  datafile 'data.dbf'
  size 100m autoextend on
  encryption using 'AES256'
  default storage (encrypt);

PRO create user devver
create user devver identified by $DEVVER_PWD default tablespace data;
grant db_developer_role to devver;
alter user devver quota unlimited on data;

exit;
EOF
