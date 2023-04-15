#!/bin/bash
podman unshare<<EOF
rm -rf "$HOME/db-free"
exit
EOF

podman pod stop dbfree-pod
podman pod rm dbfree-pod

podman secret rm ORACLE_PWD
podman secret rm DEVVER_PWD