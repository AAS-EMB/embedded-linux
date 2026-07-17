#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="$1"
PROFILE_DIR="$(cd "$(dirname "$0")" && pwd)"

source "${PROFILE_DIR}/../../common/post-build-common.sh" \
    "${TARGET_DIR}" "rpi-embedded"

FIRMWARE_DIR="${TARGET_DIR}/../images/rpi-firmware"
if [ -d "${FIRMWARE_DIR}" ]; then
    echo "[rpi0_2w] Copying cmdline.txt → ${FIRMWARE_DIR}"
    cp "${PROFILE_DIR}/boot/cmdline.txt" "${FIRMWARE_DIR}/cmdline.txt"
else
    echo "[rpi0_2w] WARN: firmware dir not ready yet, cmdline.txt will be copied in post-image"
fi

echo "[rpi0_2w] post-build done"