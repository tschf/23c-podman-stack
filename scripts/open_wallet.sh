#!/usr/bin/env bash
set -e

# Do config options on CDB
sqlplus / as sysdba<<EOF
PRO open keystore on CDB
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN
IDENTIFIED BY $KEYSTORE_PWD;
EOF

# Followed by PDB level
sqlplus sys/"$ORACLE_PWD"@localhost:1521/FREEPDB1 as sysdba <<EOF
whenever sqlerror exit failure
whenever oserror exit failure

PRO open keystore on PDB
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN
IDENTIFIED BY $KEYSTORE_PWD;

exit;
EOF
