#!/bin/bash

# Skrip Instalasi Cerdas untuk Development Tools (fnm, Node, pnpm, Bun)
# Versi: 1.7
# Fitur:
# - Deteksi otomatis & instalasi dependensi (curl, unzip).
# - Memperbarui fnm, Node.js, pnpm, dan Bun ke versi terbaru.
# - Konfigurasi shell otomatis (.bashrc/.zshrc).
# - Memuat ulang shell otomatis di akhir untuk menerapkan perubahan.
# - Output berwarna yang informatif.

# Hentikan skrip jika terjadi kesalahan
set -euo pipefail

# Opsi default
NODE_CHANNEL="latest"

# --- Definisi Variabel & Fungsi Bantuan ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_BOLD='\033[1m'

print_header() {
    echo -e "\n${C_BOLD}${C_BLUE}===================================================${C_RESET}"
    echo -e "${C_BOLD}${C_BLUE} $1${C_RESET}"
    echo -e "${C_BOLD}${C_BLUE}===================================================${C_RESET}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

get_node_target_version() {
    local channel="$1"
    local node_index_json=""
    local target=""
    node_index_json="$(curl -fsSL "https://nodejs.org/dist/index.json")"

    if [ "$channel" = "lts" ]; then
        target="$(
            printf "%s" "$node_index_json" \
                | grep -m1 -E '"version":"v[0-9]+\.[0-9]+\.[0-9]+".*"lts":"[^"]+"' \
                | sed -E 's/.*"version":"v([^"]+)".*/\1/'
        )"
    else
        target="$(
            printf "%s" "$node_index_json" \
                | grep -m1 -oE '"version":"v[0-9]+\.[0-9]+\.[0-9]+"' \
                | sed -E 's/.*"v([^"]+)".*/\1/'
        )"
    fi

    printf "%s" "$target"
}

detect_shell_profile() {
    case "${SHELL:-}" in
        */zsh) echo "$HOME/.zshrc" ;;
        */bash) echo "$HOME/.bashrc" ;;
        *)
            if [ -n "${ZSH_VERSION:-}" ]; then
                echo "$HOME/.zshrc"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
    esac
}

show_help() {
    cat <<'EOF'
Penggunaan:
  bash install-dev-tools.sh [opsi]

Opsi:
  --latest   Instal Node.js stable terbaru (default)
  --lts      Instal Node.js LTS terbaru
  -h, --help Tampilkan bantuan
EOF
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --latest)
                NODE_CHANNEL="latest"
                ;;
            --lts)
                NODE_CHANNEL="lts"
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${C_RED}Argumen tidak dikenal: $1${C_RESET}"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# --- FUNGSI UTAMA ---

check_dependencies() {
    print_header "Langkah 0: Memeriksa Dependensi Sistem"
    DEPS=("curl" "unzip")

    for dep in "${DEPS[@]}"; do
        if command_exists "$dep"; then
            echo -e "${C_GREEN}Dependensi '$dep' sudah terinstal.${C_RESET}"
        else
            echo -e "${C_RED}Dependensi '$dep' tidak ditemukan.${C_RESET}"

            # Deteksi manajer paket dan coba instal
            local PKG_MANAGER=""
            if command_exists apt-get; then PKG_MANAGER="apt-get"; fi
            if command_exists dnf; then PKG_MANAGER="dnf"; fi
            if command_exists yum; then PKG_MANAGER="yum"; fi

            if [ -n "$PKG_MANAGER" ]; then
                echo -e "${C_YELLOW}Mencoba menginstal '$dep' via '$PKG_MANAGER' (mungkin memerlukan sudo)...${C_RESET}"
                if [ "$PKG_MANAGER" = "apt-get" ]; then
                    sudo apt-get update > /dev/null
                    sudo apt-get install -y "$dep"
                else
                    sudo "$PKG_MANAGER" install -y "$dep"
                fi
                echo -e "${C_GREEN}Dependensi '$dep' berhasil diinstal.${C_RESET}"
            else
                echo -e "${C_RED}Manajer paket tidak dikenal. Instal '$dep' secara manual lalu jalankan ulang skrip ini.${C_RESET}"
                exit 1
            fi
        fi
    done
}

install_fnm_and_node() {
    print_header "Langkah 1: Instalasi fnm, Node.js, dan pnpm"

    # Selalu jalankan installer fnm agar fnm ikut terbarui.
    echo -e "${C_YELLOW}Memasang/memperbarui fnm (Fast Node Manager)...${C_RESET}"
    curl -fsSL https://fnm.vercel.app/install -o fnm_install_script.sh
    bash ./fnm_install_script.sh
    rm ./fnm_install_script.sh
    echo -e "${C_GREEN}fnm siap digunakan.${C_RESET}"

    # Menyiapkan lingkungan fnm untuk sesi ini
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env --shell bash)"

    local TARGET_NODE_VERSION=""
    TARGET_NODE_VERSION="$(get_node_target_version "$NODE_CHANNEL")"
    if [ -z "$TARGET_NODE_VERSION" ]; then
        echo -e "${C_RED}Gagal menentukan versi target Node.js (${NODE_CHANNEL}).${C_RESET}"
        exit 1
    fi

    # Gunakan resolver bawaan fnm agar selalu mengambil rilis terbaru otomatis.
    echo -e "${C_YELLOW}Mode Node.js: ${NODE_CHANNEL}${C_RESET}"
    if [ "$NODE_CHANNEL" = "lts" ]; then
        echo -e "${C_YELLOW}Menginstal/menyetel Node.js LTS terbaru...${C_RESET}"
        fnm install --lts
    else
        echo -e "${C_YELLOW}Menginstal/menyetel Node.js stable terbaru...${C_RESET}"
        fnm install --latest
    fi

    # Aktifkan Node target untuk sesi ini tanpa tergantung multishell symlink.
    local NODE_INSTALL_BIN="$HOME/.local/share/fnm/node-versions/v${TARGET_NODE_VERSION}/installation/bin"
    if [ -x "${NODE_INSTALL_BIN}/node" ]; then
        export PATH="${NODE_INSTALL_BIN}:$PATH"
    else
        echo -e "${C_RED}Instalasi Node target tidak ditemukan di ${NODE_INSTALL_BIN}.${C_RESET}"
        exit 1
    fi

    # Set default secara idempoten. Beberapa versi fnm gagal overwrite alias default.
    fnm unalias default > /dev/null 2>&1 || true
    if ! fnm default "$TARGET_NODE_VERSION" > /dev/null 2>&1; then
        ln -sfn "$HOME/.local/share/fnm/node-versions/v${TARGET_NODE_VERSION}/installation" \
            "$HOME/.local/share/fnm/aliases/default"
    fi

    echo -e "${C_YELLOW}Verifikasi versi Node.js...${C_RESET}"
    echo -e "${C_GREEN}   -> $(node -v)${C_RESET}"

    # Pastikan corepack tersedia (beberapa distribusi Node tidak membundel corepack).
    if ! command_exists corepack; then
        echo -e "${C_YELLOW}corepack belum tersedia, menginstal via npm...${C_RESET}"
        npm install -g corepack
    fi

    # Aktifkan dan paksa pnpm ke versi terbaru.
    echo -e "${C_YELLOW}Mengaktifkan corepack dan memperbarui pnpm ke latest...${C_RESET}"
    corepack enable
    if ! corepack install --global pnpm@latest; then
        corepack prepare pnpm@latest --activate
    fi

    echo -e "${C_YELLOW}Verifikasi versi pnpm...${C_RESET}"
    echo -e "${C_GREEN}   -> $(pnpm -v)${C_RESET}"
}

install_bun() {
    print_header "Langkah 2: Instalasi Bun.js"

    # Menyiapkan PATH Bun untuk sesi ini (jika sudah terpasang).
    export PATH="$HOME/.bun/bin:$PATH"

    if command_exists bun; then
        echo -e "${C_YELLOW}Bun terdeteksi, memperbarui ke stable terbaru...${C_RESET}"
        bun upgrade --stable
    else
        echo -e "${C_YELLOW}Menginstal Bun.js...${C_RESET}"
        curl -fsSL https://bun.sh/install | bash
        export PATH="$HOME/.bun/bin:$PATH"
        echo -e "${C_GREEN}Instalasi Bun selesai.${C_RESET}"
        echo -e "${C_YELLOW}Memastikan Bun di versi stable terbaru...${C_RESET}"
        bun upgrade --stable
    fi

    echo -e "${C_YELLOW}Verifikasi versi Bun...${C_RESET}"
    echo -e "${C_GREEN}   -> $(bun -v)${C_RESET}"
}

configure_shell() {
    print_header "Langkah 3: Konfigurasi Shell Otomatis"

    # Deteksi profil shell dari shell login user.
    local SHELL_PROFILE=""
    SHELL_PROFILE="$(detect_shell_profile)"

    if [ -z "$SHELL_PROFILE" ]; then
        echo -e "${C_YELLOW}Tidak dapat mendeteksi file profil shell (.bashrc atau .zshrc). Harap konfigurasi PATH secara manual.${C_RESET}"
        return
    fi

    echo -e "File profil shell terdeteksi: ${C_BOLD}${SHELL_PROFILE}${C_RESET}"

    # Tambahkan konfigurasi fnm jika belum ada
    if ! grep -q 'fnm env' "$SHELL_PROFILE"; then
        echo -e "${C_YELLOW}Menambahkan konfigurasi fnm ke ${SHELL_PROFILE}...${C_RESET}"
        cat >> "$SHELL_PROFILE" <<'EOF'

# Konfigurasi untuk fnm (Fast Node Manager)
export PATH="$HOME/.local/share/fnm:$PATH"
if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$(fnm env --shell zsh)"
else
    eval "$(fnm env --shell bash)"
fi
EOF
    else
        echo -e "${C_GREEN}Konfigurasi fnm sudah ada di ${SHELL_PROFILE}.${C_RESET}"
    fi

    # Tambahkan konfigurasi Bun jika belum ada
    if ! grep -q '.bun/bin' "$SHELL_PROFILE"; then
        echo -e "${C_YELLOW}Menambahkan konfigurasi Bun ke ${SHELL_PROFILE}...${C_RESET}"
        echo -e '\n# Konfigurasi untuk Bun.js\nexport PATH="$HOME/.bun/bin:$PATH"' >> "$SHELL_PROFILE"
    else
        echo -e "${C_GREEN}Konfigurasi Bun sudah ada di ${SHELL_PROFILE}.${C_RESET}"
    fi
}

# --- EKSEKUSI SKRIP UTAMA ---
main() {
    parse_args "$@"
    check_dependencies
    install_fnm_and_node
    install_bun
    configure_shell

    print_header "Instalasi Selesai"
    echo -e "${C_GREEN}Semua alat pengembangan telah berhasil diinstal dan dikonfigurasi ke versi terbaru.${C_RESET}"

    # --- Langkah Terakhir: Muat Ulang Shell ---
    local CURRENT_SHELL_NAME=""
    local SHELL_PROFILE=""
    SHELL_PROFILE="$(detect_shell_profile)"
    CURRENT_SHELL_NAME="$(basename "${SHELL:-}")"
    if [ "$CURRENT_SHELL_NAME" != "bash" ] && [ "$CURRENT_SHELL_NAME" != "zsh" ]; then
        CURRENT_SHELL_NAME=""
    fi

    if [ -n "$CURRENT_SHELL_NAME" ]; then
        echo -e "${C_YELLOW}PENTING: Shell akan dimuat ulang interaktif untuk menerapkan semua perubahan.${C_RESET}"
        echo -e "${C_YELLOW}Silakan tunggu...${C_RESET}"
        exec "$CURRENT_SHELL_NAME" -i
    else
        echo -e "${C_YELLOW}PENTING: Untuk menerapkan perubahan permanen, buka terminal baru,${C_RESET}"
        echo -e "${C_YELLOW}atau jalankan perintah berikut di terminal saat ini:${C_RESET}"
        echo -e "   ${C_BOLD}source ${SHELL_PROFILE:-"$HOME/.bashrc atau $HOME/.zshrc"}${C_RESET}"
    fi
}

# Jalankan fungsi utama
main "$@"
