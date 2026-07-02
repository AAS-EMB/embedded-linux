#!/usr/bin/env bash
set -euo pipefail

PROFILE_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGES_DIR="$1"

echo "[rpi0_2w] Installing boot assets"

#
# config.txt
#
cp \
  "${PROFILE_DIR}/boot/config.txt" \
  "${IMAGES_DIR}/config.txt"

#
# cmdline.txt
#
mkdir -p "${IMAGES_DIR}/rpi-firmware"

cp \
  "${PROFILE_DIR}/boot/cmdline.txt" \
  "${IMAGES_DIR}/rpi-firmware/cmdline.txt"

#
# overlays
#
if [ ! -d "${IMAGES_DIR}/rpi-firmware/overlays" ]; then
    echo "ERROR: ${IMAGES_DIR}/rpi-firmware/overlays not found"
    exit 1
fi

echo "[rpi0_2w] Installing DT overlays"

find "${IMAGES_DIR}" \
    -maxdepth 1 \
    -name "*.dtbo" \
    -exec cp -v {} "${IMAGES_DIR}/rpi-firmware/overlays/" \;

#
# genimage
#
echo "[rpi0_2w] Running genimage"

GENIMAGE_TMP="${IMAGES_DIR}/genimage.tmp"

rm -rf "${GENIMAGE_TMP}"

genimage \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${IMAGES_DIR}" \
    --outputpath "${IMAGES_DIR}" \
    --config "${PROFILE_DIR}/genimage.cfg"

echo "[rpi0_2w] Done"

ls -lh "${IMAGES_DIR}/sdcard.img"