#!/usr/bin/env bash
# Adapter: Cursor
source "$(dirname "${BASH_SOURCE[0]}")/_shared.sh"

MCP_JSON="$HOME/.cursor/mcp.json"

detect() {
  [[ -d "$HOME/.cursor" ]] || have cursor
}

configure() {
  local vault="$1"
  json_add_mcp_server "$MCP_JSON" "$SBK_SERVER_NAME" "$vault" || return 1
  ok "cursor: MCP server added to ~/.cursor/mcp.json (global)"

  ensure_rules_file "$vault"
  info "cursor: global rules live in the app — paste this into"
  info "Cursor Settings → Rules → User Rules:"
  echo
  sed 's/^/    /' "$SBK_RULES_FILE"
  echo
}

verify() {
  json_has_mcp_server "$MCP_JSON" "$SBK_SERVER_NAME"
}

unconfigure() {
  json_remove_mcp_server "$MCP_JSON" "$SBK_SERVER_NAME"
  info "cursor: remove the second-brain block from Settings → Rules → User Rules"
  ok "cursor: MCP entry removed"
}

adapter_main "$@"
