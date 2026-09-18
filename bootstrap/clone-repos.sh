#!/usr/bin/env bash
# Clone my GitHub repos into ~/workspace without hardcoding their names.
#
#   clone-repos              # interactive menu listing your repos
#   clone-repos auta foo     # clone exactly these
#
# OWNER defaults to the logged-in gh user; WORKSPACE defaults to ~/workspace.
set -euo pipefail

WORKSPACE="${WORKSPACE:-$HOME/workspace}"

gh auth status &>/dev/null || { echo "Not logged in to GitHub. Run: gh auth login" >&2; exit 1; }
OWNER="${OWNER:-$(gh api user --jq .login)}"
mkdir -p "$WORKSPACE"

clone() {
  local name="$1"
  if [[ -d "$WORKSPACE/$name" ]]; then
    echo "  - $name: already exists, skipping"
  else
    gh repo clone "$OWNER/$name" "$WORKSPACE/$name"
    echo "  ✓ $name"
  fi
}

if [[ $# -gt 0 ]]; then
  for name in "$@"; do clone "$name"; done
  exit 0
fi

mapfile -t repos < <(gh repo list "$OWNER" --limit 200 --json name,visibility,updatedAt \
  --jq 'sort_by(.updatedAt) | reverse | .[] | "\(.name)\t\(.visibility | ascii_downcase)\t\(.updatedAt[:10])"')
[[ ${#repos[@]} -gt 0 ]] || { echo "No repos found for $OWNER."; exit 0; }

echo "Repos for $OWNER (most recently updated first):"
for i in "${!repos[@]}"; do
  IFS=$'\t' read -r name vis updated <<<"${repos[$i]}"
  mark=""
  [[ -d "$WORKSPACE/$name" ]] && mark=" (cloned)"
  printf '  %3d) %-40s %-8s %s%s\n' "$((i + 1))" "$name" "$vis" "$updated" "$mark"
done

read -rp "Numbers to clone (e.g. '1 3'), 'all', or empty to quit: " selection </dev/tty
[[ -n "$selection" ]] || exit 0

if [[ "$selection" == "all" ]]; then
  selection="$(seq -s ' ' 1 "${#repos[@]}")"
fi

for n in $selection; do
  if [[ "$n" =~ ^[0-9]+$ ]] && ((n >= 1 && n <= ${#repos[@]})); then
    clone "$(cut -f1 <<<"${repos[$((n - 1))]}")"
  else
    echo "  ! ignoring invalid choice: $n"
  fi
done
