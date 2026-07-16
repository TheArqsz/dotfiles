# GitHub Copilot Instructions — dotfiles

> **Maintenance rule:** Any breaking change or major addition (new bootstrap function, new tool category, renamed alias, changed install prefix, new platform support, modified convention) **must be reflected in this file and in `AGENT.md`** before the change is considered complete.

This is a personal dotfiles repo for a security researcher/pentester.
**Stack:** Zsh · Zinit · Spaceship · Dotbot · apt/Homebrew · Go · pyenv · NVM

## Key Conventions

### Shell scripts
- Source `scripts/_bootstrap_lib.sh` first in every script
- Guard every tool install with `_cmd_exists BIN` — all functions must be idempotent
- Use `_gh_latest_version owner/repo` for dynamic GitHub release version fetching
- Use `_go_install_tool bin gomod` for Go tool installs
- Use `step "MSG"` for section output headers
- Python venv tools → `/opt/Tools/TOOLNAME/`; system binaries → `/usr/local/bin/`

### Dotfiles
- New dotfiles go in `files/` as `.<name>` — dotbot auto-symlinks via glob
- New `$HOME` dirs go in `create:` section of `install.conf.yaml`
- Do not edit `dotbot/` subdirectory — it is a git submodule

### Aliases / Functions
- Wrap tool-specific aliases in `_cmd_exists` guards
- Use `extend_path DIR` to modify `$PATH`, not direct assignment

### Platform support
- Support Linux (Debian/Ubuntu/Kali), macOS (Homebrew), and WSL in all scripts
- macOS: `[[ "$OSTYPE" == "darwin"* ]]` · WSL: `uname -r | grep -iq microsoft`

## Do Not
- Hardcode version strings — use `_gh_latest_version` or package managers
- Add files to `misc/` expecting auto-management (manual copy only)
- Break existing alias names — muscle memory and other scripts depend on them
- Store secrets or credentials in any tracked file
- Weaken SSH `StrictHostKeyChecking` or UFW rules
- Use `bootstrap_security.sh` tools outside authorized environments
