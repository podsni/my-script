#!/bin/bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: setup_sudo_nopasswd.sh [-u username] [-y]

Options:
  -u USERNAME  Username target untuk akses sudo tanpa password
  -y           Skip konfirmasi interaktif
  -h           Tampilkan bantuan
EOF
}

require_root() {
    if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
        echo "ERROR: Script ini harus dijalankan sebagai root." >&2
        exit 1
    fi
}

detect_default_user() {
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        printf '%s\n' "${SUDO_USER}"
        return
    fi

    if command -v logname >/dev/null 2>&1; then
        local logged_user
        logged_user="$(logname 2>/dev/null || true)"
        if [[ -n "${logged_user}" && "${logged_user}" != "root" ]]; then
            printf '%s\n' "${logged_user}"
            return
        fi
    fi

    printf '%s\n' ""
}

verify_sudo_access() {
    local target_user="$1"
    echo "Menjalankan verifikasi: sudo -l -U ${target_user}"
    if sudo -l -U "${target_user}"; then
        echo "Verifikasi sukses untuk user '${target_user}'."
    else
        echo "ERROR: Verifikasi sudo gagal untuk user '${target_user}'." >&2
        exit 5
    fi
}

username=""
assume_yes=0

while getopts ":u:yh" opt; do
    case "${opt}" in
        u) username="${OPTARG}" ;;
        y) assume_yes=1 ;;
        h)
            usage
            exit 0
            ;;
        :)
            echo "ERROR: Opsi -${OPTARG} membutuhkan nilai." >&2
            usage
            exit 2
            ;;
        \?)
            echo "ERROR: Opsi tidak dikenal -${OPTARG}" >&2
            usage
            exit 2
            ;;
    esac
done

require_root

if [[ -z "${username}" ]]; then
    default_user="$(detect_default_user)"
    if [[ -n "${default_user}" ]]; then
        read -r -p "Masukkan username target [${default_user}]: " input_user
        username="${input_user:-$default_user}"
    else
        read -r -p "Masukkan username target: " username
    fi
fi

if [[ -z "${username}" ]]; then
    echo "ERROR: Username tidak boleh kosong." >&2
    exit 2
fi

if [[ "${username}" == "root" ]]; then
    echo "ERROR: User root tidak perlu aturan sudo NOPASSWD." >&2
    exit 2
fi

if ! id "${username}" >/dev/null 2>&1; then
    echo "ERROR: User '${username}' tidak ditemukan." >&2
    exit 2
fi

sudoers_file="/etc/sudoers.d/90-${username}-nopasswd"
tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT
rule="${username} ALL=(ALL:ALL) NOPASSWD:ALL"
printf '%s\n' "${rule}" >"${tmpfile}"

if ! visudo -cf "${tmpfile}" >/dev/null; then
    echo "ERROR: Aturan sudoers gagal divalidasi." >&2
    exit 4
fi

if [[ ${assume_yes} -ne 1 ]]; then
    echo ""
    echo "Peringatan: ini memberikan akses sudo penuh tanpa password ke '${username}'."
    read -r -p "Lanjutkan? [y/N]: " confirm
    confirm="${confirm,,}"
    if [[ "${confirm}" != "y" && "${confirm}" != "yes" ]]; then
        echo "Operasi dibatalkan."
        exit 3
    fi
fi

if [[ -f "${sudoers_file}" ]] && cmp -s "${tmpfile}" "${sudoers_file}"; then
    echo "Info: Aturan sudoers untuk '${username}' sudah sesuai, tidak ada perubahan."
    verify_sudo_access "${username}"
    exit 0
fi

install -m 0440 "${tmpfile}" "${sudoers_file}"
echo "Sukses: '${username}' sekarang bisa sudo tanpa password."
verify_sudo_access "${username}"
