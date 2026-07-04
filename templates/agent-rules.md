# Second Brain (second-brain-kit)

You have access to an MCP server named `second-brain` — a filesystem server
sandboxed to the user's knowledge vault at `{{VAULT_PATH}}`.
Full conventions: read `AGENTS.md` at the vault root.

## RECALL protocol (do this proactively)
When the user asks about their own projects, finances, infrastructure, contacts,
past decisions, or anything phrased as "my/our ...", check the vault BEFORE
answering from memory:
1. `read_file` `index.md` at the vault root (the map of content).
2. Follow relevant links into `Reference/` and `Projects/`; read matching notes.
3. If nothing relevant exists, say so and answer normally.

## SAVE protocol
Trigger phrases: "save this session", "save to my second brain", "archive this
chat", "log my progress", "write this up".
1. Summarize the session: decisions, working code/commands, next steps. No filler.
2. Write a markdown note with fully resolved OKF frontmatter (no unresolved
   template placeholders):
   `type: session-log`, `title`, `description` (one line), `project`,
   `agent_client` (claude-desktop | claude-code | codex | kimi | gemini |
   cursor | windsurf | other), `tags`, `timestamp` (ISO 8601 UTC),
   `status: archived`.
3. Save via `write_file` to `Sessions/<Client>/YYYY-MM-DD-HHmm — <topic-slug>.md`
   (Client = Claude | Codex | Kimi | Gemini | Cursor | Windsurf | Other).
   Never overwrite an existing note.
4. If the session produced durable knowledge (a decision, a reference fact,
   project state), also create/update a note in `Reference/` or `Projects/`
   and link it from `index.md`.
5. Report the full saved path back to the user.

## Rules
- Never write credentials, API keys, tokens, account numbers, or secrets into notes.
- Never rename, move, or delete existing notes unless explicitly asked (links break).
- Use standard markdown links (`[title](path.md)`), not `[[wikilinks]]`.
- Stay inside the vault.
