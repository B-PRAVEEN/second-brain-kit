#!/usr/bin/env bash
# Adapter: generic — for any MCP-capable client not covered by a dedicated adapter.
# Never auto-detected; run explicitly:  sbk add generic
source "$(dirname "${BASH_SOURCE[0]}")/_shared.sh"

detect() { return 1; }

configure() {
  local vault="$1"
  info "Universal MCP config (JSON clients) — paste into your client's MCP settings:"
  echo
  print_mcp_json_block "$vault" | sed 's/^/    /'
  echo
  info "Command form (non-JSON clients):"
  info "  npx -y $SBK_MCP_PKG \"$vault\""
  echo
  ensure_rules_file "$vault"
  info "Agent rules — put this in your client's global/system instructions:"
  echo
  sed 's/^/    /' "$SBK_RULES_FILE"
}

verify() {
  info "generic: nothing to verify automatically — check that your client lists"
  info "read_file / write_file tools from a server named '$SBK_SERVER_NAME'."
  return 0
}

unconfigure() {
  info "generic: remove the '$SBK_SERVER_NAME' entry from your client's MCP settings."
}

adapter_main "$@"
