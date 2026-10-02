# tools/

One idempotent installer per tool that has no package manager (curl | bash, release binaries, ...).
`bootstrap/apply.sh` runs every `tools/*.sh` as the normal user.

Required header on each script:

```bash
#!/usr/bin/env bash
# check: <command that exists once installed>
set -euo pipefail
```

If the `check` command is already on PATH the script is skipped. No secrets.
