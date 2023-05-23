#!/bin/bash
set -e

podman pull container-registry.oracle.com/database/free:23.2.0.0
podman pull container-registry.oracle.com/database/free:latest
podman pull container-registry.oracle.com/database/ords:23.1.2
podman pull container-registry.oracle.com/database/ords:latest