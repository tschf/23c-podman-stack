#!/bin/bash
set -e

podman pull container-registry.oracle.com/database/free:23.6.0.0
podman pull container-registry.oracle.com/database/free:latest
podman pull container-registry.oracle.com/database/ords-developer:24.4.0
podman pull container-registry.oracle.com/database/ords-developer:latest