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
PREINSTALL_HAS_DB=0
PREINSTALL_HAS_INSTALL_INFO=0
PREINSTALL_HAS_ORIGINAL_MENU=0

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


capture_existing_state() {
    if [[ -f "${DATA_DIR}/x-ui.db" ]]; then
        PREINSTALL_HAS_DB=1
    fi

    if [[ -f "${DATA_DIR}/install-info.txt" ]]; then
        PREINSTALL_HAS_INSTALL_INFO=1
    fi

    if [[ -f "${COMMAND_FILE}" ]] && grep -q 'X-UI Admin Management Script' "${COMMAND_FILE}"; then
        PREINSTALL_HAS_ORIGINAL_MENU=1
    fi
}

install_files() {
    [[ -x "${REPO_DIR}/recovered/usr-local-x-ui/x-ui" ]] || die "missing recovered panel binary"
    [[ -x "${REPO_DIR}/recovered/usr-local-x-ui/bin/xray-linux-amd64" ]] || die "missing recovered xray binary"
    [[ -f "${REPO_DIR}/systemd/x-ui.service" ]] || die "missing systemd/x-ui.service"
    [[ -f "${REPO_DIR}/recovered/usr-bin/x-ui" ]] || die "missing recovered /usr/bin/x-ui wrapper"

    install -d -m 0755 "${INSTALL_DIR}"
    cp -a "${REPO_DIR}/recovered/usr-local-x-ui/." "${INSTALL_DIR}/"
    rm -f "${INSTALL_DIR}/bin/config.json"
    chown -R root:root "${INSTALL_DIR}"

    install -d -m 0700 "${DATA_DIR}"
    install -m 0644 "${REPO_DIR}/systemd/x-ui.service" "${SERVICE_FILE}"
    install -m 0755 "${REPO_DIR}/recovered/usr-bin/x-ui" "${COMMAND_FILE}"

    chmod 0755 "${INSTALL_DIR}/x-ui" "${INSTALL_DIR}/x-ui.sh" "${INSTALL_DIR}/bin/xray-linux-amd64" "${COMMAND_FILE}"
}


random_alnum() {
    local length="$1"
    local value=""
    local chunk=""

    while [[ ${#value} -lt ${length} ]]; do
        chunk="$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c "$((length - ${#value}))" || true)"
        value="${value}${chunk}"
    done

    printf '%s\n' "${value}"
}

random_port() {
    local port
    while :; do
        port=$((RANDOM % 45535 + 20000))
        if ! ss -ltn 2>/dev/null | awk '{print $4}' | grep -Eq ":${port}$"; then
            printf '%s\n' "${port}"
            return 0
        fi
    done
}

initialize_secure_panel() {
    local username password web_base_path panel_port
    local info_file="${DATA_DIR}/install-info.txt"

    if [[ "${X_UI_SKIP_SECURE_INIT:-0}" == "1" ]]; then
        log "skip initial panel randomization because X_UI_SKIP_SECURE_INIT=1"
        return 0
    fi

    if [[ "${X_UI_FORCE_SECURE_INIT:-0}" != "1" ]]; then
        if [[ "${PREINSTALL_HAS_INSTALL_INFO}" == "1" || -f "${info_file}" ]]; then
            log "initial panel settings already exist at ${info_file}; skip randomization"
            log "set X_UI_FORCE_SECURE_INIT=1 to regenerate username/password/path/port"
            return 0
        fi

        if [[ "${PREINSTALL_HAS_DB}" == "1" && "${PREINSTALL_HAS_ORIGINAL_MENU}" == "1" ]]; then
            log "existing original x-ui installation detected; keep current panel settings"
            log "set X_UI_FORCE_SECURE_INIT=1 to regenerate username/password/path/port"
            return 0
        fi
    fi

    username="${X_UI_USERNAME:-$(random_alnum 10)}"
    password="${X_UI_PASSWORD:-$(random_alnum 18)}"
    web_base_path="${X_UI_WEB_BASE_PATH:-$(random_alnum 12)}"
    panel_port="${X_UI_PORT:-$(random_port)}"

    "${INSTALL_DIR}/x-ui" setting \
        -username "${username}" \
        -password "${password}" \
        -webBasePath "${web_base_path}" \
        -port "${panel_port}" >/dev/null

    cat >"${info_file}" <<EOF
x-ui initial panel settings
Generated at: $(date -Is)

Port: ${panel_port}
Web Base Path: ${web_base_path}
Username: ${username}
Password: ${password}

Use 'x-ui settings' to show current panel settings.
Use 'X_UI_FORCE_SECURE_INIT=1 bash <(curl -Ls https://raw.githubusercontent.com/kelenetwork/x-ui-recovered/main/install.sh)' to regenerate these values.
EOF
    chmod 0600 "${info_file}"

    log "initial panel settings generated"
    log "port: ${panel_port}"
    log "web base path: ${web_base_path}"
    log "username: ${username}"
    log "password: ${password}"
    log "saved initial settings to ${info_file} (mode 600)"
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
    capture_existing_state
    install_files
    initialize_secure_panel
    enable_service
    log "installed ${APP_NAME} to ${INSTALL_DIR}"
    log "use 'x-ui' for the original interactive menu, or 'x-ui settings' to inspect the panel"
}

main "$@"
