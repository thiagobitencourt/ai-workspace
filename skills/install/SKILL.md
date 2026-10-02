---
name: install
description: Install and configure a tool, global package, MCP server, plugin, skill, setting or shell config on this machine AND persist it in the ai-workspace repo so every new environment gets it automatically. Use as `/install <what>`; `/install --sync` saves things installed by hand.
disable-model-invocation: true
argument-hint: <what to install> | --sync
---

# /install — install locally and persist in the repo

The repo at `~/workspace/ai-workspace` is the source of truth of my environment. `bootstrap/setup.sh` (new VPS) and `bootstrap/apply.sh` (this machine) rebuild everything from **manifests**. Your job: install what I asked for now, then record it in the right manifest, so a fresh environment ends up identical.

Request: `$ARGUMENTS`

Repo root: `~/workspace/ai-workspace` (call it `$WS`). The repo is **public**: never write secrets into it.

## Manifests

| Kind | Local install | Persist in |
|---|---|---|
| apt package | `sudo apt-get install -y <pkg>` | `packages/apt.txt` (one per line) |
| npm global | `npm install -g <pkg>` | `packages/npm-global.txt` (`pkg` or `pkg@ver`) |
| Python CLI | `pipx install <pkg>` | `packages/pipx.txt` |
| MCP server | `claude mcp add-json --scope user <name> '<json>'` | `claude/mcp-servers.json` (key = name, value = same JSON) |
| Claude plugin | `claude plugin marketplace add <src>` + `claude plugin install <p@m>` | `claude/plugins.json` (`marketplaces[{name,source}]`, `plugins["p@m"]`) |
| Skill | copy to `$WS/skills/<name>/` (keep LICENSE) | the directory itself; symlink to `~/.claude/skills/<name>` (`bootstrap/apply.sh` does it) |
| Claude setting / permission / hook | edit `~/.claude/settings.json` | same keys in `claude/settings.json` (merged over local file on apply) |
| Env var / alias / PATH | — | `shell/env.sh` (sourced from `~/.bashrc`) |
| Anything else (curl\|bash, binary release) | run the official installer | `tools/<name>.sh`: idempotent, first lines `#!/usr/bin/env bash` and `# check: <command>` (see `tools/README.md`) |

Never add an item by editing `setup.sh` or `apply.sh`; only manifests. Change those scripts only when a whole new *category* is needed.

## Flow

1. **Classify** the request into one row above. If it's ambiguous (same name in npm and apt, MCP vs plugin), ask me with AskUserQuestion. If several things were requested, handle each one in turn.
2. **Find the official install method** if it isn't obvious: use the context7 MCP or the project's docs. Don't guess package names or URLs. Prefer a package manager over `tools/*.sh`.
3. **Install and configure locally**, then **verify** (`<cmd> --version`, `claude mcp get <name>`, `claude plugin list`, `npm ls -g --depth=0`). If it fails, stop and report. **Do not persist a failed install.**
4. **Persist** in the manifest from the table. Keep files sorted/deduplicated, keep JSON valid. For `tools/*.sh` write an idempotent script and `chmod +x`.
5. **Secrets check.** If the tool needs a key/token, use `"${VAR_NAME}"` placeholders (MCP `env`, settings) — never the value — and tell me which variable to set on new machines. Before committing, scan `git diff` for tokens, keys, passwords, `Authorization`, `.env` content; if anything looks real, remove it and redo with a placeholder.
6. **Prove it reproduces:** `jq . claude/*.json`, `bash -n` on touched scripts, then run `bash $WS/bootstrap/apply.sh` and confirm it reports the new item as installed/already installed with no warnings.
7. **README:** update the "Adding things" section only if you introduced a new category or manifest.
8. **Commit** on the current branch: `feat: add <what>` (one commit per request), ending with the attribution lines required by the session's instructions. Then show me `git show --stat` and **ask before `git push`** (public repo). Push only after I confirm.
9. **Report** in a few lines: what was installed, which manifest changed, commit hash, pending manual steps (login, OAuth via `/mcp`, env vars, restart of Claude to load new MCPs/skills).

## `/install --sync`

Reconcile what is installed by hand with the manifests:

1. List local state: `npm ls -g --depth=0`, `pipx list --short`, `claude mcp list`, `claude plugin list`, `ls ~/.claude/skills`, `apt-mark showmanual` (only compare with what is already in `packages/apt.txt`; don't propose base system packages).
2. Diff against the manifests. Ignore built-ins: `npm`, `corepack`, plugins/skills synced from claude.ai (`*@synced`, `~/.claude/skills/synced`), and the packages `setup.sh` installs itself (docker, gh, node, jq, tmux, ...).
3. Show me the candidates and let me pick (AskUserQuestion, multiSelect). Persist only the picked ones using steps 4–9 above; for MCP servers read the real config with `claude mcp get <name>` and strip secrets.

## Guardrails

- Idempotent everywhere; re-running must be safe.
- Don't uninstall or overwrite existing things without asking. To *remove* something, remove it locally and from the manifest in the same commit.
- Don't touch `~/.claude/.credentials.json` or anything in `~/.claude/projects`.
- Don't push, force-push or open PRs without my explicit confirmation.
