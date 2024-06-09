#!/usr/bin/env bash
# Set up encryption wallet so we can use TDE (encrypted tablespaces)
# Doc guide: https://docs.oracle.com/en/database/oracle/oracle-database/23/asoag/configuring-united-mode2.html#GUID-CD6E4741-4916-4F24-9427-4DA25DF40587
# Also, Tim's docs: https://oracle-base.com/articles/12c/multitenant-transparent-data-encryption-tde-12cr1
set -e

wallet_path="/opt/oracle/admin/FREE/wallet"

# Make the folder where the wallet will be stored.
mkdir -p "$wallet_path"

# Do config options on CDB
sqlplus / as sysdba<<EOF
whenever sqlerror exit failure
whenever oserror exit failure

PRO Configured wallet_root
show parameter wallet_root

PRO Updating wallet_root
ALTER SYSTEM SET WALLET_ROOT='$wallet_path' SCOPE = SPFILE;
shutdown immediate
startup

PRO Verify wallet_root
show parameter wallet_root

PRO Configured tde_config
show parameter tde_config

ALTER SYSTEM SET TDE_CONFIGURATION="KEYSTORE_CONFIGURATION=FILE"
SCOPE=BOTH;

PRO Verify tde_config
show parameter tde_config

PRO create wallet
ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY $KEYSTORE_PWD;

PRO verify wallet file
host file ${wallet_path}/tde/ewallet.p12

PRO open keystore on CDB
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN
IDENTIFIED BY $KEYSTORE_PWD;

PRO configure key on CDB
ADMINISTER KEY MANAGEMENT SET KEY
IDENTIFIED BY $KEYSTORE_PWD
WITH BACKUP;

exit;
EOF

# Followed by PDB level
sqlplus sys/"$ORACLE_PWD"@localhost:1521/FREEPDB1 as sysdba <<EOF
whenever sqlerror exit failure
whenever oserror exit failure

PRO open keystore on PDB
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN
IDENTIFIED BY $KEYSTORE_PWD;

PRO configure key on PDB
ADMINISTER KEY MANAGEMENT SET KEY
IDENTIFIED BY $KEYSTORE_PWD
WITH BACKUP;

exit;
EOF

