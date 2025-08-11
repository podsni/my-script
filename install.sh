#!/bin/bash

# ====================================================================
# HADES Script Manager - Installer dan Executor
# Versi: 2.0
# Deskripsi: Installer interaktif untuk mengelola dan menjalankan skrip
# ====================================================================

set -euo pipefail

# ANSI Art Header yang lebih sederhana dan elegan
ansi_art='
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║   ██╗  ██╗ █████╗ ██████╗ ███████╗███████╗    ███████╗ ██████╗██████╗    ║
║   ██║  ██║██╔══██╗██╔══██╗██╔════╝██╔════╝    ██╔════╝██╔════╝██╔══██╗   ║
║   ███████║███████║██║  ██║█████╗  ███████╗    ███████╗██║     ██████╔╝   ║
║   ██╔══██║██╔══██║██║  ██║██╔══╝  ╚════██║    ╚════██║██║     ██╔══██╗   ║
║   ██║  ██║██║  ██║██████╔╝███████╗███████║    ███████║╚██████╗██║  ██║   ║
║   ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝   ║
║                                                                           ║
║              🚀 Script Collection Management System 🚀                   ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
'

# Konfigurasi warna dengan variasi yang lebih kaya
declare -r C_RESET='\033[0m'
declare -r C_BOLD='\033[1m'
declare -r C_DIM='\033[2m'
declare -r C_UNDERLINE='\033[4m'
declare -r C_BLINK='\033[5m'

# Warna foreground
declare -r C_BLACK='\033[0;30m'
declare -r C_RED='\033[0;31m'
declare -r C_GREEN='\033[0;32m'
declare -r C_YELLOW='\033[0;33m'
declare -r C_BLUE='\033[0;34m'
declare -r C_MAGENTA='\033[0;35m'
declare -r C_CYAN='\033[0;36m'
declare -r C_WHITE='\033[0;37m'

# Warna terang
declare -r C_BRIGHT_BLACK='\033[0;90m'
declare -r C_BRIGHT_RED='\033[0;91m'
declare -r C_BRIGHT_GREEN='\033[0;92m'
declare -r C_BRIGHT_YELLOW='\033[0;93m'
declare -r C_BRIGHT_BLUE='\033[0;94m'
declare -r C_BRIGHT_MAGENTA='\033[0;95m'
declare -r C_BRIGHT_CYAN='\033[0;96m'
declare -r C_BRIGHT_WHITE='\033[0;97m'

# Warna background
declare -r C_BG_BLACK='\033[40m'
declare -r C_BG_RED='\033[41m'
declare -r C_BG_GREEN='\033[42m'
declare -r C_BG_YELLOW='\033[43m'
declare -r C_BG_BLUE='\033[44m'
declare -r C_BG_MAGENTA='\033[45m'
declare -r C_BG_CYAN='\033[46m'
declare -r C_BG_WHITE='\033[47m'

# Emoji dan simbol untuk tampilan yang lebih menarik
declare -r ICON_SUCCESS="✅"
declare -r ICON_ERROR="❌"
declare -r ICON_WARNING="⚠️"
declare -r ICON_INFO="ℹ️"
declare -r ICON_ROCKET="🚀"
declare -r ICON_GEAR="⚙️"
declare -r ICON_FOLDER="📁"
declare -r ICON_SCRIPT="📜"
declare -r ICON_RANDOM="🎲"
declare -r ICON_ALL="📦"

# ====================================================================
# KONFIGURASI DAN INISIALISASI SISTEM
# ====================================================================

# Konfigurasi repository dan direktori
REPO_URL="${MY_SCRIPT_REPO_URL:-https://github.com/localan/my-script}"
TARGET_DIR_DEFAULT="$HOME/my-script"
TARGET_DIR="${MY_SCRIPT_DIR:-$TARGET_DIR_DEFAULT}"

# Fungsi utilitas untuk logging dan display
log_info() {
    printf "${C_BRIGHT_BLUE}${ICON_INFO}${C_RESET} ${C_BOLD}%s${C_RESET}\n" "$*"
}

log_success() {
    printf "${C_BRIGHT_GREEN}${ICON_SUCCESS}${C_RESET} ${C_BOLD}%s${C_RESET}\n" "$*"
}

log_warning() {
    printf "${C_BRIGHT_YELLOW}${ICON_WARNING}${C_RESET} ${C_BOLD}%s${C_RESET}\n" "$*"
}

log_error() {
    printf "${C_BRIGHT_RED}${ICON_ERROR}${C_RESET} ${C_BOLD}%s${C_RESET}\n" "$*"
}

draw_line() {
    local char="${1:-─}"
    local width="${2:-75}"
    printf "${C_DIM}"
    printf "%*s\n" "$width" | tr ' ' "$char"
    printf "${C_RESET}"
}

show_header() {
    clear
    printf "%b\n" "$ansi_art"
    
    # Tentukan nama pengguna yang ditampilkan
    local user_name="${SUDO_USER:-${USER:-}}"
    if [[ -z "$user_name" ]]; then 
        user_name="$(whoami 2>/dev/null || echo "pengguna")"
    fi
    
    draw_line "═" 75
    printf "${C_BRIGHT_CYAN}${C_BOLD}  Selamat datang, %s! ${ICON_ROCKET}${C_RESET}\n" "$user_name"
    printf "${C_CYAN}  Repository:${C_RESET} %s\n" "$REPO_URL"
    printf "${C_CYAN}  Lokasi:${C_RESET} %s\n" "$TARGET_DIR"
    printf "${C_CYAN}  Tanggal:${C_RESET} $(date '+%A, %d %B %Y - %H:%M:%S')\n"
    draw_line "═" 75
}

# Fungsi untuk menampilkan loading animation
show_loading() {
    local message="$1"
    local duration="${2:-3}"
    local spinner="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    
    printf "${C_BRIGHT_BLUE}${message}${C_RESET} "
    for ((i=0; i<duration*10; i++)); do
        printf "\r${C_BRIGHT_BLUE}${message}${C_RESET} ${C_BRIGHT_YELLOW}%c${C_RESET}" "${spinner:$((i%10)):1}"
        sleep 0.1
    done
    printf "\r${C_BRIGHT_BLUE}${message}${C_RESET} ${C_BRIGHT_GREEN}${ICON_SUCCESS}${C_RESET}\n"
}

# ====================================================================
# BOOTSTRAP: SETUP REPOSITORY LOKAL
# ====================================================================

bootstrap_repository() {
    log_info "Memulai proses bootstrap repository..."
    
    # Coba deteksi root skrip saat ini (jika memang dari repo lokal)
    if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]:-}" ]]; then
        POSSIBLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    else
        POSSIBLE_ROOT="$(pwd)"
    fi

    if [[ -d "$POSSIBLE_ROOT/script" ]]; then
        SCRIPT_ROOT="$POSSIBLE_ROOT"
        SCRIPT_DIR="$SCRIPT_ROOT/script"
        log_success "Repository lokal ditemukan di: $SCRIPT_ROOT"
    else
        log_info "Menyiapkan repository lokal dari $REPO_URL"
        
        if [[ -d "$TARGET_DIR/.git" ]]; then
            log_info "Repository sudah ada, melakukan update..."
            show_loading "Menarik pembaruan dari repository" 2
            if git -C "$TARGET_DIR" pull --ff-only &>/dev/null; then
                log_success "Repository berhasil diperbarui"
            else
                log_warning "Gagal memperbarui repository, melanjutkan dengan versi lokal"
            fi
        else
            log_info "Melakukan clone repository..."
            show_loading "Mengunduh repository" 3
            if git clone "$REPO_URL" "$TARGET_DIR" &>/dev/null; then
                log_success "Repository berhasil di-clone"
            else
                log_error "Gagal clone repository"
                exit 1
            fi
        fi
        
        log_info "Menjalankan installer lokal..."
        exec bash "$TARGET_DIR/install.sh" --local
    fi
}

# Jalankan bootstrap jika diperlukan
show_header
bootstrap_repository

# ====================================================================
# FUNGSI UNTUK MENGELOLA KATEGORI DAN SKRIP
# ====================================================================

# Fungsi untuk mendapatkan deskripsi skrip
get_script_description() {
    local script_file="$1"
    local description=""
    
    # Baca beberapa baris pertama untuk mencari deskripsi
    while IFS= read -r line; do
        # Skip shebang
        if [[ "$line" =~ ^#! ]]; then continue; fi
        
        # Jika baris komentar, ambil sebagai deskripsi
        if [[ "$line" =~ ^#[[:space:]]*(.*) ]]; then
            description="${BASH_REMATCH[1]}"
            break
        fi
        
        # Jika baris tidak kosong dan bukan komentar, hentikan pencarian
        if [[ -n "$line" ]]; then break; fi
    done < "$script_file"
    
    echo "$description"
}

# Fungsi untuk menampilkan statistik kategori
show_category_stats() {
    local category_dirs=("$@")
    local total_scripts=0
    local total_categories=${#category_dirs[@]}
    
    # Hitung total skrip
    for dir in "${category_dirs[@]}"; do
        local count=$(find "$dir" -name "*.sh" -type f | wc -l)
        total_scripts=$((total_scripts + count))
    done
    
    # Hitung skrip root level
    local root_count=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.sh" -type f | wc -l)
    total_scripts=$((total_scripts + root_count))
    
    printf "\n${C_BG_BLUE}${C_WHITE}${C_BOLD} STATISTIK REPOSITORY ${C_RESET}\n"
    printf "${C_CYAN}  ${ICON_FOLDER} Total Kategori: ${C_BOLD}%d${C_RESET}\n" "$total_categories"
    printf "${C_CYAN}  ${ICON_SCRIPT} Total Skrip: ${C_BOLD}%d${C_RESET}\n" "$total_scripts"
    if [[ $root_count -gt 0 ]]; then
        printf "${C_CYAN}  ${ICON_GEAR} Skrip Root Level: ${C_BOLD}%d${C_RESET}\n" "$root_count"
    fi
}

# Fungsi untuk menampilkan menu kategori dengan style yang lebih baik
show_category_menu() {
    local category_names=("$@")
    local category_dirs=()
    
    # Rebuild array direktori kategori
    shopt -s nullglob
    for d in "$SCRIPT_DIR"/*/; do
        d="${d%/}"
        if compgen -G "$d/*.sh" > /dev/null; then
            category_dirs+=("$d")
        fi
    done
    shopt -u nullglob
    
    show_header
    show_category_stats "${category_dirs[@]}"
    
    printf "\n${C_BG_MAGENTA}${C_WHITE}${C_BOLD} PILIH KATEGORI SKRIP ${C_RESET}\n\n"
    
    # Opsi khusus
    printf "  ${C_BRIGHT_GREEN}${C_BOLD}0)${C_RESET} ${ICON_ALL} ${C_BOLD}ALL${C_RESET} ${C_DIM}(jalankan dari semua kategori)${C_RESET}\n"
    printf "  ${C_BRIGHT_YELLOW}${C_BOLD}R)${C_RESET} ${ICON_RANDOM} ${C_BOLD}RANDOM${C_RESET} ${C_DIM}(pilih 1 skrip secara acak)${C_RESET}\n"
    
    draw_line "─" 50
    
    # Tampilkan kategori dengan statistik
    for i in "${!category_names[@]}"; do
        local script_count=$(find "${category_dirs[$i]}" -name "*.sh" -type f | wc -l)
        local category_name="${category_names[$i]}"
        
        # Format nama kategori dengan kapitalisasi
        category_name="$(echo "$category_name" | sed 's/-/ /g' | sed 's/\b\w/\u&/g')"
        
        printf "  ${C_BRIGHT_BLUE}${C_BOLD}%d)${C_RESET} ${ICON_FOLDER} ${C_BOLD}%-20s${C_RESET} ${C_DIM}(%d skrip)${C_RESET}\n" \
               "$((i+1))" "$category_name" "$script_count"
    done
    
    draw_line "─" 50
    printf "  ${C_BRIGHT_RED}${C_BOLD}Q)${C_RESET} ${ICON_ERROR} ${C_BOLD}Keluar${C_RESET}\n\n"
}

# ====================================================================
# MAIN LOOP: PEMILIHAN KATEGORI DAN EKSEKUSI SKRIP
# ====================================================================

main_loop() {
    while true; do
        # Deteksi kategori yang tersedia
        declare -a category_names=()
        declare -a category_dirs=()

        shopt -s nullglob
        for d in "$SCRIPT_DIR"/*/; do
            d="${d%/}"
            if compgen -G "$d/*.sh" > /dev/null; then
                category_names+=("$(basename "$d")")
                category_dirs+=("$d")
            fi
        done
        shopt -u nullglob

        # Kumpulkan skrip root-level
        root_scripts=()
        shopt -s nullglob
        for f in "$SCRIPT_DIR"/*.sh; do
            root_scripts+=("$f")
        done
        shopt -u nullglob

        # Tampilkan menu kategori
        show_category_menu "${category_names[@]}"

        # Input pilihan kategori dengan validasi yang lebih baik
        while true; do
            printf "${C_BRIGHT_CYAN}${C_BOLD}➤ Masukkan pilihan Anda: ${C_RESET}"
            read -r cat_choice
            
            case "$cat_choice" in
                [qQ]) 
                    log_info "Terima kasih telah menggunakan HADES Script Manager!"
                    exit 0 
                    ;;
                [rR]|0|""|[1-9]|[1-9][0-9])
                    break
                    ;;
                *)
                    log_error "Pilihan tidak valid. Silakan coba lagi."
                    continue
                    ;;
            esac
        done

        # Proses pilihan kategori
        local random_mode=0
        local scripts_unsorted=()
        local current_category=""
        
        case "$cat_choice" in
            [rR])
                random_mode=1
                current_category="RANDOM"
                scripts_unsorted+=("${root_scripts[@]}")
                for d in "${category_dirs[@]}"; do
                    shopt -s nullglob
                    for f in "$d"/*.sh; do scripts_unsorted+=("$f"); done
                    shopt -u nullglob
                done
                ;;
            0|"")
                current_category="ALL"
                scripts_unsorted+=("${root_scripts[@]}")
                for d in "${category_dirs[@]}"; do
                    shopt -s nullglob
                    for f in "$d"/*.sh; do scripts_unsorted+=("$f"); done
                    shopt -u nullglob
                done
                ;;
            *)
                if [[ "$cat_choice" =~ ^[0-9]+$ ]]; then
                    local idx=$((cat_choice-1))
                    if (( idx >= 0 && idx < ${#category_dirs[@]} )); then
                        local d="${category_dirs[$idx]}"
                        current_category="$(basename "$d")"
                        shopt -s nullglob
                        for f in "$d"/*.sh; do scripts_unsorted+=("$f"); done
                        shopt -u nullglob
                    else
                        log_error "Nomor kategori tidak valid."
                        continue
                    fi
                else
                    log_error "Input tidak valid."
                    continue
                fi
                ;;
        esac

        # Sort skrip yang ditemukan
        if (( ${#scripts_unsorted[@]} > 0 )); then
            mapfile -t scripts < <(printf '%s\n' "${scripts_unsorted[@]}" | sort)
        else
            scripts=()
        fi

        if [[ ${#scripts[@]} -eq 0 ]]; then
            log_warning "Tidak ada skrip yang ditemukan untuk kategori ini."
            printf "\n${C_DIM}Tekan Enter untuk kembali ke menu kategori...${C_RESET}"
            read -r
            continue
        fi

        # Lanjutkan ke pemilihan skrip
        if handle_script_selection "$current_category" "$random_mode"; then
            # Jika berhasil, keluar dari loop utama
            break
        fi
        # Jika tidak berhasil (user memilih back), lanjutkan loop
    done
}

# ====================================================================
# FUNGSI PEMILIHAN DAN EKSEKUSI SKRIP
# ====================================================================

# ====================================================================
# FUNGSI PEMILIHAN DAN EKSEKUSI SKRIP (SIMPLIFIED)
# ====================================================================

# Global variables untuk script dan status
declare -a g_scripts=()
declare -a g_selected_status=()

# Fungsi untuk menampilkan menu skrip dengan design yang lebih menarik
print_script_menu() {
    local current_category="$1"
    
    show_header
    
    printf "\n${C_BG_GREEN}${C_BLACK}${C_BOLD} KATEGORI: %-20s | TOTAL SKRIP: %-3d ${C_RESET}\n" \
           "$current_category" "${#g_scripts[@]}"
    
    draw_line "═" 75
    printf "${C_BOLD}${C_BRIGHT_BLUE}Pilih skrip yang ingin dijalankan:${C_RESET}\n\n"
    
    for i in "${!g_scripts[@]}"; do
        local script_name="$(basename "${g_scripts[$i]}")"
        local script_desc="$(get_script_description "${g_scripts[$i]}")"
        local status_icon="[ ]"
        local status_color="$C_DIM"
        
        if [[ ${g_selected_status[$i]} -eq 1 ]]; then
            status_icon="[${ICON_SUCCESS}]"
            status_color="$C_BRIGHT_GREEN"
        fi
        
        printf "  ${status_color}${status_icon}${C_RESET} ${C_BRIGHT_BLUE}%2d)${C_RESET} ${C_BOLD}%-25s${C_RESET}\n" \
               "$((i+1))" "$script_name"
        
        if [[ -n "$script_desc" ]]; then
            printf "      ${C_DIM}└─ %s${C_RESET}\n" "$script_desc"
        fi
    done
    
    draw_line "─" 75
    printf "\n${C_BG_YELLOW}${C_BLACK}${C_BOLD} KONTROL MENU ${C_RESET}\n"
    printf "${C_CYAN}  Nomor${C_RESET}     : Toggle skrip (contoh: 1 3 5 atau 2-4)\n"
    printf "${C_CYAN}  a/A${C_RESET}      : Pilih semua skrip\n"
    printf "${C_CYAN}  n/N${C_RESET}      : Batalkan semua pilihan\n"
    printf "${C_CYAN}  c/C${C_RESET}      : Lanjutkan eksekusi skrip terpilih\n"
    printf "${C_CYAN}  b/B${C_RESET}      : Kembali ke menu kategori\n"
    printf "${C_CYAN}  q/Q${C_RESET}      : Keluar dari program\n"
    draw_line "─" 75
}

# Fungsi untuk menangani pemilihan skrip
handle_script_selection() {
    local current_category="$1"
    local random_mode="$2"
    # Copy scripts to global variable
    g_scripts=("${scripts[@]}")
    
    # Inisialisasi status pilihan
    g_selected_status=()
    for ((i=0; i<${#g_scripts[@]}; i++)); do 
        g_selected_status[$i]=0
    done

    if [[ $random_mode -eq 1 ]]; then
        # Mode random: pilih satu skrip secara acak
        if (( ${#g_scripts[@]} == 0 )); then
            log_warning "Tidak ada skrip yang tersedia untuk mode random."
            return 1
        fi
        local rand_idx=$((RANDOM % ${#g_scripts[@]}))
        g_selected_status[$rand_idx]=1
        log_info "Mode RANDOM: Memilih skrip '$(basename "${g_scripts[$rand_idx]}")'"
    else
        # Mode interaktif
        while true; do
            print_script_menu "$current_category"
            
            printf "\n${C_BRIGHT_CYAN}${C_BOLD}➤ Masukkan pilihan Anda: ${C_RESET}"
            read -r choice
            
            case "$choice" in
                [qQ]) 
                    log_info "Keluar dari program."
                    exit 0 
                    ;;
                [bB]) 
                    return 1  # Kembali ke menu kategori
                    ;;
                [cC])
                    # Periksa apakah ada yang dipilih
                    local any_selected=0
                    for v in "${g_selected_status[@]}"; do 
                        if [[ $v -eq 1 ]]; then 
                            any_selected=1
                            break
                        fi
                    done
                    if [[ $any_selected -eq 1 ]]; then 
                        break
                    else 
                        log_warning "Belum ada skrip yang dipilih."
                        printf "\n${C_DIM}Tekan Enter untuk melanjutkan...${C_RESET}"
                        read -r
                    fi
                    ;;
                [aA]) 
                    for i in "${!g_selected_status[@]}"; do 
                        g_selected_status[$i]=1
                    done
                    log_success "Semua skrip dipilih."
                    sleep 1
                    ;;
                [nN]) 
                    for i in "${!g_selected_status[@]}"; do 
                        g_selected_status[$i]=0
                    done
                    log_info "Semua pilihan dibatalkan."
                    sleep 1
                    ;;
                *)
                    # Handle multiple numbers and ranges
                    local valid_input=1
                    for token in $choice; do
                        if [[ "$token" =~ ^[0-9]+-[0-9]+$ ]]; then
                            # Range input (e.g., 2-4)
                            local start=${token%-*}
                            local end=${token#*-}
                            if (( start < 1 || end < 1 || start > end )); then
                                log_error "Range tidak valid: $token"
                                valid_input=0
                                continue
                            fi
                            for ((k=start; k<=end; k++)); do
                                local idx=$((k-1))
                                if (( idx >= 0 && idx < ${#g_scripts[@]} )); then
                                    if [[ ${g_selected_status[$idx]} -eq 1 ]]; then 
                                        g_selected_status[$idx]=0
                                    else 
                                        g_selected_status[$idx]=1
                                    fi
                                fi
                            done
                        elif [[ "$token" =~ ^[0-9]+$ ]]; then
                            # Single number
                            local idx=$((token-1))
                            if (( idx >= 0 && idx < ${#g_scripts[@]} )); then
                                if [[ ${g_selected_status[$idx]} -eq 1 ]]; then 
                                    g_selected_status[$idx]=0
                                else 
                                    g_selected_status[$idx]=1
                                fi
                            else
                                log_error "Nomor di luar jangkauan: $token"
                                valid_input=0
                            fi
                        else
                            log_error "Input tidak valid: $token"
                            valid_input=0
                        fi
                    done
                    
                    if [[ $valid_input -eq 0 ]]; then
                        printf "\n${C_DIM}Tekan Enter untuk melanjutkan...${C_RESET}"
                        read -r
                    fi
                    ;;
            esac
        done
    fi

    # Kumpulkan indeks skrip yang dipilih
    local selected_indexes=()
    for i in "${!g_selected_status[@]}"; do 
        if [[ ${g_selected_status[$i]} -eq 1 ]]; then 
            selected_indexes+=("$i")
        fi
    done

    if [[ ${#selected_indexes[@]} -eq 0 ]]; then
        log_warning "Tidak ada skrip yang dipilih."
        return 1
    fi

    # Tampilkan konfirmasi dan eksekusi
    show_execution_confirmation "${selected_indexes[@]}"
    return $?
}

# Fungsi untuk menampilkan konfirmasi eksekusi
show_execution_confirmation() {
    local selected_indexes=("$@")
    
    show_header
    printf "\n${C_BG_GREEN}${C_BLACK}${C_BOLD} KONFIRMASI EKSEKUSI ${C_RESET}\n\n"
    printf "${C_BOLD}${C_BRIGHT_GREEN}Skrip yang akan dijalankan:${C_RESET}\n\n"
    
    for idx in "${selected_indexes[@]}"; do
        local script_name="$(basename "${g_scripts[$idx]}")"
        local script_desc="$(get_script_description "${g_scripts[$idx]}")"
        
        printf "  ${C_BRIGHT_GREEN}${ICON_SUCCESS}${C_RESET} ${C_BOLD}%-25s${C_RESET}" "$script_name"
        if [[ -n "$script_desc" ]]; then
            printf " ${C_DIM}│ %s${C_RESET}" "$script_desc"
        fi
        printf "\n"
    done
    
    draw_line "─" 75
    printf "\n${C_BRIGHT_YELLOW}${C_BOLD}Pilihan:${C_RESET}\n"
    printf "  ${C_BRIGHT_GREEN}Y/y${C_RESET} - Jalankan skrip sekarang\n"
    printf "  ${C_BRIGHT_BLUE}N/n${C_RESET} - Kembali ke pemilihan skrip\n"
    printf "  ${C_BRIGHT_CYAN}B/b${C_RESET} - Kembali ke menu kategori\n"
    printf "  ${C_BRIGHT_RED}Q/q${C_RESET} - Keluar dari program\n\n"
    
    while true; do
        printf "${C_BRIGHT_CYAN}${C_BOLD}➤ Konfirmasi pilihan Anda [Y/n/b/q]: ${C_RESET}"
        read -r confirm
        
        case "$confirm" in
            [yY]|"") 
                execute_selected_scripts "${selected_indexes[@]}"
                return 0
                ;;
            [nN]) 
                return 1  # Kembali ke pemilihan skrip
                ;;
            [bB]) 
                return 2  # Kembali ke kategori
                ;;
            [qQ]) 
                log_info "Keluar dari program."
                exit 0 
                ;;
            *)
                log_error "Pilihan tidak valid. Gunakan Y/n/b/q"
                ;;
        esac
    done
}

# ====================================================================
# FUNGSI EKSEKUSI SKRIP
# ====================================================================

# Fungsi untuk memeriksa kebutuhan sudo
check_sudo_requirements() {
    local selected_indexes=("$@")
    local needs_sudo=0
    
    for idx in "${selected_indexes[@]}"; do
        if head -n 5 "${g_scripts[$idx]}" | grep -qi "needs-sudo\|require.*sudo\|require.*root"; then
            needs_sudo=1
            break
        fi
    done
    
    if [[ $needs_sudo -eq 1 ]]; then
        log_warning "Beberapa skrip memerlukan hak akses root (sudo)"
        show_loading "Meminta akses sudo" 1
        
        if ! sudo -v; then
            log_error "Gagal mendapatkan hak akses sudo"
            return 1
        fi
        
        log_success "Hak akses sudo berhasil diperoleh"
        return 0
    fi
    
    return 0
}

# Fungsi untuk menjalankan satu skrip
execute_single_script() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"
    local start_time=$(date +%s)
    
    # Cek kebutuhan sudo
    local needs_sudo=0
    if head -n 5 "$script_path" | grep -qi "needs-sudo\|require.*sudo\|require.*root"; then
        needs_sudo=1
    fi
    
    printf "\n${C_BG_BLUE}${C_WHITE}${C_BOLD} MENJALANKAN: %-30s ${C_RESET}\n" "$script_name"
    draw_line "─" 75
    
    # Pastikan skrip executable
    chmod +x "$script_path" 2>/dev/null || true
    
    # Jalankan skrip
    local cmd="bash"
    if [[ $needs_sudo -eq 1 ]]; then
        log_info "Skrip ini memerlukan akses root"
        cmd="sudo bash"
    fi
    
    printf "${C_DIM}Perintah: %s \"%s\"${C_RESET}\n" "$cmd" "$script_path"
    draw_line "·" 75
    
    if $cmd "$script_path"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        draw_line "─" 75
        log_success "Skrip '$script_name' berhasil dijalankan (${duration}s)"
        return 0
    else
        local exit_code=$?
        draw_line "─" 75
        log_error "Skrip '$script_name' gagal dijalankan (exit code: $exit_code)"
        return $exit_code
    fi
}

# Fungsi utama untuk eksekusi skrip terpilih
execute_selected_scripts() {
    local selected_indexes=("$@")
    
    # Header eksekusi
    show_header
    printf "\n${C_BG_GREEN}${C_BLACK}${C_BOLD} MEMULAI EKSEKUSI SKRIP ${C_RESET}\n"
    printf "${C_BRIGHT_GREEN}Total skrip yang akan dijalankan: ${C_BOLD}%d${C_RESET}\n\n" "${#selected_indexes[@]}"
    
    # Setup interrupt handler
    trap 'log_warning "Eksekusi dibatalkan oleh pengguna"; exit 130' INT
    
    # Periksa kebutuhan sudo di awal
    if ! check_sudo_requirements "${selected_indexes[@]}"; then
        log_error "Tidak dapat melanjutkan tanpa akses sudo yang diperlukan"
        return 1
    fi
    
    # Array untuk tracking hasil
    declare -a succeeded_scripts=()
    declare -a failed_scripts=()
    local total_duration=0
    local overall_start=$(date +%s)
    
    # Eksekusi setiap skrip
    for i in "${!selected_indexes[@]}"; do
        local idx="${selected_indexes[$i]}"
        local script_path="${g_scripts[$idx]}"
        local script_name="$(basename "$script_path")"
        
        printf "\n${C_BRIGHT_CYAN}${C_BOLD}[%d/%d]${C_RESET} " "$((i+1))" "${#selected_indexes[@]}"
        
        if execute_single_script "$script_path"; then
            succeeded_scripts+=("$script_name")
        else
            failed_scripts+=("$script_name")
            
            # Tanyakan apakah ingin melanjutkan jika ada error
            if [[ $((i+1)) -lt ${#selected_indexes[@]} ]]; then
                printf "\n${C_BRIGHT_YELLOW}${ICON_WARNING} Skrip gagal dijalankan.${C_RESET}\n"
                printf "${C_CYAN}Lanjutkan ke skrip berikutnya? [Y/n]: ${C_RESET}"
                read -r continue_choice
                
                if [[ "$continue_choice" =~ ^[nN]$ ]]; then
                    log_info "Eksekusi dihentikan oleh pengguna"
                    break
                fi
            fi
        fi
    done
    
    # Hitung durasi total
    local overall_end=$(date +%s)
    total_duration=$((overall_end - overall_start))
    
    # Tampilkan ringkasan
    show_execution_summary "$total_duration" "${succeeded_scripts[@]}" "---SEPARATOR---" "${failed_scripts[@]}"
}

# Fungsi untuk menampilkan ringkasan eksekusi
show_execution_summary() {
    local total_duration="$1"
    shift
    
    # Pisahkan antara succeeded dan failed scripts
    local succeeded_scripts=()
    local failed_scripts=()
    local parsing_succeeded=true
    
    for arg in "$@"; do
        if [[ "$arg" == "---SEPARATOR---" ]]; then
            parsing_succeeded=false
            continue
        fi
        
        if [[ "$parsing_succeeded" == true ]]; then
            succeeded_scripts+=("$arg")
        else
            failed_scripts+=("$arg")
        fi
    done
    
    printf "\n\n"
    draw_line "═" 75
    printf "${C_BG_MAGENTA}${C_WHITE}${C_BOLD} RINGKASAN EKSEKUSI ${C_RESET}\n"
    draw_line "═" 75
    
    printf "\n${C_BRIGHT_BLUE}${ICON_INFO} ${C_BOLD}Statistik Eksekusi:${C_RESET}\n"
    printf "  • Total waktu eksekusi: ${C_BOLD}%d detik${C_RESET}\n" "$total_duration"
    printf "  • Skrip berhasil: ${C_BRIGHT_GREEN}${C_BOLD}%d${C_RESET}\n" "${#succeeded_scripts[@]}"
    printf "  • Skrip gagal: ${C_BRIGHT_RED}${C_BOLD}%d${C_RESET}\n" "${#failed_scripts[@]}"
    
    if [[ ${#succeeded_scripts[@]} -gt 0 ]]; then
        printf "\n${C_BRIGHT_GREEN}${ICON_SUCCESS} ${C_BOLD}Skrip Berhasil:${C_RESET}\n"
        for script in "${succeeded_scripts[@]}"; do
            printf "  ${C_BRIGHT_GREEN}✓${C_RESET} %s\n" "$script"
        done
    fi
    
    if [[ ${#failed_scripts[@]} -gt 0 ]]; then
        printf "\n${C_BRIGHT_RED}${ICON_ERROR} ${C_BOLD}Skrip Gagal:${C_RESET}\n"
        for script in "${failed_scripts[@]}"; do
            printf "  ${C_BRIGHT_RED}✗${C_RESET} %s\n" "$script"
        done
    fi
    
    draw_line "═" 75
    
    if [[ ${#failed_scripts[@]} -eq 0 ]]; then
        log_success "Semua skrip berhasil dijalankan!"
    else
        log_warning "Beberapa skrip mengalami masalah saat eksekusi"
    fi
    
    printf "\n${C_DIM}Tekan Enter untuk kembali ke menu utama...${C_RESET}"
    read -r
}

# ====================================================================
# MAIN PROGRAM EXECUTION
# ====================================================================

# Jalankan program utama
main_loop

# Pesan penutup
printf "\n${C_BRIGHT_GREEN}${ICON_SUCCESS} ${C_BOLD}Terima kasih telah menggunakan HADES Script Manager!${C_RESET}\n"
printf "${C_DIM}Dibuat dengan ❤️  untuk memudahkan pengelolaan skrip${C_RESET}\n\n"