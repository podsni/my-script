#!/usr/bin/env bash
# Installer Python + uv untuk Linux

set -euo pipefail

need_cmd() { command -v "$1" >/dev/null 2>&1; }
log() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
err() { printf "\033[1;31mxx\033[0m %s\n" "$*" >&2; exit 1; }

as_root() {
    if [ "${EUID:-$(id -u)}" -ne 0 ]; then
        if need_cmd sudo; then
            sudo "$@"
        else
            err "Butuh hak root (sudo) untuk instal paket sistem."
        fi
    else
        "$@"
    fi
}

run_as_target_user() {
    local cmd="$1"
    if [ "$(id -un)" = "$TARGET_USER" ]; then
        bash -lc "$cmd"
        return
    fi

    if need_cmd sudo; then
        sudo -H -u "$TARGET_USER" bash -lc "$cmd"
    else
        su - "$TARGET_USER" -c "$cmd"
    fi
}

detect_pkg_mgr() {
    if need_cmd apt-get; then
        PKG_MGR="apt"
    elif need_cmd dnf; then
        PKG_MGR="dnf"
    elif need_cmd yum; then
        PKG_MGR="yum"
    elif need_cmd pacman; then
        PKG_MGR="pacman"
    elif need_cmd zypper; then
        PKG_MGR="zypper"
    elif need_cmd apk; then
        PKG_MGR="apk"
    else
        err "Package manager tidak didukung."
    fi
}

install_system_python() {
    log "Install dependensi sistem dan Python..."
    case "$PKG_MGR" in
        apt)
            as_root apt-get update -y
            as_root apt-get install -y curl ca-certificates python3 python3-pip python3-venv
            ;;
        dnf)
            as_root dnf install -y curl ca-certificates python3 python3-pip
            ;;
        yum)
            as_root yum install -y curl ca-certificates python3 python3-pip
            ;;
        pacman)
            as_root pacman -Sy --noconfirm curl ca-certificates python python-pip
            ;;
        zypper)
            as_root zypper --non-interactive install curl ca-certificates python3 python3-pip
            ;;
        apk)
            as_root apk add --no-cache curl ca-certificates python3 py3-pip
            ;;
    esac
}

ensure_python_command() {
    if need_cmd python; then
        return
    fi

    if ! need_cmd python3; then
        err "python3 tidak ditemukan setelah instalasi paket."
    fi

    log "Menyiapkan command 'python' agar mengarah ke python3..."
    case "$PKG_MGR" in
        apt)
            # Pada Debian/Ubuntu, paket ini membuat /usr/bin/python -> python3
            as_root apt-get install -y python-is-python3 || true
            ;;
    esac

    if ! need_cmd python; then
        as_root ln -sfn "$(command -v python3)" /usr/local/bin/python
    fi
}

install_uv() {
    if run_as_target_user "export PATH='${TARGET_HOME}/.local/bin:\$PATH'; command -v uv >/dev/null 2>&1"; then
        log "uv sudah terpasang, menjalankan update..."
        run_as_target_user "export PATH='${TARGET_HOME}/.local/bin:\$PATH'; uv self update || true"
        return
    fi

    log "Install uv untuk user '${TARGET_USER}'..."
    run_as_target_user "curl -LsSf https://astral.sh/uv/install.sh | sh"
}

detect_latest_python_version_with_uv() {
    local latest
    latest="$(
        run_as_target_user "export PATH='${TARGET_HOME}/.local/bin:\$PATH'; uv python list" \
            | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' \
            | sort -V \
            | tail -n 1
    )"

    if [ -z "${latest}" ]; then
        err "Gagal mendeteksi versi Python terbaru dari uv."
    fi

    printf '%s\n' "${latest}"
}

detect_latest_installed_python_version_with_uv() {
    local latest_installed
    latest_installed="$(
        run_as_target_user "export PATH='${TARGET_HOME}/.local/bin:\$PATH'; uv python list --only-installed || true" \
            | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' \
            | sort -V \
            | tail -n 1
    )"

    printf '%s\n' "${latest_installed:-}"
}

install_latest_python_with_uv() {
    local installed_latest
    local latest_python

    latest_python="$(detect_latest_python_version_with_uv)"
    installed_latest="$(detect_latest_installed_python_version_with_uv)"

    if [ -n "${installed_latest}" ] && [ "${installed_latest}" = "${latest_python}" ]; then
        log "Python terbaru (${latest_python}) sudah terpasang, melewati instalasi."
        return
    fi

    log "Python terbaru terdeteksi: ${latest_python}"
    if [ -n "${installed_latest}" ]; then
        log "Python terpasang saat ini: ${installed_latest} (akan update ke ${latest_python})"
    fi
    log "Install/Update Python ${latest_python} via uv..."
    run_as_target_user "export PATH='${TARGET_HOME}/.local/bin:\$PATH'; uv self update || true; uv python install ${latest_python}"
}

verify_installation() {
    log "Verifikasi instalasi..."
    python3 --version
    run_as_target_user "export PATH='${TARGET_HOME}/.local/bin:\$PATH'; uv --version"
    run_as_target_user "export PATH='${TARGET_HOME}/.local/bin:\$PATH'; uv python list --only-installed || uv python list"
}

main() {
    TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"
    TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
    [ -n "$TARGET_HOME" ] || err "Gagal mendeteksi HOME untuk user '${TARGET_USER}'."

    detect_pkg_mgr
    install_system_python
    ensure_python_command
    install_uv
    install_latest_python_with_uv
    verify_installation

    log "Selesai. Jika uv belum terbaca di shell, jalankan:"
    echo "    export PATH=\"${TARGET_HOME}/.local/bin:\$PATH\""
}

main "$@"
