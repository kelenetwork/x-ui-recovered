#!/usr/bin/env bash
set -euo pipefail

APP_NAME="x-ui"
INSTALL_DIR="/usr/local/x-ui"
DATA_DIR="/etc/x-ui"
SERVICE_FILE="/etc/systemd/system/x-ui.service"
COMMAND_FILE="/usr/bin/x-ui"
PROJECT_NAME="x-ui-recovered"
REPO_URL="https://github.com/kelenetwork/x-ui-recovered"
DEFAULT_BRANCH="main"
TARBALL_URL="${REPO_URL}/archive/refs/heads/${DEFAULT_BRANCH}.tar.gz"
REPO_DIR=""
BOOTSTRAP_TMPDIR="${X_UI_INSTALL_BOOTSTRAP_TMPDIR:-}"

log() {
    printf '[x-ui-install] %s\n' "$*"
}

die() {
    printf '[x-ui-install] ERROR: %s\n' "$*" >&2
    exit 1
}

cleanup_bootstrap_tmpdir() {
    local tmpdir="${BOOTSTRAP_TMPDIR:-}"
    local base

    [[ -n "${tmpdir}" ]] || return 0
    base="$(basename -- "${tmpdir}")"

    if [[ "${base}" == x-ui-install.* && -f "${tmpdir}/.x-ui-install-bootstrap-tmp" ]]; then
        rm -rf -- "${tmpdir}"
    else
        log "skip cleanup for unexpected bootstrap temp dir: ${tmpdir}"
    fi
}

if [[ -n "${BOOTSTRAP_TMPDIR}" ]]; then
    unset X_UI_INSTALL_BOOTSTRAP_TMPDIR
    trap cleanup_bootstrap_tmpdir EXIT
fi

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        die "run as root"
    fi
}

has_repo_context() {
    local dir="${1:-}"

    [[ -n "${dir}" ]] || return 1
    [[ -x "${dir}/recovered/usr-local-x-ui/x-ui" ]] || return 1
    [[ -f "${dir}/systemd/x-ui.service" ]] || return 1
}

resolve_repo_dir() {
    local source_path="${BASH_SOURCE[0]:-}"
    local source_dir=""
    local cwd_dir

    if [[ -n "${source_path}" && -f "${source_path}" ]]; then
        source_dir="$(cd -- "$(dirname -- "${source_path}")" 2>/dev/null && pwd -P)" || source_dir=""
        if has_repo_context "${source_dir}"; then
            REPO_DIR="${source_dir}"
            return 0
        fi
    fi

    cwd_dir="$(pwd -P)"
    if has_repo_context "${cwd_dir}"; then
        REPO_DIR="${cwd_dir}"
        return 0
    fi

    return 1
}

download_tarball() {
    local destination="$1"

    if command -v curl >/dev/null 2>&1; then
        curl -fL "${TARBALL_URL}" -o "${destination}"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "${destination}" "${TARBALL_URL}"
    else
        die "curl or wget is required to download ${REPO_URL}"
    fi
}

bootstrap_from_tarball() {
    local archive
    local extracted

    command -v tar >/dev/null 2>&1 || die "tar is required to unpack ${TARBALL_URL}"
    command -v mktemp >/dev/null 2>&1 || die "mktemp is required to create a temporary install directory"

    BOOTSTRAP_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/x-ui-install.XXXXXXXXXX")"
    touch "${BOOTSTRAP_TMPDIR}/.x-ui-install-bootstrap-tmp"
    trap cleanup_bootstrap_tmpdir EXIT

    archive="${BOOTSTRAP_TMPDIR}/source.tar.gz"
    extracted="${BOOTSTRAP_TMPDIR}/${PROJECT_NAME}-${DEFAULT_BRANCH}"

    log "repository files not found; downloading ${REPO_URL} (${DEFAULT_BRANCH})"
    download_tarball "${archive}"
    tar -xzf "${archive}" -C "${BOOTSTRAP_TMPDIR}"

    [[ -f "${extracted}/install.sh" ]] || die "downloaded archive did not contain ${PROJECT_NAME}-${DEFAULT_BRANCH}/install.sh"
    [[ -x "${extracted}/recovered/usr-local-x-ui/x-ui" ]] || die "downloaded archive did not contain recovered panel binary"
    [[ -f "${extracted}/systemd/x-ui.service" ]] || die "downloaded archive did not contain systemd/x-ui.service"

    export X_UI_INSTALL_BOOTSTRAP_TMPDIR="${BOOTSTRAP_TMPDIR}"
    trap - EXIT
    exec bash "${extracted}/install.sh" "$@"

    cleanup_bootstrap_tmpdir
    die "failed to execute downloaded install.sh"
}

install_files() {
    [[ -x "${REPO_DIR}/recovered/usr-local-x-ui/x-ui" ]] || die "missing recovered panel binary"
    [[ -x "${REPO_DIR}/recovered/usr-local-x-ui/bin/xray-linux-amd64" ]] || die "missing recovered xray binary"
    [[ -f "${REPO_DIR}/systemd/x-ui.service" ]] || die "missing systemd/x-ui.service"
    [[ -f "${REPO_DIR}/scripts/x-ui" ]] || die "missing scripts/x-ui"

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
    if ! resolve_repo_dir; then
        bootstrap_from_tarball "$@"
    fi

    require_root
    install_files
    enable_service
    log "installed ${APP_NAME} to ${INSTALL_DIR}"
    log "use 'x-ui status' or 'x-ui settings' to inspect the panel"
}

main "$@"
