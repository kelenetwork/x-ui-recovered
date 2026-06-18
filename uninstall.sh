#!/usr/bin/env bash
set -euo pipefail

APP_NAME="x-ui"
INSTALL_DIR="/usr/local/x-ui"
DATA_DIR="/etc/x-ui"
SERVICE_FILE="/etc/systemd/system/x-ui.service"
COMMAND_FILE="/usr/bin/x-ui"

die() {
    printf '[x-ui-uninstall] ERROR: %s\n' "$*" >&2
    exit 1
}

if [[ "${EUID}" -ne 0 ]]; then
    die "run as root"
fi

if [[ "${1:-}" != "--yes" ]]; then
    printf 'This will stop x-ui and remove %s, %s, %s, and %s on this machine.\n' \
        "${INSTALL_DIR}" "${DATA_DIR}" "${SERVICE_FILE}" "${COMMAND_FILE}"
    read -r -p "Continue? [y/N] " answer
    case "${answer}" in
        y|Y|yes|YES) ;;
        *) printf 'Cancelled.\n'; exit 0 ;;
    esac
fi

systemctl stop "${APP_NAME}" 2>/dev/null || true
systemctl disable "${APP_NAME}" 2>/dev/null || true
rm -f "${SERVICE_FILE}" "${COMMAND_FILE}"
rm -rf "${INSTALL_DIR}" "${DATA_DIR}"
systemctl daemon-reload
systemctl reset-failed "${APP_NAME}" 2>/dev/null || true
printf '[x-ui-uninstall] removed local x-ui installation\n'
