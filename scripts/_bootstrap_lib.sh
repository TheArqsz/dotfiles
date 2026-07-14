#!/usr/bin/env zsh
# Shared helpers for scripts/bootstrap.sh and scripts/bootstrap_security.sh
#
# Copyright 2026 TheArqsz

# Check if a command exists
_cmd_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Print a step message
step() {
	echo -e "## ${*}"
}

# Create /opt/Tools owned by the invoking user
_ensure_tools_dir() {
	sudo install -d -o "$(id -un)" -g "$(id -gn)" -m 755 /opt/Tools
}
