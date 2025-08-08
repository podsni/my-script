#!/bin/bash
ansi_art='
╔══════════════════════════════════════════════════════════════════════╗
║ █████   █████   █████████   ██████████   ██████████  █████████       ║
║░░███   ░░███   ███░░░░░███ ░░███░░░░███ ░░███░░░░░█ ███░░░░░███      ║
║ ░███    ░███  ░███    ░███  ░███   ░░███ ░███  █ ░ ░███    ░░░       ║
║ ░███████████  ░███████████  ░███    ░███ ░██████   ░░█████████       ║
║ ░███░░░░░███  ░███░░░░░███  ░███    ░███ ░███░░█    ░░░░░░░░███      ║
║ ░███    ░███  ░███    ░███  ░███    ███  ░███ ░   █ ███    ░███      ║
║ █████   █████ █████   █████ ██████████   ██████████░░█████████       ║
║░░░░░   ░░░░░ ░░░░░   ░░░░░ ░░░░░░░░░░   ░░░░░░░░░░  ░░░░░░░░░        ║
║                                                                      ║
║                                                                      ║
║                                                                      ║
║  █████████    █████████  ███████████   █████ ███████████  ███████████║
║ ███░░░░░███  ███░░░░░███░░███░░░░░███ ░░███ ░░███░░░░░███░█░░░███░░░█║
║░███    ░░░  ███     ░░░  ░███    ░███  ░███  ░███    ░███░   ░███  ░ ║
║░░█████████ ░███          ░██████████   ░███  ░██████████     ░███    ║
║ ░░░░░░░░███░███          ░███░░░░░███  ░███  ░███░░░░░░      ░███    ║
║ ███    ░███░░███     ███ ░███    ░███  ░███  ░███            ░███    ║
║░░█████████  ░░█████████  █████   █████ █████ █████           █████   ║
║ ░░░░░░░░░    ░░░░░░░░░  ░░░░░   ░░░░░ ░░░░░ ░░░░░           ░░░░░    ║
╚══════════════════════════════════════════════════════════════════════╝
'
set -euo pipefail

# Warna sederhana
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_BLUE='\033[0;34m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_RED='\033[0;31m'
C_CYAN='\033[0;36m'

# Inisialisasi variabel repo/target lebih awal (dipakai di header)
REPO_URL="${MY_SCRIPT_REPO_URL:-https://github.com/localan/my-script}"
TARGET_DIR_DEFAULT="$HOME/my-script"
TARGET_DIR="${MY_SCRIPT_DIR:-$TARGET_DIR_DEFAULT}"

clear
printf "%b\n" "$ansi_art"
# Tentukan nama pengguna yang ditampilkan (prioritaskan SUDO_USER jika ada)
USER_NAME="${SUDO_USER:-${USER:-}}"
if [[ -z "$USER_NAME" ]]; then USER_NAME="$(whoami 2>/dev/null || echo "pengguna")"; fi
printf "\n${C_BOLD}${C_BLUE}Selamat datang, %s!${C_RESET}\n" "$USER_NAME"
printf "${C_CYAN}Repo:${C_RESET} %s\n" "$REPO_URL"
printf "${C_CYAN}Lokasi:${C_RESET} %s\n" "$TARGET_DIR"

# ------------------------------------------------------------
# Bootstrap: clone/pull repo bila tidak berjalan dari repo lokal
# Dukung cara pakai: bash <(curl -L link.dwx.my.id/my-script)
# ------------------------------------------------------------

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

# Kumpulkan daftar skrip .sh (mode lokal setelah bootstrap) dan urutkan
shopt -s nullglob
scripts_unsorted=("$SCRIPT_DIR"/*.sh)
shopt -u nullglob
if (( ${#scripts_unsorted[@]} > 0 )); then
  mapfile -t scripts < <(printf '%s\n' "${scripts_unsorted[@]}" | sort)
else
  scripts=()
fi

if [[ ${#scripts[@]} -eq 0 ]]; then
  echo "Tidak ada skrip .sh di folder: $SCRIPT_DIR"
  exit 0
fi

# --- Menu interaktif (toggle) ---
declare -a selected_status=()
for ((i=0; i<${#scripts[@]}; i++)); do selected_status[$i]=0; done

get_script_desc() {
  local f="$1"
  awk 'NR==1 && /^#!/{next} /^#/ {sub(/^# ?/, "", $0); print; exit}' "$f" 2>/dev/null || true
}

print_menu() {
  clear
  printf "%b\n" "$ansi_art"
  printf "\n${C_BOLD}Silakan pilih skrip yang ingin dijalankan (dari folder 'script/'):${C_RESET}\n\n"
  for i in "${!scripts[@]}"; do
    script_name="$(basename "${scripts[$i]}")"
    desc=$(get_script_desc "${scripts[$i]}")
    if [[ ${selected_status[$i]} -eq 1 ]]; then
      printf "  ${C_GREEN}[x]${C_RESET} %2d) %s\n" "$((i+1))" "$script_name"
    else
      printf "  [ ] %2d) %s\n" "$((i+1))" "$script_name"
    fi
    if [[ -n "$desc" ]]; then
      printf "      ${C_CYAN}- %s${C_RESET}\n" "$desc"
    fi
  done
  printf "\n${C_BOLD}Opsi:${C_RESET}\n"
  printf "%s\n" "- Ketik nomor untuk toggle (boleh banyak: 1 3 5 atau range 2-4)"
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
      for token in $choice; do
        if [[ "$token" =~ ^[0-9]+-[0-9]+$ ]]; then
          start=${token%-*}
          end=${token#*-}
          if (( start < 1 || end < 1 || start > end )); then
            printf "${C_RED}Range tidak valid:${C_RESET} %s\n" "$token"
            continue
          fi
          for ((k=start; k<=end; k++)); do
            idx=$((k-1))
            if (( idx >= 0 && idx < ${#scripts[@]} )); then
              if [[ ${selected_status[$idx]} -eq 1 ]]; then selected_status[$idx]=0; else selected_status[$idx]=1; fi
            fi
          done
        elif [[ "$token" =~ ^[0-9]+$ ]]; then
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
  script_name="$(basename "${scripts[$idx]}")"
  desc=$(get_script_desc "${scripts[$idx]}")
  if [[ -n "$desc" ]]; then
    printf -- "- %s ${C_CYAN}(%s)${C_RESET}\n" "$script_name" "$desc"
  else
    printf -- "- %s\n" "$script_name"
  fi
done

read -rp $'Lanjutkan? (y/n): ' confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
  echo "Dibatalkan."
  exit 0
fi

printf "\n${C_GREEN}Memulai eksekusi...${C_RESET}\n\n"
trap 'printf "\n${C_YELLOW}Dibatalkan oleh pengguna.${C_RESET}\n"; exit 130' INT

declare -a succeeded
declare -a failed
succeeded=()
failed=()
for idx in "${selected_indexes[@]}"; do
  script_path="${scripts[$idx]}"
  script_name="$(basename "$script_path")"
  printf "${C_BLUE}--- Menjalankan:${C_RESET} ${C_BOLD}%s${C_RESET}\n" "$script_name"
  chmod +x "$script_path" || true
  start_ts=$(date +%s)
  if ! bash "$script_path"; then
    printf "${C_RED}Gagal menjalankan:${C_RESET} %s\n" "$script_name"
    read -rp $'Lanjut ke skrip berikutnya? (y/n): ' cont
    if [[ ! "$cont" =~ ^[yY]$ ]]; then
      echo "Dihentikan oleh pengguna."
      exit 1
    fi
    failed+=("$script_name")
  else
    end_ts=$(date +%s)
    dur=$((end_ts-start_ts))
    printf "${C_GREEN}Selesai:${C_RESET} %s ${C_CYAN}(%ss)${C_RESET}\n" "$script_name" "$dur"
    succeeded+=("$script_name")
  fi
  echo
done

printf "${C_BOLD}Semua skrip terpilih telah diproses.${C_RESET}\n"
printf "\n${C_BOLD}Ringkasan:${C_RESET}\n"
if (( ${#succeeded[@]} > 0 )); then
  printf "${C_GREEN}  Berhasil:${C_RESET}\n"
  for n in "${succeeded[@]}"; do printf -- "    - %s\n" "$n"; done
fi
if (( ${#failed[@]} > 0 )); then
  printf "${C_RED}  Gagal:${C_RESET}\n"
  for n in "${failed[@]}"; do printf -- "    - %s\n" "$n"; done
fi


