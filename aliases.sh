#!/bin/bash
# . aliases.sh

alias db23_sys_password='podman exec db bash -c '\''echo $ORACLE_PWD'\'''
alias db23_devver_password='podman exec db bash -c '\''echo $DEVVER_PWD'\'''
alias db23_dba='sql sys/"$(db23_sys_password)"@localhost:1521/freepdb1 as sysdba'
alias db23_devver='sql devver/"$(db23_devver_password)"@localhost:1521/freepdb1'