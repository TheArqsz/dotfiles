#!/usr/bin/env zsh

if ! [[ -f "$HOME/.ssh/config" ]]; then
    touch "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
    cat <<EOT >> "$HOME/.ssh/config"
Host *
    ServerAliveInterval 120
    Compression yes
    ControlMaster auto
    ControlPersist 4800
    ControlPath ~/.ssh/.control/.%r.%h.%p.sock
EOT
fi

if ! [[ -d "$HOME/.ssh/.control" ]]; then
    mkdir -p "$HOME/.ssh/.control"
fi