#!/usr/bin/env bash
# Using:
#   bash scripts/build.sh <board> <project> [make-target]
#
# Examples:
#   bash scripts/build.sh rpi0_2w base
#   bash scripts/build.sh rpi0_2w fb-painter
#   bash scripts/build.sh rpi0_2w fb-painter menuconfig
#   bash scripts/build.sh rpi0_2w fb-painter linux-menuconfig
#   bash scripts/build.sh rpi0_2w fb-painter python-fb-painter-rebuild
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

source "${SCRIPT_DIR}/versions.env"

BOARD="${1:-}"
PROJECT="${2:-}"
MAKE_TARGET="${3:-}"

if [ -z "${BOARD}" ] || [ -z "${PROJECT}" ]; then
    echo "Usage: $0 <board> <project> [make-target]"
    echo ""
    echo "  Boards:   rpi0_2w"
    echo "  Projects: base, fb-painter"
    echo ""
    echo "  Examples:"
    echo "    $0 rpi0_2w base"
    echo "    $0 rpi0_2w fb-painter"
    echo "    $0 rpi0_2w fb-painter menuconfig"
    echo "    $0 rpi0_2w fb-painter python-fb-painter-rebuild"
    exit 1
fi

DEFCONFIG="${BOARD}_${PROJECT}_defconfig"
BR_DIR="${ROOT_DIR}/buildroot-${BR_VERSION}"
EXT_DIR="${ROOT_DIR}/br-external"
PROFILE_DIR="${EXT_DIR}/board/${BOARD}/${PROJECT}"
OUT_DIR="${EXT_DIR}/output/${BOARD}/${PROJECT}"

bash "${SCRIPT_DIR}/fetch-buildroot.sh"

#
# Configure Buildroot
#
echo "[build] Applying: ${DEFCONFIG}"
make -C "${BR_DIR}" \
    BR2_EXTERNAL="${EXT_DIR}" \
    O="${OUT_DIR}" \
    "${DEFCONFIG}"

#
# Generate firmware blobs (ili9488.bin etc.)
#
if [ -f "${PROFILE_DIR}/rootfs-overlay/lib/firmware/ili9488.txt" ]; then
    echo "[build] Generating firmware blobs"
    python3 "${SCRIPT_DIR}/mipi-dbi-cmd.py" \
        "${PROFILE_DIR}/rootfs-overlay/lib/firmware/ili9488.bin" \
        "${PROFILE_DIR}/rootfs-overlay/lib/firmware/ili9488.txt"
        
fi

#
# Ensure Linux source tree exists
#
echo "[build] Preparing Linux source tree"

make -C "${BR_DIR}" \
    BR2_EXTERNAL="${EXT_DIR}" \
    O="${OUT_DIR}" \
    linux-patch

#
# Locate Linux build dir
#
LINUX_BUILD_DIR=$(
    find "${OUT_DIR}/build" \
        -maxdepth 1 \
        -type d \
        -name "linux-*"
)

if [ -z "${LINUX_BUILD_DIR}" ]; then
    echo "[build] ERROR: Linux build directory not found"
    exit 1
fi

echo "[build] Linux build dir:"
echo "  ${LINUX_BUILD_DIR}"

#
# Install firmware into kernel firmware dir
#
if compgen -G "${PROFILE_DIR}/rootfs-overlay/lib/firmware/*.bin" > /dev/null; then
    echo "[build] Installing firmware blobs into kernel tree"

    mkdir -p "${LINUX_BUILD_DIR}/firmware"

    cp \
        "${PROFILE_DIR}/rootfs-overlay/lib/firmware/"*.bin \
        "${LINUX_BUILD_DIR}/firmware/"
    
    rm -f "${LINUX_BUILD_DIR}/.stamp_built"
fi

#
# Main build
#
echo "[build] board=${BOARD} project=${PROJECT} target=${MAKE_TARGET:-all}"
make -C "${BR_DIR}" \
    BR2_EXTERNAL="${EXT_DIR}" \
    O="${OUT_DIR}" \
    ${MAKE_TARGET}

#
# Artifacts
#
echo ""
echo "[build] Artifacts:"
ls -lh "${OUT_DIR}/images/" 2>/dev/null || echo "  (no images yet)"
