#!/bin/bash
set -euo pipefail

# =========================
# Usage:
#   ./setup.sh             # nur CLI-Programme
#   ./setup.sh --with-gui  # CLI + GUI-Programme
# =========================

WITH_GUI=false
if [[ "${1-}" == "--with-gui" ]]; then
  WITH_GUI=true
fi

# --------- Paketlisten ---------
# Terminal-/CLI-Programme (immer)
CLI_PROGRAMS=(
  "zsh:zsh"
  "tmux:tmux"
  "git:git"
  "stow:stow"
  "python:python"
  "python-pip:pip"
  "curl:curl"
  "lazygit:lazygit"
  "zoxide:zoxide"
  "fzf:fzf"
  "task:task"
  "timew:timew"
  "taskwarrior-tui:taskwarrior-tui"
  "r:R"
  "base-devel:gcc"      # Arch: base-devel; als Marker 'gcc'
  "nodejs:node"
  "npm:npm"
  "neovim:nvim"
  "pandoc:pandoc"
  "eza:eza"
  "tldr:tldr"
  "fastfetch:fastfetch"
  "bat:bat"             # unter Debian/Ubuntu heißt Binary oft 'batcat'
  "lf:lf"               # list file  is a command line file manager written in Go 
  "brightnessctl:brightnessctl"
)

# GUI-Programme (nur auf Nachfrage)
GUI_PROGRAMS=(
  "wezterm:wezterm"     # Terminalemulator (GUI)
  "feh:feh"             # Bildbetrachter
  "rofi:rofi"           # App-Launcher
  "polybar:polybar"     # Statusbar
  "positron:positron"   # Positron IDE (ggf. nicht in allen Repos)
)

# --------- Helpers ---------
command_exists() { command -v "$1" &>/dev/null; }
log_error() { echo "[ERROR] $1" >&2; }

determine_package_manager() {
  if command_exists apt; then
    PACKAGE_MANAGER="apt"
    sudo apt update && sudo apt upgrade -y || log_error "apt update/upgrade fehlgeschlagen."
  elif command_exists pacman; then
    PACKAGE_MANAGER="pacman"
    sudo pacman -Syu --noconfirm || log_error "pacman -Syu fehlgeschlagen."
  else
    log_error "Kein unterstützter Paketmanager (apt/pacman) gefunden."
    exit 1
  fi
}

install_programs() {
  local package_manager=$1; shift
  local programs=("$@")

  if [ "$package_manager" = "apt" ]; then
    sudo add-apt-repository -y universe >/dev/null 2>&1 || true
    sudo apt update || true
    for program in "${programs[@]}"; do
      local pkg_name="${program%%:*}"
      if ! sudo apt install -y "$pkg_name"; then
        log_error "Install $pkg_name (apt) fehlgeschlagen."
      fi
    done
  elif [ "$package_manager" = "pacman" ]; then
    for program in "${programs[@]}"; do
      local pkg_name="${program%%:*}"
      local cmd_name="${program##*:}"
      if ! command_exists "$cmd_name"; then
        if ! sudo pacman -S --noconfirm "$pkg_name"; then
          log_error "Install $pkg_name (pacman) fehlgeschlagen."
        fi
      else
        echo "$pkg_name ist bereits installiert – überspringe."
      fi
    done
  fi
}

post_install_fixes() {
  local package_manager=$1
  # Einheitlicher 'bat'-Befehl unter Debian/Ubuntu
  if [ "$package_manager" = "apt" ]; then
    if command_exists batcat && ! command_exists bat; then
      sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
      echo "Symlink /usr/local/bin/bat -> /usr/bin/batcat erstellt."
    fi
  fi
}

set_wezterm() {
  if ! command_exists wezterm; then
    echo "wezterm nicht installiert – Standard-Terminal wird nicht geändert."
    return 0
  fi
  if [ "$1" = "apt" ]; then
    sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/wezterm 50
    sudo update-alternatives --set x-terminal-emulator /usr/bin/wezterm
  elif [ "$1" = "pacman" ]; then
    sudo ln -sf /usr/bin/wezterm /usr/local/bin/x-terminal-emulator
  fi
  echo "wezterm als Standard-Terminal gesetzt."
}

set_default_shell_to_zsh() {
  if command_exists zsh; then
    local zpath
    zpath="$(command -v zsh)"
    if [ "${SHELL-}" != "$zpath" ]; then
      chsh -s "$zpath" || log_error "zsh als Standardshell setzen fehlgeschlagen."
    fi
  else
    log_error "zsh nicht installiert – kann nicht als Standardshell gesetzt werden."
  fi
}

install_dotfiles() {
  local dotfiles_dir="$HOME/mydotfiles"
  if [ -d "$dotfiles_dir" ]; then
    echo "Verzeichnis $dotfiles_dir existiert – hole neueste Änderungen."
    git -C "$dotfiles_dir" pull || log_error "git pull für Dotfiles fehlgeschlagen."
  else
    git clone https://github.com/harfn/mydotfiles.git "$dotfiles_dir" || log_error "Clonen der Dotfiles fehlgeschlagen."
  fi

  echo "DOTFILES_DIR=$dotfiles_dir"
  cd "$dotfiles_dir" || exit 1
  for dir in */ ; do
    stow -R "$dir" || log_error "stow $dir fehlgeschlagen."
  done
}

verify_installations() {
  for program in "$@"; do
    local cmd_name="${program##*:}"
    if command_exists "$cmd_name"; then
      echo "$cmd_name ist installiert."
    else
      log_error "$cmd_name ist NICHT installiert – bitte manuell prüfen."
    fi
  done
}

maybe_ask_for_gui() {
  if $WITH_GUI; then
    return 0
  fi
  # Interaktive Nachfrage (Default: Nein)
  read -r -p "GUI-Komponenten installieren? [y/N] " ans || true
  case "${ans:-N}" in
    y|Y|j|J) WITH_GUI=true ;;
    *) WITH_GUI=false ;;
  esac
}

# --------- Main ---------
determine_package_manager

# Immer: CLI
install_programs "$PACKAGE_MANAGER" "${CLI_PROGRAMS[@]}"

# Optional: GUI
maybe_ask_for_gui
if $WITH_GUI; then
  install_programs "$PACKAGE_MANAGER" "${GUI_PROGRAMS[@]}"
  post_install_fixes "$PACKAGE_MANAGER"
  set_wezterm "$PACKAGE_MANAGER"
else
  post_install_fixes "$PACKAGE_MANAGER"
  echo "GUI-Programme wurden nicht installiert."
fi

# Verifikation
verify_installations "${CLI_PROGRAMS[@]}"
if $WITH_GUI; then
  verify_installations "${GUI_PROGRAMS[@]}"
fi

# Standardshell + Dotfiles
set_default_shell_to_zsh
install_dotfiles

echo "Script completed successfully."

