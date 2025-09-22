#!/bin/bash

# ==============================================================================
# Skrip Instalasi Go (Golang) - Versi Final Otomatis
#
# Perbaikan v3: Membersihkan karakter kutip dari deteksi versi untuk
#               memastikan nama file unduhan selalu benar.
# ==============================================================================

# 1. Cek hak akses dan minta sudo jika perlu (Logika Otomatis)
if [ "$(id -u)" -ne 0 ]; then
    echo "Skrip ini memerlukan hak akses root (sudo) untuk instalasi."
    echo "Mencoba menjalankan ulang skrip dengan sudo..."
    sudo bash "$0" "$@"
    exit $?
fi

# Mulai dari sini, skrip sudah pasti berjalan dengan hak akses root (sudo)
echo "✅ Hak akses Sudo diterima. Memulai proses instalasi..."
echo ""

# Hentikan eksekusi jika ada perintah yang gagal
set -euo pipefail
umask 022

# 2. Cek dependensi yang dibutuhkan (wget atau curl)
echo " Mengecek dependensi (wget atau curl)..."
DOWNLOADER=""
if command -v wget &> /dev/null; then
    DOWNLOADER="wget"
elif command -v curl &> /dev/null; then
    DOWNLOADER="curl"
else
    echo "❌ Error: 'wget' atau 'curl' tidak ditemukan."
    echo "   Silakan install salah satunya. Contoh di Debian/Ubuntu:"
    echo "   sudo apt update && sudo apt install wget"
    exit 1
fi
echo "✅ Siap menggunakan '${DOWNLOADER}'."
echo ""

fetch_to_stdout() {
    local url="$1"
    if [ "$DOWNLOADER" = "wget" ]; then
        wget -qO- "$url"
    else
        curl -fsSL "$url"
    fi
}

fetch_to_file() {
    local url="$1"; local out="$2"
    if [ "$DOWNLOADER" = "wget" ]; then
        wget -q -O "$out" "$url"
    else
        curl -fL --progress-bar -o "$out" "$url"
    fi
}

# 3. Dapatkan versi Go terbaru & arsitektur sistem
echo " Mencari versi Go terbaru..."
LATEST_GO_VERSION=""
if LATEST_JSON=$(fetch_to_stdout "https://go.dev/dl/?mode=json" 2>/dev/null); then
    LATEST_GO_VERSION=$(printf "%s" "$LATEST_JSON" | grep -oE '"version"\s*:\s*"go[0-9]+\.[0-9]+(\.[0-9]+)?"' | head -n 1 | sed -E 's/.*"go([0-9]+\.[0-9]+(\.[0-9]+)?)"/\1/')
fi

if [ -z "$LATEST_GO_VERSION" ]; then
    echo "❌ Gagal mendapatkan versi Go terbaru. Periksa koneksi internet Anda."
    exit 1
fi
echo "✅ Versi Go terbaru yang ditemukan: ${LATEST_GO_VERSION}"

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) GO_ARCH="amd64" ;;
    i686|i386) GO_ARCH="386" ;;
    aarch64) GO_ARCH="arm64" ;;
    armv7l|armv6l) GO_ARCH="armv6l" ;;
    ppc64le) GO_ARCH="ppc64le" ;;
    s390x) GO_ARCH="s390x" ;;
    riscv64) GO_ARCH="riscv64" ;;
    *)
        echo "❌ Arsitektur sistem tidak didukung: ${ARCH}"
        exit 1
        ;;
esac
echo "✅ Arsitektur sistem Anda: ${GO_ARCH}"
echo ""

# 4. Proses Unduh dan Instalasi (tmp dir + checksum + skip jika sama)
GO_FILENAME="go${LATEST_GO_VERSION}.linux-${GO_ARCH}.tar.gz"
DOWNLOAD_URL="https://dl.google.com/go/${GO_FILENAME}"
CHECKSUM_URL="${DOWNLOAD_URL}.sha256"

TMP_DIR=$(mktemp -d)
cleanup() { rm -rf "$TMP_DIR" >/dev/null 2>&1 || true; }
trap cleanup EXIT

ARCHIVE_PATH="${TMP_DIR}/${GO_FILENAME}"
CHECKSUM_PATH="${TMP_DIR}/${GO_FILENAME}.sha256"

echo "⏬ Mengunduh arsip: ${GO_FILENAME}"
fetch_to_file "${DOWNLOAD_URL}" "${ARCHIVE_PATH}"
echo "⏬ Mengunduh checksum: ${GO_FILENAME}.sha256"
if ! fetch_to_file "${CHECKSUM_URL}" "${CHECKSUM_PATH}"; then
    echo "⚠️  Gagal mengunduh checksum resmi. Melanjutkan tanpa verifikasi checksum."
else
    echo " Memverifikasi checksum SHA256..."
    EXPECTED_SHA=$(cut -d' ' -f1 "${CHECKSUM_PATH}" | tr -d '\n' || true)
    ACTUAL_SHA=$(sha256sum "${ARCHIVE_PATH}" | awk '{print $1}')
    if [ -n "${EXPECTED_SHA}" ] && [ "${EXPECTED_SHA}" != "${ACTUAL_SHA}" ]; then
        echo "❌ Checksum tidak cocok. Diharapkan: ${EXPECTED_SHA}, Aktual: ${ACTUAL_SHA}"
        exit 1
    fi
    echo "✅ Checksum valid."
fi
echo "✅ Unduhan selesai."
echo ""

CURRENT_GO_VER=""
if [ -x "/usr/local/go/bin/go" ]; then
    CURRENT_GO_VER=$(/usr/local/go/bin/go version 2>/dev/null | awk '{print $3}' | sed 's/go//')
fi

if [ "${CURRENT_GO_VER}" = "${LATEST_GO_VERSION}" ]; then
    echo "✅ Versi Go yang terpasang sudah yang terbaru (go${CURRENT_GO_VER}). Melewati instalasi."
else
    echo " Membersihkan instalasi Go lama di /usr/local/go (jika ada)..."
    rm -rf /usr/local/go
    echo "✅ Direktori lama dibersihkan."
    echo ""

    echo " Mengekstrak file ke /usr/local..."
    tar -C /usr/local -xzf "${ARCHIVE_PATH}"
    echo "✅ Ekstraksi selesai."
    echo ""
fi

echo "️ Pembersihan direktori sementara..."
# Trap akan membersihkan TMP_DIR
echo "✅ Selesai pembersihan."
echo ""

# 5. Atur variabel lingkungan (PATH + GOPATH/bin) secara idempoten
REAL_USER=$(logname 2>/dev/null || echo ${SUDO_USER:-${USER}})
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SHELL_PROFILE=""

if [ -f "$USER_HOME/.zshrc" ]; then
    SHELL_PROFILE="$USER_HOME/.zshrc"
elif [ -f "$USER_HOME/.bashrc" ]; then
    SHELL_PROFILE="$USER_HOME/.bashrc"
fi

ensure_line_in_file() {
    local line="$1"; local file="$2"
    grep -Fqx "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

if [ -n "$SHELL_PROFILE" ] && [ -f "$SHELL_PROFILE" ]; then
    echo " Mengkonfigurasi PATH di ${SHELL_PROFILE}"
    ensure_line_in_file '' "$SHELL_PROFILE"
    ensure_line_in_file '# Tambahkan Go ke PATH' "$SHELL_PROFILE"
    ensure_line_in_file 'export PATH=$PATH:/usr/local/go/bin' "$SHELL_PROFILE"
    ensure_line_in_file 'export GOPATH=$HOME/go' "$SHELL_PROFILE"
    ensure_line_in_file 'export PATH=$PATH:$GOPATH/bin' "$SHELL_PROFILE"
    chown "$REAL_USER":"$REAL_USER" "$SHELL_PROFILE"
else
    SHELL_PROFILE="/etc/profile.d/go.sh"
    {
        echo 'export PATH=$PATH:/usr/local/go/bin'
        echo 'export GOPATH=/root/go'
        echo 'export PATH=$PATH:$GOPATH/bin'
    } > "$SHELL_PROFILE"
    echo " Mengkonfigurasi PATH untuk semua pengguna di ${SHELL_PROFILE}"
fi

# 6. Tampilkan pesan akhir
echo "================================================================"
echo "   SELAMAT! INSTALASI GO BERHASIL TERSIMPAN!            "
echo "================================================================"
echo ""
echo "Verifikasi Versi Go:"
/usr/local/go/bin/go version || true
echo ""
echo "⚠️  TINDAKAN DIPERLUKAN:"
echo "   Untuk mulai menggunakan Go, muat ulang shell Anda dengan:"
echo "   1. Menutup dan membuka kembali terminal, ATAU"
echo "   2. Menjalankan perintah yang sesuai di bawah ini:"
if [[ "$SHELL_PROFILE" == *".zshrc"* ]]; then
    echo "      source $USER_HOME/.zshrc"
elif [[ "$SHELL_PROFILE" == *".bashrc"* ]]; then
    echo "      source $USER_HOME/.bashrc"
else
    echo "      (Silakan logout dan login kembali untuk menerapkan perubahan sistem)"
fi
echo "================================================================"
