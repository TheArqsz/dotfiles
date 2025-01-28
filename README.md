# Dotfiles

My configuration for dotfiles.

Inspired by:
- https://github.com/geerlingguy/dotfiles/tree/master
- https://github.com/denysdovhan/dotfiles

## TOC

* [Installation](#installation)
* [Updating](#updating)
* [What exactly is it?](#what-exactly-is-it)
	* [Zinit and plugins](#zinit-and-plugins)
	* [Prompt](#prompt)
	* [Automatic installation of additional software](#automatic-installation-of-additional-software)
	* [Custom key bindings (additional to Emacs)](#custom-key-bindings-additional-to-emacs)
	* [Additional changes](#additional-changes)
* [Bootstraping (auto setup some tools)](#bootstraping)
	* [Categories](#categories)
	* [Additional information on tools](#additional-information-on-tools)
* [License](#license)

## Installation

Make sure you have `zsh` installed and set it as your default shell:

```bash
# Install zsh (if not already installed)
sudo apt-get install zsh

# Change the default shell to zsh
chsh -s $(which zsh)
```

To install the dotfiles, follow these steps:

```bash
# Clone the dotfiles repository
git clone https://github.com/TheArqsz/dotfiles.git $HOME/.dotfiles

# Navigate to the dotfiles directory
cd $HOME/.dotfiles

# Run the installation script
./install
```

##  Updating

Use single command to get latest updates:

`update`

This command will update dotfiles, [c4p](https://github.com/TheArqsz/containers4pentesters) (if installed), brew, apt-get packages and zinit plugins.

##  What exactly is it?

The main part of this project is `.zshrc` file which contains the main configuration. I will describe briefly the details below:

###  Zinit and plugins

The main plugin manager for my zsh shell is [zinit](https://github.com/zdharma-continuum/zinit). 

I am using some Zinit's native plugins but also some from OhMyZSH (with prefix `OMZP` or `OMZL`):

- zsh-hooks/zsh-hooks 
- zsh-users/zsh-autosuggestions 
- zsh-users/zsh-completions
- Aloxaf/fzf-tab
- OMZL::clipboard.zsh 
- OMZP::copyfile 
- OMZP::systemd 
- OMZP::pip 
- OMZP::eza 
- OMZP::tldr 
- OMZP::command-not-found

###  Prompt

As for the prompt, I am using the highly customizable [Spaceship](https://spaceship-prompt.sh/) with following sections:
- user            - Username section
- host            - Hostname section
- ip              - [Custom IP section](TheArqsz/spaceship-ip)
- dir             - Current directory section
- git             - Git section (git_branch + git_status)
- package         - Package version
- docker_compose  - Docker section
- ansible         - Ansible section
- venv            - virtualenv section
- exit_code       - Exit code section
- exec_time       - Execution time
- line_sep        - Line break
- sudo            - Sudo indicator
- char            - Prompt character

I've also written a few shell functions that allow me to modify the prompt on the fly:
- [switch_prompt_ip](./files/.functions#switch_prompt_ip)
- [switch_prompt_hostname](./files/.functions#switch_prompt_hostname)

###  Automatic installation of additional software

For my zsh to be as noninteractive to be set up as possible I made it to install a few tools automatically at the first shell boot. It sets up:

- **pyenv** with 3.11.9 as a py main version (fallback to 3.10.7)
- auto **tmux** at the ssh connection
- **fzf** (to make listings more interactive)

###  Custom key bindings (additional to Emacs)

- `Ctrl+Up` - backword history search
- `Ctrl+Down` - forward history search
- `Ctrl+Right` - forward word
- `Ctrl+Left` - backward word
- `Alt+Right` - forward word (with inclusion of `/` as a delimiter)
- `Alt+Left` - backward word (with inclusion of `/` as a delimiter)
- `Alt+Backspace` - backward delete word
- `Alt+Delete` - forward delete word

---

- `Esc+T` - execute `tldr` for a typed command (you have to type command first)
- `Start+V` - if `copyq` is installed, show the clipboard history

###  Additional changes

- Terminal history extended to 100000
- Duplicates erased from the history
- Keep history between the shell instances (terminals)
- Append to the history immidiately (not after the term is killed)
- Ignore entries in history that start with space
- Timestamps are recorded in history
- Name of a directory can be used instead of `cd dirname`

---

- Auto update for `brew` is installed to be done only once a week
- `Brew` is set to not send analytics
- `Brew` is set to not use emojis

---

- If `Go` is installed, set proper envs

---

- If [c4p](https://github.com/TheArqsz/containers4pentesters) is installed, set proper envs

### Aliases

> ls -> eza

- `ls`=`eza --color=auto --group-directories-first`
- `l`=`ls -lhF`
- `la`=`ls -lhAF`
- `tree`=`ls --tree`

> fd

- `find`=`fd`

> If fdfind is installed instead if plain fd

- `fd`=`fdfind`

> grep: color and show the line number for each match

- `grep`=`grep -n --color` 

> Enable aliases to be sudo’ed

- `sudo`=```sudo [space]```

- `update`=`source $DOTFILES/scripts/update.sh`

- `reload`=`source $HOME/.zshrc`

- `+x`=`chmod +x`

- `bootstrap`=`zsh $DOTFILES/scripts/bootstrap.sh`
- `btsp`=`zsh $DOTFILES/scripts/bootstrap.sh`
- `bootstrap.sh`=`zsh $DOTFILES/scripts/bootstrap.sh`

### Additional Functions

This repository includes several useful functions to enhance the workflow. Below is a high-level overview of the available functions:

- **dockenter**: Enter a running Docker container using its ID or name.

- **extend_path**: Extend the $PATH environment variable without adding duplicates.

- **switch_prompt_ip**: Toggle the display of the IP address in the Spaceship prompt.

- **switch_prompt_hostname**: Toggle the display of the hostname in the Spaceship prompt.

- **generate_password**: Generate a random password with customizable length and character options.

- **mount_cryptomator**: Mount a Cryptomator vault to a specified target directory.

- **mount_remote_vault**: Mount a remote Cryptomator vault hosted in an SMB share.

## Bootstraping

To automate the installation of various tools, several functions have been implemented. These can be accessed using the `bootstrap`, `bootstrap.sh`, or `btsp` aliases:

```zsh
$ bootstrap -h
Usage: bootstrap -t tool...
Bootstrap OS and/or tools

Optional arguments:
    -t, --tool             Bootstrap specific tool (default: none, can be set to "all" or "gui")
        all:    Install all CLI tools
        gui:    Install additional GUI-based tools (Signal, Brave, Burp Suite Pro)

        tool1,tool2:    Multiple tools can be specified, separated by a comma

    -l, --list-tools       List tools to be bootstrapped
    -s, --system           Bootstrap system
    -v, --verbose          Set verbose mode

    --code-extensions      Additional VSCode extensions to install
    --list-default-ext     List default VSCode extensions
```

Current list of tools:

```zsh
brave
burp
flameshot
signal_desktop
docker
updog
golang
fzf
pyenv
fdfind
eza
tmux
brew
obsidian
copyq
cryptomator-cli
```

Additionally, three categories have been prepared:

```zsh
all
c4p
gui
```

Each of the given tools or categories can be installed with:

```zsh
$ bootstrap -t copyq
```

or 

```zsh
$ bootstrap -t copyq,docker,eza
```

### Categories

- `all` - Installs all the basic tools listed above
- `c4p` - Installs the [c4p](https://github.com/TheArqsz/containers4pentesters) project
- `gui` - Installs GUI tools, such as:
    - `brave`
    - `burp suite`
    - `signal`
    - `flameshot`

### Additional information on tools

- VSCode is by default installed with the following extensions:

```bash
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
```

- For VSCode, a [settings.json](./misc/vscode-settings.json) file is provided, which is considered most useful and universal.

- Brave Browser is by default installed with extensions listed in [brave_extensions.json](./misc/brave_extensions.json):

```
SponsorBlock
uBlock Origin
Bitwarden
Wappalyzer
User Agent Switcher
DotGit
```


##  License
MIT / BSD