#!/usr/bin/env bash
# Adapter: Gemini CLI
source "$(dirname "${BASH_SOURCE[0]}")/_shared.sh"

SETTINGS="$HOME/.gemini/settings.json"
GLOBAL_MD="$HOME/.gemini/GEMINI.md"

detect() {
  have gemini || [[ -d "$HOME/.gemini" ]]
}

configure() {
  local vault="$1"
  json_add_mcp_server "$SETTINGS" "$SBK_SERVER_NAME" "$vault" || return 1
  ok "gemini-cli: MCP server added to ~/.gemini/settings.json"

  ensure_rules_file "$vault"
  backup_file "$GLOBAL_MD"
  upsert_marker_block "$GLOBAL_MD" "$SBK_RULES_FILE"
  ok "gemini-cli: agent rules installed in ~/.gemini/GEMINI.md"
}

verify() {
  json_has_mcp_server "$SETTINGS" "$SBK_SERVER_NAME" \
    && grep -qF "$SBK_MARKER_START" "$GLOBAL_MD" 2>/dev/null
}

unconfigure() {
  json_remove_mcp_server "$SETTINGS" "$SBK_SERVER_NAME"
  remove_marker_block "$GLOBAL_MD"
  ok "gemini-cli: unconfigured"
}

adapter_main "$@"
