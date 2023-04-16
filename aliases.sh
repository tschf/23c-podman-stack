#!/bin/bash
# . aliases.sh

alias db23_sys_password='podman exec db bash -c '\''echo $ORACLE_PWD'\'''
alias db23_devver_password='podman exec db bash -c '\''echo $DEVVER_PWD'\'''
alias db23_dba='podman exec -it db bash -c '\''sqlplus sys/$ORACLE_PWD@localhost:1521/freepdb1 as sysdba'\'''
alias db23_devver='podman exec -it db bash -c '\''sqlplus devver/$DEVVER_PWD@localhost:1521/freepdb1'\'''