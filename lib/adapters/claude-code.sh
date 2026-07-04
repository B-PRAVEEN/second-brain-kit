#!/usr/bin/env bash
# Adapter: Claude Code (CLI)
source "$(dirname "${BASH_SOURCE[0]}")/_shared.sh"

GLOBAL_MD="$HOME/.claude/CLAUDE.md"

detect() {
  have claude || [[ -f "$HOME/.claude.json" ]]
}

configure() {
  local vault="$1"
  if have claude; then
    if claude mcp add --scope user "$SBK_SERVER_NAME" -- npx -y "$SBK_MCP_PKG" "$vault" 2>/dev/null \
       || claude mcp add -s user "$SBK_SERVER_NAME" -- npx -y "$SBK_MCP_PKG" "$vault" 2>/dev/null; then
      ok "claude-code: registered via 'claude mcp add' (user scope)"
    else
      warn "claude-code: 'claude mcp add' failed (server may already exist) — checking config"
      json_has_mcp_server "$HOME/.claude.json" "$SBK_SERVER_NAME" \
        || json_add_mcp_server "$HOME/.claude.json" "$SBK_SERVER_NAME" "$vault" || return 1
      ok "claude-code: MCP server present in ~/.claude.json"
    fi
  else
    json_add_mcp_server "$HOME/.claude.json" "$SBK_SERVER_NAME" "$vault" || return 1
    ok "claude-code: MCP server added to ~/.claude.json"
  fi

  ensure_rules_file "$vault"
  backup_file "$GLOBAL_MD"
  upsert_marker_block "$GLOBAL_MD" "$SBK_RULES_FILE"
  ok "claude-code: agent rules installed in ~/.claude/CLAUDE.md (loads in every session)"
}

verify() {
  json_has_mcp_server "$HOME/.claude.json" "$SBK_SERVER_NAME" \
    && grep -qF "$SBK_MARKER_START" "$GLOBAL_MD" 2>/dev/null
}

unconfigure() {
  if have claude; then claude mcp remove -s user "$SBK_SERVER_NAME" 2>/dev/null || true; fi
  json_remove_mcp_server "$HOME/.claude.json" "$SBK_SERVER_NAME"
  remove_marker_block "$GLOBAL_MD"
  ok "claude-code: unconfigured"
}

adapter_main "$@"
