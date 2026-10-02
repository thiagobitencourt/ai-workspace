# ai-workspace

My AI workspace: Claude Code skills, settings, and the bootstrap for a fresh dev VPS.

> ⚠️ This repo is **public**. Never commit secrets (tokens, `.env`, private keys).

## Layout

```
skills/        Claude Code skills (symlinked into ~/.claude/skills)
claude/        Claude Code settings (settings.json) and MCP servers (mcp-servers.json)
bootstrap/     VPS setup scripts
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
- Clones this repo to `~/workspace/ai-workspace`, symlinks the skills, installs `settings.json` if missing
- Registers the MCP servers from `claude/mcp-servers.json` at user scope (context7, playwright) and installs headless Chromium for Playwright
- Installs the `clone-repos` helper

Then, as the new user:

```bash
gh auth login
clone-repos            # pick repos from a menu (names are never stored here)
clone-repos foo bar    # or clone specific ones
claude                 # log in
```

Skills synced from claude.ai (docx, pdf, xlsx, ...) come back automatically after login.

## Adding an MCP server

Add an entry to `claude/mcp-servers.json` (same JSON as `claude mcp add-json`) and re-run `setup.sh`. Already-registered servers are skipped. Never put secrets there: use `"env": {"KEY": "${KEY}"}` and set the value on the VPS. OAuth-based MCPs need `/mcp` inside `claude` to authenticate.

## Manual migration checklist

Not covered by git, move these by hand before shutting down the old server:

- [ ] Project `.env` files
- [ ] Database data (e.g. `docker compose exec postgres pg_dump ...`)
- [ ] `~/.claude/projects/*/memory` (optional)

## Security notes

- Always read `setup.sh` before running it as root.
- Keep 2FA enabled on GitHub: whoever can push here can run code on the next bootstrap.
