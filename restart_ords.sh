#!/bin/bash
podman container restart ords
podman cp standalone ords:/etc/ords/config/global/
podman logs -f ords