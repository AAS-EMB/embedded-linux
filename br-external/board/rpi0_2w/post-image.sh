#!/usr/bin/env bash
set -euo pipefail

BOARD_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGES_DIR="$1"

echo "[rpi0_2w] config.txt → ${IMAGES_DIR}"
cp "${BOARD_DIR}/config.txt" "${IMAGES_DIR}/config.txt"

if [ ! -f "${IMAGES_DIR}/rpi-firmware/cmdline.txt" ]; then
    echo "[rpi0_2w] cmdline.txt → ${IMAGES_DIR}/rpi-firmware"
    mkdir -p "${IMAGES_DIR}/rpi-firmware"
    cp "${BOARD_DIR}/cmdline.txt" "${IMAGES_DIR}/rpi-firmware/cmdline.txt"
fi

if [ ! -d "${IMAGES_DIR}/rpi-firmware/overlays" ]; then
    echo "ERROR: ${IMAGES_DIR}/rpi-firmware/overlays not found"
    echo "       Убедись что BR2_PACKAGE_RPI_FIRMWARE=y в defconfig"
    exit 1
fi

echo "[rpi0_2w] Running genimage..."
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
rm -rf "${GENIMAGE_TMP}"

genimage \
    --rootpath  "${TARGET_DIR}" \
    --tmppath   "${GENIMAGE_TMP}" \
    --inputpath "${IMAGES_DIR}" \
    --outputpath "${IMAGES_DIR}" \
    --config    "${BOARD_DIR}/genimage.cfg"

echo "[rpi0_2w] Done: ${IMAGES_DIR}/sdcard.img"
ls -lh "${IMAGES_DIR}/sdcard.img"