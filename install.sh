#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

# Check OS and set release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Failed to check the system OS, please contact the author!" >&2
    exit 1
fi
echo "The OS release is: $release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${green}Unsupported CPU architecture! ${plain}" && rm -f install.sh && exit 1 ;;
    esac
}

echo "arch: $(arch)"

install_dependencies() {
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -y -q wget curl tar tzdata cron
        ;;
    centos | almalinux | rocky | ol)
        yum -y update && yum install -y -q wget curl tar tzdata cronie
        ;;
    fedora | amzn)
        dnf -y update && dnf install -y -q wget curl tar tzdata cronie
        ;;
    arch | manjaro | parch)
        pacman -Syu && pacman -Syu --noconfirm wget curl tar tzdata cronie
        ;;
    opensuse-tumbleweed)
        zypper refresh && zypper -q install -y wget curl tar timezone cron
        ;;
    *)
        apt-get update && apt install -y -q wget curl tar tzdata cron
        ;;
    esac
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

config_after_install() {
    local existing_username=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'username: .+' | awk '{print $2}')
    local existing_password=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'password: .+' | awk '{print $2}')
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')

    if [[ ${#existing_webBasePath} -lt 4 ]]; then
        if [[ "$existing_username" == "admin" && "$existing_password" == "admin" ]]; then
            local config_webBasePath=$(gen_random_string 15)
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            read -p "Would you like to customize the Panel Port settings? (If not, random port will be applied) [y/n]: " config_confirm
            if [[ "${config_confirm}" == "y" || "${config_confirm}" == "Y" ]]; then
                read -p "Please set up the panel port: " config_port
                echo -e "${yellow}Your Panel Port is: ${config_port}${plain}"
            else
                local config_port=$(shuf -i 1024-62000 -n 1)
                echo -e "${yellow}Generated random port: ${config_port}${plain}"
            fi

            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}" -port "${config_port}" -webBasePath "${config_webBasePath}"
            echo -e "This is a fresh installation, generating random login info for security concerns:"
            echo -e "###############################################"
            echo -e "${green}Username: ${config_username}${plain}"
            echo -e "${green}Password: ${config_password}${plain}"
            echo -e "${green}Port: ${config_port}${plain}"
            echo -e "${green}WebBasePath: ${config_webBasePath}${plain}"
            echo -e "###############################################"
            echo -e "${yellow}If you forgot your login info, you can type 'x-ui settings' to check${plain}"
        else
            local config_webBasePath=$(gen_random_string 15)
            echo -e "${yellow}WebBasePath is missing or too short. Generating a new one...${plain}"
            /usr/local/x-ui/x-ui setting -webBasePath "${config_webBasePath}"
            echo -e "${green}New WebBasePath: ${config_webBasePath}${plain}"
        fi
    else
        if [[ "$existing_username" == "admin" && "$existing_password" == "admin" ]]; then
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            echo -e "${yellow}Default credentials detected. Security update required...${plain}"
            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}"
            echo -e "Generated new random login credentials:"
            echo -e "###############################################"
            echo -e "${green}Username: ${config_username}${plain}"
            echo -e "${green}Password: ${config_password}${plain}"
            echo -e "###############################################"
            echo -e "${yellow}If you forgot your login info, you can type 'x-ui settings' to check${plain}"
        else
            echo -e "${green}Username, Password, and WebBasePath are properly set. Exiting...${plain}"
        fi
    fi

    /usr/local/x-ui/x-ui migrate
}


PROJECT_NAME="x-ui-recovered"
REPO_URL="https://github.com/kelenetwork/x-ui-recovered"
DEFAULT_BRANCH="main"
TARBALL_URL="${REPO_URL}/archive/refs/heads/${DEFAULT_BRANCH}.tar.gz"
RECOVERED_REPO_DIR=""
RECOVERED_TMPDIR=""

has_recovered_repo() {
    local dir="$1"
    [[ -x "${dir}/recovered/usr-local-x-ui/x-ui" ]] || return 1
    [[ -x "${dir}/recovered/usr-local-x-ui/bin/xray-linux-amd64" ]] || return 1
    [[ -f "${dir}/recovered/usr-bin/x-ui" ]] || return 1
    [[ -f "${dir}/systemd/x-ui.service" ]] || return 1
}

cleanup_recovered_tmpdir() {
    if [[ -n "${RECOVERED_TMPDIR}" && -f "${RECOVERED_TMPDIR}/.x-ui-recovered-install" ]]; then
        rm -rf "${RECOVERED_TMPDIR}"
    fi
}

ensure_recovered_repo() {
    local script_source="${BASH_SOURCE[0]:-}"
    local script_dir=""

    if [[ -n "${script_source}" && -f "${script_source}" ]]; then
        script_dir="$(cd -- "$(dirname -- "${script_source}")" 2>/dev/null && pwd -P)" || script_dir=""
        if [[ -n "${script_dir}" ]] && has_recovered_repo "${script_dir}"; then
            RECOVERED_REPO_DIR="${script_dir}"
            return 0
        fi
    fi

    if has_recovered_repo "$(pwd -P)"; then
        RECOVERED_REPO_DIR="$(pwd -P)"
        return 0
    fi

    command -v tar >/dev/null 2>&1 || { echo -e "${red}tar is required to unpack recovered package${plain}"; exit 1; }
    command -v mktemp >/dev/null 2>&1 || { echo -e "${red}mktemp is required to create temporary directory${plain}"; exit 1; }

    RECOVERED_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/x-ui-recovered.XXXXXXXXXX")"
    touch "${RECOVERED_TMPDIR}/.x-ui-recovered-install"
    trap cleanup_recovered_tmpdir EXIT

    echo -e "Got x-ui recovered package source: ${REPO_URL}, downloading..."
    if command -v curl >/dev/null 2>&1; then
        curl -fL "${TARBALL_URL}" -o "${RECOVERED_TMPDIR}/source.tar.gz"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "${RECOVERED_TMPDIR}/source.tar.gz" "${TARBALL_URL}"
    else
        echo -e "${red}curl or wget is required to download recovered package${plain}"
        exit 1
    fi

    tar -xzf "${RECOVERED_TMPDIR}/source.tar.gz" -C "${RECOVERED_TMPDIR}"
    RECOVERED_REPO_DIR="${RECOVERED_TMPDIR}/${PROJECT_NAME}-${DEFAULT_BRANCH}"
    if ! has_recovered_repo "${RECOVERED_REPO_DIR}"; then
        echo -e "${red}Downloaded recovered package is incomplete${plain}"
        exit 1
    fi
}

install_x-ui() {
    # checks if the installation backup dir exist. if existed then ask user if they want to restore it else continue installation.
    if [[ -e /usr/local/x-ui-backup/ ]]; then
        read -p "Failed installation detected. Do you want to restore previously installed version? [y/n]? ": restore_confirm
        if [[ "${restore_confirm}" == "y" || "${restore_confirm}" == "Y" ]]; then
            systemctl stop x-ui >/dev/null 2>&1 || true
            if [[ -f /usr/local/x-ui-backup/x-ui.db ]]; then
                mkdir -p /etc/x-ui/
                mv /usr/local/x-ui-backup/x-ui.db /etc/x-ui/ -f
            fi
            rm -rf /usr/local/x-ui/
            mv /usr/local/x-ui-backup/ /usr/local/x-ui/ -f
            systemctl start x-ui >/dev/null 2>&1 || true
            echo -e "${green}previous installed x-ui restored successfully${plain}, it is up and running now..."
            exit 0
        else
            echo -e "Continuing installing x-ui ..."
        fi
    fi

    cd /usr/local/

    if [[ $(arch) != "amd64" ]]; then
        echo -e "${red}This recovered repository currently ships Linux amd64 binaries only.${plain}"
        exit 1
    fi

    ensure_recovered_repo

    last_version="1.10.2"
    if [ $# != 0 ]; then
        echo -e "${yellow}Version argument '$1' was provided, but this recovered repository only ships x-ui ${last_version}.${plain}"
    fi
    echo -e "Got x-ui recovered version: ${last_version}, beginning the installation..."

    if [[ -e /usr/local/x-ui/ ]]; then
        systemctl stop x-ui >/dev/null 2>&1 || true
        rm -rf /usr/local/x-ui-backup/
        mv /usr/local/x-ui/ /usr/local/x-ui-backup/ -f
        if [[ -f /etc/x-ui/x-ui.db ]]; then
            cp /etc/x-ui/x-ui.db /usr/local/x-ui-backup/ -f
        fi
    fi

    mkdir -p /usr/local/x-ui/
    cp -a "${RECOVERED_REPO_DIR}/recovered/usr-local-x-ui/." /usr/local/x-ui/
    rm -f /usr/local/x-ui/bin/config.json
    mkdir -p /etc/x-ui/

    cd /usr/local/x-ui
    chmod +x x-ui
    chmod +x x-ui bin/xray-linux-amd64
    cp -f "${RECOVERED_REPO_DIR}/systemd/x-ui.service" /etc/systemd/system/x-ui.service
    install -m 0755 "${RECOVERED_REPO_DIR}/recovered/usr-bin/x-ui" /usr/bin/x-ui
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install
    rm /usr/local/x-ui-backup/ -rf
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui ${last_version}${plain} installation finished, it is up and running now..."
    echo -e ""
    echo -e "You may access the Panel with following URL(s):${yellow}"
    /usr/local/x-ui/x-ui uri
    echo -e "${plain}"
    echo "X-UI Control Menu Usage"
    echo "------------------------------------------"
    echo "SUBCOMMANDS:"
    echo "x-ui              - Admin Management Script"
    echo "x-ui start        - Start"
    echo "x-ui stop         - Stop"
    echo "x-ui restart      - Restart"
    echo "x-ui status       - Current Status"
    echo "x-ui settings     - Current Settings"
    echo "x-ui enable       - Enable Autostart on OS Startup"
    echo "x-ui disable      - Disable Autostart on OS Startup"
    echo "x-ui log          - Check Logs"
    echo "x-ui update       - Update"
    echo "x-ui install      - Install"
    echo "x-ui uninstall    - Uninstall"
    echo "x-ui help         - Control Menu Usage"
    echo "------------------------------------------"
}

echo -e "${green}Running...${plain}"
install_dependencies
install_x-ui $1
