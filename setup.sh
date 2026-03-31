#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  gemini-cli   Reserved for future support
  codex-cli    Reserved for future support

Examples:
  ./setup.sh claude ~/Downloads/lightup-api-credential.json
  ./setup.sh
EOF
}

normalize_client() {
    local raw="${1:-}"
    case "$raw" in
        claude|claude-code)
            echo "claude"
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
    echo "  2) Gemini CLI (coming soon)" >&2
    echo "  3) Codex CLI (coming soon)" >&2
    echo "" >&2

    while true; do
        read -rp "Choice [1-3]: " choice
        case "$choice" in
            1)
                echo "claude"
                return 0
                ;;
            2)
                echo "gemini-cli"
                return 0
                ;;
            3)
                echo "codex-cli"
                return 0
                ;;
            *)
                warn "Invalid choice. Enter 1, 2, or 3."
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
            if [[ ! -f "$target_script" ]]; then
                err "Missing setup script: $target_script"
                exit 1
            fi

            info "Running Claude Code setup..."
            bash "$target_script" "$@"
            ok "Claude Code setup finished."
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
