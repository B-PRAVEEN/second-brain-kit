#!/usr/bin/env bash
# Adapter: OpenAI Codex (CLI)
source "$(dirname "${BASH_SOURCE[0]}")/_shared.sh"

CODEX_TOML="$HOME/.codex/config.toml"
GLOBAL_MD="$HOME/.codex/AGENTS.md"
TOML_KEY="mcp_servers.second_brain"

toml_has_server() {
  [[ -f "$CODEX_TOML" ]] && grep -q "^\[$TOML_KEY\]" "$CODEX_TOML"
}

detect() {
  have codex || [[ -d "$HOME/.codex" ]]
}

configure() {
  local vault="$1"
  if have codex && codex mcp add second_brain -- npx -y "$SBK_MCP_PKG" "$vault" 2>/dev/null; then
    ok "codex: registered via 'codex mcp add'"
  elif toml_has_server; then
    skip "codex: [$TOML_KEY] already in config.toml — left untouched"
  else
    mkdir -p "$(dirname "$CODEX_TOML")"
    backup_file "$CODEX_TOML"
    cat >> "$CODEX_TOML" <<EOF

[$TOML_KEY]
command = "npx"
args = ["-y", "$SBK_MCP_PKG", "$vault"]
startup_timeout_sec = 30
tool_timeout_sec = 120
EOF
    ok "codex: [$TOML_KEY] appended to config.toml"
  fi

  ensure_rules_file "$vault"
  backup_file "$GLOBAL_MD"
  upsert_marker_block "$GLOBAL_MD" "$SBK_RULES_FILE"
  ok "codex: agent rules installed in ~/.codex/AGENTS.md (loads in every session)"
}

verify() {
  toml_has_server && grep -qF "$SBK_MARKER_START" "$GLOBAL_MD" 2>/dev/null
}

unconfigure() {
  if have codex; then codex mcp remove second_brain 2>/dev/null || true; fi
  remove_marker_block "$GLOBAL_MD"
  toml_has_server && warn "codex: remove the [$TOML_KEY] block from $CODEX_TOML manually (TOML edits are not automated)"
  ok "codex: unconfigured (rules removed)"
}

adapter_main "$@"
