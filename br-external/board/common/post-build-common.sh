#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="$1"
BOARD_NAME="$2"

echo "[common] hostname → ${BOARD_NAME}"
echo "${BOARD_NAME}" > "${TARGET_DIR}/etc/hostname"

echo "[common] Trimming getty entries"
if [ -f "${TARGET_DIR}/etc/inittab" ]; then
    sed -i '/::respawn:.*tty[2-6]/d' "${TARGET_DIR}/etc/inittab"
fi

echo "[common] post-build-common done"