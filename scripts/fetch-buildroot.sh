#!/usr/bin/env bash
# Using:
#   bash scripts/fetch-buildroot.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

source "${SCRIPT_DIR}/versions.env"

BR_DIR="${ROOT_DIR}/buildroot-${BR_VERSION}"

if [ -d "${BR_DIR}" ]; then
    echo "[fetch] Buildroot ${BR_VERSION} already at ${BR_DIR}, skipping."
    exit 0
fi

echo "[fetch] Downloading Buildroot ${BR_VERSION}..."
wget -q --show-progress "${BR_URL}" -P "${ROOT_DIR}"

echo "[fetch] Extracting..."
tar xf "${ROOT_DIR}/buildroot-${BR_VERSION}.tar.gz" -C "${ROOT_DIR}"
rm     "${ROOT_DIR}/buildroot-${BR_VERSION}.tar.gz"

echo "[fetch] Done: ${BR_DIR}"