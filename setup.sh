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
  ./setup.sh <client> [credential_json_path]
  ./setup.sh <client> [client args...]
  ./setup.sh

Supported clients:
  claude       Configure Lightup for Claude Code
  gemini-cli   Configure Lightup for Gemini CLI
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
    echo "Select an AI client to configure with Lightup:" >&2
    echo "" >&2
    echo "  1) Claude Code" >&2
    echo "  2) Gemini CLI" >&2
    echo "  3) Codex CLI (coming soon)" >&2
    echo "" >&2
    echo "Make sure you have your lightup-api-credential.json file ready." >&2
    echo "Download it from: Lightup UI → Profile → API Credentials" >&2
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

prompt_for_credential_path() {
    local cred_path=""
    echo "" >&2
    echo "Optional: credential JSON path" >&2
    echo "If your file name/path is non-standard, you can provide it here." >&2
    echo "Leave empty to let the client setup auto-discover it (or prompt later)." >&2

    read -rp "Path to lightup-api-credential.json (optional): " cred_path

    # Empty -> use default discovery in the client scripts
    if [[ -z "${cred_path:-}" ]]; then
        echo ""
        return 0
    fi

    if [[ -f "$cred_path" ]]; then
        echo "$cred_path"
        return 0
    fi

    err "Invalid credential path: '$cred_path' (expected an existing file)."
    err "Re-run setup with the correct path, or leave it empty."
    return 1
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
        gemini-cli)
            local target_script="$ROOT_DIR/gemini-cli/setup.sh"
            if [[ -n "$ROOT_DIR" && -f "$target_script" ]]; then
                info "Running Gemini CLI setup..."
                bash "$target_script" "$@"
            else
                # Running via `curl | bash` — download the client script to a temp file.
                local tmp_script
                tmp_script="$(mktemp)"
                trap "rm -f '$tmp_script'" EXIT
                info "Downloading Gemini CLI setup script..."
                if ! curl -fsSL "$LIGHTUP_REPO_RAW/gemini-cli/setup.sh" -o "$tmp_script"; then
                    err "Failed to download Gemini CLI setup script from $LIGHTUP_REPO_RAW"
                    exit 1
                fi
                info "Running Gemini CLI setup..."
                bash "$tmp_script" "$@"
            fi
            ok "Gemini CLI setup finished."
            ;;
        codex-cli)
            warn "$client support is not available yet."
            warn "Use 'claude' or 'gemini-cli' today. This wrapper already reserves the future client entry point."
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
    local client_args=()

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
            client_args=("$@")
        else
            err "Unknown client: ${1:-}"
            echo ""
            usage
            exit 1
        fi
    else
        client="$(prompt_for_client)"
        client_args=()
    fi

    # If user didn't provide a credential path (or other client args), offer
    # an interactive optional prompt to handle non-standard filenames/locations.
    if [[ ${#client_args[@]} -eq 0 ]]; then
        local cred_path
        cred_path="$(prompt_for_credential_path)"
        if [[ -n "${cred_path:-}" ]]; then
            client_args=("$cred_path")
        fi
    fi

    dispatch_client "$client" "${client_args[@]:-}"
}

main "$@"
