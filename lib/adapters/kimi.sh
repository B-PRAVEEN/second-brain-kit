#!/usr/bin/env bash
# Adapter: Kimi Code (CLI)
source "$(dirname "${BASH_SOURCE[0]}")/_shared.sh"

SKILL_DST="$HOME/.kimi-code/commands/obsidian-save/SKILL.md"

detect() {
  have kimi || [[ -d "$HOME/.kimi-code" ]]
}

configure() {
  local vault="$1"
  SBK_VAULT="$vault" render_template \
    "$SBK_KIT_DIR/templates/skills/obsidian-save/SKILL.md" "$SKILL_DST"
  ok "kimi: obsidian-save skill installed at ~/.kimi-code/commands/obsidian-save/"
  info "kimi: register the MCP server with Kimi's interactive helper:"
  info "  kimi /mcp-config add global $SBK_SERVER_NAME $SBK_MCP_PKG \"$vault\""
}

verify() {
  [[ -f "$SKILL_DST" ]]
}

unconfigure() {
  rm -rf "$HOME/.kimi-code/commands/obsidian-save"
  info "kimi: remove the MCP entry with: kimi /mcp-config remove global $SBK_SERVER_NAME"
  ok "kimi: skill removed"
}

adapter_main "$@"
