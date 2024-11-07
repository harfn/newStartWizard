#!/bin/bash

# Liste der zu installierenden Programme und deren Kommandos
PROGRAMS=(
    "wezterm:wezterm"           # Modernes Terminal mit GPU-Beschleunigung und vielen Anpassungsoptionen
    "zsh:zsh"                   # Alternative Shell, die viele nützliche Funktionen und Plugins bietet
    "tmux:tmux"                 # Terminal-Multiplexer zum Verwalten mehrerer Sitzungen in einem Terminal
    "git:git"                   # Versionskontrollsystem, das zur Verwaltung von Quellcode verwendet wird
    "stow:stow"                 # Tool zur Verwaltung von Symbolischen Links, nützlich für Dotfiles
    "python:python"             # Programmiersprache, weit verbreitet in der Entwicklung und Skripterstellung
    "python-pip:pip"            # Paketmanager für Python, zur Installation von Python-Paketen
    "feh:feh"                   # Schneller und leichter Bildbetrachter für X
    "curl:curl"                 # Werkzeug zur Übertragung von Daten mit URL-Syntax
    "lazygit:lazygit"           # Einfache und schnelle Benutzeroberfläche für Git im Terminal
    "zoxide:zoxide"             # Schnellere Alternative zu cd, die Verzeichniswechsel effizienter macht
    "fzf:fzf"                   # Fuzzy Finder für schnelle Suche im Terminal
    "task:task"                 # Taskwarrior CLI zur Aufgabenverwaltung
    "timew:timew"               # Zeiterfassungstool
    "taskwarrior-tui:taskwarrior-tui" # TUI für Taskwarrior
    "r:R"                       # Programmiersprache und Umgebung für statistische Berechnungen
    "base-devel:gcc"            # Basis-Entwicklungswerkzeuge, erforderlich für NVIM und viele Softwarekompilierungen
    "neovim:nvim"               # Neovim, eine erweiterbare und verbesserte Version des Vim-Editors für effiziente Textbearbeitung
)

# Funktion zur Überprüfung, ob ein Befehl existiert
command_exists() {
    command -v "$1" &> /dev/null
}

# Fehlerprotokollierung
log_error() {
    echo "[ERROR] $1" >&2
}

# Funktion, die wezterm als Standard-Terminalemulator festlegt
set_wezterm() {
    if ! command_exists wezterm; then
        log_error "wezterm is not installed. Skipping setting it as default terminal emulator."
        return 1
    fi
    local package_manager=$1
    if [ "$package_manager" = "apt" ]; then
        sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/wezterm 50
        sudo update-alternatives --set x-terminal-emulator /usr/bin/wezterm
    elif [ "$package_manager" = "pacman" ]; then
        sudo ln -sf /usr/bin/wezterm /usr/local/bin/x-terminal-emulator
    fi
    echo "wezterm is set as the default terminal emulator."
}

# Funktion zur Installation der Programme
install_programs() {
    local package_manager=$1
    local programs=(${@:2})

    if [ "$package_manager" = "apt" ]; then
        for program in "${programs[@]}"; do
            local pkg_name="${program%%:*}"
            sudo apt install -y "$pkg_name" || log_error "Failed to install $pkg_name with apt."
        done
    elif [ "$package_manager" = "pacman" ]; then
        for program in "${programs[@]}"; do
            local pkg_name="${program%%:*}"
            if ! command_exists "${program##*:}"; then
                sudo pacman -S --noconfirm "$pkg_name" || log_error "Failed to install $pkg_name with pacman."
            else
                echo "$pkg_name is already installed. Skipping."
            fi
        done
    else
        log_error "Unsupported package manager. This script supports apt and pacman."
        exit 1
    fi
}

# Funktion zur Installation und Verwaltung der Dotfiles
install_dotfiles() {
    local dotfiles_dir="$HOME/mydotfiles"

    if [ -d "$dotfiles_dir" ]; then
        echo "Directory $dotfiles_dir already exists. Pulling the latest changes."
        git -C "$dotfiles_dir" pull || log_error "Failed to pull latest changes for dotfiles."
    else
        git clone https://github.com/harfn/mydotfiles.git "$dotfiles_dir" || log_error "Failed to clone dotfiles repository."
    fi

    echo "DOTFILES_DIR=$dotfiles_dir"
    cd "$dotfiles_dir" || exit 1
    for dir in */ ; do
        stow -R "$dir" || log_error "Failed to stow $dir."
    done
}

# Funktion zur Bestimmung des Paketmanagers
determine_package_manager() {
    if command_exists apt; then
        PACKAGE_MANAGER="apt"
        sudo apt update && sudo apt upgrade -y || log_error "Failed to update or upgrade packages with apt."
    elif command_exists pacman; then
        PACKAGE_MANAGER="pacman"
        sudo pacman -Syu --noconfirm || log_error "Failed to synchronize packages with pacman."
    else
        log_error "No supported package manager found (apt or pacman)."
        exit 1
    fi
}

# Funktion zur Überprüfung der Installationen
verify_installations() {
    for program in "$@"; do
        local cmd_name="${program##*:}"
        if command_exists "$cmd_name"; then
            echo "$cmd_name is installed."
        else
            log_error "$cmd_name is NOT installed. Please check the installation manually."
        fi
    done
}

# Funktion zur Konfiguration von zsh als Standard-Shell
set_default_shell_to_zsh() {
    if command_exists zsh; then
        chsh -s "$(command -v zsh)" || log_error "Failed to set zsh as default shell."
    else
        log_error "zsh is not installed, cannot set it as default shell."
    fi
}

# Main-Teil

# Paketmanager bestimmen
determine_package_manager

# Programme installieren
install_programs "$PACKAGE_MANAGER" "${PROGRAMS[@]}"

# Installationen überprüfen
verify_installations "${PROGRAMS[@]}"

# Setzen des wezterm als Standard-Terminalemulator
set_wezterm "$PACKAGE_MANAGER"

# Standard-Shell auf zsh setzen
set_default_shell_to_zsh

# Dotfiles installieren
install_dotfiles

# Beenden
echo "Script completed successfully."

