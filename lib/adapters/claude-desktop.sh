#!/usr/bin/env bash
# Adapter: Claude Desktop (GUI app, incl. Cowork)
source "$(dirname "${BASH_SOURCE[0]}")/_shared.sh"

config_path() {
  case "$(detect_os)" in
    macos) echo "$HOME/Library/Application Support/Claude/claude_desktop_config.json" ;;
    linux) echo "$HOME/.config/Claude/claude_desktop_config.json" ;;
  esac
}

detect() {
  local f; f="$(config_path)"
  [[ -d "$(dirname "$f")" ]]
}

configure() {
  local vault="$1" f; f="$(config_path)"
  json_add_mcp_server "$f" "$SBK_SERVER_NAME" "$vault" || return 1
  ok "claude-desktop: MCP server added to $(basename "$f")"
  info "claude-desktop: no global rules file exists — paste the block below into"
  info "your Project instructions (re-print any time with: sbk print-rules):"
  echo
  SBK_VAULT="$vault" render_template \
    "$SBK_KIT_DIR/templates/claude-desktop-instructions.md" /dev/stdout | sed 's/^/    /'
  echo
  warn "restart Claude Desktop to load the MCP server"
}

verify() {
  json_has_mcp_server "$(config_path)" "$SBK_SERVER_NAME"
}

unconfigure() {
  json_remove_mcp_server "$(config_path)" "$SBK_SERVER_NAME"
  ok "claude-desktop: MCP server entry removed"
}

adapter_main "$@"
