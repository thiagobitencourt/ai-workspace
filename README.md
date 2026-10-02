# ai-workspace

My AI workspace: Claude Code skills, settings, and the bootstrap for a fresh dev VPS.

> ⚠️ This repo is **public**. Never commit secrets (tokens, `.env`, private keys).

## Layout

```
skills/        Claude Code skills (symlinked into ~/.claude/skills)
claude/        settings.json, mcp-servers.json, plugins.json
packages/      apt.txt, npm-global.txt, pipx.txt (one package per line)
tools/         idempotent installers for tools without a package manager
shell/         env.sh (exports/aliases/PATH, sourced from ~/.bashrc)
bootstrap/     setup.sh (new VPS, as root) and apply.sh (applies the manifests as the user)
```

## Bootstrap a new VPS (Ubuntu 24.04+ / 26.04)

As **root** on the new server:

```bash
curl -fsSL https://raw.githubusercontent.com/thiagobitencourt/ai-workspace/main/bootstrap/setup.sh | bash
```

Use a different SSH public key:

```bash
curl -fsSL https://raw.githubusercontent.com/thiagobitencourt/ai-workspace/main/bootstrap/setup.sh \
  | SSH_PUBKEY="ssh-ed25519 AAAA... me@laptop" bash
```

Other overrides (env vars): `NEW_USER`, `GIT_NAME`, `GIT_EMAIL`, `NODE_VERSION`, `SKIP_DOCKER=1`.

What it does (idempotent, safe to re-run):

- Creates the user with passwordless sudo and SSH key login
- Installs Docker + Compose (official repo) and the GitHub CLI
- Configures git globals (+ gh as credential helper)
- Installs Node via nvm and Claude Code (native installer)
- Clones this repo to `~/workspace/ai-workspace` and runs `bootstrap/apply.sh`, which applies every manifest: skills (symlinks), `settings.json` (merged over the local file), MCP servers, plugins, npm/pipx packages, `tools/*.sh`, `shell/env.sh`
- Installs `packages/apt.txt` and headless Chromium for the Playwright MCP
- Installs the `clone-repos` helper

Then, as the new user:

```bash
gh auth login
clone-repos            # pick repos from a menu (names are never stored here)
clone-repos foo bar    # or clone specific ones
claude                 # log in
```

Skills synced from claude.ai (docx, pdf, xlsx, ...) come back automatically after login.

## Adding things: `/install`

Inside Claude Code in this repo, run `/install <what>` (e.g. `/install ripgrep`, `/install the sentry MCP`). The skill installs and configures it on the current machine, records it in the right manifest below, validates with `apply.sh`, commits, and asks before pushing. `/install --sync` saves things installed by hand.

| Manifest | What |
|---|---|
| `packages/apt.txt` | apt packages |
| `packages/npm-global.txt` | global npm packages |
| `packages/pipx.txt` | Python CLIs |
| `claude/mcp-servers.json` | MCP servers (`claude mcp add-json` format) |
| `claude/plugins.json` | plugin marketplaces and plugins |
| `claude/settings.json` | settings, permissions, hooks |
| `skills/<name>/` | skills |
| `tools/<name>.sh` | custom installers (see `tools/README.md`) |
| `shell/env.sh` | env vars, aliases, PATH |

To apply the manifests on the current machine: `bootstrap/apply.sh` (idempotent). Never put secrets in any of them: use `"${VAR}"` placeholders and set the value on each machine. OAuth-based MCPs need `/mcp` inside `claude`.

## Manual migration checklist

Not covered by git, move these by hand before shutting down the old server:

- [ ] Project `.env` files
- [ ] Database data (e.g. `docker compose exec postgres pg_dump ...`)
- [ ] `~/.claude/projects/*/memory` (optional)

## Security notes

- Always read `setup.sh` before running it as root.
- Keep 2FA enabled on GitHub: whoever can push here can run code on the next bootstrap.
