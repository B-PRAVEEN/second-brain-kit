# 🧠 second-brain-kit

**A portable, OKF-conformant second brain for AI agents. One command, every agent, your files.**

Talk to Claude, Codex, Gemini, Kimi, Cursor, or Windsurf. Say **"save this
session"** — the agent writes a structured summary into a plain-markdown vault
on your machine. Ask about your projects later — from *any* agent — and it
recalls from the same vault. No cloud service, no database, no lock-in:
just markdown files you can sync, grep, and version however you like.

```
curl -fsSL https://raw.githubusercontent.com/B-PRAVEEN/second-brain-kit/main/install.sh | bash
```

*(macOS & Linux. Windows: run inside WSL.)*

## What you get

- **A vault** (default `~/SecondBrain`) — markdown + YAML frontmatter,
  conformant with [Google's Open Knowledge Format (OKF) v0.1](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf),
  and a perfectly normal [Obsidian](https://obsidian.md) vault.
- **Every AI client wired up** — the installer detects your clients and
  registers a sandboxed `second-brain` MCP filesystem server with each, with
  a timestamped backup of every config it touches.
- **Save & recall protocols** — installed into each client's *global* rules
  (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md`, …) so
  they work in every session, from any directory:
  - **SAVE** — "save this session" → structured, collision-proof session log
    in `Sessions/<Client>/`, durable knowledge promoted to `Reference/`.
  - **RECALL** — questions about *your* projects/data make the agent read the
    vault's `index.md` and follow links before answering from memory.
- **`sbk` CLI** — `doctor` (verify everything), `visualize` (interactive
  graph of your brain, zero dependencies), `add`/`remove` clients,
  `print-rules`, `uninstall`.
- **Optional git backup** — `--git` initializes a repo and installs a
  30-minute autocommit timer. Sync (Syncthing/iCloud/Dropbox) is not backup;
  this is.

## Supported clients

| Client | MCP config | Rules |
|---|---|---|
| Claude Code | `claude mcp add` (user scope) | `~/.claude/CLAUDE.md` |
| Claude Desktop / Cowork | `claude_desktop_config.json` | paste block → Project instructions |
| OpenAI Codex CLI | `codex mcp add` / `config.toml` | `~/.codex/AGENTS.md` |
| Gemini CLI | `~/.gemini/settings.json` | `~/.gemini/GEMINI.md` |
| Kimi CLI | `kimi /mcp-config` (printed) | `obsidian-save` skill |
| Cursor | `~/.cursor/mcp.json` | paste block → User Rules |
| Windsurf | `mcp_config.json` | `memories/global_rules.md` |
| Anything else | `sbk add generic` prints the universal block | printed |

## Vault layout (OKF)

```
SecondBrain/
├── index.md            home map-of-content — agents start recall here
├── AGENTS.md           vault conventions (source of truth)
├── log.md              chronological vault history
├── Reference/          durable facts, runbooks, how-tos (curated)
├── Projects/           living per-project notes
└── Sessions/<Client>/  append-only session logs
```

Every note carries YAML frontmatter with a required `type` plus `title`,
`description`, `tags`, `timestamp` — so the vault is queryable by any OKF
consumer, today and tomorrow.

## Usage

```bash
./install.sh                 # interactive
./install.sh -y --git        # non-interactive, with git backup
./install.sh --vault ~/Brain --no-clients

sbk doctor                   # end-to-end health check
sbk visualize                # interactive graph of your vault
sbk add cursor               # configure one client later
sbk print-rules              # re-print paste blocks (Claude Desktop, Cursor)
sbk uninstall                # removes configs & timer — never touches the vault
```

Then, in any configured agent:

> …do some work…
> **"save this session"**
> → `Sessions/Claude/2026-07-04-1530 — okf-vault-design.md`

> **"what did I decide about my home network setup?"**
> → agent reads `index.md` → `Reference/home-network.md` → answers from your notes

## Syncing across devices

The vault is plain files — use anything: **Syncthing** (a `.stignore` is
included), git, iCloud, Dropbox. Re-run `install.sh` on each device (it's
idempotent) to wire up that device's clients.

## Security notes

- The MCP server is sandboxed to the vault directory — agents can't read
  outside it.
- The agent rules forbid writing credentials/secrets into notes, but rules
  are advisory: **don't store account numbers, passwords, or keys in a
  plaintext synced folder.** Use full-disk encryption on every device.
- Every client config edit is backed up first (`*.bak.<timestamp>`).

## Roadmap

- `--search`: optional local full-text search MCP (SQLite FTS5) for semantic
  recall over large vaults
- PowerShell installer for native Windows
- OKF `log.md` auto-maintenance and vault lint in CI

## Contributing

Adding a client is one file — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
