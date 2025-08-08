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

# --- Menu interaktif (toggle) ---
declare -a selected_status=()
for ((i=0; i<${#scripts[@]}; i++)); do selected_status[$i]=0; done

print_menu() {
  printf "\n${C_BOLD}Silakan pilih skrip yang ingin dijalankan (dari folder 'script/'):${C_RESET}\n\n"
  for i in "${!scripts[@]}"; do
    script_name="$(basename "${scripts[$i]}")"
    if [[ ${selected_status[$i]} -eq 1 ]]; then
      printf "  ${C_GREEN}[x]${C_RESET} %2d) %s\n" "$((i+1))" "$script_name"
    else
      printf "  [ ] %2d) %s\n" "$((i+1))" "$script_name"
    fi
  done
  printf "\n${C_BOLD}Opsi:${C_RESET}\n"
  printf "%s\n" "- Ketik nomor untuk toggle (boleh banyak: 1 3 5)"
  printf "%s\n" "- 'a' pilih semua, 'n' batal semua, 'c' lanjut, 'q' keluar"
}

while true; do
  print_menu
  read -rp $'Masukkan pilihan Anda: ' choice
  case "$choice" in
    [qQ]) echo "Dibatalkan."; exit 0 ;;
    [cC])
      # pastikan ada yang dipilih
      any=0; for v in "${selected_status[@]}"; do if [[ $v -eq 1 ]]; then any=1; break; fi; done
      if [[ $any -eq 1 ]]; then break; else printf "${C_YELLOW}Belum ada yang dipilih.${C_RESET}\n"; fi
      ;;
    [aA]) for i in "${!selected_status[@]}"; do selected_status[$i]=1; done ;;
    [nN]) for i in "${!selected_status[@]}"; do selected_status[$i]=0; done ;;
    *)
      # izinkan banyak angka dipisah spasi
      valid=1
      for token in $choice; do
        if [[ "$token" =~ ^[0-9]+$ ]]; then
          idx=$((token-1))
          if (( idx >= 0 && idx < ${#scripts[@]} )); then
            if [[ ${selected_status[$idx]} -eq 1 ]]; then selected_status[$idx]=0; else selected_status[$idx]=1; fi
          else
            printf "${C_RED}Nomor di luar jangkauan:${C_RESET} %s\n" "$token"; valid=0
          fi
        else
          printf "${C_RED}Input tidak valid:${C_RESET} %s\n" "$token"; valid=0
        fi
      done
      ;;
  esac
done

selected_indexes=()
for i in "${!selected_status[@]}"; do if [[ ${selected_status[$i]} -eq 1 ]]; then selected_indexes+=("$i"); fi; done

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


