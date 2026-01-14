#!/usr/bin/env bash
set -euo pipefail

if command -v podman >/dev/null 2>&1; then
  echo podman
elif command -v docker >/dev/null 2>&1; then
  echo docker
else
  echo "No container engine found (podman/docker)." >&2
  exit 1
fi