# Contributing

## Adding a client adapter (the most useful contribution)

One file: `lib/adapters/<client>.sh`. Contract:

```bash
#!/usr/bin/env bash
# Adapter: <Client Name>
source "$(dirname "${BASH_SOURCE[0]}")/_shared.sh"

detect()      { ... }  # exit 0 iff the client is installed on this machine
configure()   { ... }  # $1 = vault path. Register the MCP server + agent rules.
verify()      { ... }  # $1 = vault path. Exit 0 iff fully configured.
unconfigure() { ... }  # best-effort removal of what configure added

adapter_main "$@"
```

Rules:

1. **Back up before editing** any file outside the vault: `backup_file "$f"`.
2. **JSON configs**: use `json_add_mcp_server <file> "$SBK_SERVER_NAME" <vault>`
   (merge-safe, jq with node fallback). Don't hand-roll JSON.
3. **Global rules**: call `ensure_rules_file "$vault"`, then
   `upsert_marker_block <rules-file> "$SBK_RULES_FILE"`. The marker block is
   idempotent — re-running replaces, never duplicates.
4. **Prefer the client's official CLI** (`claude mcp add`, `codex mcp add`)
   over editing files, with a file-edit fallback.
5. **If something can't be automated safely, print it** — an accurate paste
   block beats a risky write.
6. Idempotent: running `configure` twice must be safe.
7. `bash` 3.2-compatible (macOS ships old bash): no associative arrays,
   no `readarray`.

Test:

```bash
shellcheck lib/adapters/<client>.sh
HOME=$(mktemp -d) bash lib/adapters/<client>.sh detect || echo "not detected (expected on CI)"
./install.sh -y --vault "$(mktemp -d)/vault" --no-clients   # smoke test
```

## Other contributions

- **Templates** (`templates/`): keep them OKF v0.1-conformant — `type` is
  required in every note's frontmatter; standard markdown links only.
- **`sbk` subcommands**: add a `cmd_<name>()` and a case entry.
- **CI** runs shellcheck on every `*.sh` and `bin/sbk` — keep it green.

## Style

- `set -euo pipefail` in every executable script.
- Quote every expansion. Run shellcheck before pushing.
- User-facing output goes through `ok/warn/fail/info/skip` from `common.sh`.
