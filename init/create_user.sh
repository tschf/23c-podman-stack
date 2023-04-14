#!/bin/bash
set -e

# If a password for devver user wasn't provided, just exit the script
[[ "$DEVVER_PWD" == "" ]] && exit 0

sqlplus sys/$ORACLE_PWD@localhost:1521/FREEPDB1 as sysdba <<EOF

create user devver identified by $DEVVER_PWD;
grant db_developer_role to devver;
alter user devver quota unlimited on users;

exit;
EOF
