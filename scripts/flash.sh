#!/usr/bin/env bash
# Using:
#   bash scripts/flash.sh <device> <board> [project]
#
# Examples:
#   bash scripts/flash.sh /dev/sdb rpi0_2w base
#   bash scripts/flash.sh /dev/sdb rpi0_2w fb-painter
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

DEVICE="${1:-}"
BOARD="${2:-}"
PROJECT="${3:-base}"

if [ -z "${DEVICE}" ] || [ -z "${BOARD}" ]; then
    echo "Usage: $0 <device> <board> [project]"
    echo ""
    echo "  Example: $0 /dev/sdb rpi0_2w base"
    echo "  Example: $0 /dev/sdb rpi0_2w fb-painter"
    exit 1
fi

if mount | grep -q "^${DEVICE}"; then
    echo "ERROR: ${DEVICE} is currently mounted. Unmount first:"
    mount | grep "^${DEVICE}"
    exit 1
fi

IMAGE="${ROOT_DIR}/br-external/output/${BOARD}/${PROJECT}/images/sdcard.img"

if [ ! -f "${IMAGE}" ]; then
    echo "ERROR: Image not found: ${IMAGE}"
    echo ""
    echo "Build it first:"
    echo "  bash scripts/build.sh ${BOARD} ${PROJECT}"
    exit 1
fi

IMAGE_SIZE=$(du -h "${IMAGE}" | cut -f1)
DEVICE_SIZE=$(lsblk -dn -o SIZE "${DEVICE}" 2>/dev/null || echo "unknown")

echo "┌─────────────────────────────────────────┐"
echo "│              FLASH SUMMARY              │"
echo "├─────────────────────────────────────────┤"
printf "│  Image  : %-30s │\n" "${PROJECT}/sdcard.img (${IMAGE_SIZE})"
printf "│  Target : %-30s │\n" "${DEVICE} (${DEVICE_SIZE})"
printf "│  Board  : %-30s │\n" "${BOARD}"
echo "├─────────────────────────────────────────┤"
echo "│  !! All data on ${DEVICE} will be ERASED !!  │"
echo "└─────────────────────────────────────────┘"
echo ""
echo "Press Ctrl+C within 5 seconds to cancel..."
sleep 5

echo "[flash] Writing..."
sudo dd if="${IMAGE}" of="${DEVICE}" bs=4M conv=fsync status=progress
sync

echo ""
echo "[flash] Done."
echo ""

case "${BOARD}" in
    rpi0_2w)
        echo "  → Insert SD card into RPi Zero 2W and power on"
        echo "  → Serial debug (115200 8N1):"
        echo "       minicom -D /dev/ttyUSB0 -b 115200"
        echo "  → UART pins: TX=GPIO14 (pin8), RX=GPIO15 (pin10)"
        if [ "${PROJECT}" = "fb-painter" ]; then
            echo "  → fb-painter starts automatically via S99fb-painter"
            echo "  → Logs: tail -f /var/log/messages"
        fi
        ;;
    bbb)
        echo "  → Insert SD card into BeagleBone Black"
        echo "  → Hold BOOT button (S2) while powering on"
        echo "  → Serial debug: minicom -D /dev/ttyUSB0 -b 115200"
        ;;
esac