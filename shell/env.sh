# Exports, aliases and PATH tweaks. Sourced from ~/.bashrc. NEVER put secrets here.

# Bun (tools/bun.sh)
export BUN_INSTALL="$HOME/.bun"
case ":$PATH:" in *":$BUN_INSTALL/bin:"*) ;; *) export PATH="$BUN_INSTALL/bin:$PATH" ;; esac
