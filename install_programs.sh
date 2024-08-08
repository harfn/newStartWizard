#!/bin/bash

# Liste der zu installierenden Programme
PROGRAMS="xfce4-terminal zsh tmux git stow python3 python3-pip"

# Funktion zur Überprüfung, ob ein Befehl existiert
command_exists() {
    command -v "$1" &> /dev/null
}

# Funktion die xfce4-terminal als Standard-Terminalemulator festlegt
set_xfce4_terminal() {
    local package_manager=$1
    if [ "$PACKAGE_MANAGER" = "apt" ]; then
        sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/xfce4-terminal 50
        sudo update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal
    elif [ "$PACKAGE_MANAGER" = "pacman" ]; then
        sudo ln -sf /usr/bin/xfce4-terminal /usr/local/bin/x-terminal-emulator
    fi
    echo "xfce4-terminal is set as the default terminal emulator."

}


# Funktion zur Installation der Programme
install_programs() {
    local package_manager=$1
    local programs=$2

    if [ "$package_manager" = "apt" ]; then
        sudo apt install -y $programs
    elif [ "$package_manager" = "pacman" ]; then
        sudo pacman -Syu --noconfirm
        
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
set_xfce4_terminal $PACKAGE_MANAGER

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


git clone https://github.com/harfn/mydotfiles.git ~/mydotfiles
stow *




echo "Script completed."
