#!/usr/bin/env zsh

# Get script and packages updates
# Inspired by https://github.com/denysdovhan/dotfiles/blob/master/scripts/update

# Set directory
export DOTFILES=${DOTFILES:-"$HOME/.dotfiles"}

_exists() {
	command -v "$1" >/dev/null 2>&1
}

info() {
	echo -e "${*}"
}

finished() {
	info "Finished updating with $1"
	echo
	sleep 1
}

update_dotfiles() {
	info "## Updating dotfiles"

	cd "$DOTFILES" || exit

	local stashed=0
	if ! git diff --quiet || ! git diff --cached --quiet; then
		info "Local changes detected — stashing before pull"
		git stash push --include-untracked -m "update.sh: auto-stash $(date +%Y-%m-%dT%H:%M:%S)"
		stashed=1
	fi

	git pull
	./install --except shell

	if [[ "$stashed" -eq 1 ]]; then
		info "Restoring local changes"
		if ! git stash pop; then
			info "Could not restore stashed changes automatically — resolve conflicts and run 'git stash pop' manually"
		fi
	fi

	cd - >/dev/null 2>&1 || exit

	info "Updating Zinit plugins"

	finished update_dotfiles
}

update_c4p() {
	if ! [[ -d "$HOME/.c4p" ]]; then
		info "## Containers4Pentesters don't exists in the default directory $HOME/.c4p - skipping"
		return
	fi
	info "## Updating c4p"

	cd "$HOME/.c4p" || exit
	git pull
	cd - >/dev/null 2>&1 || exit

	finished update_c4p
}

update_zinit() {
	info "## Updating zinit plugins"

	(
		ZINIT[NO_PAGER]=1
		zinit self-update
		zinit update --all --parallel
	)

	finished update_dotfiles
}

update_brew() {
	if ! _exists brew; then
		return
	fi

	info "## Updating Homebrew"

	(
		# Skip brew's "ask mode" confirmation.
		# Third-party taps must be trusted once via
		# `brew trust --tap <name>`
		export HOMEBREW_NO_ASK=1

		brew update
		brew upgrade
		brew cleanup
	)

	finished update_brew
}

update_apt_get() {
	if ! _exists apt || [[ "$(uname)" != "Linux" ]]; then
		return
	fi

	info "## Updating Ubuntu and installed packages"
	info "## Before updating, please type your sudo password:"
	sudo -v

	sudo apt update -yqq
	sudo apt upgrade -yqq
	sudo apt autoremove -yqq
	sudo apt autoclean -yqq

	finished update_apt_get
}

main() {

	update_dotfiles "$*"
	update_zinit "$*"
	update_c4p "$*"
	update_brew "$*"
	update_apt_get "$*"

	info "Reload your shell"
}

main
