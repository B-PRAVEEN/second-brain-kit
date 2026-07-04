---
type: doc
title: AGENTS.md — Vault Conventions
description: Universal agent instructions for this vault (source of truth).
tags: [setup, rules]
timestamp: {{TIMESTAMP}}
status: living
---

# AGENTS.md — Vault Conventions (source of truth)

> Universal instructions for any AI agent operating on this vault.
> Global client rules (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, …) carry a
> condensed copy installed by second-brain-kit; this file is the full spec.

## What this vault is
A portable, [OKF v0.1](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf)-conformant
personal knowledge base ("second brain"). Plain markdown + YAML frontmatter,
readable by humans and agents, synced across devices by the user's tool of
choice (Syncthing, git, iCloud, …). Agents access it through the `second-brain`
MCP server (filesystem, sandboxed to this directory).

## Layout
```
index.md           home map-of-content — START HERE for recall
log.md             chronological vault history (append entries)
AGENTS.md          this file
Reference/         durable facts & how-tos (typed concepts, curated)
Projects/          per-project living notes
Sessions/<Client>/ append-only session logs (Claude, Codex, Kimi, Gemini,
                   Cursor, Windsurf, Other)
```

## Note format (OKF)
Every note starts with YAML frontmatter. `type` is REQUIRED (OKF); the rest are
strongly recommended. Resolve every value — never write unresolved template
placeholders (double curly braces) into a note.

```yaml
---
type: session-log            # or: reference | project | runbook | decision …
title: Second brain MCP setup
description: One-line summary of the note.
project: general
agent_client: claude-code    # claude-desktop | claude-code | codex | kimi | gemini | cursor | windsurf | other
tags: [setup, mcp]
timestamp: {{TIMESTAMP}}
status: archived             # archived | living
---
```

- Link with standard markdown links: `[orders table](Reference/orders.md)`.
  Not `[[wikilinks]]` — OKF consumers and plain renderers can't follow those.
- Each folder has an `index.md` listing its contents (progressive disclosure).

## RECALL protocol
Before answering questions about the user's own projects, data, infrastructure,
finances, or past decisions: read `index.md`, follow relevant links, read the
matching notes in `Reference/` / `Projects/`. Answer from the vault first,
general knowledge second. If the vault has nothing, say so.

## SAVE protocol
Triggers: "save this session", "save to my second brain", "archive this chat",
"log my progress", "write this up".

1. **Summarize**: key decisions, working code and commands, open questions,
   concrete next steps. Be specific; omit filler.
2. **Format** with the frontmatter above, `type: session-log`.
3. **Name** collision-proof: `YYYY-MM-DD-HHmm — <topic-slug>.md`
   (time + slug prevents same-day overwrites and sync conflicts).
4. **Save** to `Sessions/<Client>/` matching the active client.
5. **Promote**: durable knowledge also goes to `Reference/` or `Projects/`
   (create or update the note, link it from `index.md`, add a line to `log.md`).
6. **Report** the full saved path to the user.

## Hard rules
1. NEVER write credentials, API keys, tokens, account numbers, or other secrets.
2. NEVER rename, move, or delete existing notes unless explicitly instructed.
3. Session logs are append-only: create new files, don't overwrite.
4. Only update a `Reference/`/`Projects/` note when the user asks, or when
   promoting session knowledge (step 5) — and preserve existing content.
5. Stay inside the vault; all file access goes through the `second-brain` server.
