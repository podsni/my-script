#!/bin/bash

set -euo pipefail

# Warna sederhana
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_BLUE='\033[0;34m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_RED='\033[0;31m'

printf "${C_BOLD}${C_BLUE}Selamat datang, Hendra!${C_RESET}\n"

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

printf "\n${C_BOLD}Silakan pilih skrip yang ingin dijalankan (dari folder 'script/'):${C_RESET}\n\n"
for i in "${!scripts[@]}"; do
  script_name="$(basename "${scripts[$i]}")"
  printf "  %2d) %s\n" "$((i+1))" "$script_name"
done

printf "\n${C_BOLD}Opsi input:${C_RESET}\n"
printf "- Masukkan nomor dipisah spasi (misal: 1 3 5)\n"
printf "- Atau ketik 'a' untuk memilih semua\n"
printf "- Atau ketik 'q' untuk keluar\n"

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

printf "\n${C_BOLD}Skrip yang akan dijalankan:${C_RESET}\n"
for idx in "${selected_indexes[@]}"; do
  echo "- $(basename "${scripts[$idx]}")"
done

read -rp $'Lanjutkan? (y/n): ' confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
  echo "Dibatalkan."
  exit 0
fi

printf "\n${C_GREEN}Memulai eksekusi...${C_RESET}\n\n"
for idx in "${selected_indexes[@]}"; do
  script_path="${scripts[$idx]}"
  script_name="$(basename "$script_path")"
  printf "${C_BLUE}--- Menjalankan:${C_RESET} ${C_BOLD}%s${C_RESET}\n" "$script_name"
  chmod +x "$script_path" || true
  if ! bash "$script_path"; then
    printf "${C_RED}Gagal menjalankan:${C_RESET} %s\n" "$script_name"
    read -rp $'Lanjut ke skrip berikutnya? (y/n): ' cont
    if [[ ! "$cont" =~ ^[yY]$ ]]; then
      echo "Dihentikan oleh pengguna."
      exit 1
    fi
  else
    printf "${C_GREEN}Selesai:${C_RESET} %s\n" "$script_name"
  fi
  echo
done

printf "${C_BOLD}Semua skrip terpilih telah diproses.${C_RESET}\n"


