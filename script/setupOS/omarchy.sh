#!/usr/bin/env bash
# Arch Linux using the tiling window manager Hyprland.
set -euo pipefail

URL="https://raw.githubusercontent.com/basecamp/omarchy/refs/heads/master/boot.sh"

# Simpan sementara file sebelum eval (supaya bisa diperiksa kalau mau)
TMP_FILE=$(mktemp)
wget -qO "$TMP_FILE" "$URL"

echo "[INFO] Script berhasil diunduh ke $TMP_FILE"
echo "[INFO] Menjalankan script..."

# Jalankan script
eval "$(cat "$TMP_FILE")"

# Hapus file sementara
rm -f "$TMP_FILE"

