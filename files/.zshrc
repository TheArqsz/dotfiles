#
# .zshrc
#

# Inspired by https://github.com/geerlingguy/dotfiles/blob/master/.zshrc

# Skipping Ubuntu system-wide compinit
# https://gist.github.com/ctechols/ca1035271ad134841284?permalink_comment_id=3401477#gistcomment-3401477
if [[ -f /etc/os-release ]] && [[ "$(awk -F= '/^NAME/{print $2}' /etc/os-release)" == *"Ubuntu"* ]]; then
  export skip_global_compinit=1
fi

# TERM
export TERM=xterm-256color
export DOTFILES="$HOME/.dotfiles"

# Colors
unset LSCOLORS
export CLICOLOR=1
export CLICOLOR_FORCE=1

# Custom PATH
export PATH="/home/user/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:$HOME/go/bin:$PATH"

# Include alias file (if present) containing aliases for ssh, etc.
if [ -f ~/.aliases ]
then
  source ~/.aliases
fi

# Include .functions file (if present) containing some useful functions
if [ -f ~/.functions ]
then
  source ~/.functions
fi

# Allow comments even in interactive shells.
setopt interactive_comments

# Python Pyenv
# ---
export DEFAULT_PYENV_PYTHON_VERSION=3.11.9
export FALLBACK_PYENV_PYTHON_VERSION=3.10.7
# Initialization takes huge portion of time when shell is started
# Temporary workaround: https://github.com/pyenv/pyenv/issues/2918#issuecomment-1977029534
pyenv() {
  eval "$(command pyenv init -)"
  pyenv "$@"
}
if [[ -d "$HOME/.pyenv" ]]; then
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  if ! (( $+commands[python] )) || [ "$(which python)" != "$PYENV_ROOT/shims/python" ]; then
    if pyenv install -l | \grep -q $DEFAULT_PYENV_PYTHON_VERSION 2>/dev/null; then
      pyenv install -s $DEFAULT_PYENV_PYTHON_VERSION
      pyenv global $DEFAULT_PYENV_PYTHON_VERSION
      exec zsh
    else
      pyenv install -s $FALLBACK_PYENV_PYTHON_VERSION
      pyenv global $FALLBACK_PYENV_PYTHON_VERSION
      exec zsh
    fi
  fi
fi
# --- END Python Pyenv

# Tmux on ssh
if [[ -n "$PS1" ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]]; then
  tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux
fi

# Zinit's installer
# ---
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "${ZINIT_HOME}" ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)" &&  chmod g-rwX "${ZINIT_HOME}"
  git clone https://github.com/zdharma-continuum/zinit "${ZINIT_HOME}" || \
  print -P "The zinit installation has failed."
fi

source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
# --- End of Zinit's installer

# EZA
# ---
if [[ $+commands[eza] -eq 0 ]]; then
  echo "EZA is not installed"
  echo "  Follow instructions at https://github.com/eza-community/eza/blob/main/INSTALL.md and restart your shell"
  echo "  or use bootstrap from .dotfiles"
fi
# --- END EZA

# Zinit snippets and plugins https://zdharma-continuum.github.io/zinit/wiki/Example-Oh-My-Zsh-setup/
setopt promptsubst

# https://github.com/marlonrichert/zsh-autocomplete/issues/441#issuecomment-1227104931
zmodload zsh/complist
autoload -Uz compinit && compinit -C

# Temporary prompt until pure theme loads
PS1="$ "

# Plugins
# ---
# Must load OMZ library git before others
zinit lucid for \
OMZL::git.zsh \
OMZP::git

export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

zinit for \
atload"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
blockf \
lucid \
wait \
zsh-hooks/zsh-hooks \
zsh-users/zsh-autosuggestions \
zsh-users/zsh-completions

zinit light zsh-users/zsh-history-substring-search
[[ "$(uname)" != "Darwin" ]] && zinit light zdharma-continuum/fast-syntax-highlighting # this really slows down prompt typing on MacOS

zinit lucid for \
OMZL::clipboard.zsh \
OMZP::copyfile \
OMZP::systemd \
OMZP::pip \
Aloxaf/fzf-tab \
OMZP::eza \
OMZP::tldr \
OMZP::command-not-found

# zinit ice as"completion"; zinit snippet https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker

# https://htr3n.github.io/2018/07/faster-zsh/
# https://gist.github.com/ctechols/ca1035271ad134841284
# autoload -Uz compinit
# if [[ -f "$HOME/.zcompdump" ]]; then
#   # Check if the cached .zcompdump file must be regenerated once a day
#   # (today as a day in the year vs the time of .zcompdump creation in a day of a year)
#   if [ $(date +%j) != $(date -r "$HOME/.zcompdump" +%j) ]; then
#     compinit
#   else
#     # Use cached
#     # compinit -C - not working? gonna fix it in the future
#     # Some completions are not loading poperly after the first session is loaded
#     # As an example - ufw is not completing properly
#     # compinit -w says that:
#     # regenerating because: number of files in dump 993 differ from files found in $fpath 1303
#     # This takes almost half the time of prompt to initialize
#     compinit
#   fi
# else
#   # File doesn't exist - we have to regenerate it anyway
#   compinit
# fi

zinit cdreplay -q

ZSH_HIGHLIGHT_HIGHLIGHTERS+=(brackets root line)
# --- END plugins

# Spaceship Theme
# ---
# Prompt
# Adds a newline character before each prompt line
SPACESHIP_PROMPT_ADD_NEWLINE=true
# Make the prompt span across two lines
SPACESHIP_PROMPT_SEPARATE_LINE=true
# Show prefixes before prompt sections or not
SPACESHIP_PROMPT_PREFIXES_SHOW=true
# Symbol displayed before the async section
SPACESHIP_ASYNC_SYMBOL=''
# Changing prompt character for the root user
SPACESHIP_CHAR_SYMBOL_ROOT="# "
# Prompt character to be shown before any command
SPACESHIP_CHAR_SYMBOL="$ "
# Secondary prompt character to be shown for incomplete commands
SPACESHIP_CHAR_SYMBOL_SECONDARY=""
# Prompt character to be shown after failed command
SPACESHIP_CHAR_SYMBOL_FAILURE="$ "

# Exit code section
SPACESHIP_EXIT_CODE_SHOW=true
SPACESHIP_EXIT_CODE_SYMBOL=''

# User section
SPACESHIP_USER_SHOW='always'
# Section's suffix
SPACESHIP_USER_SUFFIX=''

# Host section
SPACESHIP_HOST_SHOW=true
SPACESHIP_HOST_SUFFIX=''
SPACESHIP_HOST_PREFIX='@'

# Directory section
SPACESHIP_DIR_PREFIX=' '
# Number of folders of cwd to show in prompt, 0 to show all
SPACESHIP_DIR_TRUNC=0

# Git section
# Do not truncate path in repos
SPACESHIP_DIR_TRUNC_REPO=false
# Render git section asynchronously
SPACESHIP_GIT_BRANCH_ASYNC=false
[[ "$(uname)" == "Darwin" ]] && SPACESHIP_GIT_BRANCH_ASYNC=true
# Section's prefix
SPACESHIP_GIT_PREFIX=''
# Symbol displayed before the section (by default requires powerline patched font)
# This has to be exported because there is an issue with git section (SYMBOL is not passed to a constructor)
# It has to be configured with an ENV value
SPACESHIP_GIT_SYMBOL=''
SPACESHIP_GIT_STATUS_AHEAD='↑'
SPACESHIP_GIT_STATUS_BEHIND='↓'
SPACESHIP_GIT_STATUS_DELETED='X'
SPACESHIP_GIT_STATUS_DIVERGED='↕'

# IP section
SPACESHIP_IP_PREFIX=':'
SPACESHIP_IP_SUFFIX=''
SPACESHIP_IP_SYMBOL=''

# venv section
SPACESHIP_VENV_PREFIX="venv("
SPACESHIP_VENV_SUFFIX=") "

# Package section
SPACESHIP_PACKAGE_PREFIX="pkg("
SPACESHIP_PACKAGE_SUFFIX=") "
SPACESHIP_PACKAGE_SYMBOL=""


# Initialize prompt
zinit light spaceship-prompt/spaceship-prompt

# Additional, local configuration may be specified in "$HOME/.config/spaceship.zsh"
[[ -f "$HOME/.config/custom.spaceship.zsh" ]] && source "$HOME/.config/custom.spaceship.zsh"

# Custom sections
zinit light TheArqsz/spaceship-ip
spaceship add ip

# https://github.com/spaceship-prompt/spaceship-prompt/issues/1356
SPACESHIP_PROMPT_ASYNC=false
[[ "$(uname)" == "Darwin" ]] && SPACESHIP_PROMPT_ASYNC=true
# https://github.com/spaceship-prompt/spaceship-prompt/issues/1193#issuecomment-1954674054
SPACESHIP_PROMPT_ORDER=(
  user            # Username section
  host            # Hostname section
  ip              # IP section
  dir             # Current directory section
  git             # Git section (git_branch + git_status)
  package         # Package version
  docker_compose  # Docker section
  ansible         # Ansible section
  venv            # virtualenv section
  exit_code       # Exit code section
  exec_time       # Execution time
  line_sep        # Line break
  sudo            # Sudo indicator
  char            # Prompt character
)

# --- END Theme

# Case insensitive.
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Completion colors
zstyle ':completion:*' list-colors '${(s.:.)LS_COLORS}'

# fzf
# fzf installation https://github.com/junegunn/fzf?tab=readme-ov-file#using-git https://www.youtube.com/watch?v=ud7YxC33Z3w
# ---
if ! (( $+commands[fzf] )) ; then
  echo "FZF is not installed - installing"
  [[ -d "$HOME/.fzf" ]] || git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  [[ -f "$HOME/.fzf/bin/fzf" ]] || "$HOME/.fzf/install" --no-zsh --no-bash --no-update-rc --no-completion --no-key-bindings --bin
  echo "FZF was installed at $HOME/.fzf/bin/fzf"
  echo "If you want it to be accessible by every user, copy it to /usr/local/bin/ with:"
  echo "  sudo cp $HOME/.fzf/bin/fzf /usr/local/bin/"
  echo "  or use bootstrap from .dotfiles"
fi
if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
fi
# fd installation is necessary https://github.com/sharkdp/fd?tab=readme-ov-file#installation
if ! (( $+commands[fdfind] )) && ! (( $+commands[fd] )); then
  echo "fdfind/fd is not installed"
  echo "  Follow instructions at https://github.com/sharkdp/fd?tab=readme-ov-file#installation and restart your shell"
  echo "  or use bootstrap from .dotfiles"
fi
export FZF_DEFAULT_COMMAND="fd --type=f --color=always --hidden --follow"
export FZF_DEFAULT_OPTS="--ansi"
zstyle ':completion:*' menu yes
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:complete:(cd|ls|lsd|exa|eza|bat|cat|emacs|nano|vi|vim):*' \
fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls -1 --color=always $realpath'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
fzf-preview 'echo ${(P)word}'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup # https://github.com/Aloxaf/fzf-tab?tab=readme-ov-file#tmux
# Preivew `systemctl` command
# https://github.com/seagle0128/dotfiles/blob/master/.zshrc
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
zstyle ':fzf-tab:*' switch-group '<' '>'
eval "$(fzf --zsh)"
# --- END fzf

# Bindings
# ---
# https://unix.stackexchange.com/a/420414
# Stop keystroke on directory delimiter /
# Alt+Backspace
backward-kill-dir () {
  local WORDCHARS=${WORDCHARS/\/}
  zle backward-kill-word
  zle -f kill  # Ensures that after repeated backward-kill-dir, Ctrl+Y will restore all of them.
}
zle -N backward-kill-dir
# Alt+Left
backward-word-dir () {
  local WORDCHARS=${WORDCHARS/\/}
  zle backward-word
}
zle -N backward-word-dir
# Alt+Right
forward-word-dir () {
  local WORDCHARS=${WORDCHARS/\/}
  zle forward-word
}
zle -N forward-word-dir
# Alt+Delete
kill-dir () {
  local WORDCHARS=${WORDCHARS/\/}
  zle kill-word
}
zle -N kill-dir

clipboard_history () { 
  if (( $+commands[copyq] )); then
    sh -c 'nohup copyq > /dev/null 2>&1 &' && copyq show
  fi
}
zle -N clipboard_history   

bindkey -e    # Emacs keybindings
# Double bind because...WSL
bindkey "^A"                        history-substring-search-up                     # Ctrl+Up
bindkey '^[[1;5A'                   history-substring-search-up                     # Ctrl+Up
bindkey "^B"                        history-substring-search-down                   # Ctrl+Down
bindkey '^[[1;5B'                   history-substring-search-up                     # Ctrl+Down
# Setting this to make it work on Mac and Linux with Ctrl and Opt/Alt
bindkey '^C'                        forward-word                                    # Ctrl+Right
bindkey '^D'                        backward-word                                   # Ctrl+Left
# Commenting out default bindings in place of defined above
# bindkey '^[C'                       forward-word                                    # Alt+Right/Opt+Right
# bindkey '^[[1;3C'                   forward-word                                    # Alt+Right/Opt+Right
bindkey '^[C'                       forward-word-dir                                # Alt+Right/Opt+Right
bindkey '^[[1;3C'                   forward-word-dir                                # Alt+Right/Opt+Right
# bindkey '^[D'                       backward-word                                   # Alt+Left/Opt+Left
# bindkey '^[[1;3D'                   backward-word                                   # Alt+Left/Opt+Left
bindkey '^[D'                       backward-word-dir                               # Alt+Left/Opt+Left
bindkey '^[[1;3D'                   backward-word-dir                               # Alt+Left/Opt+Left
bindkey "\e"t                       tldr-command-line                               # ESC+t
# bindkey '^[^?'                      backward-kill-word                              # Alt+Backspace/Opt+Backspace
bindkey '^[^?'                      backward-kill-dir                               # Alt+Backspace/Opt+Backspace
# bindkey '^[~'                       kill-word                                       # Alt+Delete/Opt+Delete
# bindkey '^[[3;3~'                   kill-word                                       # Alt+Delete/Opt+Delete
bindkey '^[~'                       kill-dir                                        # Alt+Delete/Opt+Delete
bindkey '^[[3;3~'                   kill-dir                                        # Alt+Delete/Opt+Delete
(( $+commands[copyq] )) && bindkey '^X@sv'                   clipboard_history                                       # Meta+V

# --- END Bindings

# History
# ---
HISTFILE="$HOME/.histfile"
HISTSIZE=100000
SAVEHIST=$HISTSIZE
HISTDUP=erase             	# Erase duplicates in the history file
setopt	appendhistory     	# Append history to the history file (no overwriting)
setopt	sharehistory		# Share history across terminals
setopt	incappendhistory	# Immediately append to the history file, not just when a term is killed
setopt	hist_ignore_space	# Don't store commands prefixed with a space
setopt	hist_ignore_dups	# Ignore duplicated commands history list
setopt	hist_ignore_all_dups	# Do not enter command lines into the history list if they are duplicates of the previous event.
setopt 	extended_history	# Record timestamp of command in HISTFILE
# --- END History

# Other ZSH options
setopt	autocd			# Use the name of a directory instead of "cd name"

# Brew specific
# ---
if [ -d "/home/linuxbrew/.linuxbrew/bin/" ] && ! (( $+commands[brew] )); then
  export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
fi
if (( $+commands[brew] )); then
  # Tell homebrew to autoupdate just once a week
  export HOMEBREW_AUTO_UPDATE_SECS=604800
  export HOMEBREW_NO_ANALYTICS=true
  export HOMEBREW_NO_EMOJI=true
  fpath+=("$(brew --prefix)/share/zsh/site-functions")
fi
# --- END Brew

# Golang
# ---
if [ -d "/usr/local/go/bin" ] && ! (( $+commands[go] )); then
  mkdir -p "$HOME/go" && \
  export GOPATH="$HOME/go"
  export PATH="/usr/local/go/bin:$GOPATH/bin:$PATH"
fi
# --- END Golang

# C4P
# ---
[ -d "$HOME/.c4p" ] && . $HOME/.c4p_config
# --- END C4P