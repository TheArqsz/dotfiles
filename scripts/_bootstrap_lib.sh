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
