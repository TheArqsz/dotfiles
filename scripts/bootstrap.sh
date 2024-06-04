#!/usr/bin/env zsh
# Bootstrap system and/or tools
#
# Copyright 2024 TheArqsz

_cmd_exists() {
    command -v "$1" > /dev/null 2>&1
}

step() {
    echo -e "## ${*}"
}

show_help() {
cat <<%
Usage: bootstrap -t tool...
Bootstrap OS and/or tools

Optional arguments:
    -t, --tool             Bootstrap specific tool (default: none)
    -l, --list-tools       List tools to be bootstrapped
    -s, --system           Bootstrap system
    -v, --verbose          Set verbose mode

    --code-extensions      Additional VSCode extensions to install
    --list-default-ext     List default VSCode extensions
%
}

bootstrap_system() {
    echo "bootstrap_system not implemented"
    return
}

vscode_base_extensions=(
    ms-python.black-formatter # Black Formatter
    ms-vscode-remote.remote-containers # Dev Containers
    ms-azuretools.vscode-docker # Docker
    waderyan.gitblame # Git Blame
    github.vscode-github-actions # GitHub Actions
    eamodio.gitlens # GitLens
    ms-python.isort # isort
    ms-vscode.live-server # Live Preview
    ahmadalli.vscode-nginx-conf # NGINX Configuration Support
    mushan.vscode-paste-image # Paste Image
    ms-python.python # Python
    ms-python.vscode-pylance # Python Pylance
    ms-vscode-remote.remote-ssh # Remote SSH
    Gruntfuggly.todo-tree # Todo Tree
    redhat.vscode-yaml # YAML
)

bootstrap_code() {
    # WSL
    if ! _cmd_exists code && [[ "$(uname -r)" == *"microsoft"* ]]; then
        step "Working in WSL - install VSCode on your host"
        step "      https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-vscode"
    # Debian-based system
    elif ! _cmd_exists code && [[ -f "/etc/debian_version" ]]; then
        # https://code.visualstudio.com/docs/setup/linux
        echo "Type in your sudo password:"
        sudo -v
        sudo apt install -yq wget gpg
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        rm -f /tmp/packages.microsoft.gpg

        sudo apt install -yq apt-transport-https
        sudo apt update -yq
        sudo apt install -yq code
    # MacOS
    elif ! _cmd_exists code && [[ "$(uname)" == "Darwin" ]]; then
        _cmd_exists brew || { step "Brew not installed - exiting"; exit 1 }
        brew install --cask visual-studio-code
    fi

    if _cmd_exists code; then
        # https://code.visualstudio.com/docs/editor/command-line#_working-with-extensions 
        step "Setting up extensions"
        if ! [ -z "$additional_code_extensions" ]; then
            for extension in ${additional_code_extensions//,/ }; do
                vscode_base_extensions+=($extension)
            done
        fi
        for extension in "${vscode_base_extensions[@]}"; do
            code --install-extension $extension --force || \
                {
                    echo
                    step "Installation of extension $extension failed"
                    echo
                    sleep 2
                }
        done
        step "Installed extensions:"
        code --list-extensions
    else
        step "VSCode doesn't exist and cannot be installed automatically"
    fi

}

tool_to_bootstrap=
bt_system=false
list_tools=false
additional_code_extensions=
list_default_code_ext=false

# CLI Parameters
while [ -n "$1" ]; do 
	case "$1" in
	    -h|--help)
            show_help
            exit;;
   	    -t|--tool)
            tool_to_bootstrap="$2"
            shift
            ;;
   	    -l|--list-tools)
            list_tools=true
            shift 0
            ;;
   	    -s|--system)
            bt_system=true
            shift 0
            ;;
   	    --code-extensions)
            additional_code_extensions="$2"
            shift
            ;;
   	    --list-default-ext)
            list_default_code_ext=true
            shift 0
            ;;
   	    -v|--verbose)
            set -x
            shift 0
            ;;
        *) 
            echo "Option '$1' is not recognized"
            echo
            show_help
            exit 1
            ;;
      esac
      shift
done

# List all possible tools to bootstrap
if [[ "$list_tools" == true ]]; then
    all_tools=$(typeset -f | \grep -e "^bootstrap\_" | \grep -v 'system' | cut -d'_' -f2 | cut -d' ' -f1)
    echo $all_tools | sort
    exit 0
fi

# List default VSCode extensions
if [[ "$list_default_code_ext" == true ]]; then
    IFS=$'\n' sorted=($(sort <<<"${vscode_base_extensions[*]}"))
    unset IFS
    for extension in "${sorted[@]}"; do
        echo $extension
    done 
    exit 0
fi


if [[ $bt_system == false ]] && [ -z "$tool_to_bootstrap" ]; then
   show_help
   exit 0
fi

if [[ $bt_system == true ]]; then
   bootstrap_system
fi

if [[ -n "${tool_to_bootstrap}" ]]; then
    if [[ "$tool_to_bootstrap" == "system" ]]; then
        echo "Bootstrap system with:"
        echo "      bootstrap -s"
        type bootstrap_"$tool_to_bootstrap" 
        # exit 0
    elif type bootstrap_"$tool_to_bootstrap" | grep -q "not found"; then
        step "Bootstrap for $tool_to_bootstrap not implemented - exiting"
        exit 1
    fi
    bootstrap_"$tool_to_bootstrap"
fi