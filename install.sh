#!/bin/bash

set -euo pipefail

echo "Selamat datang, Hendra!"

# ------------------------------------------------------------
# Bootstrap: clone/pull repo bila tidak berjalan dari repo lokal
# Dukung cara pakai: bash <(curl -L link.dwx.my.id/my-script)
# ------------------------------------------------------------
REPO_URL="${MY_SCRIPT_REPO_URL:-https://github.com/localan/my-script}"
TARGET_DIR_DEFAULT="$HOME/my-script"
TARGET_DIR="${MY_SCRIPT_DIR:-$TARGET_DIR_DEFAULT}"

# Coba deteksi root skrip saat ini (jika memang dari repo lokal)
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]:-}" ]]; then
  POSSIBLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  POSSIBLE_ROOT="$(pwd)"
fi

if [[ -d "$POSSIBLE_ROOT/script" ]]; then
  SCRIPT_ROOT="$POSSIBLE_ROOT"
  SCRIPT_DIR="$SCRIPT_ROOT/script"
else
  echo "Menyiapkan repo lokal dari $REPO_URL ..."
  if [[ -d "$TARGET_DIR/.git" ]]; then
    echo "Repo sudah ada di $TARGET_DIR, menarik pembaruan (git pull)..."
    git -C "$TARGET_DIR" pull --ff-only | cat
  else
    echo "Meng-clone ke $TARGET_DIR ..."
    git clone "$REPO_URL" "$TARGET_DIR" | cat
  fi
  echo "Menjalankan installer lokal..."
  exec bash "$TARGET_DIR/install.sh" --local
fi

# Kumpulkan daftar skrip .sh (mode lokal setelah bootstrap)
shopt -s nullglob
scripts=("$SCRIPT_DIR"/*.sh)
shopt -u nullglob

if [[ ${#scripts[@]} -eq 0 ]]; then
  echo "Tidak ada skrip .sh di folder: $SCRIPT_DIR"
  exit 0
fi

echo "\nSilakan pilih skrip yang ingin dijalankan (dari folder 'script/'):\n"
for i in "${!scripts[@]}"; do
  script_name="$(basename "${scripts[$i]}")"
  printf "  %2d) %s\n" "$((i+1))" "$script_name"
fi

echo "\nOpsi input:"
echo "- Masukkan nomor dipisah spasi (misal: 1 3 5)"
echo "- Atau ketik 'a' untuk memilih semua"
echo "- Atau ketik 'q' untuk keluar"

read -rp $'Masukkan pilihan Anda: ' choice

if [[ "$choice" =~ ^[qQ]$ ]]; then
  echo "Dibatalkan."
  exit 0
fi

selected_indexes=()
if [[ "$choice" =~ ^[aA]$ ]]; then
  for i in "${!scripts[@]}"; do selected_indexes+=("$i"); done
else
  # Parse angka-angka
  for token in $choice; do
    if [[ "$token" =~ ^[0-9]+$ ]]; then
      idx=$((token-1))
      if (( idx >= 0 && idx < ${#scripts[@]} )); then
        selected_indexes+=("$idx")
      else
        echo "Nomor di luar jangkauan: $token"
        exit 1
      fi
    else
      echo "Input tidak valid: $token"
      exit 1
    fi
  done
fi

if [[ ${#selected_indexes[@]} -eq 0 ]]; then
  echo "Tidak ada skrip yang dipilih. Keluar."
  exit 0
fi

echo "\nSkrip yang akan dijalankan:" 
for idx in "${selected_indexes[@]}"; do
  echo "- $(basename "${scripts[$idx]}")"
done

read -rp $'Lanjutkan? (y/n): ' confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
  echo "Dibatalkan."
  exit 0
fi

echo "\nMemulai eksekusi...\n"
for idx in "${selected_indexes[@]}"; do
  script_path="${scripts[$idx]}"
  script_name="$(basename "$script_path")"
  echo "--- Menjalankan: $script_name ---"
  chmod +x "$script_path" || true
  if ! bash "$script_path"; then
    echo "Gagal menjalankan: $script_name"
    read -rp $'Lanjut ke skrip berikutnya? (y/n): ' cont
    if [[ ! "$cont" =~ ^[yY]$ ]]; then
      echo "Dihentikan oleh pengguna."
      exit 1
    fi
  else
    echo "Selesai: $script_name"
  fi
  echo
done

echo "Semua skrip terpilih telah diproses."


