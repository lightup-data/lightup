#!/usr/bin/env bash
# =============================================================================
# Lightup MCP Setup Script
# Extracts host and refresh_token from a Lightup API credential JSON file
# and registers the remote MCP server with Gemini CLI.
# =============================================================================
set -euo pipefail

# ----- Configuration --------------------------------------------------------
GEMINI_BIN=""  # resolved in check_prerequisites
MCP_PORT="${LIGHTUP_MCP_PORT:-}"
MCP_NAME="lightup"
SCOPE="-s user"

# ----- Colors ---------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}[INFO]${NC}  $*" >&2; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*" >&2; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*" >&2; }
err()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ----- JSON parser ----------------------------------------------------------
# Uses jq if available, falls back to python3 (no extra dependencies).
json_read() {
    # Usage: json_read <file> <jq_expression>
    # Examples:
    #   json_read cred.json '.data.server'
    #   json_read cred.json '.data.expiredTs // 0'
    local file="$1" expr="$2"

    if command -v jq &>/dev/null; then
        jq -r "$expr" "$file"
    elif command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('$file') as f:
    data = json.load(f)
# Navigate dot path (supports simple .a.b.c and // default)
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
        err "Neither jq nor python3 found. Install one of them:"
        echo "  jq:      brew install jq  (macOS)  |  sudo apt install jq  (Linux)"
        echo "  python3: https://www.python.org/downloads/"
        exit 1
    fi
}

json_validate() {
    # Usage: json_validate <file>  — returns 0 if valid JSON, 1 otherwise
    local file="$1"
    if command -v jq &>/dev/null; then
        jq empty "$file" 2>/dev/null
    elif command -v python3 &>/dev/null; then
        python3 -c "import json; json.load(open('$file'))" 2>/dev/null
    else
        return 1
    fi
}

# ----- Prerequisites -------------------------------------------------------
check_prerequisites() {
    local missing=0

    # Check for JSON parser (jq preferred, python3 fallback)
    if ! command -v jq &>/dev/null && ! command -v python3 &>/dev/null; then
        err "Neither jq nor python3 is installed. Need at least one for JSON parsing."
        echo "  Install jq:      brew install jq  (macOS)  |  sudo apt install jq  (Linux)"
        echo "  Install python3:  https://www.python.org/downloads/"
        missing=1
    elif ! command -v jq &>/dev/null; then
        info "jq not found — using python3 as JSON parser"
    fi

    # Check for gemini (Gemini CLI).
    if command -v gemini &>/dev/null; then
        GEMINI_BIN="$(command -v gemini)"
    else
        err "Gemini CLI is not installed."
        echo ""
        echo "  Install Gemini CLI:"
        echo "    npm install -g @google/gemini-cli"
        echo "    — or —"
        echo "    See https://github.com/google-gemini/gemini-cli for installation options"
        echo ""
        missing=1
    fi

    if [[ $missing -eq 1 ]]; then
        echo ""
        err "Missing prerequisites. Please install them and re-run this script."
        exit 1
    fi

    ok "Prerequisites satisfied (JSON parser, gemini)"
}

# ----- Credential file discovery --------------------------------------------
find_credential_file() {
    local cred_file=""

    # 1. Passed as argument
    if [[ $# -ge 1 && -n "${1:-}" ]]; then
        cred_file="$1"
    fi

    # 2. Look in common locations
    if [[ -z "$cred_file" ]]; then
        local search_paths=(
            "."
            "$HOME/Downloads"
            "$HOME/Desktop"
            "$HOME"
        )
        for dir in "${search_paths[@]}"; do
            local found
            found=$(find "$dir" -maxdepth 1 -name "lightup-api-credential*.json" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)
            if [[ -n "$found" ]]; then
                cred_file="$found"
                info "Found credential file: $cred_file"
                break
            fi
        done
    fi

    # 3. No file found — offer login or trial
    if [[ -z "$cred_file" || ! -f "$cred_file" ]]; then
        echo "" >&2
        warn "No credential file found automatically."
        echo "" >&2
        echo "  Do you have a Lightup account?" >&2
        echo "" >&2
        echo "    1) Yes — log in and download my credentials" >&2
        echo "    2) No  — sign up for a 30-day free trial" >&2
        echo "" >&2

        local choice
        while true; do
            read -rp "  Choice [1/2]: " choice
            case "$choice" in
                1)
                    echo "" >&2
                    echo "  Log in to Lightup and go to:" >&2
                    echo "  Profile → API Credentials → Generate API Credentials → Download" >&2
                    echo "" >&2
                    read -rp "  Path to lightup-api-credential.json (once downloaded): " cred_file
                    break
                    ;;
                2)
                    echo "" >&2
                    local _url="https://my.lightup.ai/"
                    local _opened=false
                    if command -v open &>/dev/null; then
                        open "$_url" 2>/dev/null || true
                        _opened=true
                    elif command -v xdg-open &>/dev/null; then
                        xdg-open "$_url" 2>/dev/null || true
                        _opened=true
                    elif command -v start &>/dev/null; then
                        start "$_url" 2>/dev/null || true
                        _opened=true
                    else
                        for _browser in firefox google-chrome chromium chromium-browser microsoft-edge brave-browser; do
                            if command -v "$_browser" &>/dev/null; then
                                "$_browser" "$_url" &>/dev/null &
                                _opened=true
                                break
                            fi
                        done
                    fi
                    if [[ "$_opened" == true ]]; then
                        info "Opening Lightup in your browser..."
                    else
                        echo "  Could not detect a browser. Open this URL manually:" >&2
                        echo "  $_url" >&2
                    fi
                    echo "" >&2
                    echo "  Follow these steps in the browser:" >&2
                    echo "  1. Select \"Sign Up\" and enter your email and password." >&2
                    echo "  2. Check your inbox, verify your email, enter your first and last name, then click \"Start Trial\"." >&2
                    echo "  3. You'll be redirected to https://my.lightup.ai — click \"Enter Lightup Cloud Free Trial\"." >&2
                    echo "  4. Go to Profile → API Credentials → Generate API Credentials → Download." >&2
                    echo "" >&2
                    echo "  Come back here once you have the file." >&2
                    echo "" >&2
                    read -rp "  Path to lightup-api-credential.json (once downloaded): " cred_file
                    break
                    ;;
                *)
                    warn "Please enter 1 or 2." >&2
                    ;;
            esac
        done
    fi

    if [[ ! -f "$cred_file" ]]; then
        err "File not found: $cred_file"
        exit 1
    fi

    echo "$cred_file"
}

# ----- Extract credentials --------------------------------------------------
extract_credentials() {
    local cred_file="$1"

    # Validate JSON
    if ! json_validate "$cred_file"; then
        err "Invalid JSON in $cred_file"
        exit 1
    fi

    # Extract host (server field in .data.server)
    local host
    host=$(json_read "$cred_file" '.data.server // empty')
    if [[ -z "$host" ]]; then
        err "Could not find .data.server in credential file."
        err "Expected format: { \"data\": { \"server\": \"https://app.xxx.lightup.ai\", \"refresh\": \"eyJ...\" } }"
        exit 1
    fi

    # Extract refresh token (.data.refresh)
    local refresh_token
    refresh_token=$(json_read "$cred_file" '.data.refresh // empty')
    if [[ -z "$refresh_token" ]]; then
        err "Could not find .data.refresh in credential file."
        exit 1
    fi

    # Check if token is expired
    local expired_ts
    expired_ts=$(json_read "$cred_file" '.data.expiredTs // 0')
    local now
    now=$(date +%s)
    if [[ "$expired_ts" -gt 0 && "$now" -gt "$expired_ts" ]]; then
        warn "Refresh token appears to be expired (expiredTs: $expired_ts)."
        warn "You may need to download a new credential file from Lightup."
    fi

    ok "Extracted credentials"
    echo "  Host:  $host"
    echo "  Token: ${refresh_token:0:20}...${refresh_token: -10}"

    # Export for use by caller
    LIGHTUP_HOST="$host"
    LIGHTUP_REFRESH_TOKEN="$refresh_token"
}

# ----- Infer MCP endpoint from host -----------------------------------------
# app.mcd-dev.lightup.ai  →  mcp.mcd-dev.lightup.ai
# app.stage.lightup.ai    →  mcp.stage.lightup.ai
# app.acme.lightup.ai     →  mcp.acme.lightup.ai
infer_mcp_endpoint() {
    local host="$1"

    # Strip protocol (https:// or http://)
    local hostname="${host#https://}"
    hostname="${hostname#http://}"
    # Strip trailing slash
    hostname="${hostname%/}"

    # Replace leading "app." with "mcp."
    if [[ "$hostname" == app.* ]]; then
        local mcp_host="mcp.${hostname#app.}"
    else
        # Fallback: prepend mcp. to whatever the hostname is
        local mcp_host="mcp.${hostname}"
    fi

    # Allow env override, otherwise use inferred endpoint (no port by default)
    local mcp_base="https://${mcp_host}${MCP_PORT:+:${MCP_PORT}}"
    local mcp_server="${LIGHTUP_MCP_SERVER:-$mcp_base}"
    echo "$mcp_server"
}

# ----- Register MCP ---------------------------------------------------------
register_mcp() {
    local mcp_server
    mcp_server=$(infer_mcp_endpoint "$LIGHTUP_HOST")

    local sse_url="${mcp_server}/sse?host=${LIGHTUP_HOST}&refresh_token=${LIGHTUP_REFRESH_TOKEN}"

    info "Inferred MCP endpoint: $mcp_server"

    info "Removing any existing '$MCP_NAME' MCP registration..."
    "$GEMINI_BIN" mcp remove "$MCP_NAME" $SCOPE 2>/dev/null || true

    info "Registering Lightup MCP server with Gemini CLI..."
    "$GEMINI_BIN" mcp add --transport sse "$MCP_NAME" "$sse_url" $SCOPE

    ok "MCP server registered successfully!"
    echo ""
    echo "  Verify with:  gemini mcp list"
    echo ""
}

# ----- Verify ---------------------------------------------------------------
verify_setup() {
    info "Verifying MCP registration..."
    if ! "$GEMINI_BIN" mcp list 2>&1 | grep -q "$MCP_NAME"; then
        warn "Could not verify registration. Run 'gemini mcp list' manually."
        return
    fi
    ok "Lightup MCP server is registered."

    # Test the actual SSE endpoint — this is what Gemini CLI connects to,
    # so an HTTP error here means the MCP connection will fail in-session too.
    local mcp_server sse_url http_code
    mcp_server=$(infer_mcp_endpoint "$LIGHTUP_HOST")
    sse_url="${mcp_server}/sse?host=${LIGHTUP_HOST}&refresh_token=${LIGHTUP_REFRESH_TOKEN}"

    info "Testing MCP SSE endpoint..."
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$sse_url" 2>/dev/null) || true

    case "$http_code" in
        200)
            ok "MCP server is reachable and accepted the connection."
            ;;
        000)
            err "MCP server is not reachable at $mcp_server"
            echo ""
            echo "  The server may be down or your network/firewall may be blocking it."
            echo "  Contact your Lightup administrator to confirm the MCP server is running."
            echo ""
            exit 1
            ;;
        401|403)
            err "MCP server rejected the credentials (HTTP $http_code)."
            echo ""
            echo "  Your refresh token may be expired. Download a new credential file from:"
            echo "  Lightup UI → Profile → API Credentials"
            echo ""
            exit 1
            ;;
        *)
            err "MCP server returned unexpected HTTP $http_code."
            echo ""
            echo "  Contact your Lightup administrator."
            echo ""
            exit 1
            ;;
    esac
}

# ----- Main -----------------------------------------------------------------
main() {
    echo ""
    echo "=========================================="
    echo "  Lightup MCP Setup for Gemini CLI"
    echo "=========================================="
    echo ""

    check_prerequisites

    local cred_file
    cred_file=$(find_credential_file "${1:-}")

    extract_credentials "$cred_file"

    register_mcp

    verify_setup

    echo ""
    ok "Setup complete! Start a new Gemini CLI session and try:"
    echo ""
    echo "    gemini"
    echo "    > list workspaces"
    echo ""
}

main "$@"
