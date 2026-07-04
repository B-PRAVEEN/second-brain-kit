#!/usr/bin/env bash
# json.sh — merge-safe JSON config editing for second-brain-kit.
# Uses jq when available, falls back to node. Never edits without a backup.
# Requires common.sh to be sourced first.

# json_add_mcp_server <config_file> <server_name> <vault_path>
# Merges {"mcpServers": {<name>: {command: npx, args: [-y, PKG, VAULT]}}}
# into the file, creating it (and parent dirs) if missing. Preserves all
# other keys. Returns non-zero on parse failure (file left untouched).
json_add_mcp_server() {
  local file="$1" name="$2" vault="$3"
  mkdir -p "$(dirname "$file")"
  [[ -s "$file" ]] || echo '{}' > "$file"
  backup_file "$file"

  if have jq; then
    local tmp
    tmp="$(mktemp)"
    if jq --arg name "$name" --arg pkg "$SBK_MCP_PKG" --arg vault "$vault" \
      '.mcpServers = (.mcpServers // {}) |
       .mcpServers[$name] = {command: "npx", args: ["-y", $pkg, $vault]}' \
      "$file" > "$tmp" 2>/dev/null; then
      mv "$tmp" "$file"
      return 0
    fi
    rm -f "$tmp"
    fail "jq could not parse $file — is it valid JSON?"
    return 1
  fi

  if have node; then
    SBK_JSON_FILE="$file" SBK_JSON_NAME="$name" SBK_JSON_PKG="$SBK_MCP_PKG" \
    SBK_JSON_VAULT="$vault" node -e '
      const fs = require("fs");
      const f = process.env.SBK_JSON_FILE;
      let cfg = {};
      const raw = fs.readFileSync(f, "utf8").trim();
      if (raw) cfg = JSON.parse(raw);
      cfg.mcpServers = cfg.mcpServers || {};
      cfg.mcpServers[process.env.SBK_JSON_NAME] = {
        command: "npx",
        args: ["-y", process.env.SBK_JSON_PKG, process.env.SBK_JSON_VAULT],
      };
      fs.writeFileSync(f, JSON.stringify(cfg, null, 2) + "\n");
    ' && return 0
    fail "node could not parse $file — is it valid JSON?"
    return 1
  fi

  fail "need jq or node to edit $file — install one, or paste the block manually (sbk print-config)"
  return 1
}

# json_has_mcp_server <config_file> <server_name> — 0 if present.
json_has_mcp_server() {
  local file="$1" name="$2"
  [[ -f "$file" ]] || return 1
  if have jq; then
    jq -e --arg name "$name" '.mcpServers[$name]? // empty | length > 0' \
      "$file" >/dev/null 2>&1
  else
    grep -q "\"$name\"" "$file"
  fi
}

# json_remove_mcp_server <config_file> <server_name>
json_remove_mcp_server() {
  local file="$1" name="$2"
  [[ -f "$file" ]] || return 0
  backup_file "$file"
  if have jq; then
    local tmp
    tmp="$(mktemp)"
    jq --arg name "$name" 'if .mcpServers then del(.mcpServers[$name]) else . end' \
      "$file" > "$tmp" && mv "$tmp" "$file"
  elif have node; then
    SBK_JSON_FILE="$file" SBK_JSON_NAME="$name" node -e '
      const fs = require("fs");
      const f = process.env.SBK_JSON_FILE;
      const cfg = JSON.parse(fs.readFileSync(f, "utf8"));
      if (cfg.mcpServers) delete cfg.mcpServers[process.env.SBK_JSON_NAME];
      fs.writeFileSync(f, JSON.stringify(cfg, null, 2) + "\n");
    '
  fi
}

# print_mcp_json_block <vault> — the universal JSON block for manual paste.
print_mcp_json_block() {
  cat <<EOF
{
  "mcpServers": {
    "$SBK_SERVER_NAME": {
      "command": "npx",
      "args": ["-y", "$SBK_MCP_PKG", "$1"]
    }
  }
}
EOF
}
