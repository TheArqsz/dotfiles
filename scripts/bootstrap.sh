#!/usr/bin/env zsh
# Bootstrap system and/or tools
#
# Copyright 2024 TheArqsz

export DOTFILES=${DOTFILES:-"$HOME/.dotfiles"}

# Check if a command exists
_cmd_exists() { 
    alias -s "$1" >/dev/null 2>&1 || command -v "$1" >/dev/null 2>&1
}

# Print a step message
step() {
    echo -e "## ${*}"
}

# Display help message
show_help() {
    cat <<%
Usage: bootstrap [options]

Bootstrap OS and/or tools

Options:
    -t, --tool             Bootstrap specific tool (default: none, can be set to "all" or "gui")
                           all: Install all CLI tools
                           gui: Install additional GUI-based tools (e.g. Signal, Brave, Burp Suite Pro)
                           tool1,tool2: Specify multiple tools separated by a comma
    --gui-tool             Install specific GUI tool

    -l, --list-tools       List tools to be bootstrapped
    -s, --system           Bootstrap system
    -v, --verbose          Enable verbose mode
    --code-extensions      Additional VSCode extensions to install
    --list-default-ext     List default VSCode extensions

    security               Run the security module

    -h, --help             Show this help message and exit

Security Module Options:
    bootstrap security [options]

Options:
    -h, --help             Show help message and exit
%
}

# Setup GUI tools
gui_setup_signal_desktop() {
    echo
    if ! _cmd_exists signal-desktop; then
        step "Installing Signal Desktop"
        if ! _cmd_exists gpg; then
            step "Installing Signal Desktop dependency - gpg"
            sudo apt-get install --show-progress -yqq gpg
        fi
        # https://signal.org/download/linux/
        wget -q -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor >signal-desktop-keyring.gpg
        cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg >/dev/null

        echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |
            sudo tee /etc/apt/sources.list.d/signal-xenial.list

        # 3. Update your package database and install Signal:
        sudo apt update -yqq |grep Progress && sudo apt install --show-progress -yqq signal-desktop 
    else
        step "Signal Desktop is already installed"
    fi
}

gui_setup_brave() {
    echo
    if ! _cmd_exists brave-browser; then
        step "Installing Brave Browser"
        if ! _cmd_exists curl; then
            step "Installing Brave Browser dependency - curl"
            sudo apt-get install --show-progress -yqq curl
        fi
        # https://brave.com/linux/
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

        sudo apt update -yqq && sudo apt install --show-progress -yqq brave-browser
        mkdir -p "$HOME/.config/BraveSoftware/Brave-Browser" &&
            cp "$DOTFILES/misc/brave_local_state.json" "$HOME/.config/BraveSoftware/Brave-Browser/Local State"
    else
        step "Brave Browser is already installed"
    fi
    # Extensions
    if _cmd_exists brave-browser; then
        step "Installing Brave Browser extensions"
        if ! _cmd_exists jq; then
            step "Installing Brave Browser extensions dependency - jq"
            sudo apt-get install --show-progress -yqq jq
        fi
        local EXTENSIONS_PATH="/opt/brave.com/brave/extensions"
        sudo mkdir -p $EXTENSIONS_PATH && sudo chmod 644 $EXTENSIONS_PATH
        for ext_b64 in $(cat "$DOTFILES/misc/brave_extensions.json" | jq -r '.[] | @base64'); do
            ext_json=$(echo $ext_b64 | base64 --decode)
            ext_name=$(echo $ext_json | jq -r '.name')
            ext_id=$(echo $ext_json | jq -r '.id')
            step "  Brave Browser extension - $ext_name"
            if grep -q "$ext_id" "$HOME/.config/BraveSoftware/Brave-Browser/Default/Preferences" 2>/dev/null || sudo [ -f "${EXTENSIONS_PATH}/${ext_id}.json" ]; then
                step "Extension $ext_name already installed"
            else
                echo '{ "external_update_url": "https://clients2.google.com/service/update2/crx" }' |
                    sudo tee "${EXTENSIONS_PATH}/${ext_id}.json" 1>/dev/null
            fi
        done
        sudo chmod -R 755 "${EXTENSIONS_PATH}"
    fi
    step "Wait for 10 seconds for browser data to reload"
    timeout 10 brave-browser --disable-gpu --silent-launch brave://settings 2>/dev/null
    step "Brave setup completed"
    step "  Update manually ad filters at:"
    step "      brave://settings/shields/filters"
    step "  Configure extensions at:"
    step "      brave://extensions/"
}

gui_setup_chrome() {
    echo
    if ! _cmd_exists google-chrome; then
        step "Installing Google Chrome"
        if ! _cmd_exists curl; then
            step "Installing Google Chrome dependency - curl"
            sudo apt-get install --show-progress -yqq curl
        fi
        curl -# -SL "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" --output /tmp/google-chrome-stable_current_amd64.deb
        sudo apt install -yq /tmp/google-chrome-stable_current_amd64.deb
    else
        step "Google Chrome is already installed"
    fi
}

gui_setup_flameshot() {
    echo
    if ! _cmd_exists flameshot && [[ -f "/etc/debian_version" ]]; then
        step "Installing flameshot"
        FLAMESHOT_LATEST_VERSION=$(curl -sL https://github.com/flameshot-org/flameshot/releases | \grep -E 'flameshot/tree/v[0-9]+' | \grep -v '.rc' | awk -F'/v' '{print $2}' | awk -F'" ' '{print $1}' | head -n1)
        step "  Downloading official release"
        curl -# -SL "https://github.com/flameshot-org/flameshot/releases/download/v$FLAMESHOT_LATEST_VERSION/flameshot-${FLAMESHOT_LATEST_VERSION}-1.$(lsb_release -i -s | tr '[:upper:]' '[:lower:]')-$(lsb_release -r -s).$(dpkg --print-architecture).deb" --output flameshot.deb
        sudo dpkg -i flameshot.deb
    elif [[ ! -f "/etc/debian_version" ]]; then
        step "Installation of flameshot is not implemented on your current system"
    else
        step "flameshot is already installed"
    fi
}

gui_setup_obsidian() {
    echo
    OBSIDIAN_LATEST_VERSION=$(curl -sL https://github.com/obsidianmd/obsidian-releases/releases | \grep -P 'obsidian-releases/tree/v[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}"' | awk -F'tree/v' '{print $2}' | awk -F'" ' '{print $1}' | head -n1)
    if _cmd_exists obsidian; then
            step "Obsidian is already installed"
            return
    fi
    if [[ -f "/etc/debian_version" ]]; then
        step "Installing Obsidian on Debian-based system"
        step "  Installing version $OBSIDIAN_LATEST_VERSION"
        step "  Downloading official release"
        curl -# -SL "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_LATEST_VERSION}/obsidian_${OBSIDIAN_LATEST_VERSION}_amd64.deb" --output /tmp/obsidian_${OBSIDIAN_LATEST_VERSION}.deb && \
        {
            sudo dpkg -i /tmp/obsidian_${OBSIDIAN_LATEST_VERSION}.deb && \
            step "Obsidian installed"
        } || step "Failed to install Obsidian"
    fi
}

gui_setup_copyq() {
    echo
    # Debian-based system
    if ! _cmd_exists copyq && [[ -f "/etc/debian_version" ]]; then
        step "Installing CopyQ"
        echo "You may need to type in your sudo password:"
        sudo -v
        sudo apt-get update -yqq
        sudo apt-get install --show-progress -yqq copyq
        sh -c 'nohup copyq > /dev/null 2>&1 &'
        step "CopyQ installed"
    # MacOS
    elif ! _cmd_exists copyq && [[ "$(uname)" == "Darwin" ]] && _cmd_exists brew; then
        step "Installing CopyQ"
        brew install --cask copyq
        copyq &
        step "CopyQ installed"
    elif _cmd_exists copyq; then
        step "CopyQ is already installed"
    fi
}

# Wrapper for installing all GUI tools
bootstrap_gui() {
    if [[ x$DISPLAY == x ]]; then
        step "Bootstrapping for GUI is disabled"
        return
    fi
    local DISTRO="$(lsb_release -i | \grep ID: | cut -d: -f2 | tr -d '[:space:]')"
    if [[ -f "/etc/debian_version" ]]; then
        step "Setting up OS with additional GUI tools and software"
        gui_setup_brave
        gui_setup_signal_desktop
        gui_setup_flameshot
        gui_setup_obsidian
        gui_setup_copyq
    else
        step "This is not a Debian-based OS - skipping"
    fi
}

# Wrapper for simple system pre-setup
bootstrap_system() {
    echo
    if ! _cmd_exists ufw; then
        step "Installing UFW"
        sudo apt update -yqq && sudo apt install --show-progress -yqq ufw
    fi
    step "Setting up UFW"
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp
    sudo ufw enable
    step "UFW ready"
}

# ------------------------------------------------------------

# Installation of CLI tools

# Extensions for VSCode
vscode_base_extensions=(
    ms-python.black-formatter          # Black Formatter
    ms-vscode-remote.remote-containers # Dev Containers
    ms-azuretools.vscode-docker        # Docker
    waderyan.gitblame                  # Git Blame
    github.vscode-github-actions       # GitHub Actions
    eamodio.gitlens                    # GitLens
    ms-python.isort                    # isort
    ms-vscode.live-server              # Live Preview
    ahmadalli.vscode-nginx-conf        # NGINX Configuration Support
    mushan.vscode-paste-image          # Paste Image
    ms-python.python                   # Python
    ms-python.vscode-pylance           # Python Pylance
    ms-vscode-remote.remote-ssh        # Remote SSH
    Gruntfuggly.todo-tree              # Todo Tree
    redhat.vscode-yaml                 # YAML
    tomoki1207.pdf                     # PDF Viewer
    ms-vscode-remote.remote-wsl        # WSL
    GitHub.copilot                     # Github Copilot
)

bootstrap_code() {
    echo
    step "Setting up VSCode with extensions and config"
    # WSL
    if ! _cmd_exists code && [[ "$(uname -r)" == *"microsoft"* ]]; then
        step "Working in WSL - install VSCode on your host"
        step "      https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-vscode"
    # Debian-based system
    elif ! _cmd_exists code && [[ -f "/etc/debian_version" ]]; then
        # https://code.visualstudio.com/docs/setup/linux
        echo "You may need to type in your sudo password:"
        sudo -v
        sudo apt install --show-progress -yqq wget gpg
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >/tmp/packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
        rm -f /tmp/packages.microsoft.gpg

        sudo apt install --show-progress -yqq apt-transport-https
        sudo apt update -yqq
        sudo apt install --show-progress -yqq code
    # MacOS
    elif ! _cmd_exists code && [[ "$(uname)" == "Darwin" ]]; then
        _cmd_exists brew || {
            step "Brew not installed - exiting"
            exit 1
        }
        brew install --cask visual-studio-code
    elif _cmd_exists code; then
        step "VSCode is already installed"
    fi
    if _cmd_exists code; then
        # Handle extensions - if already installed it updates them with '--force'
        # https://code.visualstudio.com/docs/editor/command-line#_working-with-extensions
        step "Setting up VSCode extensions"
        if ! [ -z "$additional_code_extensions" ]; then
            for extension in ${additional_code_extensions//,/ }; do
                vscode_base_extensions+=($extension)
            done
        fi
        for extension in "${vscode_base_extensions[@]}"; do
            code --install-extension $extension --force --log warn ||
                {
                    echo
                    step "Installation of extension $extension failed"
                    echo
                    sleep 2
                }
        done
    else
        step "VSCode doesn't exist and cannot be installed automatically"
    fi

    if [[ "$(uname)" == "Darwin" ]]; then
        mkdir -p "$HOME/Library/Application Support/Code/User/" &&
            cp "$DOTFILES/misc/vscode-settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
    elif [[ "$(uname -r)" == *"microsoft"* ]]; then
        # Handle the main VSCode instance within the Windows
        local APPDATA="$(cmd.exe /c echo %APPDATA% 2>/dev/null)"
        local WINDOWS_CODE_SETTINGS="$(wslpath $APPDATA | tr -d '\r')/Code/User/settings.json"
        echo -E "Copying $DOTFILES/misc/vscode-settings.json to $(wslpath $APPDATA | tr -d '\r')/Code/User/settings.json"
        cp "$WINDOWS_CODE_SETTINGS" "$WINDOWS_CODE_SETTINGS".old_$(date +%s)
        cp "$DOTFILES/misc/vscode-settings.json" "$WINDOWS_CODE_SETTINGS"
        
        # Handle WSL itself
        mkdir -p "$HOME/.config/Code/User/" &&
            cp "$DOTFILES/misc/vscode-settings.json" "$HOME/.config/Code/User/settings.json"
        echo
    elif [[ "$(uname)" == "Linux" ]]; then
        mkdir -p "$HOME/.config/Code/User/" &&
            cp "$DOTFILES/misc/vscode-settings.json" "$HOME/.config/Code/User/settings.json"
    fi

}

bootstrap_docker() {
    echo
    # Debian-based system
    if ! _cmd_exists docker && [[ -f "/etc/debian_version" ]]; then
        _cmd_exists apt-get || {
            step "apt-get not installed - exiting"
            exit 1
        }
        echo "You may need to type in your sudo password:"
        sudo -v
        sudo apt-get update -yqq
        for pkg in docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -yq $pkg 2>/dev/null; done
        sudo apt-get install --show-progress -yqq ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        DISTRO="$(lsb_release -i | \grep ID: | cut -d: -f2 | tr -d '[:space:]')"
        if [[ "$DISTRO" == *"Ubuntu"* ]]; then
            step "Installing Docker in Ubuntu"
            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
                sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        elif [[ "$DISTRO" == *"Kali"* ]]; then
            step "Installing Docker in Kali"
            sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
                bookworm stable" |
                sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        else
            step "Installing Docker in Debian-based system"
            sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
                sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        fi

        sudo apt-get update -yqq
        sudo apt-get install --show-progress -yqq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo groupadd docker &>/dev/null
        sudo usermod -aG docker $USER
        step "Docker is installed"
        step "Log out from your current account or open new shell session"
    # MacOS
    elif ! _cmd_exists docker && [[ "$(uname)" == "Darwin" ]]; then
        echo
        step "Working in MacOS"
        step "      https://docs.docker.com/desktop/install/mac-install/"
        echo
        sleep 4
    elif _cmd_exists docker; then
        step "Docker is already installed"
    fi

}

bootstrap_updog() {
    echo
    if ! _cmd_exists pip; then
        step "Cannot install updog - pip not found"
        return 1
    elif ! _cmd_exists updog; then
        step "Installing updog"
    else
        step "Updog is already installed - updating"
    fi
    pip install --upgrade -q updog
    step "Updog installed"
}

bootstrap_golang() {
    echo
    if ! _cmd_exists go; then
        if ! _cmd_exists curl; then
            step "Installing Go dependency - curl"
            sudo apt-get install --show-progress -yqq curl
        fi
        step "Installing Golang"
        GO_LATEST_VERSION_ENDPOINT=$(curl -sL https://go.dev/dl/ | \grep 'download.*downloadBox' | \grep -io "/dl/.*$(uname -s).*gz")
        step "  Downloading official binary"
        curl -# -SL "https://go.dev/$GO_LATEST_VERSION_ENDPOINT" --output golang.tar.gz
        sudo tar -C /usr/local -xzf golang.tar.gz && \
        rm golang.tar.gz
        step "Golang installed"
    else
        step "Golang is already installed"
    fi
}

bootstrap_go() {
    bootstrap_golang
}

bootstrap_fzf() {
    echo
    if ! _cmd_exists fzf; then
        step "Installing FZF"
        [[ -d "$HOME/.fzf" ]] || git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        [[ -f "$HOME/.fzf/bin/fzf" ]] || "$HOME/.fzf/install" --no-zsh --no-bash --no-update-rc --no-completion --no-key-bindings --bin
        sudo cp $HOME/.fzf/bin/fzf /usr/local/bin/
    elif _cmd_exists fzf && [[ "$(which fzf)" == *"$HOME"* ]]; then
        step "FZF is already installed in user's home dir - copying to /usr/local/bin/"
        sudo cp "$HOME/.fzf/bin/fzf" /usr/local/bin/
    else
        step "FZF is already installed"
    fi
}

bootstrap_pyenv() {
    echo
    if ! _cmd_exists pyenv; then
        step "Installing pyenv dependencies"
        sudo apt-get install --show-progress -yqq build-essential libssl-dev zlib1g-dev \
            libbz2-dev libreadline-dev libsqlite3-dev curl git \
            libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev llvm
        step "Installing pyenv"
        [[ -d "$HOME/.pyenv" ]] || git clone https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
        export PATH="$HOME/.pyenv/bin:$PATH"
        source "$HOME/.zshrc"
    else
        step "pyenv is already installed"
    fi
}

bootstrap_fdfind() {
    echo
    if ! _cmd_exists fdfind && ! _cmd_exists fd; then
        step "Installing fdfind"
        FD_LATEST_VERSION=$(curl -sL https://github.com/sharkdp/fd/releases | \grep -E 'fd/tree/v[0-9]+' | awk -F'/v' '{print $2}' | awk -F'" ' '{print $1}' | head -n1)
        step "  Downloading official release"
        curl -# -SL "https://github.com/sharkdp/fd/releases/download/v$FD_LATEST_VERSION/fd-musl_${FD_LATEST_VERSION}_$(dpkg --print-architecture).deb" --output fd.deb
        sudo dpkg -i fd.deb && \
        rm fd.deb && \
        sudo ln -fs /usr/bin/fd /usr/bin/fdfind
    else
        step "fdfind is already installed"
    fi
}

bootstrap_eza() {
    echo
    if ! _cmd_exists eza; then
        step "Installing eza dependencies"
        sudo apt-get install --show-progress -yqq curl gpg
        step "Installing eza"
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --yes --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list 1>/dev/null
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt update -yqq && sudo apt-get install --show-progress -yqq eza
        step "eza installed"
    else
        step "eza is already installed"
    fi
}

bootstrap_tmux() {
    echo
    TMUX_LATEST_VERSION=$(curl -sL https://github.com/tmux/tmux/releases | \grep -E 'tmux/tree/' | awk -F'tree/' '{print $2}' | awk -F'" ' '{print $1}' | head -n1)
    if _cmd_exists tmux; then
        if [[ "tmux $TMUX_LATEST_VERSION" == "$(tmux -V)" ]]; then
            step "Tmux is already installed and updated to the latest version"
            return
        else
            step "Tmux is already installed - updating"
            sudo apt-get remove -yqq tmux 2>/dev/null
            # If still exists
            if _cmd_exists tmux; then
                step "Force removing old tmux (was not installed with apt)"
                sudo rm -f $(which tmux) 2>/dev/null
            fi
        fi
    fi
    step "Installing Tmux dependencies"
    sudo apt-get install --show-progress -yqq libevent-dev ncurses-dev build-essential bison pkg-config
    step "Installing Tmux"
    step "  Installing version $TMUX_LATEST_VERSION"
    step "  Downloading official release"
    curl -# -SL "https://github.com/tmux/tmux/releases/download/$TMUX_LATEST_VERSION/tmux-${TMUX_LATEST_VERSION}.tar.gz" --output /tmp/tmux_${TMUX_LATEST_VERSION}.tar.gz
    sudo tar -C /tmp/ -zxf /tmp/tmux_${TMUX_LATEST_VERSION}.tar.gz
    cd /tmp/tmux-$TMUX_LATEST_VERSION/
    step "  Running configure"
    sudo ./configure 1>/dev/null
    step "  Running make and make install"
    sudo make 1>/dev/null && sudo make install 1>/dev/null && \
    sudo rm -rf /tmp/tmux-$TMUX_LATEST_VERSION/
    cd -
    tmux kill-server 2>/dev/null
    step "Tmux installed"
}

bootstrap_brew() {
    echo
    # Debian-based system
    if ! _cmd_exists brew && [[ -f "/etc/debian_version" ]]; then
        _cmd_exists apt-get || {
            step "apt-get not installed - exiting"
            exit 1
        }
        step "Installing brew"
        echo "You may need to type in your sudo password:"
        sudo -v
        step "Installing brew dependencies"
        sudo apt-get install --show-progress -yqq build-essential procps curl file git
        # https://docs.brew.sh/Installation
        $(which bash) -c "NONINTERACTIVE=1 $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh) 1>brew.log" 
        step "Brew is probably installed - reload your shell or check brew.log"
    elif _cmd_exists brew; then
        step "Brew is already installed"
    fi

}

bootstrap_c4p() {
    echo
    if ! _cmd_exists c4p && ! [[ -d "$HOME/.c4p" ]]; then
        _cmd_exists docker || {
            step "docker is not installed - bootstrapping"
            bootstrap_docker
        }
        step "Installing containers4pentesters project"
        step "  https://github.com/TheArqsz/containers4pentesters" 
        [[ -d "$HOME/.c4p" ]] || git clone https://github.com/TheArqsz/containers4pentesters "$HOME/.c4p"
        sudo ln -s "$HOME/.c4p/c4p.sh" /usr/local/bin/c4p

        step "Containers4Pentesters project is installed"
        step "  You have to install each tool manually"
        step "  c4p -t TOOL"
    elif _cmd_exists c4p; then
        step "containers4pentesters project is already installed"
        local C4P_BIN=$(which c4p | awk -F'/' '{for (i=2; i<=NF; i++) printf "/"$i}')
        $C4P_BIN -l
    fi

}

bootstrap_cryptomator-cli() {
    echo
    CRYPTO_CLI_LATEST_VERSION=$(curl -sL https://github.com/cryptomator/cli/releases | \grep -P 'cryptomator/cli/tree/[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}"' | awk -F'tree/' '{print $2}' | awk -F'" ' '{print $1}' | head -n1)
    # Debian-based system
    if [[ -f "/etc/debian_version" ]]; then
        step "Installing Cryptomator's CLI on Debian-based system"
        step "You may need to type in your sudo password:"
        sudo -v
        sudo apt-get update -yqq
        sudo apt-get install --show-progress -yqq fuse3 unzip
        step "  Installing version $CRYPTO_CLI_LATEST_VERSION"
        step "  Downloading official release"
        curl -# -SL "https://github.com/cryptomator/cli/releases/download/${CRYPTO_CLI_LATEST_VERSION}/cryptomator-cli-${CRYPTO_CLI_LATEST_VERSION}-linux-x64.zip" --output /tmp/cryptomator-cli-${CRYPTO_CLI_LATEST_VERSION}-linux-x64.zip && \
        {
            unzip -o -d /tmp/ /tmp/cryptomator-cli-${CRYPTO_CLI_LATEST_VERSION}-linux-x64.zip && \
            rm /tmp/cryptomator-cli-${CRYPTO_CLI_LATEST_VERSION}-linux-x64.zip && \
            sudo rm -rf /opt/cryptomator-cli 2>/dev/null && \
            sudo mv -f /tmp/cryptomator-cli /opt/ && \
            chown $(id -u):$(id -g) /opt/cryptomator-cli && \
            sudo ln -f -s /opt/cryptomator-cli/bin/cryptomator-cli /usr/local/bin/cryptomator-cli && \
            [ -f /usr/local/bin/cryptomator-cli ] && \
            step "Cryptomator's CLI installed"
        } || step "Failed to install Cryptomator's CLI"
    # MacOS
    elif ! _cmd_exists copyq && [[ "$(uname)" == "Darwin" ]] && _cmd_exists brew; then
        step "Not implemented"
        return
    elif _cmd_exists cryptomator-cli; then
        step "cryptomator-cli is already installed"
    fi

}

bootstrap_micro() {
    echo
    MICRO_LATEST_VERSION=$(curl -sL https://github.com/zyedidia/micro/releases | \grep -E 'micro/tree/' | awk -F'tree/v' '{print $2}' | awk -F'" ' '{print $1}' | awk 'NF' | head -n1)
    if _cmd_exists micro; then
        if micro -version | grep -q "Version: $MICRO_LATEST_VERSION"; then
            step "Micro is already installed and updated to the latest version"
            return
        else
            step "Micro is already installed - updating"
            sudo apt-get remove -yqq micro 2>/dev/null
            # If still exists
            if _cmd_exists micro; then
                step "Force removing old micro (was not installed with apt)"
                sudo rm -f $(which micro) 2>/dev/null
            fi
        fi
    fi
    platform=''
    machine=$(uname -m)
    case "$(uname -s | tr '[:upper:]' '[:lower:]')" in
        "linux")
        case "$machine" in
            "arm64"* | "aarch64"* ) platform='linux-arm64' ;;
            "arm"* | "aarch"*) platform='linux-arm' ;;
            *"86") platform='linux32' ;;
            *"64") platform='linux64' ;;
        esac
        ;;
        "darwin") platform='osx' ;;
    esac
    step "Installing micro"
    step "  Installing version $MICRO_LATEST_VERSION"
    step "  Downloading official release"
    curl -# -SL "https://github.com/zyedidia/micro/releases/download/v${MICRO_LATEST_VERSION}/micro-${MICRO_LATEST_VERSION}-${platform}-static.tar.gz" --output /tmp/micro_${MICRO_LATEST_VERSION}.tar.gz 
    tar -C /tmp/ -zxf /tmp/micro_${MICRO_LATEST_VERSION}.tar.gz 
    cd /tmp/micro-$MICRO_LATEST_VERSION/
    sudo mv -f micro /usr/local/bin/ 
    sudo rm -rf /tmp/micro-$MICRO_LATEST_VERSION/
    cd -
    if [[ "$(uname -r)" == *"microsoft"* ]]; then
        step "Updating xclip for WSL"
        sudo ln -fs "$DOTFILES/misc/micro/wsl-xclip.sh" /usr/bin/xclip && sudo chmod +x /usr/bin/xclip
        sudo ln -fs "$DOTFILES/misc/micro/wsl-xclip.sh" /usr/bin/xsel && sudo chmod +x /usr/bin/xsel
    elif [[ -f "/etc/debian_version" ]]; then
        sudo apt-get install --show-progress -yqq xclip xsel
    fi
    mkdir -p "$HOME/.config/micro"
    ln -fs "$DOTFILES/misc/micro/settings.json" "$HOME/.config/micro/settings.json"
    ln -fs "$DOTFILES/misc/micro/bindings.json" "$HOME/.config/micro/bindings.json"
    step "Micro installed"
}

bootstrap_tldr() {
    echo
    # Debian-based system
    if ! _cmd_exists tldr && [[ -f "/etc/debian_version" ]]; then
        _cmd_exists apt-get || {
            step "apt-get not installed - exiting"
            exit 1
        }
        echo "You may need to type in your sudo password:"
        sudo -v
        step "Installing tldr dependencies"
        sudo apt-get install --show-progress -yqq build-essential gcc libcurl4-openssl-dev libzip-dev pkg-config

        step "Installing tldr"
        local clone_dir=$(mktemp -d)
        # https://github.com/tldr-pages/tldr-c-client?tab=readme-ov-file#building
        git clone https://github.com/tldr-pages/tldr-c-client.git $clone_dir
        cd $clone_dir
        make && \
        sudo make install && \
        tldr -u && \
        rm -rf $clone_dir
    elif _cmd_exists tldr; then
        step "tldr is already installed"
    fi

}

# ------------------------------------------------------------

# Main script handler and flags

tool_to_bootstrap=
bt_system=false
list_tools=false
additional_code_extensions=
list_default_code_ext=false

# CLI Parameters
if [ $# -eq 0 ]; then
    show_help
    exit 0
elif [[ $1 == "security" ]]; then
    # Security module
    shift 
    source "$DOTFILES/scripts/bootstrap_security.sh" "$@"
    exit 0
fi
while [ -n "$1" ]; do
    case "$1" in
    -h | --help)
        show_help
        exit
        ;;
    -t | --tool)
        if [ $# -lt 2 ]; then
            echo "Missing argument for --tool"
            exit 1
        fi
        tool_to_bootstrap="$2"
        shift
        ;;
    -l | --list-tools)
        list_tools=true
        shift 0
        ;;
    -s | --system)
        bt_system=true
        shift 0
        ;;
    --code-extensions)
        if [ $# -lt 2 ]; then
            echo "Missing argument for --code-extensions"
            exit 1
        fi
        additional_code_extensions="$2"
        shift
        ;;
    --list-default-ext)
        list_default_code_ext=true
        shift 0
        ;;
    --gui-tool)
        if [ $# -lt 2 ]; then
            echo "Missing argument for --gui-tool"
            exit 1
        fi
        gui_tool_to_bootstrap="$2"
        shift
        ;;
    -v | --verbose)
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

local EXCLUDED_PACKAGES='system\|gui\|c4p'
# List all possible tools to bootstrap
if [[ "$list_tools" == true ]]; then
    all_tools=$(typeset -f | \grep -e "^bootstrap\_" | \grep -v "$EXCLUDED_PACKAGES" | cut -d'_' -f2 | cut -d' ' -f1)
    all_gui_tools=$(typeset -f | \grep -e "^gui\_setup\_" | cut -d'_' -f3,4 | cut -d' ' -f1)
    echo '--- CLI ---' 
    echo $all_tools | sort
    echo
    echo '--- GUI ---' 
    echo $all_gui_tools | sort
    echo
    echo '--- GROUPS ---'
    echo all
    echo c4p
    echo gui
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

# Handle rest of the flags
if [[ $bt_system == false ]] && ([ -z "$tool_to_bootstrap" -a -z "$gui_tool_to_bootstrap" ]); then
    show_help
    exit 0
fi

if [[ $bt_system == true ]]; then
    bootstrap_system
fi

# User passed the CLI tools as a coma-separated list
IFS=',' read -r -A few_tools_to_bootstrap <<< "$tool_to_bootstrap"

for tool_to_bootstrap in "${few_tools_to_bootstrap[@]}"
do
    if [[ -n "${tool_to_bootstrap}" ]]; then
        if [[ "$tool_to_bootstrap" == "system" ]]; then
            echo "Bootstrap system with:"
            echo "      bootstrap -s"
            exit 0
        elif [[ "$tool_to_bootstrap" != "all" ]] && type bootstrap_"$tool_to_bootstrap" | grep -q "not found"; then
            step "Bootstrap for $tool_to_bootstrap not implemented - exiting"
            exit 1
        elif [[ "$tool_to_bootstrap" == "all" ]]; then
            all_tools=$(typeset -f | \grep -e "^bootstrap\_" | \grep -v "$EXCLUDED_PACKAGES" | cut -d'_' -f2 | cut -d' ' -f1)
            all_tools_sorted=$(echo $all_tools | sort)
            IFS=$'\n' all_tools_sorted=($(sort <<<"$all_tools"))
            unset IFS
            for tool in "${all_tools_sorted[@]}"; do
                bootstrap_"$tool"
            done

            exit 0
        else
            bootstrap_"$tool_to_bootstrap"
        fi
    fi
done

# User passed the GUI tools as a coma-separated list
IFS=',' read -r -A gui_tools_to_bootstrap <<< "$gui_tool_to_bootstrap"
for gui_tool_to_bootstrap in "${gui_tools_to_bootstrap[@]}"
do
    if [[ -n "${gui_tool_to_bootstrap}" ]]; then
        if type gui_setup_"$gui_tool_to_bootstrap" | grep -q "not found"; then
            step "GUI bootstrap for $gui_tool_to_bootstrap not implemented - exiting"
            exit 1
        else
            gui_setup_"$gui_tool_to_bootstrap"
        fi
    fi
done