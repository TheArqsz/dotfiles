#!/usr/bin/env zsh

SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"

# Ensure the SSH config file exists and has the correct permissions
if ! [[ -f "$SSH_CONFIG" ]]; then
	touch "$SSH_CONFIG" && chmod 600 "$SSH_CONFIG"
	if [[ $? -ne 0 ]]; then
		echo "Error: Failed to create or set permissions for $SSH_CONFIG"
		exit 1
	fi
fi

# Ensure the control directory exists
if ! [[ -d "$SSH_DIR/.control" ]]; then
	mkdir -p "$SSH_DIR/.control"
	chmod 700 "$SSH_DIR/.control"
	if [[ $? -ne 0 ]]; then
		echo "Error: Failed to create directory $SSH_DIR/.control"
		exit 1
	fi
fi

if ! grep -q "### DOTFILES MANAGED BLOCK ###" "$SSH_CONFIG"; then
	echo "Adding Dotfiles SSH configuration..."
	cat <<EOT >>"$SSH_CONFIG"

### DOTFILES MANAGED BLOCK ###
Host *
    ServerAliveInterval 120
    Compression yes
    ControlMaster auto
    ControlPersist 4800
    ControlPath ~/.ssh/.control/.%r.%h.%p.sock
    StrictHostKeyChecking ask
    UserKnownHostsFile ~/.ssh/known_hosts
### END DOTFILES MANAGED BLOCK ###
EOT
else
	echo "Dotfiles SSH configuration already present."
fi
