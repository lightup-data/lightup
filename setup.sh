#!/usr/bin/env bash
set -euo pipefail

# When invoked via `curl | bash`, BASH_SOURCE[0] is unset or empty.
# Fall back to an empty ROOT_DIR and download client scripts at runtime.
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" ]]; then
    ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    ROOT_DIR=""
fi

LIGHTUP_REPO_RAW="${LIGHTUP_REPO_RAW:-https://raw.githubusercontent.com/lightup-data/lightup/main}"
SANDBOX_REPO_RAW="${SANDBOX_REPO_RAW:-https://raw.githubusercontent.com/lightup-data/sandbox/main}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
    cat <<'EOF'
Lightup setup

Usage:
  ./setup.sh <client> [client args...]
  ./setup.sh

Supported clients:
  claude       Configure Lightup for Claude Code
  sandbox      Install the Lightup Sandbox (Databricks transformation MCP)
  gemini-cli   Reserved for future support
  codex-cli    Reserved for future support

Examples:
  ./setup.sh claude ~/Downloads/lightup-api-credential.json
  ./setup.sh sandbox
  ./setup.sh
EOF
}

normalize_client() {
    local raw="${1:-}"
    case "$raw" in
        claude|claude-code)
            echo "claude"
            ;;
        sandbox)
            echo "sandbox"
            ;;
        gemini|gemini-cli)
            echo "gemini-cli"
            ;;
        codex|codex-cli)
            echo "codex-cli"
            ;;
        *)
            echo ""
            ;;
    esac
}

prompt_for_client() {
    local choice=""

    echo "" >&2
    echo "Select a Lightup client to configure:" >&2
    echo "  1) Claude Code" >&2
    echo "  2) Sandbox (Databricks transformation MCP)" >&2
    echo "  3) Gemini CLI (coming soon)" >&2
    echo "  4) Codex CLI (coming soon)" >&2
    echo "" >&2

    while true; do
        read -rp "Choice [1-4]: " choice
        case "$choice" in
            1)
                echo "claude"
                return 0
                ;;
            2)
                echo "sandbox"
                return 0
                ;;
            3)
                echo "gemini-cli"
                return 0
                ;;
            4)
                echo "codex-cli"
                return 0
                ;;
            *)
                warn "Invalid choice. Enter 1, 2, 3, or 4."
                ;;
        esac
    done
}

dispatch_client() {
    local client="$1"
    shift || true

    case "$client" in
        claude)
            local target_script="$ROOT_DIR/claude/setup.sh"
            if [[ -n "$ROOT_DIR" && -f "$target_script" ]]; then
                info "Running Claude Code setup..."
                bash "$target_script" "$@"
            else
                # Running via `curl | bash` — download the client script to a temp file.
                local tmp_script
                tmp_script="$(mktemp)"
                trap "rm -f '$tmp_script'" EXIT
                info "Downloading Claude Code setup script..."
                if ! curl -fsSL "$LIGHTUP_REPO_RAW/claude/setup.sh" -o "$tmp_script"; then
                    err "Failed to download Claude setup script from $LIGHTUP_REPO_RAW"
                    exit 1
                fi
                info "Running Claude Code setup..."
                bash "$tmp_script" "$@"
            fi
            ok "Claude Code setup finished."
            ;;
        sandbox)
            local tmp_script
            tmp_script="$(mktemp)"
            trap "rm -f '$tmp_script'" EXIT
            info "Downloading Sandbox install script..."
            if ! curl -fsSL "$SANDBOX_REPO_RAW/install.sh" -o "$tmp_script"; then
                err "Failed to download Sandbox install script from $SANDBOX_REPO_RAW"
                exit 1
            fi
            info "Running Sandbox install..."
            bash "$tmp_script"
            ok "Sandbox install finished."
            ;;
        gemini-cli|codex-cli)
            warn "$client support is not available yet."
            warn "Use 'claude' today. This wrapper already reserves the future client entry point."
            exit 1
            ;;
        *)
            err "Unsupported client: $client"
            usage
            exit 1
            ;;
    esac
}

main() {
    local client=""

    case "${1:-}" in
        -h|--help)
            usage
            exit 0
            ;;
    esac

    if [[ $# -gt 0 ]]; then
        client="$(normalize_client "${1:-}")"
        if [[ -n "$client" ]]; then
            shift
        else
            err "Unknown client: ${1:-}"
            echo ""
            usage
            exit 1
        fi
    else
        client="$(prompt_for_client)"
    fi

    dispatch_client "$client" "$@"
}

main "$@"
