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

# Funktion zur Überprüfung, ob SSH eingerichtet ist und ggf. einrichten
check_ssh_setup() {
    if [ -f "$HOME/.ssh/id_rsa.pub" ] || [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
        echo "SSH is already set up."
    else
        echo "No SSH setup found. Generating a new SSH key..."
        ssh-keygen -t ed25519 -C "your_email@example.com" -f "$HOME/.ssh/id_ed25519" -N "" || return 1
    fi
}

# Funktion, um den SSH-Schlüssel in die Zwischenablage zu kopieren
copy_ssh_key_to_clipboard() {
    if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
        if command_exists xclip; then
            xclip -selection clipboard < "$HOME/.ssh/id_ed25519.pub" || return 1
            echo "The SSH key has been copied to your clipboard."
        elif command_exists pbcopy; then
            pbcopy < "$HOME/.ssh/id_ed25519.pub" || return 1
            echo "The SSH key has been copied to your clipboard."
        else
            echo "Could not copy the SSH key to the clipboard. Please copy it manually:"
            cat "$HOME/.ssh/id_ed25519.pub"
        fi
    else
        echo "SSH public key not found. Please generate it first."
        return 1
    fi
}


# Funktion zur Aufforderung, den SSH-Schlüssel zu GitLab hinzuzufügen
prompt_add_ssh_key_to_gitlab() {
    echo "##############################################################"
    echo "Please add your SSH key to GitLab:"
    echo "URL: https://gitlab.uni-oldenburg.de/-/user_settings/ssh_keys"
    echo "##############################################################"

    # Abfrage, ob der SSH-Schlüssel hinzugefügt wurde
    while true; do
        read -p "Did you add the SSH key to GitLab? (y/n/c to copy key again): " yn
        case $yn in
            [Yy]* ) break;;  # Weiter, wenn "y" oder "Y" eingegeben wurde
            [Nn]* ) echo "Please add the SSH key to GitLab and then confirm.";;
            [Cc]* ) 
                if ! copy_ssh_key_to_clipboard; then
                    echo "Error: Failed to copy SSH key to clipboard." >&2
                    exit 1
                fi
                echo "The SSH key has been copied to your clipboard again."
                ;;
            * ) echo "Please answer yes (y), no (n), or copy (c).";;
        esac
    done
}

# Funktion zur Aufforderung, den SSH-Schlüssel zu GitHub hinzuzufügen
prompt_add_ssh_key_to_github(){
    echo "##############################################################"
    echo "Please add your SSH key to GitHub:"
    echo "URL: https://github.com/settings/keys"
    echo "##############################################################"

    # Abfrage, ob der SSH-Schlüssel hinzugefügt wurde
    while true; do
        read -p "Did you add the SSH key to GitHub? (y/n/c to copy key again): " yn
        case $yn in
            [Yy]* ) break;;  # Weiter, wenn "y" oder "Y" eingegeben wurde
            [Nn]* ) echo "Please add the SSH key to GitHub and then confirm.";;
            [Cc]* ) 
                if ! copy_ssh_key_to_clipboard; then
                    echo "Error: Failed to copy SSH key to clipboard." >&2
                    exit 1
                fi
                echo "The SSH key has been copied to your clipboard again."
                ;;
            * ) echo "Please answer yes (y), no (n), or copy (c).";;
        esac
    done
}


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

check_ssh_setup
prompt_add_ssh_key_to_gitlab
prompt_add_ssh_key_to_github

# Dotfiles installieren
install_dotfiles



# Beenden
echo "Script completed."

