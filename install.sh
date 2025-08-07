#!/bin/bash

# =================================================================
#   Installer Skrip Interaktif & Modern
# =================================================================
# Tampilan lebih baik, interaktif dengan pemilihan gaya checkbox,
# dan output berwarna untuk kejelasan.
# =================================================================

# --- Definisi Warna & Gaya ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'
C_BOLD='\033[1m'

# --- Variabel Global ---
SCRIPT_DIR="$(dirname "$0")/script"
shopt -s nullglob # Aktifkan agar array kosong jika tidak ada file
scripts=("$SCRIPT_DIR"/*.sh)
shopt -u nullglob # Matikan lagi untuk perilaku default

# Array untuk melacak status pemilihan (0 = tidak dipilih, 1 = dipilih)
selected_status=()

# --- Fungsi Bantuan ---
print_header() {
    echo -e "
${C_BOLD}${C_BLUE}=====================================================${C_RESET}"
    echo -e "${C_BOLD}${C_BLUE} $1${C_RESET}"
    echo -e "${C_BOLD}${C_BLUE}=====================================================${C_RESET}"
}

# Inisialisasi status pemilihan, semua tidak dipilih
initialize_selection() {
    for ((i=0; i<${#scripts[@]}; i++)); do
        selected_status[$i]=0
    done
}

# --- Fungsi Utama ---

# Fungsi untuk menampilkan menu pemilihan utama
display_menu() {
    clear
    print_header "Pilih Skrip untuk Diinstal"
    echo -e "Gunakan angka untuk memilih/membatalkan pilihan skrip.
"

    for i in "${!scripts[@]}"; do
        script_name=$(basename "${scripts[$i]}")
        if [ "${selected_status[$i]}" -eq 1 ]; then
            echo -e "  ${C_GREEN}[x] $((i+1))) ${C_BOLD}$script_name${C_RESET}"
        else
            echo -e "  [ ] $((i+1))) $script_name"
        fi
    done

    echo -e "
${C_CYAN}-----------------------------------------------------${C_RESET}"
    echo -e "${C_BOLD}Opsi:${C_RESET}"
    echo -e "  ${C_YELLOW}a${C_RESET} - Pilih Semua   ${C_YELLOW}n${C_RESET} - Batal Semua"
    echo -e "  ${C_GREEN}c${C_RESET} - Lanjutkan     ${C_RED}q${C_RESET} - Keluar"
    echo -e "${C_CYAN}-----------------------------------------------------${C_RESET}"
}

# Fungsi untuk menjalankan skrip yang telah dipilih
run_selected_scripts() {
    local scripts_to_run=()
    for i in "${!scripts[@]}"; do
        if [ "${selected_status[$i]}" -eq 1 ]; then
            scripts_to_run+=("${scripts[$i]}")
        fi
    done

    if [ ${#scripts_to_run[@]} -eq 0 ]; then
        echo -e "${C_YELLOW}Tidak ada skrip yang dipilih. Proses dibatalkan.${C_RESET}"
        exit 0
    fi

    print_header "Memulai Proses Instalasi"

    for script_path in "${scripts_to_run[@]}"; do
        script_name=$(basename "$script_path")
        echo -e "
${C_CYAN}---[ ▶️  Menjalankan: ${C_BOLD}$script_name${C_RESET}${C_CYAN} ]---${C_RESET}"
        
        chmod +x "$script_path"
        if ! bash "$script_path"; then
            echo -e "
${C_RED}${C_BOLD}=====================================================${C_RESET}"
            echo -e "${C_RED}${C_BOLD}⚠️  ERROR: Terjadi kesalahan saat menjalankan $script_name.${C_RESET}"
            echo -e "${C_RED}${C_BOLD}=====================================================${C_RESET}"
            read -p "Apakah Anda ingin melanjutkan dengan skrip berikutnya? (y/n): " continue_on_error
            if [[ "$continue_on_error" != "y" ]]; then
                echo -e "${C_RED}Instalasi dihentikan oleh pengguna.${C_RESET}"
                exit 1
            fi
        fi
        echo -e "${C_GREEN}---[ ✅ Selesai: ${C_BOLD}$script_name${C_RESET}${C_GREEN} ]---${C_RESET}"
    done

    print_header "✨ Semua Instalasi Selesai ✨"
    echo -e "Semua skrip yang Anda pilih telah berhasil dijalankan.
"
}

# --- Logika Eksekusi Skrip ---

# Periksa apakah ada skrip yang ditemukan
if [ ${#scripts[@]} -eq 0 ]; then
  echo -e "${C_RED}Error: Tidak ada skrip instalasi (*.sh) yang ditemukan di direktori '$SCRIPT_DIR'.${C_RESET}"
  exit 1
fi

initialize_selection

# Loop untuk menu interaktif
while true; do
    display_menu
    read -rp "Masukkan pilihan Anda: " choice

    case "$choice" in
        [qQ]) # Keluar
            echo -e "${C_YELLOW}Instalasi dibatalkan.${C_RESET}"
            exit 0
            ;;
        [cC]) # Lanjutkan
            break
            ;;
        [aA]) # Pilih Semua
            for i in "${!scripts[@]}"; do selected_status[$i]=1; done
            ;;
        [nN]) # Batal Semua
            initialize_selection
            ;;
        *)
            # Cek apakah input adalah angka
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#scripts[@]}" ]; then
                index=$((choice - 1))
                # Toggle selection
                if [ "${selected_status[$index]}" -eq 1 ]; then
                    selected_status[$index]=0
                else
                    selected_status[$index]=1
                fi
            else
                echo -e "${C_RED}Pilihan tidak valid. Tekan Enter untuk mencoba lagi...${C_RESET}"
                read -r
            fi
            ;;
    esac
done

# Jalankan skrip yang dipilih setelah keluar dari loop
run_selected_scripts