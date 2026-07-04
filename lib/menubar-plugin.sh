#!/usr/bin/env bash
# second-brain.5m.sh — SwiftBar/xbar menu-bar plugin for second-brain-kit.
# Installed by `sbk menubar` (source: lib/menubar-plugin.sh in the kit repo).
#
# <xbar.title>Second Brain</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>second-brain-kit</xbar.author>
# <xbar.desc>Vault status, recent sessions, and quick capture for your second brain.</xbar.desc>
# <xbar.dependencies>bash,git</xbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
set -euo pipefail

# SwiftBar/xbar run plugins with a minimal PATH.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/second-brain-kit/config"
if [[ ! -f "$CONFIG" ]]; then
  printf '🧠 ⚠️\n---\nsecond-brain-kit is not configured — run install.sh\n'
  exit 0
fi
# shellcheck disable=SC1090
source "$CONFIG"
SBK_VAULT="${SBK_VAULT:-}"
SBK_KIT_DIR="${SBK_KIT_DIR:-}"
SBK_BIN="$SBK_KIT_DIR/bin/sbk"
SELF="${SWIFTBAR_PLUGIN_PATH:-$0}"

if [[ -z "$SBK_VAULT" || ! -d "$SBK_VAULT" ]]; then
  printf '🧠 ⚠️\n---\nvault not found — re-run install.sh\n'
  exit 0
fi

# ---- action mode (menu items re-invoke this script) ----
if [[ "${1:-}" == "capture" ]]; then
  # Static AppleScript literal — user text travels OUT via stdout only,
  # then into sbk as a quoted argv element. Never interpolate into the script.
  txt="$(osascript \
    -e 'try' \
    -e 'display dialog "Quick capture → Inbox" default answer "" with title "Second Brain" buttons {"Cancel","Save"} default button "Save"' \
    -e 'text returned of result' \
    -e 'end try' 2>/dev/null || true)"
  if [[ -n "$txt" && -x "$SBK_BIN" ]]; then
    "$SBK_BIN" capture "$txt" >/dev/null 2>&1 || true
  fi
  exit 0
fi

# ---- render mode: gather stats (each guarded — never blank the menu bar) ----
note_count="$(find "$SBK_VAULT" -type f -name '*.md' -not -path '*/.*' 2>/dev/null | wc -l | tr -d ' ')" || note_count="?"
sess_count="$(find "$SBK_VAULT/Sessions" -type f -name '*.md' ! -name 'index.md' 2>/dev/null | wc -l | tr -d ' ')" || sess_count="0"

git_enabled=0 dirty=0 last_ac=""
if [[ -d "$SBK_VAULT/.git" ]]; then
  git_enabled=1
  dirty="$(git -C "$SBK_VAULT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')" || dirty=0
  [[ -n "$dirty" ]] || dirty=0
  last_ac="$(git -C "$SBK_VAULT" log -1 --grep='^sbk autocommit:' --format=%cr 2>/dev/null || true)"
fi

# ---- menu ----
if [[ "$git_enabled" == "1" && "$dirty" != "0" ]]; then
  printf '🧠 %s ●\n' "$note_count"
else
  printf '🧠 %s\n' "$note_count"
fi
echo "---"
vault_disp="$SBK_VAULT"
if [[ "$vault_disp" == "$HOME"* ]]; then vault_disp="~${vault_disp#"$HOME"}"; fi
printf 'Second Brain — %s | size=12\n' "$vault_disp"
if [[ "$git_enabled" == "1" ]]; then
  if [[ "$dirty" == "0" ]]; then
    printf 'Git: ✓ clean | color=#81c995\n'
  else
    printf 'Git: ● %s uncommitted | color=#fdd663\n' "$dirty"
  fi
  if [[ -n "$last_ac" ]]; then
    printf 'Last autocommit: %s\n' "$last_ac"
  else
    printf 'Last autocommit: — (none yet)\n'
  fi
else
  printf 'Git backup not enabled | color=#9aa0ae\n'
fi
printf '%s notes · %s session logs\n' "$note_count" "$sess_count"
echo "---"
echo "Recent sessions"
found=0
while IFS=$'\t' read -r base path; do
  [[ -n "$base" ]] || continue
  found=1
  client="${path#"$SBK_VAULT/Sessions/"}"
  client="${client%%/*}"
  label="$client · ${base%.md}"
  label="${label//|/·}"   # "|" is the SwiftBar field separator
  printf -- '-- %s | bash=/usr/bin/open param1="%s" terminal=false\n' "$label" "$path"
done < <(
  { while IFS= read -r -d '' f; do
      printf '%s\t%s\n' "$(basename "$f")" "$f"
    done < <(find "$SBK_VAULT/Sessions" -type f -name '*.md' ! -name 'index.md' -print0 2>/dev/null)
  } | sort -r | head -7
)
[[ "$found" == "1" ]] || echo "-- (none yet)"
echo "---"
printf '✍️ Quick capture… | bash="%s" param1=capture terminal=false refresh=true\n' "$SELF"
if [[ -x "$SBK_BIN" ]]; then
  printf '🕸 Open graph view | bash="%s" param1=visualize terminal=false\n' "$SBK_BIN"
fi
echo "---"
printf '📂 Open vault in Finder | bash=/usr/bin/open param1="%s" terminal=false\n' "$SBK_VAULT"
printf '📝 Open vault home note | bash=/usr/bin/open param1="%s/index.md" terminal=false\n' "$SBK_VAULT"
if [[ -x "$SBK_BIN" ]]; then
  printf '🩺 Run doctor | bash="%s" param1=doctor terminal=true\n' "$SBK_BIN"
fi
echo "---"
echo "🔄 Refresh | refresh=true"
