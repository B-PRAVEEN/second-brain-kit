#!/usr/bin/env bash
# common.sh — shared helpers for second-brain-kit
# Sourced by install.sh, bin/sbk, and every adapter.

# shellcheck disable=SC2034
SBK_VERSION="0.1.0"
SBK_SERVER_NAME="second-brain"
SBK_MCP_PKG="@modelcontextprotocol/server-filesystem"
SBK_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/second-brain-kit"
SBK_CONFIG_FILE="$SBK_CONFIG_DIR/config"
SBK_MARKER_START="<!-- second-brain-kit:start -->"
SBK_MARKER_END="<!-- second-brain-kit:end -->"

# ---------- output ----------
if [[ -t 1 ]]; then
  _C_GREEN=$'\033[32m'; _C_YELLOW=$'\033[33m'; _C_RED=$'\033[31m'
  _C_CYAN=$'\033[36m'; _C_BOLD=$'\033[1m'; _C_RESET=$'\033[0m'
else
  _C_GREEN=""; _C_YELLOW=""; _C_RED=""; _C_CYAN=""; _C_BOLD=""; _C_RESET=""
fi

ok()    { printf '  %s✓%s %s\n' "$_C_GREEN"  "$_C_RESET" "$1"; }
warn()  { printf '  %s!%s %s\n' "$_C_YELLOW" "$_C_RESET" "$1"; }
fail()  { printf '  %s✗%s %s\n' "$_C_RED"    "$_C_RESET" "$1"; }
info()  { printf '  %si%s %s\n' "$_C_CYAN"   "$_C_RESET" "$1"; }
skip()  { printf '  %s–%s %s\n' "$_C_YELLOW" "$_C_RESET" "$1"; }
title() { printf '\n%s%s%s\n' "$_C_BOLD" "$1" "$_C_RESET"; }
die()   { fail "$1"; exit 1; }

# ---------- prompts ----------
# ask "question" -> 0 for yes. Honors SBK_ASSUME_YES=1.
ask() {
  [[ "${SBK_ASSUME_YES:-0}" == "1" ]] && return 0
  local a
  read -r -p "  ? $1 [y/N] " a </dev/tty || return 1
  [[ "$a" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# ask_value "prompt" "default" -> echoes answer
ask_value() {
  local a
  if [[ "${SBK_ASSUME_YES:-0}" == "1" ]]; then
    echo "$2"; return 0
  fi
  read -r -p "  ? $1 [$2] " a </dev/tty || true
  echo "${a:-$2}"
}

# ---------- environment ----------
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)  echo "linux" ;;
    *)      echo "unsupported" ;;
  esac
}

have() { command -v "$1" >/dev/null 2>&1; }

# ---------- files ----------
# backup_file <path> — timestamped copy next to original; no-op if missing.
backup_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  local b
  b="$f.bak.$(date +%Y%m%d%H%M%S)"
  cp -p "$f" "$b"
  info "backup: $b"
}

# render_template <src> <dst> — substitutes {{VAULT_PATH}}, {{DATE}}, {{TIMESTAMP}}.
render_template() {
  local src="$1" dst="$2"
  local date_now ts_now
  date_now="$(date +%Y-%m-%d)"
  ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  mkdir -p "$(dirname "$dst")"
  sed -e "s|{{VAULT_PATH}}|$SBK_VAULT|g" \
      -e "s|{{DATE}}|$date_now|g" \
      -e "s|{{TIMESTAMP}}|$ts_now|g" \
      "$src" > "$dst"
}

# upsert_marker_block <file> <content-file>
# Idempotently inserts/replaces the kit-managed block between markers.
upsert_marker_block() {
  local file="$1" content_file="$2" tmp
  mkdir -p "$(dirname "$file")"
  touch "$file"
  tmp="$(mktemp)"
  awk -v start="$SBK_MARKER_START" -v end="$SBK_MARKER_END" '
    $0 == start { inblock = 1; next }
    $0 == end   { inblock = 0; next }
    !inblock    { print }
  ' "$file" > "$tmp"
  {
    cat "$tmp"
    echo ""
    echo "$SBK_MARKER_START"
    cat "$content_file"
    echo "$SBK_MARKER_END"
  } > "$file"
  rm -f "$tmp"
}

# remove_marker_block <file>
remove_marker_block() {
  local file="$1" tmp
  [[ -f "$file" ]] || return 0
  tmp="$(mktemp)"
  awk -v start="$SBK_MARKER_START" -v end="$SBK_MARKER_END" '
    $0 == start { inblock = 1; next }
    $0 == end   { inblock = 0; next }
    !inblock    { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

# ---------- kit config ----------
save_kit_config() {
  mkdir -p "$SBK_CONFIG_DIR"
  {
    echo "# second-brain-kit — generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "SBK_VAULT=\"$SBK_VAULT\""
    echo "SBK_KIT_DIR=\"$SBK_KIT_DIR\""
  } > "$SBK_CONFIG_FILE"
}

load_kit_config() {
  # shellcheck disable=SC1090
  [[ -f "$SBK_CONFIG_FILE" ]] && source "$SBK_CONFIG_FILE"
  return 0
}
