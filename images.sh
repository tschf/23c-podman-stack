#!/bin/bash
set -e

podman pull container-registry.oracle.com/database/free:23.4.0.0
podman pull container-registry.oracle.com/database/free:latest
podman pull container-registry.oracle.com/database/ords-developer:24.2.2
podman pull container-registry.oracle.com/database/ords-developer:latest