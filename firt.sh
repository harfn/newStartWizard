#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Determine package manager and install packages
if command_exists apt; then
    PACKAGE_MANAGER="apt"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y xfce4-terminal zsh tmux git stow python3 python3-pip
elif command_exists pacman; then
    PACKAGE_MANAGER="pacman"
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm xfce4-terminal zsh tmux git stow python python-pip
else
    echo "Unsupported package manager. This script supports apt and pacman."
    exit 1
fi

# Set xfce4-terminal as the default terminal emulator
if [ "$PACKAGE_MANAGER" = "apt" ]; then
    sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/xfce4-terminal 50
    sudo update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal
elif [ "$PACKAGE_MANAGER" = "pacman" ]; then
    sudo ln -sf /usr/bin/xfce4-terminal /usr/local/bin/x-terminal-emulator
fi

# Verify installations
echo "Verifying installations..."
for cmd in xfce4-terminal zsh tmux git stow python3 pip3; do
    if command_exists $cmd; then
        echo "$cmd is installed."
    else
        echo "$cmd is NOT installed."
    fi
done

echo "xfce4-terminal is set as the default terminal emulator."

# Optionally, you can change the default shell to zsh
# chsh -s $(which zsh)

echo "Script completed."
