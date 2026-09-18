#!/usr/bin/env bash
# Bootstrap a fresh Ubuntu (24.04+, target 26.04) VPS into my dev environment.
#
# Usage (as root):
#   curl -fsSL https://raw.githubusercontent.com/thiagobitencourt/ai-workspace/main/bootstrap/setup.sh | bash
#   curl -fsSL .../setup.sh | SSH_PUBKEY="ssh-ed25519 AAAA... me@pc" bash
#
# Safe to re-run: every step checks what already exists.
set -euo pipefail

NEW_USER="${NEW_USER:-thiago}"
GIT_NAME="${GIT_NAME:-Thiago Bitencourt}"
GIT_EMAIL="${GIT_EMAIL:-thiago.mbitencourt@gmail.com}"
DEFAULT_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOqJdL7abHjDpdvwCIRxXIDtvTm+aXvCxj0tNIqe/nzC thiago@vps"
SSH_PUBKEY="${SSH_PUBKEY:-$DEFAULT_PUBKEY}"
NODE_VERSION="${NODE_VERSION:-24}"
NVM_VERSION="${NVM_VERSION:-v0.40.3}"
WORKSPACE_REPO="${WORKSPACE_REPO:-https://github.com/thiagobitencourt/ai-workspace.git}"
SKIP_DOCKER="${SKIP_DOCKER:-0}"

export DEBIAN_FRONTEND=noninteractive

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m  ✗ %s\033[0m\n' "$*" >&2; exit 1; }

preflight() {
  log "Preflight"
  [[ $EUID -eq 0 ]] || die "Run as root."
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == "ubuntu" ]] || die "Ubuntu only (found: ${ID:-unknown})."
  dpkg --compare-versions "$VERSION_ID" ge 24.04 || die "Ubuntu 24.04+ required (found: $VERSION_ID)."
  ok "Ubuntu $VERSION_ID ($VERSION_CODENAME)"

  apt-get update -y
  apt-get upgrade -y
  apt-get install -y curl git ca-certificates gnupg unzip jq tmux htop build-essential sudo
  install -m 0755 -d /etc/apt/keyrings
  ok "Base packages installed"
}

setup_user() {
  log "User '$NEW_USER'"
  if id "$NEW_USER" &>/dev/null; then
    ok "User already exists"
  else
    adduser --disabled-password --gecos "" "$NEW_USER"
    ok "User created"
  fi
  usermod -aG sudo "$NEW_USER"

  local sudoers="/etc/sudoers.d/90-$NEW_USER"
  local tmp
  tmp="$(mktemp)"
  echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" >"$tmp"
  if command -v visudo &>/dev/null; then
    visudo -cf "$tmp" >/dev/null || { rm -f "$tmp"; die "Invalid sudoers entry."; }
  fi
  install -m 0440 -o root -g root "$tmp" "$sudoers"
  rm -f "$tmp"
  sudo -l -U "$NEW_USER" >/dev/null || die "sudo validation failed for $NEW_USER."
  ok "Passwordless sudo configured ($sudoers)"
}

setup_ssh_key() {
  log "SSH key"
  local home ssh_dir auth
  home="$(getent passwd "$NEW_USER" | cut -d: -f6)"
  ssh_dir="$home/.ssh"
  auth="$ssh_dir/authorized_keys"
  install -d -m 0700 -o "$NEW_USER" -g "$NEW_USER" "$ssh_dir"
  touch "$auth"
  if grep -qF "$SSH_PUBKEY" "$auth"; then
    ok "Key already authorized"
  else
    echo "$SSH_PUBKEY" >>"$auth"
    ok "Key added: $(awk '{print $1, $3}' <<<"$SSH_PUBKEY")"
  fi
  chown "$NEW_USER:$NEW_USER" "$auth"
  chmod 0600 "$auth"
}

setup_docker() {
  log "Docker"
  if [[ "$SKIP_DOCKER" == "1" ]]; then
    warn "SKIP_DOCKER=1, skipping"
    return
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  local codename="$VERSION_CODENAME"
  if ! curl -fsI "https://download.docker.com/linux/ubuntu/dists/$codename/Release" >/dev/null; then
    warn "Docker has no repo for '$codename' yet, falling back to 'noble'"
    codename="noble"
  fi
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $codename stable" \
    >/etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
  usermod -aG docker "$NEW_USER"
  ok "$(docker --version)"
  ok "$(docker compose version)"
}

setup_gh() {
  log "GitHub CLI"
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
  chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    >/etc/apt/sources.list.d/github-cli.list
  apt-get update -y
  apt-get install -y gh
  ok "$(gh --version | head -1)"
}

setup_user_env() {
  log "User environment (git, nvm/node, Claude Code, ai-workspace)"
  local home
  home="$(getent passwd "$NEW_USER" | cut -d: -f6)"
  runuser -u "$NEW_USER" -- env -i \
    HOME="$home" USER="$NEW_USER" PATH="/usr/local/bin:/usr/bin:/bin" TERM="${TERM:-xterm}" \
    GIT_NAME="$GIT_NAME" GIT_EMAIL="$GIT_EMAIL" NODE_VERSION="$NODE_VERSION" \
    NVM_VERSION="$NVM_VERSION" WORKSPACE_REPO="$WORKSPACE_REPO" \
    bash -s <<'USER_SCRIPT'
set -eo pipefail
ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }

# --- git ---
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
for host in https://github.com https://gist.github.com; do
  git config --global --unset-all "credential.$host.helper" || true
  git config --global --add "credential.$host.helper" ""
  git config --global --add "credential.$host.helper" "!/usr/bin/gh auth git-credential"
done
ok "git configured for $GIT_NAME <$GIT_EMAIL>"

# --- nvm + node ---
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | PROFILE="$HOME/.bashrc" bash
fi
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"
nvm install "$NODE_VERSION" >/dev/null
nvm alias default "$NODE_VERSION" >/dev/null
ok "node $(node --version) via nvm"

# --- Claude Code ---
mkdir -p "$HOME/.local/bin"
if [[ -x "$HOME/.local/bin/claude" ]]; then
  ok "Claude Code already installed"
else
  curl -fsSL https://claude.ai/install.sh | bash
fi
grep -qF 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" \
  || echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$HOME/.bashrc"
ok "$("$HOME/.local/bin/claude" --version 2>/dev/null || echo 'claude installed')"

# --- ai-workspace repo ---
ws="$HOME/workspace/ai-workspace"
mkdir -p "$HOME/workspace"
if [[ -d "$ws/.git" ]]; then
  git -C "$ws" pull --ff-only || warn "Could not pull $ws (local changes?)"
else
  git clone "$WORKSPACE_REPO" "$ws"
fi
ok "ai-workspace at $ws"

# --- skills (symlinked so a git pull updates them) ---
mkdir -p "$HOME/.claude/skills"
for skill in "$ws"/skills/*/; do
  [[ -d "$skill" ]] || continue
  name="$(basename "$skill")"
  target="$HOME/.claude/skills/$name"
  if [[ -e "$target" && ! -L "$target" ]]; then
    mv "$target" "$target.bak.$(date +%s)"
    warn "Existing $target moved to backup"
  fi
  ln -sfn "${skill%/}" "$target"
  ok "skill: $name"
done

# --- settings (never overwrite) ---
if [[ -f "$HOME/.claude/settings.json" ]]; then
  ok "~/.claude/settings.json already exists, kept"
else
  cp "$ws/claude/settings.json" "$HOME/.claude/settings.json"
  ok "~/.claude/settings.json installed"
fi

# --- helpers ---
ln -sfn "$ws/bootstrap/clone-repos.sh" "$HOME/.local/bin/clone-repos"
ok "clone-repos available"
USER_SCRIPT
}

summary() {
  log "Done!"
  cat <<EOF

  Next steps:
    1. In ANOTHER terminal, before closing this root session, test:
         ssh $NEW_USER@<this-server-ip>
    2. As $NEW_USER:
         gh auth login          # GitHub login (also used by git)
         clone-repos            # pick private repos to clone into ~/workspace
         claude                 # log in to Claude Code
    3. Manual items (not in git): project .env files, database dumps,
       ~/.claude/projects/*/memory

EOF
}

main() {
  preflight
  setup_user
  setup_ssh_key
  setup_docker
  setup_gh
  setup_user_env
  summary
}

# Wrapped in main so the whole script is parsed before running (safe with curl | bash).
main "$@"
