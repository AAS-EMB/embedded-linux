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
OUT_DIR="${EXT_DIR}/output/${BOARD}/${PROJECT}"

bash "${SCRIPT_DIR}/fetch-buildroot.sh"

if [ ! -f "${OUT_DIR}/.config" ]; then
    echo "[build] Configuring: ${DEFCONFIG}"
    make -C "${BR_DIR}" \
        BR2_EXTERNAL="${EXT_DIR}" \
        O="${OUT_DIR}" \
        "${DEFCONFIG}"
else
    echo "[build] Already configured. To reset: rm ${OUT_DIR}/.config"
fi

echo "[build] board=${BOARD} project=${PROJECT} target=${MAKE_TARGET:-all}"
make -C "${BR_DIR}" \
    BR2_EXTERNAL="${EXT_DIR}" \
    O="${OUT_DIR}" \
    ${MAKE_TARGET}

echo ""
echo "[build] Artifacts:"
ls -lh "${OUT_DIR}/images/" 2>/dev/null || echo "  (no images yet)"