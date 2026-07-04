#!/usr/bin/env bash
# menubar.sh — install/remove the SwiftBar/xbar menu-bar plugin (macOS only).
#   menubar.sh install <vault>
#   menubar.sh remove
#   menubar.sh status              (prints installed plugin path, exit 1 if absent)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

PLUGIN_NAME="second-brain.5m.sh"
XBAR_PLUGIN_DIR="$HOME/Library/Application Support/xbar/plugins"

CMD="${1:-}"
VAULT="${2:-}"

# Echo the plugin directory of the installed menu-bar host.
# Exit codes: 0 found, 1 no host installed, 2 SwiftBar present but never launched.
detect_plugin_dir() {
  local dir
  dir="$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)"
  if [[ -n "$dir" ]]; then
    printf '%s\n' "${dir/#\~/$HOME}"
    return 0
  fi
  if [[ -d "/Applications/SwiftBar.app" || -d "$HOME/Applications/SwiftBar.app" ]]; then
    return 2
  fi
  if [[ -d "/Applications/xbar.app" || -d "$HOME/Applications/xbar.app" ]]; then
    printf '%s\n' "$XBAR_PLUGIN_DIR"
    return 0
  fi
  return 1
}

case "$CMD" in
  install)
    [[ -n "$VAULT" ]] || die "usage: menubar.sh install <vault>"
    [[ "$(detect_os)" == "macos" ]] || die "the menu-bar plugin is macOS-only (SwiftBar/xbar)"
    rc=0
    DIR="$(detect_plugin_dir)" || rc=$?
    case "$rc" in
      0) ;;
      2) fail "SwiftBar is installed but has no plugin folder yet"
         info "launch SwiftBar once, choose a plugin folder, then re-run: sbk menubar"
         exit 1 ;;
      *) fail "no menu-bar host (SwiftBar or xbar) found"
         info "install one:  brew install swiftbar   (or: brew install xbar)"
         exit 1 ;;
    esac
    mkdir -p "$DIR"
    cp "$SCRIPT_DIR/menubar-plugin.sh" "$DIR/$PLUGIN_NAME"
    chmod +x "$DIR/$PLUGIN_NAME"
    open -g "swiftbar://refreshallplugins" 2>/dev/null || true
    ok "menu-bar plugin installed: $DIR/$PLUGIN_NAME"
    ;;

  remove)
    [[ "$(detect_os)" == "macos" ]] || exit 0
    removed=0
    for d in "$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)" "$XBAR_PLUGIN_DIR"; do
      [[ -n "$d" ]] || continue
      d="${d/#\~/$HOME}"
      if [[ -f "$d/$PLUGIN_NAME" ]]; then
        rm -f "$d/$PLUGIN_NAME"
        removed=1
      fi
    done
    if [[ "$removed" == "1" ]]; then ok "menu-bar plugin removed"
    else skip "menu-bar plugin not installed"; fi
    ;;

  status)
    [[ "$(detect_os)" == "macos" ]] || exit 1
    for d in "$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)" "$XBAR_PLUGIN_DIR"; do
      [[ -n "$d" ]] || continue
      d="${d/#\~/$HOME}"
      if [[ -f "$d/$PLUGIN_NAME" ]]; then
        printf '%s\n' "$d/$PLUGIN_NAME"
        exit 0
      fi
    done
    exit 1
    ;;

  *) die "usage: menubar.sh install <vault> | remove | status" ;;
esac
