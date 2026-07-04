#!/usr/bin/env bash
# Adapter: Windsurf
source "$(dirname "${BASH_SOURCE[0]}")/_shared.sh"

MCP_JSON="$HOME/.codeium/windsurf/mcp_config.json"
GLOBAL_MD="$HOME/.codeium/windsurf/memories/global_rules.md"

detect() {
  [[ -d "$HOME/.codeium/windsurf" ]] || have windsurf
}

configure() {
  local vault="$1"
  json_add_mcp_server "$MCP_JSON" "$SBK_SERVER_NAME" "$vault" || return 1
  ok "windsurf: MCP server added to mcp_config.json"

  ensure_rules_file "$vault"
  backup_file "$GLOBAL_MD"
  upsert_marker_block "$GLOBAL_MD" "$SBK_RULES_FILE"
  ok "windsurf: agent rules installed in memories/global_rules.md"
}

verify() {
  json_has_mcp_server "$MCP_JSON" "$SBK_SERVER_NAME" \
    && grep -qF "$SBK_MARKER_START" "$GLOBAL_MD" 2>/dev/null
}

unconfigure() {
  json_remove_mcp_server "$MCP_JSON" "$SBK_SERVER_NAME"
  remove_marker_block "$GLOBAL_MD"
  ok "windsurf: unconfigured"
}

adapter_main "$@"
