#!/usr/bin/env bash
# Installer OCaml + OPAM untuk Linux
# By Hendra 😎

set -euo pipefail
export OPAMYES=1
export OPAMJOBS="${OPAMJOBS:-$(command -v nproc >/dev/null 2>&1 && nproc || echo 2)}"

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

# ---------- Install deps ----------
install_deps() {
  log "Menginstall dependency dasar..."
  case "$PKG_MGR" in
    pacman) as_root pacman -Sy --noconfirm curl m4 git unzip base-devel ;; 
    apt) as_root apt-get update -y && as_root apt-get install -y curl m4 git unzip bubblewrap build-essential pkg-config ;; 
    dnf) as_root dnf install -y curl m4 git unzip gcc make patch pkgconfig ;; 
    yum) as_root yum install -y curl m4 git unzip gcc make patch pkgconfig ;; 
    zypper) as_root zypper --non-interactive install curl m4 git unzip gcc make patch pkg-config ;; 
    apk) as_root apk add --no-cache curl m4 git unzip build-base ;; 
  esac
}

# ---------- Install opam ----------
install_opam() {
  if need_cmd opam; then
    log "opam sudah terpasang."
    return
  fi
  log "Menginstall opam..."
  case "$PKG_MGR" in
    pacman) as_root pacman -Sy --noconfirm opam ;;
    apt) as_root apt-get install -y opam ;;
    dnf) as_root dnf install -y opam ;;
    yum) as_root yum install -y opam ;;
    zypper) as_root zypper --non-interactive install opam ;;
    apk)
      log "Membangun opam dari script resmi..."
      sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)
      ;;
  esac
}

# ---------- Init & Install OCaml ----------
install_ocaml() {
  if [ ! -d "$HOME/.opam" ]; then
    log "Inisialisasi opam..."
    opam init --disable-sandboxing
  fi

  log "Memperbarui repository opam..."
  opam update

  CURRENT_SWITCH="$(opam switch show 2>/dev/null || echo default)"
  if ! opam switch list --short | grep -qx "default"; then
    log "Membuat switch default dengan compiler OCaml terbaru..."
    opam switch create default ocaml-base-compiler.latest
  else
    log "Switch default sudah ada. Menggunakan switch default."
  fi

  eval "$(opam env --switch=default)"
}

# ---------- Setup PATH ----------
setup_path() {
  # Tambahkan ke bashrc
  if [ -f "$HOME/.bashrc" ] && ! grep -qs 'opam env' "$HOME/.bashrc" 2>/dev/null; then
    echo 'eval "$(opam env)"' >> "$HOME/.bashrc"
  fi
  # Tambahkan ke zshrc jika ada
  if [ -f "$HOME/.zshrc" ] && ! grep -qs 'opam env' "$HOME/.zshrc" 2>/dev/null; then
    echo 'eval "$(opam env)"' >> "$HOME/.zshrc"
  fi
}

# ---------- Verifikasi ----------
verify_ocaml() {
  log "Verifikasi instalasi:"
  ocaml -version
  opam --version
  command -v ocamlc >/dev/null 2>&1 && ocamlc -version || true
}

# ---------- Main ----------
main() {
  detect_pkg_mgr
  install_deps
  install_opam
  install_ocaml
  setup_path
  verify_ocaml
  log "Instalasi OCaml selesai 🎉. Jalankan: ocaml -version"
}

main "$@"
