# CLAUDE.md — second-brain-kit developer guide

Context file for AI coding agents working on THIS repository.
(Not to be confused with `templates/AGENTS.md`, which is the file the kit
installs into users' vaults, or the vault-side CLAUDE.md symlink.)

## What this project is

An open-source installer kit that gives users a portable, OKF v0.1-conformant
"second brain": a plain-markdown vault (default `~/SecondBrain`) that every AI
client (Claude Code, Claude Desktop, Codex, Gemini CLI, Kimi, Cursor,
Windsurf) reads and writes through a sandboxed MCP filesystem server named
`second-brain` (`@modelcontextprotocol/server-filesystem`).

Two behaviors are installed into each client's GLOBAL rules so they work in
every session: SAVE ("save this session" → structured log in
`Sessions/<Client>/`) and RECALL (questions about the user's own stuff →
read vault `index.md`, follow links, answer from notes).

## Architecture

```
install.sh              entry point; also self-clones when run via curl|bash
lib/common.sh           logging (ok/warn/fail/info/skip), prompts (ask/ask_value),
                        backup_file, render_template, marker-block upsert/remove,
                        kit config (~/.config/second-brain-kit/config)
lib/json.sh             merge-safe JSON edits (jq, node fallback); never edit JSON by hand
lib/autocommit.sh       git autocommit timer (launchd on macOS, systemd user on Linux)
lib/menubar.sh          installs/removes the macOS menu-bar plugin (SwiftBar/xbar)
lib/menubar-plugin.sh   the plugin itself; sources ~/.config/second-brain-kit/config
                        at runtime, calls sbk by absolute path (SwiftBar strips PATH)
lib/adapters/_shared.sh adapter boilerplate + adapter_main dispatch
lib/adapters/<client>.sh  one per client — THE extension point
lib/visualize.html      self-contained graph + dashboard template; sbk visualize
                        splices JSON (nodes/links/meta/sessions) at the
                        /*__SBK_DATA__*/ marker (via awk, not sed — no escaping issues)
bin/sbk                 CLI: doctor | add | remove | adapters | visualize | capture |
                        menubar | print-rules | print-config | git-timer | update | uninstall
templates/              vault seed files; {{VAULT_PATH}} {{DATE}} {{TIMESTAMP}}
                        substituted by render_template at install
templates/agent-rules.md  the global rules block adapters install (condensed protocols)
templates/AGENTS.md       full vault conventions (source of truth, lives in the vault)
.github/workflows/ci.yml  shellcheck + smoke test (Ubuntu)
```

## Adapter contract (most contributions land here)

Each `lib/adapters/<client>.sh` sources `_shared.sh`, defines four functions,
and ends with `adapter_main "$@"`:

- `detect` — exit 0 iff the client is installed on this machine
- `configure <vault>` — register MCP server + install agent rules
- `verify <vault>` — exit 0 iff fully configured
- `unconfigure` — best-effort removal

Rules for configure: prefer the client's official CLI (`claude mcp add`,
`codex mcp add`) with file-edit fallback; JSON via `json_add_mcp_server`;
global rules via `ensure_rules_file "$vault"` + `upsert_marker_block` (the
`<!-- second-brain-kit:start/end -->` block is idempotent — replaced, never
duplicated); `backup_file` before touching ANY file outside the vault; if it
can't be automated safely, PRINT an accurate paste block instead.

## Hard invariants — do not break

1. **Idempotent everywhere.** install.sh and every adapter must be safe to
   re-run. Vault seeding never overwrites existing user files.
2. **Never touch user data.** `sbk uninstall` removes configs/timers, NEVER
   the vault. Existing config entries are skipped, not replaced (see codex
   adapter — an existing `[mcp_servers.second_brain]` TOML block is left
   untouched and only reported).
3. **bash 3.2 compatible** (macOS default): no associative arrays, no
   `readarray`, no `${var,,}`. Target both GNU and BSD userland — e.g. no
   `timeout(1)` on macOS (see cmd_doctor for the pattern), no `sed -i`
   without suffix portability care, no `realpath -m`.
4. **`set -euo pipefail`** in every executable; quote all expansions;
   arithmetic like `((x++))` needs `|| true` under set -e.
5. **Templates stay OKF v0.1-conformant**: every seeded note has YAML
   frontmatter with required `type`; standard markdown links only (no
   `[[wikilinks]]`); per-folder `index.md`. Don't put literal `{{`
   anywhere in templates except real placeholders — CI and `sbk doctor`
   grep for unresolved placeholders.
6. **User-facing output** goes through `ok/warn/fail/info/skip`.

## Test & lint (run before every commit)

```bash
# syntax + lint (CI runs exactly this shellcheck)
bash -n install.sh lib/*.sh lib/adapters/*.sh bin/sbk
shellcheck -x -S warning install.sh lib/*.sh lib/adapters/*.sh bin/sbk

# end-to-end in a throwaway HOME (never test against your real HOME)
export HOME=$(mktemp -d) && mkdir -p "$HOME/.claude"
./install.sh -y --vault "$HOME/SecondBrain" --git
PATH="$HOME/.local/bin:$PATH" sbk doctor
PATH="$HOME/.local/bin:$PATH" sbk visualize --no-open
./install.sh -y --vault "$HOME/SecondBrain"   # idempotency check
```

CI (`.github/workflows/ci.yml`) runs shellcheck plus this smoke flow on
Ubuntu. Keep it green; macOS-specific paths (launchd, Claude Desktop config
location, zsh PATH handling) must be tested manually on a Mac.

## Known sharp edges

- `awk -v var=` mangles backslash escapes — that's why visualize splices JSON
  from a temp file with `getline`, not `-v`/`sed`.
- `~/.local/bin` isn't on macOS zsh PATH; install.sh offers an rc-file append
  (idempotent, guarded by grep).
- Kimi MCP registration and Cursor User Rules can't be file-automated —
  they're printed paste blocks by design.
- Vault filenames contain an em dash (`YYYY-MM-DD-HHmm — slug.md`) — always
  quote, always `-print0`/`sort -z` in find pipelines.
- bin/sbk's help text is its top-of-file comment block printed via
  `sed -n '2,18p'` — adding a command line means bumping that range too.
- SwiftBar/xbar run plugins with a minimal PATH — lib/menubar-plugin.sh sets
  its own PATH and only ever calls sbk via `$SBK_KIT_DIR/bin/sbk`.

## Release

Bump `SBK_VERSION` in `lib/common.sh` → update README if flags changed →
tag `vX.Y.Z` → push main + tags. The curl one-liner serves from `main`.
