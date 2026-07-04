---
type: index
title: Second Brain — Home
description: Map of content for this vault. Agents start recall here.
tags: [index, moc]
timestamp: {{TIMESTAMP}}
status: living
---

# 🧠 Second Brain — Home

The entry point for humans and agents. Durable knowledge is linked from here;
session logs stay in their dated folders.

## Setup & rules
- [AGENTS.md](AGENTS.md) — vault conventions, save & recall protocols
- [log.md](log.md) — chronological vault history

## Knowledge
- [Reference/](Reference/index.md) — durable facts, runbooks, how-tos
- [Projects/](Projects/index.md) — active project notes
- [Inbox/](Inbox/index.md) — quick captures awaiting triage

## Session archives
- [Sessions/](Sessions/index.md) — append-only agent session logs, per client

## Conventions (short version)
- Every note: YAML frontmatter, `type` required (OKF v0.1).
- Names: `YYYY-MM-DD-HHmm — topic-slug.md` for session logs.
- Links: standard markdown links, no wikilinks.
- Promote durable knowledge out of `Sessions/` into `Reference/` or
  `Projects/`, then link it here.
