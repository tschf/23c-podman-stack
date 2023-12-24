#!/bin/bash
podman pod stop dbfree-pod
podman pod rm dbfree-pod

podman volume rm oradata
podman volume rm ordsconfig
podman volume rm ordsinit

podman secret rm ORACLE_PWD
podman secret rm DEVVER_PWD
podman secret rm EXPORTER_PWD
