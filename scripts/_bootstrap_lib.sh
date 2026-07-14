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

# $1 = owner/repo; prints the latest release tag with "v" stripped
_gh_latest_version() {
	local version
	version=$(curl -fsSL "https://api.github.com/repos/$1/releases/latest" | jq -r '.tag_name // empty' | sed 's/^v//')
	if [[ -z "$version" ]]; then
		step "Failed to determine latest release version for $1"
		return 1
	fi
	echo "$version"
}

# $1 = binary name, $2 = go module path (without @latest)
_go_install_tool() {
	local bin="$1" mod="$2"
	echo
	if ! _cmd_exists go; then
		step "Golang is not installed - skipping"
		return
	fi
	_cmd_exists "$bin" && step "Updating $bin" || step "Installing $bin"
	go install -v "${mod}@latest" && step "$bin tool is installed"
}
