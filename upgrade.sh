#!/usr/bin/env bash
set -euo pipefail

APP_NAME="x-ui"
INSTALL_DIR="/usr/local/x-ui"
SERVICE_FILE="/etc/systemd/system/x-ui.service"
COMMAND_FILE="/usr/bin/x-ui"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    printf '[x-ui-upgrade] %s\n' "$*"
}

die() {
    printf '[x-ui-upgrade] ERROR: %s\n' "$*" >&2
    exit 1
}

if [[ "${EUID}" -ne 0 ]]; then
    die "run as root"
fi

[[ -d "${INSTALL_DIR}" ]] || die "${INSTALL_DIR} does not exist; run install.sh first"
[[ -x "${REPO_DIR}/recovered/usr-local-x-ui/x-ui" ]] || die "missing recovered panel binary"

cp -a "${REPO_DIR}/recovered/usr-local-x-ui/." "${INSTALL_DIR}/"
rm -f "${INSTALL_DIR}/bin/config.json"
chown -R root:root "${INSTALL_DIR}"
install -m 0644 "${REPO_DIR}/systemd/x-ui.service" "${SERVICE_FILE}"
install -m 0755 "${REPO_DIR}/scripts/x-ui" "${COMMAND_FILE}"
chmod 0755 "${INSTALL_DIR}/x-ui" "${INSTALL_DIR}/x-ui.sh" "${INSTALL_DIR}/bin/xray-linux-amd64" "${COMMAND_FILE}"

systemctl daemon-reload
systemctl restart "${APP_NAME}"
log "upgraded files from this repository and restarted ${APP_NAME}"
