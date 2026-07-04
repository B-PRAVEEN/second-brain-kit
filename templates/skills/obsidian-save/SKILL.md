---
name: obsidian-save
description: >
  Condenses the current session — decisions, working code, commands — and saves
  it to the personal second-brain vault via the second-brain MCP server.
  Call when asked to save, archive, or log work.
compatibility:
  mcp-servers:
    - second-brain
---

# obsidian-save

Vault root: `{{VAULT_PATH}}` (via the `second-brain` MCP server).
Full conventions: `AGENTS.md` at the vault root.

## Execution
1. Extract the session: key decisions, code that worked, commands run, next
   steps. Discard noise.
2. Format as markdown with fully resolved OKF frontmatter (no unresolved
   template placeholders):

   ```yaml
   ---
   type: session-log
   title: <short topic>
   description: <one line>
   project: general
   agent_client: kimi
   tags: [session]
   timestamp: <ISO 8601 UTC, e.g. 2026-07-04T15:30:00Z>
   status: archived
   ---
   ```

3. `write_file` to `Sessions/Kimi/YYYY-MM-DD-HHmm — <topic-slug>.md`.
4. If durable knowledge emerged, also create/update a note in `Reference/` or
   `Projects/` and link it from `index.md`.
5. Report the full saved path.

## Rules
- No credentials, keys, tokens, or account numbers in notes.
- Never rename, move, or overwrite existing notes.
- Standard markdown links only.
