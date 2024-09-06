#!/bin/bash
set -e

podman pull container-registry.oracle.com/database/free:23.5.0.0
podman pull container-registry.oracle.com/database/free:latest
podman pull container-registry.oracle.com/database/ords-developer:24.2.3
podman pull container-registry.oracle.com/database/ords-developer:latest