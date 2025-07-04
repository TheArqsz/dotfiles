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

# Local reload, separate from the global reload
_local_reload() {
    local _current_sh="$(ps -cp "$$" -o command="")"
    source $HOME/.${_current_sh}rc
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

security_bootstrap_nmap() {
    echo
    if ! _cmd_exists nmap && [[ -f "/etc/debian_version" ]]; then
        step "Installing nmap"
        _cmd_exists apt-get || {
            step "apt-get not installed - exiting"
            exit 1
        }
        sudo apt-get install --show-progress -yqq nmap
    elif _cmd_exists nmap; then
        step "nmap is already installed"
    else
        step "Not implemented on non Debian-based system - skipping"
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
        sudo apt-get install --show-progress -yqq libpcap-dev make build-essential

        local _current_dir=$(pwd)
        local _clone_dir=$(mktemp -d)
        # https://github.com/blechschmidt/massdns#compilation
        git clone https://github.com/blechschmidt/massdns $_clone_dir
        cd $_clone_dir
        make && \
        sudo make install && \
        cd "$_current_dir" && \
        rm -rf $_clone_dir
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
        if ! _cmd_exists pdtm; then
            step "Installing pdtm"
            go install -v github.com/projectdiscovery/pdtm/cmd/pdtm@latest
            step "ProjectDiscovery's Open Source Tool Manager is installed"
        else
            step "Updating pdtm"
            pdtm -nc -dc -up
        fi
        
        local -a _pdtm_tools_to_install=(
            subfinder
            tldfinder
            naabu
            notify
            nuclei
            shuffledns
            httpx
            dnsx
            asnmap
            chaos-client
        )

        for tool in "${_pdtm_tools_to_install[@]}"; do
            if ! _cmd_exists $tool; then
                if [ "$tool" = "naabu" ]; then
                    _cmd_exists apt-get || {
                        step "apt-get not installed - exiting"
                        exit 1
                    }
                    step "Installing naabu dependencies"
                    sudo apt-get install --show-progress -yqq libpcap-dev
                    security_bootstrap_nmap
                elif [ "$tool" = "shuffledns" ]; then
                    step "Installing shuffledns dependencies"
                    security_bootstrap_massdns
                    _local_reload
                fi
                pdtm -dc -nc -duc -i $tool 
            else
                step "$tool already installed - updating"
                pdtm -dc -nc -duc -u $tool 2>/dev/null
            fi
        done
         
        # Update templates
        _local_reload
        if _cmd_exists nuclei; then
            nuclei -nc -nm -ut 
        fi
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_github-subdomains() {
    echo
    if ! _cmd_exists github-subdomains && _cmd_exists go && [[ -f "/etc/debian_version" ]]; then
        step "Installing github-subdomains"
        go install -v github.com/gwen001/github-subdomains@latest
        step "github-subdomains tool is installed"
    elif _cmd_exists github-subdomains; then
        step "github-subdomains is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_gitlab-subdomains() {
    echo
    if ! _cmd_exists gitlab-subdomains && _cmd_exists go && [[ -f "/etc/debian_version" ]]; then
        step "Installing gitlab-subdomains"
        go install -v github.com/gwen001/gitlab-subdomains@latest
        step "gitlab-subdomains tool is installed"
    elif _cmd_exists gitlab-subdomains; then
        step "gitlab-subdomains is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_check_mdi() {
    echo
    if ! _cmd_exists python3;  then 
        step "Installing check_mdi dependencies"
        sudo apt-get install --show-progress -yqq python3 python3-venv
    fi
    if ! _cmd_exists check_mdi && _cmd_exists python3 && $(python3 -m venv -h 2>&1 1>/dev/null); then
        step "Installing check_mdi"
        echo "You may need to type in your sudo password:"
        sudo -v
        sudo chmod a+rwx /opt
        mkdir -p /opt/Tools
        git clone https://github.com/TheArqsz/check_mdi /opt/Tools/check_mdi 2>/dev/null || {
            echo "check_mdi repository is already cloned"
        }
        python3 -m venv /opt/Tools/check_mdi/venv
        /opt/Tools/check_mdi/venv/bin/pip install -r /opt/Tools/check_mdi/requirements.txt
        echo '#!/usr/bin/env bash' | sudo tee /usr/local/bin/check_mdi 1>/dev/null
        echo '/opt/Tools/check_mdi/venv/bin/python /opt/Tools/check_mdi/check_mdi.py "$@"' | sudo tee -a /usr/local/bin/check_mdi 1>/dev/null
        sudo chmod +x /usr/local/bin/check_mdi
        step "check_mdi tool is installed"
    elif _cmd_exists check_mdi; then
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
        local choice
        echo -n "Do you want to install OneListForAll? (y/n): "
        read choice
        if [[ "$choice" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
            echo "  > OneListForAll"
            git clone https://github.com/six2dez/OneListForAll /opt/Tools/wordlists/OneListForAll || {
                echo "OneListForAll repository is already cloned" && \
                cd /opt/Tools/wordlists/OneListForAll && \
                git fetch --all && \
                git reset --hard HEAD && \
                git pull
            }
        else
            echo "OneListForAll skipped."
        fi
        
        choice=''
        echo -n "Do you want to install SecLists? (y/n): "
        read choice
        if [[ "$choice" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
            echo "  > SecLists"
            git clone https://github.com/danielmiessler/SecLists /opt/Tools/wordlists/SecLists || {
                echo "SecLists repository is already cloned" && \
                cd /opt/Tools/wordlists/SecLists && \
                git fetch --all && \
                git reset --hard HEAD && \
                git pull
            }
        else
            echo "SecLists skipped."
        fi
        
        choice=''
        echo -n "Do you want to install assetnote wordlists? (y/n): "
        read choice
        if [[ "$choice" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
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
                xargs -I {} wget -nH -e robots=off -q --show-progress -nc -P /opt/Tools/wordlists/assetnote/lists/automated {}
            cat /opt/Tools/wordlists/assetnote/data/technologies.json | jq -r '.[] | .[].Download' | cut -d"'" -f2 | \
                xargs -I {} wget -nH -e robots=off -q --show-progress -nc -P /opt/Tools/wordlists/assetnote/lists/technologies {}
        else
            echo "assetnote wordlists skipped."
        fi
        
        choice=''
        echo -n "Do you want to install n0kovo DNS wordlists? (y/n): "
        read choice
        if [[ "$choice" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
            echo "  > n0kovo DNS"
            git clone https://github.com/n0kovo/n0kovo_subdomains /opt/Tools/wordlists/n0kovo_subdomains || {
                echo "n0kovo DNS repository is already cloned" && \
                cd /opt/Tools/wordlists/n0kovo_subdomains && \
                git fetch --all && \
                git reset --hard HEAD && \
                git pull
            }
        else
            echo "n0kovo DNS skipped."
        fi

        step "wordlists are installed"
    else
        step "Python or venv are not installed - skipping"
    fi
}

security_bootstrap_nomore403() {
    echo
    if _cmd_exists go && [[ -f "/etc/debian_version" ]]; then
        step "Installing nomore403"
        go install -v github.com/devploit/nomore403@latest
        step "nomore403 tool is installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_jsluice() {
    echo
    if ! _cmd_exists jsluice && _cmd_exists go && [[ -f "/etc/debian_version" ]]; then
        step "Installing jsluice"
        go install -v github.com/BishopFox/jsluice/cmd/jsluice@latest
        step "jsluice tool is installed"
    elif _cmd_exists jsluice; then
        step "jsluice is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_brutespray() {
    # https://github.com/x90skysn3k/brutespray
    # https://github.com/Arcanum-Sec/brutespray
    echo
    if ! _cmd_exists brutespray && _cmd_exists go && [[ -f "/etc/debian_version" ]]; then
        step "Installing brutespray"
        go install -v github.com/x90skysn3k/brutespray@latest
        step "brutespray tool is installed"
    elif _cmd_exists brutespray; then
        step "brutespray is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_nomore403() {
    # https://github.com/jhaddix/nomore403
    # https://github.com/devploit/nomore403
    echo
    if [[ -f "/etc/debian_version" ]]; then
        NOMORE403_LATEST_VERSION=$(curl -sSL https://github.com/devploit/nomore403/releases | \grep -E 'devploit/nomore403/tree' | awk -F'tree/' '{print $2}' | awk -F'" ' '{print $1}' | head -n1)
        if _cmd_exists nomore403; then
            sha256_latest="$(curl -# -sSL "https:/github.com/devploit/nomore403/releases/download/$NOMORE403_LATEST_VERSION/checksums.txt" -o - | \grep nomore403_linux_amd64 | awk '{print $1}')"
            sha256_installed="$(sha1sum "$(which nomore403)" | awk '{print $1}')"
            if [ "$md5_1" = "$md5_2" ]; then
                step "Skipping update"
                return
            else
                step "Updating nomore403"
            fi
        else
            step "Installing nomore403"
        fi
        curl -# -SL "https:/github.com/devploit/nomore403/releases/download/$NOMORE403_LATEST_VERSION/nomore403_linux_amd64" --output /tmp/nomore403_${NOMORE403_LATEST_VERSION}
        sudo mv /tmp/nomore403_${NOMORE403_LATEST_VERSION} /usr/local/bin/nomore403
        sudo chmod +x /usr/local/bin/nomore403
        step "nomore403 installed"
    else
        step "nomore403 is not installed - skipping"
    fi
}

security_bootstrap_caduceus() {
    # https://github.com/g0ldencybersec/Caduceus
    # https://github.com/jhaddix/Caduceus
    echo
    if ! _cmd_exists caduceus && _cmd_exists go && [[ -f "/etc/debian_version" ]]; then
        step "Installing caduceus"
        sudo apt-get install --show-progress -yqq gcc
        go install -v github.com/g0ldencybersec/Caduceus/cmd/caduceus@latest
        step "caduceus tool is installed"
    elif _cmd_exists caduceus; then
        step "caduceus is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_msftrecon() {
    echo
    if ! _cmd_exists msftrecon && _cmd_exists python && $(python -m venv -h 2>&1 1>/dev/null); then
        step "Installing msftrecon"
        echo "You may need to type in your sudo password:"
        sudo -v
        sudo chmod a+rwx /opt
        mkdir -p /opt/Tools
        step "Cloning the repository"
        git clone https://github.com/Arcanum-Sec/msftrecon /opt/Tools/msftrecon 2>/dev/null || {
            echo "msftrecon repository is already cloned"
        }
        python -m venv /opt/Tools/msftrecon/venv
        /opt/Tools/msftrecon/venv/bin/pip install -r /opt/Tools/msftrecon/requirements.txt
        /opt/Tools/msftrecon/venv/bin/pip install setuptools
        /opt/Tools/msftrecon/venv/bin/python /opt/Tools/msftrecon/setup.py install
        echo '#!/usr/bin/env bash' | sudo tee /usr/local/bin/msftrecon 1>/dev/null
        echo '/opt/Tools/msftrecon/venv/bin/msftrecon "$@"' | sudo tee -a /usr/local/bin/msftrecon 1>/dev/null
        sudo chmod +x /usr/local/bin/msftrecon
        step "msftrecon tool is installed"
    elif _cmd_exists msftrecon; then
        step "msftrecon is already installed"
    else
        step "Python or venv are not installed - skipping"
    fi
}

security_bootstrap_trufflehog() {
    echo
    if ! _cmd_exists trufflehog && _cmd_exists go; then
        step "Installing trufflehog"
        echo "You may need to type in your sudo password:"
        sudo -v
        sudo chmod a+rwx /opt
        mkdir -p /opt/Tools
        step "Cloning the repository"
        git clone https://github.com/trufflesecurity/trufflehog.git /opt/Tools/trufflehog 2>/dev/null || {
            echo "trufflehog repository is already cloned"
        }
        cd /opt/Tools/trufflehog
        
        step "Building trufflehog"
        go install -v
        step "trufflehog is installed"
    elif _cmd_exists trufflehog; then
        step "trufflehog is already installed"
    else
        step "golang is not installed"
    fi
}

security_bootstrap_gitleaks() {
    echo
    if ! _cmd_exists gitleaks && _cmd_exists go; then
        step "Installing gitleaks"
        echo "You may need to type in your sudo password:"
        sudo -v
        sudo chmod a+rwx /opt
        mkdir -p /opt/Tools
        step "Cloning the repository"
        git clone https://github.com/gitleaks/gitleaks.git /opt/Tools/gitleaks 2>/dev/null || {
            echo "gitleaks repository is already cloned"
        }
        cd /opt/Tools/gitleaks
        step "Building gitleaks"
        make build
        [ -f gitleaks ] && sudo mv gitleaks /usr/local/bin/gitleaks
        step "gitleaks is installed"
    elif _cmd_exists gitleaks; then
        step "gitleaks is already installed"
    else
        step "golang is not installed"
    fi
}

security_bootstrap_waybackurls() {
    echo
    if ! _cmd_exists waybackurls && _cmd_exists go; then
        step "Installing waybackurls"
        go install -v github.com/tomnomnom/waybackurls@latest
        step "waybackurls tool is installed"
    elif _cmd_exists waybackurls; then
        step "waybackurls is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_assetfinder() {
    echo
    if ! _cmd_exists assetfinder && _cmd_exists go; then
        step "Installing assetfinder"
        go install -v github.com/tomnomnom/assetfinder@latest
        step "assetfinder tool is installed"
    elif _cmd_exists assetfinder; then
        step "assetfinder is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_unfurl() {
    echo
    if ! _cmd_exists unfurl && _cmd_exists go; then
        step "Installing unfurl"
        go install -v github.com/tomnomnom/unfurl@latest
        step "unfurl tool is installed"
    elif _cmd_exists unfurl; then
        step "unfurl is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_cero() {
    echo
    if ! _cmd_exists cero && _cmd_exists go; then
        step "Installing cero"
        go install -v github.com/glebarez/cero@latest
        step "cero tool is installed"
    elif _cmd_exists cero; then
        step "cero is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_puredns() {
    echo
    if ! _cmd_exists puredns && _cmd_exists go; then
        if ! _cmd_exists massdns; then
            step "massdns is required for puredns. Installing massdns..."
            security_bootstrap_massdns
            _local_reload
        fi
        step "Installing puredns"
        go install -v github.com/d3mondev/puredns/v2@latest
        step "puredns tool is installed"
    elif _cmd_exists puredns; then
        step "puredns is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_amass() {
    echo
    if ! _cmd_exists amass && _cmd_exists go; then
        step "Installing amass"
        go install -v github.com/owasp-amass/amass/v4/...@master
        step "amass tool is installed"
    elif _cmd_exists amass; then
        step "amass is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_csprecon() {
    echo
    if ! _cmd_exists csprecon && _cmd_exists go; then
        step "Installing csprecon"
        go install -v github.com/edoardottt/csprecon/cmd/csprecon@latest
        step "csprecon tool is installed"
    elif _cmd_exists csprecon; then
        step "csprecon is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_shosubgo() {
    echo
    if ! _cmd_exists shosubgo && _cmd_exists go; then
        step "Installing shosubgo"
        go install -v github.com/incogbyte/shosubgo@latest
        step "shosubgo tool is installed"
    elif _cmd_exists shosubgo; then
        step "shosubgo is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_CloudRecon() {
    echo
    if ! _cmd_exists CloudRecon && _cmd_exists go; then
        sudo apt-get install --show-progress -yqq gcc
        step "Installing CloudRecon"
        go install -v github.com/g0ldencybersec/CloudRecon@latest
        step "CloudRecon tool is installed"
    elif _cmd_exists CloudRecon; then
        step "CloudRecon is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_getallurls() {
    echo
    if ! _cmd_exists getallurls && _cmd_exists go; then
        step "Installing gau"
        go install -v github.com/lc/gau/v2/cmd/gau@latest
        echo '#!/usr/bin/env bash' | sudo tee /usr/local/bin/getallurls 1>/dev/null
        echo '$GOPATH/bin/gau "$@"' | sudo tee -a /usr/local/bin/getallurls 1>/dev/null
        sudo chmod +x /usr/local/bin/getallurls
        step "getallurls tool is installed"
    elif _cmd_exists getallurls; then
        step "getallurls is already installed"
    else
        step "Golang is not installed - skipping"
    fi
}

security_bootstrap_crt.sh() {
    # https://github.com/az7rb/crt.sh
    # https://github.com/TheArqsz/crt.sh
    echo
    if ! _cmd_exists crt.sh; then
        step "Installing the fork of crt.sh"
        git clone https://github.com/TheArqsz/crt.sh /opt/Tools/crt.sh 2>/dev/null || {
            echo "crt.sh repository is already cloned" && \
            cd /opt/Tools/crt.sh && \
            git fetch --all && \
            git reset --hard HEAD && \
            git pull
        }
        chmod +x /opt/Tools/crt.sh/crt_v2.sh
        if [ ! -f /usr/local/bin/crt.sh ]; then
            echo '#!/usr/bin/env bash' | sudo tee /usr/local/bin/crt.sh 1>/dev/null
            echo '/opt/Tools/crt.sh/crt_v2.sh "$@"' | sudo tee -a /usr/local/bin/crt.sh 1>/dev/null
            sudo chmod +x /usr/local/bin/crt.sh
            step "crt.sh tool is installed"
        fi
    else
        step "crt.sh is already installed"
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

security_gui_setup_burp_community() {
    echo
    if ! _cmd_exists burpsuite; then
        step "Installing Burp Suite Community"
        local LATEST_VERSION="$(curl -s https://portswigger.net/burp/releases | \grep -E 'Professional / Community [0-9]{4}\.[0-9]+(\.[0-9]+)?' | awk -F 'Community ' '{print $2}' | cut -d'<' -f1 | head -n1)"
        step "  Downloading official installer"
        curl -# -SL 'https://portswigger-cdn.net/burp/releases/download?product=community&version='$LATEST_VERSION'&type=Linux' -o burp_installer
        chmod +x ./burp_installer && sudo ./burp_installer
        rm ./burp_installer
        step "Burp Suite Community is installed"
    else
        step "Burp Suite Community is already installed"
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