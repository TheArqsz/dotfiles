# Dotfiles — Agent Instructions

> **Maintenance rule:** Any breaking change or major addition to this repo (new bootstrap function, new tool category, renamed alias, changed install prefix, new platform support, modified convention) **must be reflected here** before the PR/commit is considered complete.

## Project Identity
Personal dotfiles for a security researcher/pentester (TheArqsz).
Goal: fully reproducible Linux/macOS dev+pentesting environment via a single `./install`.

**Stack:** Zsh · Zinit · Spaceship · Dotbot · apt/Homebrew · Go · pyenv · NVM · Docker

---

## Repository Layout

```
files/              # Dotfiles → symlinked to $HOME by dotbot (glob: ./files/.*)
scripts/            # Bootstrap and maintenance scripts
misc/               # App configs NOT managed by dotbot (manual copy)
dotbot/             # Git submodule — do not edit directly
install             # Entry point: ./install
install.conf.yaml   # Dotbot config: symlinks · dirs · shell bootstrap
```

| File | Role |
|---|---|
| `files/.zshrc` | Zsh config: PATH, plugins, prompt, keybindings, lazy-loaders |
| `files/.aliases` | Tool aliases guarded by `_cmd_exists` |
| `files/.functions` | Shell utility functions |
| `scripts/_bootstrap_lib.sh` | Shared helpers — **always source first** |
| `scripts/bootstrap.sh` | Dev tool installer (`-t TOOL`, `-l`, `-s`, `--gui-tool`) |
| `scripts/bootstrap_security.sh` | Pentest tool installer |
| `scripts/update.sh` | Full update: dotfiles + zinit + brew + apt |
| `scripts/ssh.sh` | Idempotent SSH config setup |

---

## Patterns & Conventions

### Bootstrap scripts

```bash
# Source helpers at the top of every script
source "$(dirname "$0")/_bootstrap_lib.sh"

# Every install function must be idempotent
bootstrap_toolname() {
    if _cmd_exists toolname; then
        step "toolname already installed — skipping"
        return
    fi
    step "Installing toolname"
    # ... install logic ...
}
```

Key helpers from `_bootstrap_lib.sh`:

| Helper | Usage |
|---|---|
| `_cmd_exists BIN` | Guard before any install |
| `step "MSG"` | Section header output |
| `_ensure_tools_dir` | Create `/opt/Tools/` before writing there |
| `_gh_latest_version owner/repo` | Fetch latest GitHub release tag |
| `_go_install_tool bin gomod` | Install/update a Go tool |

**Install prefixes:**
- Python venv tools → `/opt/Tools/TOOLNAME/`
- System-wide binaries/symlinks → `/usr/local/bin/`
- Go tools → `$GOPATH/bin` via `go install` or pdtm

### Dotbot config

- New dotfile: drop it in `files/` as `.<name>` — glob auto-symlinks it
- New `$HOME` directory: add to `create:` section in `install.conf.yaml`
- New bootstrap shell command: add to `shell:` section

### Aliases (`.aliases`)

```zsh
# Always guard tool-specific aliases
if _cmd_exists eza; then
  alias ls='eza'
fi
```

### Functions (`.functions`)

- Extend PATH with `extend_path DIR` — no duplicates, no direct `$PATH=`
- Use `gitleaks_entropy STRING` to calculate Shannon entropy using Gitleaks' current string handling
- Toggle prompt sections via `switch_prompt_ip` / `switch_prompt_hostname`

### Zsh / `.zshrc`

- Lazy-load heavy tools (NVM, pyenv auto-install) — don't load eagerly
- Use zinit `ice` directives for deferred/conditional plugin loading
- fzf backend: `fd`/`fdfind` preferred over `find`
- Custom spaceship sections go in `~/.config/custom.spaceship.zsh`

---

## Common Commands

```bash
./install                              # Symlink dotfiles + run bootstrap
./install --except shell               # Skip zinit (used by update.sh)

zsh scripts/bootstrap.sh -l           # List available tools
zsh scripts/bootstrap.sh -t all       # Install all dev tools
zsh scripts/bootstrap.sh -t docker,golang  # Install specific tools
zsh scripts/bootstrap.sh -s           # System setup (UFW)
zsh scripts/bootstrap.sh --gui-tool brave  # Install GUI tool

zsh scripts/bootstrap_security.sh -l  # List security tools
zsh scripts/bootstrap_security.sh -t nuclei,subfinder

update          # Shell alias: pull + install + zinit update + brew + apt
reload          # Source ~/.zshrc
btsp            # Alias for bootstrap.sh
```

---

## Platform Handling

Always support all three targets:

```bash
# macOS
[[ "$OSTYPE" == "darwin"* ]] && ...

# WSL
uname -r | grep -iq microsoft && ...

# Linux (Debian/Ubuntu/Kali) — default path
```

Homebrew path on Linux: `/home/linuxbrew/.linuxbrew/bin`
Homebrew path on macOS: `/opt/homebrew/bin`

---

## Security Rules — Do Not Violate

| Rule | Reason |
|---|---|
| Keep `safe-chain` sourcing in `.zshrc` | npm/yarn/pnpm/bun supply chain protection |
| Keep `StrictHostKeyChecking ask` in SSH config | Prevents MITM silently |
| Keep UFW rules: deny-in, allow-out, allow 22/tcp | Minimal attack surface |
| Never store secrets in dotfiles | Configs are version-controlled |
| `bootstrap_security.sh` tools are offensive — authorized use only | Legal requirement |

---

## Anti-Patterns

- **Never** add dotfiles outside `files/` expecting dotbot to symlink them
- **Never** install tools without `_cmd_exists` guard — breaks idempotency
- **Never** hardcode version strings — use `_gh_latest_version` or package managers
- **Never** edit `dotbot/` or `dotbot/lib/pyyaml/` — git submodules
- **Never** use bare `apt install` without `sudo` and platform check
- **Never** add files to `misc/` expecting automatic management — manual copy only
- **Never** break existing alias names — other scripts and muscle memory depend on them
