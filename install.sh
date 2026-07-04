#!/usr/bin/env bash
#
# second-brain-kit installer
#
#   One-liner:  curl -fsSL https://raw.githubusercontent.com/B-PRAVEEN/second-brain-kit/main/install.sh | bash
#   From clone: ./install.sh [flags]
#
# Flags:
#   -y, --yes         non-interactive (accept defaults, configure all detected clients)
#   --vault PATH      vault location            (default: ~/SecondBrain)
#   --git             enable git backup in the vault (init + autocommit timer)
#   --menubar         install the macOS menu-bar plugin (SwiftBar/xbar)
#   --search          reserved: local full-text search MCP (v2, prints roadmap note)
#   --no-clients      create the vault only; skip client configuration
#   -h, --help        this help
#
# The installer is idempotent — safe to re-run at any time.

set -euo pipefail

SBK_REPO_URL="${SBK_REPO_URL:-https://github.com/B-PRAVEEN/second-brain-kit}"
SBK_DEFAULT_VAULT="$HOME/SecondBrain"
SBK_KIT_DIR_DEFAULT="$HOME/.second-brain-kit"

# ---------- self-locate / self-download (curl | bash support) ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd || echo "")"
if [[ -z "$SCRIPT_DIR" || ! -f "$SCRIPT_DIR/lib/common.sh" ]]; then
  echo "Downloading second-brain-kit to $SBK_KIT_DIR_DEFAULT ..."
  if command -v git >/dev/null 2>&1; then
    if [[ -d "$SBK_KIT_DIR_DEFAULT/.git" ]]; then
      git -C "$SBK_KIT_DIR_DEFAULT" pull --ff-only
    else
      git clone --depth 1 "$SBK_REPO_URL" "$SBK_KIT_DIR_DEFAULT"
    fi
  else
    echo "git is required for the one-liner install. Install git, or download the repo manually." >&2
    exit 1
  fi
  exec bash "$SBK_KIT_DIR_DEFAULT/install.sh" "$@"
fi

SBK_KIT_DIR="$SCRIPT_DIR"
# shellcheck source=lib/common.sh
source "$SBK_KIT_DIR/lib/common.sh"
# shellcheck source=lib/json.sh
source "$SBK_KIT_DIR/lib/json.sh"

# ---------- args ----------
SBK_ASSUME_YES=0
SBK_VAULT=""
OPT_GIT=0
OPT_MENUBAR=0
OPT_SEARCH=0
OPT_NO_CLIENTS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes)      SBK_ASSUME_YES=1 ;;
    --vault)       SBK_VAULT="${2:?--vault needs a path}"; shift ;;
    --git)         OPT_GIT=1 ;;
    --menubar)     OPT_MENUBAR=1 ;;
    --search)      OPT_SEARCH=1 ;;
    --no-clients)  OPT_NO_CLIENTS=1 ;;
    -h|--help)     grep '^#' "$0" | head -20 | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)             die "unknown flag: $1 (see --help)" ;;
  esac
  shift
done
export SBK_ASSUME_YES

title "second-brain-kit v$SBK_VERSION"

# ---------- preflight ----------
title "Preflight"
OS="$(detect_os)"
[[ "$OS" == "unsupported" ]] && die "unsupported OS ($(uname -s)) — macOS and Linux only (Windows: use WSL)"
ok "OS: $OS"
if have node; then ok "node $(node -v)"; else warn "node not found — the MCP server needs Node.js (https://nodejs.org). Install it before using agents."; fi
if have npx; then ok "npx present"; else warn "npx not found (ships with Node.js)"; fi
if have jq; then ok "jq present"; else info "jq not found — will fall back to node for JSON edits"; fi

# ---------- vault ----------
title "Vault"
if [[ -z "$SBK_VAULT" ]]; then
  SBK_VAULT="$(ask_value "Vault location" "$SBK_DEFAULT_VAULT")"
fi
SBK_VAULT="${SBK_VAULT/#\~/$HOME}"
export SBK_VAULT
mkdir -p "$SBK_VAULT"
ok "vault: $SBK_VAULT"

# Seed templates (never overwrite user content).
seed() { # seed <template-rel> <vault-rel>
  local dst="$SBK_VAULT/$2"
  if [[ -e "$dst" ]]; then
    skip "$2 exists — left untouched"
  else
    render_template "$SBK_KIT_DIR/templates/$1" "$dst"
    ok "created $2"
  fi
}

seed "index.md"              "index.md"
seed "AGENTS.md"             "AGENTS.md"
seed "log.md"                "log.md"
seed "stignore.template"     ".stignore"
seed "Reference/index.md"    "Reference/index.md"
seed "Projects/index.md"     "Projects/index.md"
seed "Sessions/index.md"     "Sessions/index.md"
seed "Inbox/index.md"        "Inbox/index.md"

for d in Claude Codex Kimi Gemini Cursor Windsurf Other; do
  mkdir -p "$SBK_VAULT/Sessions/$d"
done
ok "Sessions/{Claude,Codex,Kimi,Gemini,Cursor,Windsurf,Other} ready"

# CLAUDE.md symlink for agents that read it when launched inside the vault.
if [[ -L "$SBK_VAULT/CLAUDE.md" || ! -e "$SBK_VAULT/CLAUDE.md" ]]; then
  ln -sf AGENTS.md "$SBK_VAULT/CLAUDE.md"
  ok "CLAUDE.md → AGENTS.md symlink"
else
  skip "CLAUDE.md exists as a real file — left untouched"
fi

# Render the global agent-rules block once; adapters reuse it.
SBK_RULES_FILE="$(mktemp)"
export SBK_RULES_FILE
render_template "$SBK_KIT_DIR/templates/agent-rules.md" "$SBK_RULES_FILE"

# ---------- clients ----------
CONFIGURED=()
SKIPPED=()
if [[ "$OPT_NO_CLIENTS" == "1" ]]; then
  title "Clients"
  skip "skipped (--no-clients)"
else
  title "Clients"
  for adapter in "$SBK_KIT_DIR"/lib/adapters/*.sh; do
    name="$(basename "$adapter" .sh)"
    [[ "$name" == _* || "$name" == "generic" ]] && continue
    if bash "$adapter" detect; then
      if ask "Configure $name?"; then
        if bash "$adapter" configure "$SBK_VAULT"; then
          CONFIGURED+=("$name")
        else
          warn "$name configuration reported a problem — see above"
          SKIPPED+=("$name")
        fi
      else
        SKIPPED+=("$name")
      fi
    fi
  done
  if [[ ${#CONFIGURED[@]} -eq 0 ]]; then
    info "no clients configured — universal MCP block for any client:"
    echo
    print_mcp_json_block "$SBK_VAULT" | sed 's/^/    /'
  fi
fi

# ---------- git backup (opt-in) ----------
title "Git backup"
if [[ "$OPT_GIT" == "1" ]] || { [[ "$SBK_ASSUME_YES" != "1" ]] && ask "Enable git backup for the vault (recommended — sync is not backup)?"; }; then
  if have git; then
    if [[ ! -d "$SBK_VAULT/.git" ]]; then
      git -C "$SBK_VAULT" init -q
      # repo-local identity so commits work even without global git config
      git -C "$SBK_VAULT" config user.name  >/dev/null 2>&1 \
        || git -C "$SBK_VAULT" config user.name "second-brain-kit"
      git -C "$SBK_VAULT" config user.email >/dev/null 2>&1 \
        || git -C "$SBK_VAULT" config user.email "sbk@localhost"
      printf '.obsidian/workspace*\n.DS_Store\n*.bak.*\n.sbk-graph.html\n' > "$SBK_VAULT/.gitignore"
      git -C "$SBK_VAULT" add -A
      git -C "$SBK_VAULT" commit -qm "second-brain-kit: initial vault" || true
      ok "git repository initialized"
    else
      skip "already a git repository"
    fi
    bash "$SBK_KIT_DIR/lib/autocommit.sh" install "$SBK_VAULT" || warn "autocommit timer not installed — commit manually or re-run: sbk git-timer"
  else
    warn "git not found — skipping"
  fi
else
  skip "disabled (re-run with --git to enable)"
fi

# ---------- menu bar (opt-in, macOS) ----------
title "Menu bar (macOS)"
if [[ "$OS" == "macos" ]]; then
  if [[ "$OPT_MENUBAR" == "1" ]] || { [[ "$SBK_ASSUME_YES" != "1" ]] && ask "Install the SwiftBar/xbar menu-bar plugin (vault status + quick capture)?"; }; then
    bash "$SBK_KIT_DIR/lib/menubar.sh" install "$SBK_VAULT" || warn "menu-bar plugin not installed — run later: sbk menubar"
  else
    skip "disabled (re-run with --menubar, or later: sbk menubar)"
  fi
else
  skip "macOS-only — skipped"
fi

# ---------- search (v2 stub) ----------
if [[ "$OPT_SEARCH" == "1" ]]; then
  title "Search"
  info "--search (local full-text search MCP) is on the roadmap and not yet shipped."
  info "Tier-2 recall (index navigation) is active via the agent rules."
fi

# ---------- sbk CLI ----------
title "sbk CLI"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
ln -sf "$SBK_KIT_DIR/bin/sbk" "$BIN_DIR/sbk"
ok "sbk → $BIN_DIR/sbk"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    # ~/.local/bin is not on PATH (default on macOS zsh) — offer to fix the rc file.
    case "$(basename "${SHELL:-/bin/sh}")" in
      zsh)  RC_FILE="$HOME/.zshrc" ;;
      bash) RC_FILE="$HOME/.bashrc" ;;
      *)    RC_FILE="" ;;
    esac
    PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
    if [[ -n "$RC_FILE" ]] && ask "Add ~/.local/bin to PATH in ${RC_FILE/#$HOME/~}?"; then
      if ! grep -qsF "$PATH_LINE" "$RC_FILE"; then
        printf '\n# second-brain-kit\n%s\n' "$PATH_LINE" >> "$RC_FILE"
      fi
      ok "PATH updated in ${RC_FILE/#$HOME/~} — restart your terminal (or: source ${RC_FILE/#$HOME/~})"
    else
      warn "$BIN_DIR is not on your PATH — add manually:  $PATH_LINE"
    fi
    ;;
esac

save_kit_config
ok "config saved: $SBK_CONFIG_FILE"
rm -f "$SBK_RULES_FILE"

# ---------- summary ----------
title "Done"
[[ ${#CONFIGURED[@]} -gt 0 ]] && ok "configured: ${CONFIGURED[*]}"
[[ ${#SKIPPED[@]}    -gt 0 ]] && skip "skipped: ${SKIPPED[*]}"
cat <<EOF

  Next steps:
  1. RESTART every configured client — MCP servers load at startup.
  2. Claude Desktop / GUI clients: paste the printed instructions block
     into your Project instructions (re-print any time: sbk print-rules).
  3. Verify everything:            sbk doctor
  4. In any agent, try:            "save this session"
     → a note should land in $SBK_VAULT/Sessions/<Client>/
  5. Browse your brain as a graph: sbk visualize
  6. macOS: menu-bar companion:    sbk menubar
     (vault status, recent sessions, quick capture — needs SwiftBar or xbar)

EOF
