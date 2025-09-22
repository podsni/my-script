#!/bin/bash

# ==============================================================================
# Skrip Instalasi Odin Programming Language - Versi Otomatis
#
# Skrip ini akan mengunduh dan menginstal Odin compiler terbaru
# dengan konfigurasi PATH otomatis untuk semua pengguna.
# ==============================================================================

# 1. Cek hak akses dan minta sudo jika perlu (Logika Otomatis)
if [ "$(id -u)" -ne 0 ]; then
    echo "Skrip ini memerlukan hak akses root (sudo) untuk instalasi."
    echo "Mencoba menjalankan ulang skrip dengan sudo..."
    sudo bash "$0" "$@"
    exit $?
fi

# Mulai dari sini, skrip sudah pasti berjalan dengan hak akses root (sudo)
echo "✅ Hak akses Sudo diterima. Memulai proses instalasi Odin..."
echo ""

# Hentikan eksekusi jika ada perintah yang gagal
set -e

# 2. Cek dependensi yang dibutuhkan (curl lebih disukai untuk GitHub redirects)
echo "🔍 Mengecek dependensi (curl atau wget)..."
DOWNLOADER=""
if command -v curl &> /dev/null; then
    DOWNLOADER="curl"
elif command -v wget &> /dev/null; then
    DOWNLOADER="wget"
else
    echo "❌ Error: 'curl' atau 'wget' tidak ditemukan."
    echo "   Silakan install salah satunya. Contoh di Debian/Ubuntu:"
    echo "   sudo apt update && sudo apt install curl"
    exit 1
fi
echo "✅ Siap mengunduh menggunakan '${DOWNLOADER}'."

# Cek dan install jq untuk parsing JSON yang lebih baik
if ! command -v jq &> /dev/null; then
    echo "📦 Menginstal jq untuk parsing JSON yang lebih baik..."
    apt update && apt install -y jq
fi

# Cek dan install clang (dependency untuk Odin compiler)
if ! command -v clang &> /dev/null; then
    echo "📦 Menginstal clang (dependency untuk Odin compiler)..."
    apt update && apt install -y clang
fi
echo ""

# 3. Dapatkan versi Odin terbaru & arsitektur sistem
echo "🔍 Mencari versi Odin terbaru..."
# Menggunakan GitHub API untuk mendapatkan release terbaru dengan fallback
LATEST_ODIN_VERSION=""
if command -v jq &> /dev/null; then
    # Jika jq tersedia, gunakan untuk parsing JSON yang lebih reliable
    LATEST_ODIN_VERSION=$(curl -s "https://api.github.com/repos/odin-lang/Odin/releases/latest" | jq -r '.tag_name')
else
    # Fallback tanpa jq
    LATEST_ODIN_VERSION=$(curl -s "https://api.github.com/repos/odin-lang/Odin/releases/latest" | grep -oP '"tag_name":\s*"\K[^"]*' | head -n 1)
fi

# Jika masih gagal, gunakan versi yang diketahui stabil
if [ -z "$LATEST_ODIN_VERSION" ]; then
    echo "⚠️ Tidak dapat mengambil versi terbaru dari GitHub API."
    echo "🔍 Menggunakan versi stabil yang diketahui: 0.4.0"
    LATEST_ODIN_VERSION="0.4.0"
fi
echo "✅ Versi Odin terbaru yang ditemukan: ${LATEST_ODIN_VERSION}"

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ODIN_ARCH="linux-amd64" ;;
    aarch64) ODIN_ARCH="linux-arm64" ;;
    *)
        echo "❌ Arsitektur sistem tidak didukung: ${ARCH}"
        echo "   Odin saat ini hanya mendukung x86_64 dan aarch64"
        exit 1
        ;;
esac
echo "✅ Arsitektur sistem Anda: ${ODIN_ARCH}"
echo ""

# 4. Proses Unduh dan Instalasi
# Format filename yang benar berdasarkan GitHub releases
if [[ "$LATEST_ODIN_VERSION" == *"dev"* ]]; then
    ODIN_FILENAME="odin-${ODIN_ARCH}-${LATEST_ODIN_VERSION}.zip"
    DOWNLOAD_URL="https://github.com/odin-lang/Odin/releases/download/${LATEST_ODIN_VERSION}/${ODIN_FILENAME}"
else
    ODIN_FILENAME="odin-${ODIN_ARCH}-${LATEST_ODIN_VERSION}.zip"
    DOWNLOAD_URL="https://github.com/odin-lang/Odin/releases/download/v${LATEST_ODIN_VERSION}/${ODIN_FILENAME}"
fi

echo "⏬ Mengunduh ${ODIN_FILENAME}..."
if [ "$DOWNLOADER" = "wget" ]; then
    wget -q --show-progress --max-redirect=10 -O "${ODIN_FILENAME}" "${DOWNLOAD_URL}"
else # Menggunakan curl
    curl -L --progress-bar --max-redirs 10 -o "${ODIN_FILENAME}" "${DOWNLOAD_URL}"
fi
echo "✅ Unduhan selesai."
echo ""

# Cek apakah unzip tersedia
if ! command -v unzip &> /dev/null; then
    echo "📦 Menginstal unzip..."
    apt update && apt install -y unzip
fi

echo "🧹 Membersihkan instalasi Odin lama di /opt/odin (jika ada)..."
rm -rf /opt/odin
echo "✅ Direktori lama dibersihkan."
echo ""

echo "📦 Mengekstrak file ke /opt/odin..."
mkdir -p /opt/odin
unzip -q "${ODIN_FILENAME}" -d /opt/odin

# Jika ada dist.tar.gz, ekstrak juga
if [ -f "/opt/odin/dist.tar.gz" ]; then
    echo "📦 Mengekstrak dist.tar.gz..."
    tar -C /opt/odin -xzf /opt/odin/dist.tar.gz
    rm /opt/odin/dist.tar.gz
fi

# Cari direktori odin yang sebenarnya dan pindahkan isinya ke /opt/odin
ODIN_DIR=$(find /opt/odin -name "odin" -type f -executable | head -1 | xargs dirname)
if [ -n "$ODIN_DIR" ] && [ "$ODIN_DIR" != "/opt/odin" ]; then
    echo "📁 Memindahkan file dari $ODIN_DIR ke /opt/odin..."
    mv "$ODIN_DIR"/* /opt/odin/ 2>/dev/null || true
    rmdir "$ODIN_DIR" 2>/dev/null || true
fi

echo "✅ Ekstraksi selesai."
echo ""

echo "🗑️ Menghapus file arsip yang sudah diunduh..."
rm "${ODIN_FILENAME}"
echo "✅ File arsip dihapus."
echo ""

# 5. Atur variabel lingkungan (PATH)
REAL_USER=$(logname 2>/dev/null || echo ${SUDO_USER:-${USER}})
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SHELL_PROFILE=""

if [ -f "$USER_HOME/.zshrc" ]; then
    SHELL_PROFILE="$USER_HOME/.zshrc"
elif [ -f "$USER_HOME/.bashrc" ]; then
    SHELL_PROFILE="$USER_HOME/.bashrc"
fi

if [ -n "$SHELL_PROFILE" ] && [ -f "$SHELL_PROFILE" ]; then
    echo "⚙️ Mengkonfigurasi PATH di ${SHELL_PROFILE}"
    sed -i '/# Tambahkan Odin ke PATH/d' "$SHELL_PROFILE"
    sed -i '/export PATH=\$PATH:\/opt\/odin/d' "$SHELL_PROFILE"
    echo '' >> "$SHELL_PROFILE"
    echo '# Tambahkan Odin ke PATH' >> "$SHELL_PROFILE"
    echo 'export PATH=$PATH:/opt/odin' >> "$SHELL_PROFILE"
    chown "$REAL_USER":"$REAL_USER" "$SHELL_PROFILE"
else
    SHELL_PROFILE="/etc/profile.d/odin.sh"
    echo 'export PATH=$PATH:/opt/odin' > "$SHELL_PROFILE"
    echo "⚙️ Mengkonfigurasi PATH untuk semua pengguna di ${SHELL_PROFILE}"
fi

# 6. Tampilkan pesan akhir
echo "================================================================"
echo "   SELAMAT! INSTALASI ODIN BERHASIL TERSIMPAN!            "
echo "================================================================"
echo ""
echo "Verifikasi Versi Odin:"
/opt/odin/odin version
echo ""
echo "⚠️  TINDAKAN DIPERLUKAN:"
echo "   Untuk mulai menggunakan Odin, muat ulang shell Anda dengan:"
echo "   1. Menutup dan membuka kembali terminal, ATAU"
echo "   2. Menjalankan perintah yang sesuai di bawah ini:"
if [[ "$SHELL_PROFILE" == *".zshrc"* ]]; then
    echo "      source $USER_HOME/.zshrc"
elif [[ "$SHELL_PROFILE" == *".bashrc"* ]]; then
    echo "      source $USER_HOME/.bashrc"
else
    echo "      (Silakan logout dan login kembali untuk menerapkan perubahan sistem)"
fi
echo ""
echo "📚 CONTOH PENGGUNAAN ODIN:"
echo "   1. Buat file hello.odin dengan konten:"
echo "      package main"
echo "      import \"core:fmt\""
echo "      main :: proc() {"
echo "          fmt.println(\"Hello, World!\")"
echo "      }"
echo ""
echo "   2. Kompilasi dan jalankan:"
echo "      odin run hello.odin"
echo ""
echo "   3. Atau kompilasi saja:"
echo "      odin build hello.odin"
echo ""
echo "🌐 Dokumentasi lengkap: https://odin-lang.org/docs/"
echo "================================================================"
