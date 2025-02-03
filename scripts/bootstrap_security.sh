#!/usr/bin/env zsh
# Bootstrap pentesting and/or bug bounty tools
#
# Copyright 2025 TheArqsz

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
Usage: bootstrap security [options]

Bootstrap security-related tools

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

    -h, --help             Show this help message and exit
%
}

# ------------------------------------------------------------

# Installation of CLI tools

# Security extensions for VSCode
vscode_sec_extensions=(
    Surendrajat.apklab                          # APKLab
    tintinweb.vscode-decompiler                 # Decompiler
    snyk-security.snyk-vulnerability-scanner    # Snyk Security
)

security_bootstrap_code-extensions() {
    echo
    if _cmd_exists code; then
        # https://code.visualstudio.com/docs/editor/command-line#_working-with-extensions
        step "Setting up VSCode extensions"
        if ! [ -z "$additional_code_extensions" ]; then
            for extension in ${additional_code_extensions//,/ }; do
                vscode_sec_extensions+=($extension)
            done
        fi
        for extension in "${vscode_sec_extensions[@]}"; do
            code --install-extension $extension --force --log warn ||
                {
                    echo
                    step "Installation of extension $extension failed"
                    echo
                    sleep 2
                }
        done
    else
        step "VSCode doesn't exist - skipping extensions installation"  
    fi
}

security_bootstrap_massdns() {
    echo
    if ! _cmd_exists massdns && [[ -f "/etc/debian_version" ]]; then
        step "Installing massdns"
        _cmd_exists apt-get || {
            step "apt-get not installed - exiting"
            exit 1
        }
        step "Installing dependencies"
        sudo apt-get install --show-progress -yqq libpcap-dev

        local clone_dir=$(mktemp -d)
        # https://github.com/blechschmidt/massdns#compilation
        git clone https://github.com/blechschmidt/massdns $clone_dir
        cd $clone_dir
        make && \
        sudo make install && \
        rm -rf $clone_dir
    elif _cmd_exists massdns; then
        step "massdns is already installed"
    else
        step "Not implemented on non Debian-based system - skipping"
    fi
}

security_bootstrap_projectdiscovery() {
    echo
    if _cmd_exists go && [[ -f "/etc/debian_version" ]]; then
        step "Installing ProjectDiscovery tools with pdtm"
        go install -v github.com/projectdiscovery/pdtm/cmd/pdtm@latest
        step "ProjectDiscovery's Open Source Tool Manager is installed"
        _cmd_exists apt-get || {
            step "apt-get not installed - exiting"
            exit 1
        }
        step "Installing dependencies"
        sudo apt-get install --show-progress -yqq libpcap-dev
        security_bootstrap_massdns

        pdtm -dc -nc -duc \
            -i subfinder,tldfinder,naabu,notify,nuclei,shuffledns,httpx,dnsx,asnmap
        # Update templates
        nuclei -nc -nm -ut 
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_github-subdomains() {
    echo
    if _cmd_exists go && [[ -f "/etc/debian_version" ]]; then
        step "Installing github-subdomains"
        go install github.com/gwen001/github-subdomains@latest
        step "github-subdomains tool is installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_check-mdi() {
    echo
    if ! _cmd_exists check-mdi && _cmd_exists python && $(python -m venv -h 2>&1 1>/dev/null); then
        step "Installing check-mdi"
        echo "You may need to type in your sudo password:"
        sudo -v
        sudo chmod a+rwx /opt
        mkdir -p /opt/Tools
        git clone https://github.com/TheArqsz/check_mdi /opt/Tools/check_mdi 2>/dev/null || {
            echo "check_mdi repository is already cloned"
        }
        python -m venv /opt/Tools/check_mdi/venv
        /opt/Tools/check_mdi/venv/bin/pip install -r /opt/Tools/check_mdi/requirements.txt
        echo '#!/usr/bin/env bash' | sudo tee /usr/local/bin/check-mdi 1>/dev/null
        echo '/opt/Tools/check_mdi/venv/bin/python /opt/Tools/check_mdi/check_mdi.py "$@"' | sudo tee -a /usr/local/bin/check-mdi 1>/dev/null
        sudo chmod +x /usr/local/bin/check-mdi
        step "check_mdi tool is installed"
    elif _cmd_exists check-mdi; then
        step "check-mdi is already installed"
    else
        step "Python or venv are not installed - skipping"
    fi
}

security_bootstrap_wordlists() {
    echo
    if _cmd_exists curl && _cmd_exists git; then
        step "Installing wordlists"
        echo "You may need to type in your sudo password:"
        sudo -v
        sudo chmod a+rwx /opt
        mkdir -p /opt/Tools/wordlists
        echo "  > OneListForAll"
        git clone https://github.com/six2dez/OneListForAll /opt/Tools/wordlists/OneListForAll || {
            echo "OneListForAll repository is already cloned" && \
            cd /opt/Tools/wordlists/OneListForAll && \
            git fetch --all && \
            git reset --hard HEAD && \
            git pull
        }
        echo "  > SecLists"
        git clone https://github.com/danielmiessler/SecLists /opt/Tools/wordlists/SecLists || {
            echo "SecLists repository is already cloned" && \
            cd /opt/Tools/wordlists/SecLists && \
            git fetch --all && \
            git reset --hard HEAD && \
            git pull
        }
        echo "  > assetnote"
        sudo apt-get install jq -yqq --show-progress
        git clone https://github.com/assetnote/wordlists /opt/Tools/wordlists/assetnote || {
            echo "assetnote wordlists repository is already cloned" && \
            cd /opt/Tools/wordlists/assetnote && \
            git fetch --all && \
            git reset --hard HEAD && \
            git pull
        }
        mkdir -p /opt/Tools/wordlists/assetnote/lists/{automated,technologies}
        cat /opt/Tools/wordlists/assetnote/data/automated.json | jq -r '.[] | .[].Download' | cut -d"'" -f2 | \
            xargs -I {} wget -nH -e robots=off -q --show-progress -P /opt/Tools/wordlists/assetnote/lists/automated {}
        cat /opt/Tools/wordlists/assetnote/data/technologies.json | jq -r '.[] | .[].Download' | cut -d"'" -f2 | \
            xargs -I {} wget -nH -e robots=off -q --show-progress -nc -P /opt/Tools/wordlists/assetnote/lists/technologies {}

        step "wordlists are installed"
    else
        step "Python or venv are not installed - skipping"
    fi
}

# ------------------------------------------------------------

# Installation of GUI tools

security_gui_setup_burp() {
    echo
    if ! _cmd_exists burpsuite && ! _cmd_exists BurpSuitePro; then
        step "Installing Burp Suite"
        local LATEST_VERSION="$(curl -s https://portswigger.net/burp/releases | \grep -E 'Professional / Community [0-9]{4}\.[0-9]+(\.[0-9]+)?' | awk -F 'Community ' '{print $2}' | cut -d'<' -f1 | head -n1)"
        step "  Downloading official installer"
        curl -# -SL 'https://portswigger-cdn.net/burp/releases/download?product=pro&version='$LATEST_VERSION'&type=Linux' -o burp_installer
        chmod +x ./burp_installer && sudo ./burp_installer
        rm ./burp_installer
        step "Burp Suite is installed"
    else
        step "Burp Suite is already installed"
    fi
}

# ------------------------------------------------------------

# Main script handler and flags

if [ $# -eq 0 ]; then
    show_help
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

local EXCLUDED_PACKAGES='TBD'
# List all possible tools to bootstrap
if [[ "$list_tools" == true ]]; then
    all_tools=$(typeset -f | \grep -e "^security\_bootstrap\_" | \grep -v "$EXCLUDED_PACKAGES" | cut -d'_' -f3 | cut -d' ' -f1)
    all_gui_tools=$(typeset -f | \grep -e "^security\_gui\_setup\_" | cut -d'_' -f4,5 | cut -d' ' -f1)
    echo '--- CLI ---' 
    echo $all_tools | sort
    echo
    echo '--- GUI ---' 
    echo $all_gui_tools | sort
    echo
    echo '--- GROUPS ---'
    echo all
    exit 0
fi

# List default security-related VSCode extensions
if [[ "$list_default_code_ext" == true ]]; then
    IFS=$'\n' sorted=($(sort <<<"${vscode_sec_extensions[*]}"))
    unset IFS
    for extension in "${sorted[@]}"; do
        echo $extension
    done
    exit 0
fi

# Handle rest of the flags
if [ -z "$tool_to_bootstrap" -a -z "$gui_tool_to_bootstrap" ]; then
    show_help
    exit 0
fi

local EXCLUDED_PACKAGES='allgui'

# User passed the CLI tools as a coma-separated list
IFS=',' read -r -A few_tools_to_bootstrap <<< "$tool_to_bootstrap"

for tool_to_bootstrap in "${few_tools_to_bootstrap[@]}"
do
    if [[ -n "${tool_to_bootstrap}" ]]; then
        if [[ "$tool_to_bootstrap" != "all" ]] && type security_bootstrap_"$tool_to_bootstrap" | grep -q "not found"; then
            step "Bootstrap for $tool_to_bootstrap not implemented - exiting"
            exit 1
        elif [[ "$tool_to_bootstrap" == "all" ]]; then
            all_tools=$(typeset -f | \grep -e "^security\_bootstrap\_" | \grep -v "$EXCLUDED_PACKAGES" | cut -d'_' -f3 | cut -d' ' -f1)
            all_tools_sorted=$(echo $all_tools | sort)
            IFS=$'\n' all_tools_sorted=($(sort <<<"$all_tools"))
            unset IFS
            for tool in "${all_tools_sorted[@]}"; do
                security_bootstrap_"$tool"
            done
            exit 0
        else
            security_bootstrap_"$tool_to_bootstrap"
        fi
    fi
done

# User passed the GUI tools as a coma-separated list
IFS=',' read -r -A gui_tools_to_bootstrap <<< "$gui_tool_to_bootstrap"
for gui_tool_to_bootstrap in "${gui_tools_to_bootstrap[@]}"
do
    if [[ -n "${gui_tool_to_bootstrap}" ]]; then
        if type security_gui_setup_"$gui_tool_to_bootstrap" | grep -q "not found"; then
            step "GUI bootstrap for $gui_tool_to_bootstrap not implemented - exiting"
            exit 1
        elif [[ "$tool_to_bootstrap" == "gui" ]]; then
            all_tools=$(typeset -f | \grep -e "^security\_gui\_setup" | \grep -v "$EXCLUDED_PACKAGES" | cut -d'_' -f4 | cut -d' ' -f1)
            all_tools_sorted=$(echo $all_tools | sort)
            IFS=$'\n' all_tools_sorted=($(sort <<<"$all_tools"))
            unset IFS
            for tool in "${all_tools_sorted[@]}"; do
                security_gui_setup_"$tool"
            done
            exit 0
        else
            security_gui_setup_"$gui_tool_to_bootstrap"
        fi
    fi
done