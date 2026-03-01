#!/bin/bash

# Argument Data Validation
if [[ $# -ne 1 ]]; then
  echo "Please pass the username as an argument"
  exit 1
fi
USERNAME=$1

# Check if user already exists
if id "$USERNAME" &>/dev/null; then
  echo "User $USERNAME already exists"
  exit 1
fi

# Create the user, and set the default password
sudo useradd -m -s /bin/zsh "$USERNAME"

# Add the user to the docker group
sudo usermod -aG docker "$USERNAME"

# Copy the configuration files
USER_HOMEDIR=$(getent passwd "$USERNAME" | cut -d: -f6)
sudo mkdir -p "$USER_HOMEDIR/.config"
sudo cp ~/.zshrc ~/.xbindkeysrc "$USER_HOMEDIR"
sudo cp /opt/.zsh/bash_aliases "$USER_HOMEDIR/.bash_aliases"
sudo cp -r ~/.config/nvim/ "$USER_HOMEDIR/.config"

sudo ln -s "$USER_HOMEDIR" /home 2>/dev/null || true

# Set byobu to have scroll mode on by default
sudo rm -rf "$USER_HOMEDIR/.byobu" && sudo mkdir -p "$USER_HOMEDIR/.byobu"
echo 'set -g mouse on' | sudo tee -a "$USER_HOMEDIR/.byobu/.tmux.conf"
echo 'set -g default-terminal "tmux-256color"' | sudo tee -a "$USER_HOMEDIR/.byobu/.tmux.conf"
sudo touch "$USER_HOMEDIR/.byobu/.screenrc"

# Set huggingface cache to shared cache (if it exists)
if [ -d "/opt/huggingface" ]; then
  sudo mkdir -p "$USER_HOMEDIR/.cache"
  sudo rm -rf "$USER_HOMEDIR/.cache/huggingface"
  sudo ln -s /opt/huggingface "$USER_HOMEDIR/.cache/huggingface"
fi

# Change user folder permission, and disable others from reading it
sudo chown "$USERNAME:$USERNAME" -R "$USER_HOMEDIR"
sudo chmod o-rwX -R "$USER_HOMEDIR"

# Force user to change password on first login
sudo chage -d 0 "$USERNAME"

# Set default git diff to delta for a nicer UI
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
