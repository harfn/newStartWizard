#!/bin/bash

# Funktion zur Überprüfung, ob ein Befehl existiert
command_exists() {
    command -v "$1" &> /dev/null
}

# Funktion, die wezterm als Standard-Terminalemulator festlegt
set_wezterm() {
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
    local programs=$2

    if [ "$package_manager" = "apt" ]; then
        sudo apt install -y $programs
    elif [ "$package_manager" = "pacman" ]; then
        sudo pacman -S --noconfirm $programs
    else
        echo "Unsupported package manager. This script supports apt and pacman."
        exit 1
    fi
}

# Funktion zur Installation und Verwaltung der Dotfiles
install_dotfiles() {
    local dotfiles_dir="$HOME/mydotfiles"

    if [ -d "$dotfiles_dir" ]; then
        echo "Directory $dotfiles_dir already exists. Pulling the latest changes."
        git -C "$dotfiles_dir" pull
    else
        git clone https://github.com/harfn/mydotfiles.git "$dotfiles_dir"
    fi

    echo "DOTFILES_DIR=$dotfiles_dir"
    cd "$dotfiles_dir"
    for dir in */ ; do
        stow -R "$dir"
    done
}

# Funktion zur Bestimmung des Paketmanagers
determine_package_manager() {
    if command_exists apt; then
        PACKAGE_MANAGER="apt"
        sudo apt update && sudo apt upgrade -y
    elif command_exists pacman; then
        PACKAGE_MANAGER="pacman"
        sudo pacman -Syu --noconfirm
    else
        echo "Unsupported package manager. This script supports apt and pacman."
        exit 1
    fi
}

# Funktion zur Überprüfung der Installationen
verify_installations() {
    local programs=$1
    echo "Verifying installations..."
    for cmd in $programs; do
        if command_exists $cmd; then
            echo "$cmd is installed."
        else
            echo "$cmd is NOT installed."
        fi
    done
}

# Liste der zu installierenden Programme
PROGRAMS="wezterm zsh tmux git stow python python-pip feh curl lazygit zoxide fzf"

# Main-Teil

# Paketmanager bestimmen
determine_package_manager

# Programme installieren
install_programs "$PACKAGE_MANAGER" "$PROGRAMS"

# Installationen überprüfen
verify_installations "$PROGRAMS"

# Setzen des wezterm als Standard-Terminalemulator
set_wezterm "$PACKAGE_MANAGER"

# Standard-Shell auf zsh setzen
chsh -s "$(which zsh)"

# Dotfiles installieren
install_dotfiles

# Beenden
echo "Script completed."

