#!/usr/bin/env bash
# _shared.sh — adapter boilerplate. Every adapter sources this, defines
# detect / configure / verify / unconfigure functions, then calls adapter_main.
#
# Adapter contract (see CONTRIBUTING.md):
#   detect            exit 0 if the client is installed on this machine
#   configure <vault> register the second-brain MCP server + agent rules
#   verify    <vault> exit 0 if fully configured
#   unconfigure       remove what configure added (best-effort)

set -euo pipefail

ADAPTER_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SBK_KIT_DIR="${SBK_KIT_DIR:-$(cd "$ADAPTER_LIB_DIR/.." && pwd)}"
# shellcheck source=../common.sh
source "$ADAPTER_LIB_DIR/common.sh"
# shellcheck source=../json.sh
source "$ADAPTER_LIB_DIR/json.sh"

# ensure_rules_file <vault> — guarantees $SBK_RULES_FILE points at the rendered
# global agent-rules block (installer pre-renders it; standalone runs render here).
ensure_rules_file() {
  if [[ -z "${SBK_RULES_FILE:-}" || ! -s "${SBK_RULES_FILE:-/nonexistent}" ]]; then
    SBK_RULES_FILE="$(mktemp)"
    SBK_VAULT="$1" render_template "$SBK_KIT_DIR/templates/agent-rules.md" "$SBK_RULES_FILE"
  fi
}

adapter_main() {
  local cmd="${1:-}"
  shift || true
  case "$cmd" in
    detect)      detect ;;
    configure)   configure "${1:?vault path required}" ;;
    verify)      verify "${1:?vault path required}" ;;
    unconfigure) unconfigure ;;
    *) die "usage: $(basename "$0") detect | configure <vault> | verify <vault> | unconfigure" ;;
  esac
}
