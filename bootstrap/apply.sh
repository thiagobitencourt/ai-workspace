#!/usr/bin/env bash
# Apply the declarative manifests of this repo to the current user environment.
# Runs as the normal user (no root), idempotent. Used by setup.sh on a new VPS
# and by the /install skill locally to prove a manifest reproduces the state.
#
# Manifests: skills/, claude/{settings,mcp-servers,plugins}.json, packages/{npm-global,pipx}.txt,
#            tools/*.sh, shell/env.sh   (packages/apt.txt needs root: see setup.sh)
set -eo pipefail

WS="${WS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude || echo "$HOME/.local/bin/claude")}"

ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# Print the non-empty, non-comment lines of a list file.
list_items() { [[ -f "$1" ]] && grep -Ev '^\s*(#|$)' "$1" || true; }

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
# shellcheck disable=SC1091
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"

apply_skills() {
  log "Skills"
  mkdir -p "$HOME/.claude/skills"
  for skill in "$WS"/skills/*/; do
    [[ -d "$skill" ]] || continue
    local name target
    name="$(basename "$skill")"
    target="$HOME/.claude/skills/$name"
    if [[ -e "$target" && ! -L "$target" ]]; then
      mv "$target" "$target.bak.$(date +%s)"
      warn "Existing $target moved to backup"
    fi
    ln -sfn "${skill%/}" "$target"
    ok "skill: $name"
  done
}

# Repo settings are merged over the existing file: repo keys win, local-only keys are kept.
apply_settings() {
  log "Claude settings"
  local dest="$HOME/.claude/settings.json" tmp
  mkdir -p "$HOME/.claude"
  if [[ -f "$dest" ]]; then
    tmp="$(mktemp)"
    jq -s '.[0] * .[1]' "$dest" "$WS/claude/settings.json" >"$tmp" && mv "$tmp" "$dest"
    ok "settings.json merged"
  else
    cp "$WS/claude/settings.json" "$dest"
    ok "settings.json installed"
  fi
}

apply_mcp() {
  log "MCP servers"
  local name cfg
  while IFS= read -r name; do
    if "$CLAUDE_BIN" mcp get "$name" &>/dev/null; then
      ok "mcp: $name already registered"
    else
      cfg="$(jq -c --arg n "$name" '.[$n]' "$WS/claude/mcp-servers.json")"
      if "$CLAUDE_BIN" mcp add-json --scope user "$name" "$cfg" &>/dev/null; then
        ok "mcp: $name registered"
      else
        warn "mcp: failed to register $name"
      fi
    fi
  done < <(jq -r 'keys[]' "$WS/claude/mcp-servers.json")
}

apply_plugins() {
  log "Claude plugins"
  local f="$WS/claude/plugins.json" installed name src p
  [[ -f "$f" ]] || return 0
  while IFS=$'\t' read -r name src; do
    [[ -n "$name" ]] || continue
    if "$CLAUDE_BIN" plugin marketplace list 2>/dev/null | grep -qF "$name"; then
      ok "marketplace: $name already added"
    elif "$CLAUDE_BIN" plugin marketplace add "$src" &>/dev/null; then
      ok "marketplace: $name added"
    else
      warn "marketplace: failed to add $name ($src)"
    fi
  done < <(jq -r '.marketplaces[]? | [.name, .source] | @tsv' "$f")
  installed="$("$CLAUDE_BIN" plugin list 2>/dev/null || true)"
  while IFS= read -r p; do
    [[ -n "$p" ]] || continue
    if grep -qF "$p" <<<"$installed"; then
      ok "plugin: $p already installed"
    elif "$CLAUDE_BIN" plugin install "$p" &>/dev/null; then
      ok "plugin: $p installed"
    else
      warn "plugin: failed to install $p"
    fi
  done < <(jq -r '.plugins[]?' "$f")
}

apply_npm() {
  log "npm global packages"
  local pkg bare want
  while IFS= read -r pkg; do
    bare="$(sed -E 's/^(@?[^@]+)@.*/\1/' <<<"$pkg")"
    want="$bare@"; [[ "$pkg" == "$bare" ]] || want="$pkg"
    if npm ls -g --depth=0 "$bare" 2>/dev/null | grep -qF "$want"; then
      ok "npm: $pkg already installed"
    elif npm install -g "$pkg" &>/dev/null; then
      ok "npm: $pkg installed"
    else
      warn "npm: failed to install $pkg"
    fi
  done < <(list_items "$WS/packages/npm-global.txt")
}

apply_pipx() {
  local pkgs pkg
  pkgs="$(list_items "$WS/packages/pipx.txt")"
  [[ -n "$pkgs" ]] || return 0
  log "pipx packages"
  if ! command -v pipx &>/dev/null; then
    sudo apt-get install -y pipx &>/dev/null && pipx ensurepath &>/dev/null || { warn "pipx not available"; return 0; }
  fi
  while IFS= read -r pkg; do
    if pipx list --short 2>/dev/null | awk '{print $1}' | grep -qx "${pkg%%[=<>@ ]*}"; then
      ok "pipx: $pkg already installed"
    elif pipx install "$pkg" &>/dev/null; then
      ok "pipx: $pkg installed"
    else
      warn "pipx: failed to install $pkg"
    fi
  done <<<"$pkgs"
}

apply_tools() {
  log "Custom tools"
  local script check
  for script in "$WS"/tools/*.sh; do
    [[ -f "$script" ]] || continue
    check="$(sed -n 's/^# check:[[:space:]]*//p' "$script" | head -1)"
    if [[ -n "$check" ]] && command -v "$check" &>/dev/null; then
      ok "tool: $(basename "$script" .sh) already installed"
    elif bash "$script"; then
      ok "tool: $(basename "$script" .sh) installed"
    else
      warn "tool: $(basename "$script") failed"
    fi
  done
}

apply_shell_env() {
  log "Shell env"
  local line="[ -f \"$WS/shell/env.sh\" ] && . \"$WS/shell/env.sh\""
  grep -qF "$WS/shell/env.sh" "$HOME/.bashrc" 2>/dev/null || echo "$line" >>"$HOME/.bashrc"
  ok "shell/env.sh sourced from ~/.bashrc"
}

# PATH tweaks from shell/env.sh (e.g. ~/.bun/bin) must be visible to the steps below.
[ -f "$WS/shell/env.sh" ] && . "$WS/shell/env.sh"

apply_skills
apply_settings
apply_mcp
apply_npm
apply_pipx
apply_tools      # before plugins: plugins may need tool runtimes (vercel plugin needs bun)
apply_plugins
apply_shell_env
