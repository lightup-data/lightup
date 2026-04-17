#!/usr/bin/env bash
# Lightup Claude Code Plugin — MCP connection script.
#
# Discovers lightup-api-credential.json, parses credentials, infers the MCP
# server URL, and starts an mcp-remote bridge (STDIO → SSE).
#
# Overrides:
#   LIGHTUP_CREDENTIAL_FILE  — path to credential JSON (skips auto-discovery)
#   LIGHTUP_MCP_SERVER       — full MCP base URL (skips URL inference)
#
# All diagnostic output goes to stderr — stdout is reserved for MCP protocol.

set -euo pipefail

err() { echo "[lightup-plugin] ERROR: $*" >&2; }
info() { echo "[lightup-plugin] $*" >&2; }

# ---------------------------------------------------------------------------
# JSON parser — jq preferred, python3 fallback (same as setup.sh)
# ---------------------------------------------------------------------------
json_read() {
    local file="$1" expr="$2"
    if command -v jq &>/dev/null; then
        jq -r "$expr" "$file"
    elif command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('$file') as f:
    data = json.load(f)
expr = '''$expr'''
parts = expr.split('//')
path = parts[0].strip()
default = parts[1].strip().strip('\"') if len(parts) > 1 else ''
obj = data
for key in path.strip('.').split('.'):
    if not key:
        continue
    if isinstance(obj, dict):
        obj = obj.get(key)
    else:
        obj = None
    if obj is None:
        break
result = obj if obj is not None else default
if isinstance(result, (int, float)):
    print(int(result) if isinstance(result, int) or result == int(result) else result)
else:
    print(result if result else '')
"
    else
        err "Neither jq nor python3 found."
        err "Install one:  brew install jq  (macOS)  |  sudo apt install jq  (Linux)"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Credential file discovery — same search order as setup.sh
# ---------------------------------------------------------------------------
find_credential_file() {
    local search_paths=("$HOME/Downloads" "$HOME/Desktop" "$HOME" ".")
    for dir in "${search_paths[@]}"; do
        local matches
        matches=$(find "$dir" -maxdepth 1 -name "lightup-api-credential*.json" -type f -print0 2>/dev/null \
                  | xargs -0 ls -t 2>/dev/null || true)
        if [[ -n "$matches" ]]; then
            echo "$matches" | head -1
            return 0
        fi
    done
    return 1
}

# ---------------------------------------------------------------------------
# Infer MCP server URL from host — same logic as setup.sh
# app.X.lightup.ai  →  https://mcp.X.lightup.ai:8765
# ---------------------------------------------------------------------------
infer_mcp_server() {
    local host="$1"
    local hostname="${host#https://}"
    hostname="${hostname#http://}"
    hostname="${hostname%/}"
    local mcp_host
    if [[ "$hostname" == app.* ]]; then
        mcp_host="mcp.${hostname#app.}"
    else
        mcp_host="mcp.${hostname}"
    fi
    echo "https://${mcp_host}:8765"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
CRED_FILE="${LIGHTUP_CREDENTIAL_FILE:-}"

if [[ -z "$CRED_FILE" ]]; then
    if ! CRED_FILE=$(find_credential_file); then
        err "No lightup-api-credential.json found in ~/Downloads, ~/Desktop, or ~."
        err ""
        err "Fix options:"
        err "  1. Download the file: Lightup UI → Profile → API Credentials → Download"
        err "  2. Set env var:       export LIGHTUP_CREDENTIAL_FILE=/path/to/file"
        exit 1
    fi
fi

if [[ ! -f "$CRED_FILE" ]]; then
    err "Credential file not found: $CRED_FILE"
    exit 1
fi

HOST=$(json_read "$CRED_FILE" '.data.server // empty')
TOKEN=$(json_read "$CRED_FILE" '.data.refresh // empty')

if [[ -z "$HOST" || -z "$TOKEN" ]]; then
    err "Could not parse credentials from: $CRED_FILE"
    err "Expected format: { \"data\": { \"server\": \"https://...\", \"refresh\": \"eyJ...\" } }"
    exit 1
fi

MCP_SERVER="${LIGHTUP_MCP_SERVER:-$(infer_mcp_server "$HOST")}"
SSE_URL="${MCP_SERVER}/sse?host=${HOST}&refresh_token=${TOKEN}"

info "Connecting to ${MCP_SERVER}"

exec npx --yes --quiet @modelcontextprotocol/mcp-remote "$SSE_URL" 2>/dev/null
