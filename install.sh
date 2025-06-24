#!/bin/bash
set -e

# Prompt to create a new user
read -rp "Do you want to create a new user? (y/n): " CREATE_USER
CREATE_USER=$(echo "$CREATE_USER" | tr '[:upper:]' '[:lower:]')

if [[ "$CREATE_USER" == "y" || "$CREATE_USER" == "yes" ]]; then
  read -rp "Enter the username to create: " NEW_USER

  # Check if the user already exists
  if id "$NEW_USER" >/dev/null 2>&1; then
    echo "User '$NEW_USER' already exists."
  else
    # Create user with home directory
    sudo adduser --gecos "" "$NEW_USER"

    # Ensure docker group exists
    if ! getent group docker >/dev/null 2>&1; then
      sudo groupadd docker
    fi

    # Add user to docker group
    sudo usermod -aG docker "$NEW_USER"
    echo "User '$NEW_USER' added to 'docker' group. Docker will be usable without sudo after re-login."
  fi

  echo "Switching to user '$NEW_USER'..."
  exec su - "$NEW_USER"
fi

# Install zsh if not present
if ! command -v zsh >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y zsh
fi

# Verify zsh installation
zsh --version

# Make zsh the default shell
if [ "$SHELL" != "$(command -v zsh)" ]; then
  chsh -s "$(command -v zsh)"
fi

# Install Oh My Zsh if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  export RUNZSH=no
  export CHSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install Powerlevel10k theme
THEME_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$THEME_DIR" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_DIR"
fi

# Install useful Oh My Zsh plugins
PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
if [ ! -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_DIR/zsh-syntax-highlighting"
fi
if [ ! -d "$PLUGIN_DIR/fast-syntax-highlighting" ]; then
  git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$PLUGIN_DIR/fast-syntax-highlighting"
fi
if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
fi

# Configure theme in ~/.zshrc
if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
  sed -i 's#^ZSH_THEME=.*#ZSH_THEME="powerlevel10k/powerlevel10k"#' "$HOME/.zshrc"
else
  echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$HOME/.zshrc"
fi

# Configure plugins in ~/.zshrc
PLUGIN_LINE='plugins=(git zsh-syntax-highlighting fast-syntax-highlighting zsh-autosuggestions)'
if grep -q '^plugins=' "$HOME/.zshrc"; then
  sed -i "s/^plugins=.*/$PLUGIN_LINE/" "$HOME/.zshrc"
else
  echo "$PLUGIN_LINE" >> "$HOME/.zshrc"
fi

# Install Docker if not installed
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not found. Installing Docker..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  echo "Docker is already installed."
fi

# Show Docker versions
docker --version
docker compose version
