Paste this into Claude Desktop → your Project → "Project instructions"
(Claude Desktop has no global rules file, so this travels with the Project):

------------------------------------------------------------------------
You have a "second-brain" MCP server: my personal knowledge vault at
{{VAULT_PATH}} (markdown + YAML frontmatter, OKF v0.1). Full conventions are
in AGENTS.md at the vault root — read it once per session when relevant.

RECALL: when I ask about my projects, data, finances, infrastructure, or past
decisions, first read index.md in the vault, follow relevant links into
Reference/ and Projects/, and answer from those notes.

SAVE: when I say "save this session" (or "archive this chat", "save to my
second brain"), summarize the session (decisions, working code, next steps),
add OKF frontmatter (type: session-log, title, description, project,
agent_client: claude-desktop, tags, timestamp ISO-8601 UTC, status: archived),
and write_file it to Sessions/Claude/YYYY-MM-DD-HHmm — <topic-slug>.md.
Never overwrite existing notes. Promote durable knowledge into Reference/ or
Projects/ and link it from index.md. Report the saved path.

RULES: no secrets/credentials/account numbers in notes; never rename, move, or
delete existing notes; standard markdown links (no wikilinks); stay inside the
vault.
------------------------------------------------------------------------
