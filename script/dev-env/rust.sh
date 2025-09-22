#!/usr/bin/env bash
# Installer Rust otomatis + auto-deps untuk Linux
# By Hendra 😎

set -euo pipefail

need_cmd() { command -v "$1" >/dev/null 2>&1; }
as_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    if need_cmd sudo; then sudo "$@"; else
      echo "Butuh root. Install sudo atau jalankan sebagai root." >&2
      exit 1
    fi
  else
    "$@"
  fi
}

log() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
err() { printf "\033[1;31mxx\033[0m %s\n" "$*" >&2; exit 1; }

# ---------- Deteksi package manager ----------
PKG_MGR=""
detect_pkg_mgr() {
  if need_cmd pacman; then PKG_MGR="pacman"
  elif need_cmd apt-get; then PKG_MGR="apt"
  elif need_cmd dnf; then PKG_MGR="dnf"
  elif need_cmd yum; then PKG_MGR="yum"
  elif need_cmd zypper; then PKG_MGR="zypper"
  elif need_cmd apk; then PKG_MGR="apk"
  else
    err "Tidak menemukan package manager yang didukung."
  fi
}

# ---------- Install alat jaringan (curl) jika belum ada ----------
install_curl() {
  if need_cmd curl; then
    log "curl sudah terpasang."
    return
  fi

  log "Menginstall curl..."
  case "$PKG_MGR" in
    pacman) as_root pacman -Sy --noconfirm curl ;;
    apt) as_root apt-get update -y && as_root apt-get install -y curl ;;
    dnf) as_root dnf install -y curl ;;
    yum) as_root yum install -y curl ;;
    zypper) as_root zypper --non-interactive install curl ;;
    apk) as_root apk add --no-cache curl ;;
  esac
}

# ---------- Install toolchain build dependensi ----------
install_build_deps() {
  log "Menginstall dependency build untuk Rust..."
  case "$PKG_MGR" in
    pacman) as_root pacman -Sy --noconfirm base-devel pkgconf openssl ;; 
    apt) as_root apt-get install -y build-essential pkg-config libssl-dev ;; 
    dnf) as_root dnf install -y gcc make patch pkgconfig openssl-devel ;; 
    yum) as_root yum install -y gcc make patch pkgconfig openssl-devel ;; 
    zypper) as_root zypper --non-interactive install gcc make patch pkg-config libopenssl-devel ;; 
    apk) as_root apk add --no-cache build-base pkgconf openssl-dev ;; 
  esac
}

# ---------- Install Rust ----------
install_rust() {
  if need_cmd rustup; then
    log "rustup sudah terpasang. Memperbarui toolchain..."
    rustup self update || true
    rustup update
  else
    log "Menginstall Rust via rustup (non-interaktif)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable
  fi

  # shellcheck disable=SC1090
  [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

  # Pastikan komponen penting ada
  if need_cmd rustup; then
    rustup component add rustfmt clippy || true
  fi
}

# ---------- Load PATH & verifikasi ----------
ensure_path() {
  # Tambahkan sourcing cargo/env ke shell rc secara idempoten
  if [ -f "$HOME/.bashrc" ] && ! grep -qs 'source \$HOME/.cargo/env' "$HOME/.bashrc" 2>/dev/null; then
    echo 'source $HOME/.cargo/env' >> "$HOME/.bashrc"
  fi
  if [ -f "$HOME/.zshrc" ] && ! grep -qs 'source \$HOME/.cargo/env' "$HOME/.zshrc" 2>/dev/null; then
    echo 'source $HOME/.cargo/env' >> "$HOME/.zshrc"
  fi
}

verify_rust() {
  # shellcheck disable=SC1090
  [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
  log "Verifikasi Rust:"
  rustc --version || true
  cargo --version || true
  command -v rustfmt >/dev/null 2>&1 && rustfmt --version || true
  command -v cargo-clippy >/dev/null 2>&1 && cargo clippy -V || true
}

# ---------- Main ----------
main() {
  detect_pkg_mgr
  install_curl
    install_build_deps
  install_rust
    ensure_path
  verify_rust
  log "Instalasi selesai 🎉. Jalankan 'source ~/.cargo/env' jika PATH belum aktif."
}

main "$@"
