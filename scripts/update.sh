#!/usr/bin/env zsh

# Get script and packages updates
# Inspired by https://github.com/denysdovhan/dotfiles/blob/master/scripts/update

# Set directory
export DOTFILES=${1:-"$HOME/.dotfiles"}

_exists() {
    command -v "$1" > /dev/null 2>&1
}

# Success reporter
info() {
    echo -e "${*}"
}

# End section
finished() {
    success "Finished updating $1"
    echo
    sleep 1
}

update_dotfiles() {
    info "## Updating dotfiles"

    cd "$DOTFILES" || exit
    git pull
    ./install --except shell
    cd - > /dev/null 2>&1 || exit

    info "Updating Zinit plugins"

    finished update_dotfiles
}

update_zinit() {
    info "## Updating zinit plugins"

    zinit self-update
    zinit update --all --parallel


    finished update_dotfiles
}

update_brew() {
    if ! _exists brew; then
        return
    fi

    info "## Updating Homebrew"

    brew update
    brew upgrade
    brew cleanup

    finished update_brew
}

update_apt_get() {
    if ! _exists apt; then
        return
    fi

    info "## Updating Ubuntu and installed packages"
    info "## Before updating, please type your sudo password:"
    sudo -v

    sudo apt update
    sudo apt upgrade -yq
    sudo apt autoremove -yq
    sudo apt autoclean -yq

    finished update_apt_get
}

main() {

    update_dotfiles "$*"
    update_zinit "$*"
    update_brew "$*"
    update_apt_get "$*"

    info "Reload your shell"
}

main