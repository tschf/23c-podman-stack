#!/bin/bash
set -e

podman pull container-registry.oracle.com/database/free:latet
podman pull container-registry.oracle.com/database/ords:23.1.0
# registry.gitlab.com/gitlab-ci-utils/curl-jq