#!/bin/bash

# Liste der zu installierenden Programme
PROGRAMS="wezterm zsh tmux git stow python python-pip feh curl lazygit zoxide fzf"

# Funktion zur Überprüfung, ob ein Befehl existiert
command_exists() {
    command -v "$1" &> /dev/null
}

# Funktion die xfce4-terminal als Standard-Terminalemulator festlegt
set_wezterm() {
    local package_manager=$1
    if [ "$PACKAGE_MANAGER" = "apt" ]; then
        sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/wezterm 50
        sudo update-alternatives --set x-terminal-emulator /usr/bin/wezterm
    elif [ "$PACKAGE_MANAGER" = "pacman" ]; then
        sudo ln -sf /usr/bin/wezterm /usr/local/bin/x-terminal-emulator
    fi
    echo "wezterm is set as the default terminal emulator."

}


# Funktion zur Installation der Programme
install_programs(){
    local package_manager=$1
    local programs=$2

    if [ "$package_manager" = "apt" ]; then
        sudo apt install -y $programs
    elif [ "$package_manager" = "pacman" ]; then
        sudo pacman -Syu #--noconfirm
        
    else
        echo "Unsupported package manager. This script supports apt and pacman."
        exit 1
    fi
}

# Bestimmen des Paketmanagers und Installieren der Programme
if command_exists apt; then
    PACKAGE_MANAGER="apt"
    sudo apt update && sudo apt upgrade -y
elif command_exists pacman; then
    PACKAGE_MANAGER="pacman"
    sudo pacman -S --noconfirm $programs
else
    echo "Unsupported package manager. This script supports apt and pacman."
    exit 1
fi

# Programme installieren
install_programs $PACKAGE_MANAGER "$PROGRAMS"

# Setzen des xfce4-terminal als Standard-Terminalemulator
set_wezterm $PACKAGE_MANAGER

# Installationen überprüfen
echo "Verifying installations..."
for cmd in $PROGRAMS; do
    if command_exists $cmd; then
        echo "$cmd is installed."
    else
        echo "$cmd is NOT installed."
    fi
done



# Standard-Shell auf zsh setzen
chsh -s $(which zsh)


# Dotfiles klonen und stow verwenden
DOTFILES_DIR="$HOME/mydotfiles"
if [ -d "$DOTFILES_DIR" ]; then
    echo "Directory $DOTFILES_DIR already exists. Pulling the latest changes."
    git -C "$DOTFILES_DIR" pull
else
    git clone https://github.com/harfn/mydotfiles.git "$DOTFILES_DIR"
fi
echo 'DOTFILES_DIR='$HOME'/mydotfiles'
cd "$DOTFILES_DIR"
for dir in */ ; do
    stow -R "$dir"
done

#sudo -v ; curl https://rclone.org/install.sh | sudo bash

echo "Script completed."
