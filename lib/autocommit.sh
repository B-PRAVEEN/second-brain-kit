#!/usr/bin/env bash
# autocommit.sh — install/remove a 30-minute git autocommit timer for the vault.
#   autocommit.sh install <vault>
#   autocommit.sh remove
#   autocommit.sh run <vault>      (what the timer executes)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

LABEL="com.second-brain-kit.autocommit"
CMD="${1:-}"
VAULT="${2:-}"

case "$CMD" in
  run)
    [[ -d "$VAULT/.git" ]] || exit 0
    cd "$VAULT"
    git add -A
    git diff --cached --quiet || git commit -qm "sbk autocommit: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    ;;

  install)
    [[ -n "$VAULT" ]] || die "usage: autocommit.sh install <vault>"
    case "$(detect_os)" in
      macos)
        PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
        mkdir -p "$(dirname "$PLIST")"
        cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array>
    <string>/bin/bash</string>
    <string>$SCRIPT_DIR/autocommit.sh</string>
    <string>run</string>
    <string>$VAULT</string>
  </array>
  <key>StartInterval</key><integer>1800</integer>
  <key>RunAtLoad</key><false/>
</dict></plist>
EOF
        launchctl unload "$PLIST" 2>/dev/null || true
        launchctl load "$PLIST"
        ok "launchd autocommit timer installed (every 30 min)"
        ;;
      linux)
        if have systemctl && systemctl --user show-environment >/dev/null 2>&1; then
          UNIT_DIR="$HOME/.config/systemd/user"
          mkdir -p "$UNIT_DIR"
          cat > "$UNIT_DIR/sbk-autocommit.service" <<EOF
[Unit]
Description=second-brain-kit vault autocommit
[Service]
Type=oneshot
ExecStart=/bin/bash $SCRIPT_DIR/autocommit.sh run $VAULT
EOF
          cat > "$UNIT_DIR/sbk-autocommit.timer" <<EOF
[Unit]
Description=second-brain-kit vault autocommit (every 30 min)
[Timer]
OnBootSec=10min
OnUnitActiveSec=30min
[Install]
WantedBy=timers.target
EOF
          systemctl --user daemon-reload
          systemctl --user enable --now sbk-autocommit.timer
          ok "systemd autocommit timer installed (every 30 min)"
        else
          warn "systemd user session unavailable — add a cron entry instead:"
          info "*/30 * * * * /bin/bash $SCRIPT_DIR/autocommit.sh run $VAULT"
          exit 1
        fi
        ;;
      *) die "unsupported OS" ;;
    esac
    ;;

  remove)
    case "$(detect_os)" in
      macos)
        PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
        launchctl unload "$PLIST" 2>/dev/null || true
        rm -f "$PLIST"
        ok "launchd timer removed"
        ;;
      linux)
        systemctl --user disable --now sbk-autocommit.timer 2>/dev/null || true
        rm -f "$HOME/.config/systemd/user/sbk-autocommit.service" \
              "$HOME/.config/systemd/user/sbk-autocommit.timer"
        systemctl --user daemon-reload 2>/dev/null || true
        ok "systemd timer removed"
        ;;
    esac
    ;;

  *) die "usage: autocommit.sh install <vault> | remove | run <vault>" ;;
esac
