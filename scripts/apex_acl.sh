#!/usr/bin/env bash

sqlplus sys/$ORACLE_PWD@localhost:1521/FREEPDB1 as sysdba <<EOF
begin
  dbms_network_acl_admin.append_host_ace(
    host => '*',
    ace =>
      xs\$ace_type(
        privilege_list => xs\$name_list('CONNECT','RESOLVE','HTTP'),
        principal_name => apex_application.g_flow_schema_owner,
        principal_type=> xs_acl.ptype_db
      )
  );
end;
/
EOF
