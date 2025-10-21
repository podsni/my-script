#!/usr/bin/env bash
# Neovim Installer Script
# By Hendra 😎
# 
# Description: Installs Neovim with interactive choice of stable or nightly version
# Supports multiple Linux distributions: Ubuntu/Debian, Fedora, Arch, Alpine
# Prerequisites: curl, bash, sudo (for most operations)
# Usage: ./neovim-install.sh [--help]

set -euo pipefail

# Color definitions
declare -r C_RESET='\033[0m'
declare -r C_BOLD='\033[1m'
declare -r C_RED='\033[0;31m'
declare -r C_GREEN='\033[0;32m'
declare -r C_YELLOW='\033[0;33m'
declare -r C_BLUE='\033[0;34m'

# Logging functions
log_info() {
    printf "${C_BLUE}ℹ️ %s${C_RESET}\n" "$*"
}

log_success() {
    printf "${C_GREEN}✅ %s${C_RESET}\n" "$*"
}

log_warning() {
    printf "${C_YELLOW}⚠️ %s${C_RESET}\n" "$*"
}

log_error() {
    printf "${C_RED}❌ %s${C_RESET}\n" "$*"
}

# Help function
show_help() {
    cat << EOF
Neovim Installer Script

DESCRIPTION:
    Installs Neovim with interactive choice of stable or nightly version.
    Supports multiple Linux distributions.

USAGE:
    ./neovim-install.sh [OPTIONS]

OPTIONS:
    --help       Show this help message

SUPPORTED DISTRIBUTIONS:
    - Ubuntu/Debian (uses PPA)
    - Fedora (uses COPR)
    - Arch Linux (uses AUR)
    - Alpine Linux (uses apk)

EXAMPLES:
    ./neovim-install.sh

EOF
}

# Check for required commands
need_cmd() { 
    command -v "$1" >/dev/null 2>&1 || {
        log_error "Required command '$1' not found"
        exit 1
    }
}

# Handle sudo requirements
as_root() {
    if [ "${EUID:-$(id -u)}" -ne 0 ]; then
        if need_cmd sudo; then 
            sudo "$@"
        else
            log_error "Root access required. Install sudo or run as root."
            exit 1
        fi
    else
        "$@"
    fi
}

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO="rhel"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
    else
        DISTRO="unknown"
    fi
    
    log_info "Detected distribution: $DISTRO"
}

# Install package based on distribution
install_package() {
    local package="$1"
    
    case $DISTRO in
        ubuntu|debian)
            as_root DEBIAN_FRONTEND=noninteractive apt-get install -y "$package"
            ;;
        fedora)
            as_root dnf install -y "$package"
            ;;
        arch|manjaro)
            as_root pacman -S --noconfirm "$package"
            ;;
        alpine)
            as_root apk add "$package"
            ;;
        *)
            log_error "Unsupported distribution: $DISTRO"
            return 1
            ;;
    esac
}


# Install Neovim on Ubuntu/Debian
install_neovim_ubuntu() {
    local version="$1"
    
    log_info "Installing Neovim on Ubuntu/Debian..."
    
    # Install prerequisites
    install_package "software-properties-common"
    
    if [[ "$version" == "nightly" ]]; then
        log_info "Adding Neovim nightly PPA..."
        as_root add-apt-repository -y ppa:neovim-ppa/unstable
    else
        log_info "Adding Neovim stable PPA..."
        as_root add-apt-repository -y ppa:neovim-ppa/stable
    fi
    
    as_root apt-get update
    install_package "neovim"
}

# Install Neovim on Fedora
install_neovim_fedora() {
    local version="$1"
    
    log_info "Installing Neovim on Fedora..."
    
    if [[ "$version" == "nightly" ]]; then
        log_info "Installing Neovim nightly from COPR..."
        as_root dnf copr enable -y agriffis/neovim-nightly
    fi
    
    install_package "neovim"
}

# Install Neovim on Arch Linux
install_neovim_arch() {
    local version="$1"
    
    log_info "Installing Neovim on Arch Linux..."
    
    if [[ "$version" == "nightly" ]]; then
        log_info "Installing Neovim nightly from AUR..."
        if command -v yay >/dev/null 2>&1; then
            yay -S --noconfirm neovim-nightly-bin
        elif command -v paru >/dev/null 2>&1; then
            paru -S --noconfirm neovim-nightly-bin
        else
            log_warning "AUR helper not found, installing stable version instead"
            install_package "neovim"
        fi
    else
        install_package "neovim"
    fi
}

# Install Neovim on Alpine Linux
install_neovim_alpine() {
    local version="$1"
    
    log_info "Installing Neovim on Alpine Linux..."
    
    if [[ "$version" == "nightly" ]]; then
        log_warning "Nightly version not available on Alpine, installing stable version"
    fi
    
    install_package "neovim"
}

# Verify Neovim installation
verify_installation() {
    log_info "Verifying Neovim installation..."
    
    if command -v nvim >/dev/null 2>&1; then
        local version=$(nvim --version | head -n1)
        log_success "Neovim is installed: $version"
        return 0
    else
        log_error "Neovim command not found"
        return 1
    fi
}

# Main installation function
install_neovim() {
    local version="$1"
    
    log_info "Starting Neovim installation..."
    log_info "Version: $version"
    
    # Check prerequisites
    need_cmd "curl"
    need_cmd "bash"
    
    # Detect distribution
    detect_distro
    
    # Install based on distribution
    case $DISTRO in
        ubuntu|debian)
            install_neovim_ubuntu "$version"
            ;;
        fedora)
            install_neovim_fedora "$version"
            ;;
        arch|manjaro)
            install_neovim_arch "$version"
            ;;
        alpine)
            install_neovim_alpine "$version"
            ;;
        *)
            log_error "Unsupported distribution: $DISTRO"
            log_info "Supported distributions: Ubuntu, Debian, Fedora, Arch Linux, Alpine"
            exit 1
            ;;
    esac
    
    # Verify installation
    if verify_installation; then
        log_success "Neovim installation completed successfully!"
        log_info "You can now run 'nvim' to start Neovim"
    else
        log_error "Installation verification failed"
        exit 1
    fi
}

# Main function
main() {
    # Check for help first
    for arg in "$@"; do
        if [[ "$arg" == "--help" ]]; then
            show_help
            exit 0
        fi
    done
    
    log_info "Neovim Installer Script"
    log_info "======================"
    
    # Interactive version selection
    echo
    log_info "Choose Neovim version:"
    echo "1) Stable (recommended for production)"
    echo "2) Nightly (latest features, may be unstable)"
    echo
    read -p "Enter your choice (1-2): " -n 1 -r
    echo
    
    local version="stable"
    case $REPLY in
        1)
            version="stable"
            ;;
        2)
            version="nightly"
            ;;
        *)
            log_warning "Invalid choice, defaulting to stable"
            version="stable"
            ;;
    esac
    
    # Confirm installation
    echo
    log_info "Installation details:"
    log_info "  Version: $version"
    log_info "  Distribution: Will be auto-detected"
    echo
    
    read -p "Do you want to proceed with the installation? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_neovim "$version"
    else
        log_info "Installation cancelled"
        exit 0
    fi
}

# Run main function with all arguments
main "$@"
