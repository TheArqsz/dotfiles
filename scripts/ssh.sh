#!/usr/bin/env zsh

# Ensure the SSH directory exists and has the correct permissions
if ! [[ -d "$HOME/.ssh" ]]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create or set permissions for $HOME/.ssh"
        exit 1
    fi
fi

# Ensure the SSH config file exists and has the correct permissions
if ! [[ -f "$HOME/.ssh/config" ]]; then
    touch "$HOME/.ssh/config" && chmod 600 "$HOME/.ssh/config"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create or set permissions for $HOME/.ssh/config"
        exit 1
    fi
fi

# Check if the configuration already exists before appending
if ! grep -q "ServerAliveInterval 120" "$HOME/.ssh/config"; then
    cat <<EOT >> "$HOME/.ssh/config"
Host *
    ServerAliveInterval 120
    Compression yes
    ControlMaster auto
    ControlPersist 4800
    ControlPath ~/.ssh/.control/.%r.%h.%p.sock
    StrictHostKeyChecking ask
    UserKnownHostsFile ~/.ssh/known_hosts
EOT
fi

# Ensure the control directory exists
if ! [[ -d "$HOME/.ssh/.control" ]]; then
    mkdir -p "$HOME/.ssh/.control"
    chmod 700 "$HOME/.ssh/.control"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to create directory $HOME/.ssh/.control"
        exit 1
    fi
fi