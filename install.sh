#!/usr/bin/env bash
set -euo pipefail

APP_NAME="x-ui"
INSTALL_DIR="/usr/local/x-ui"
DATA_DIR="/etc/x-ui"
SERVICE_FILE="/etc/systemd/system/x-ui.service"
COMMAND_FILE="/usr/bin/x-ui"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    printf '[x-ui-install] %s\n' "$*"
}

die() {
    printf '[x-ui-install] ERROR: %s\n' "$*" >&2
    exit 1
}

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        die "run as root"
    fi
}

install_files() {
    [[ -x "${REPO_DIR}/recovered/usr-local-x-ui/x-ui" ]] || die "missing recovered panel binary"
    [[ -x "${REPO_DIR}/recovered/usr-local-x-ui/bin/xray-linux-amd64" ]] || die "missing recovered xray binary"
    [[ -f "${REPO_DIR}/systemd/x-ui.service" ]] || die "missing systemd/x-ui.service"

    install -d -m 0755 "${INSTALL_DIR}"
    cp -a "${REPO_DIR}/recovered/usr-local-x-ui/." "${INSTALL_DIR}/"
    rm -f "${INSTALL_DIR}/bin/config.json"
    chown -R root:root "${INSTALL_DIR}"

    install -d -m 0700 "${DATA_DIR}"
    install -m 0644 "${REPO_DIR}/systemd/x-ui.service" "${SERVICE_FILE}"
    install -m 0755 "${REPO_DIR}/scripts/x-ui" "${COMMAND_FILE}"

    chmod 0755 "${INSTALL_DIR}/x-ui" "${INSTALL_DIR}/x-ui.sh" "${INSTALL_DIR}/bin/xray-linux-amd64" "${COMMAND_FILE}"
}

enable_service() {
    systemctl daemon-reload
    systemctl enable "${APP_NAME}"
    systemctl restart "${APP_NAME}"
}

main() {
    require_root
    install_files
    enable_service
    log "installed ${APP_NAME} to ${INSTALL_DIR}"
    log "use 'x-ui status' or 'x-ui settings' to inspect the panel"
}

main "$@"
