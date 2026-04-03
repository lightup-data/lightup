# Lightup + Claude Code Setup

Connect your [Lightup](https://lightup.ai) data quality platform to [Claude Code](https://docs.anthropic.com/en/docs/claude-code) via MCP in under 2 minutes.

## Quick Start

```bash
# 1. Install Claude Code only if it is not already installed
command -v claude >/dev/null || npm install -g @anthropic-ai/claude-code

# 2. Authenticate if you are not already signed in
claude auth login

# 3. Run the setup script
curl -sL https://raw.githubusercontent.com/lightup-data/lightup/main/claude/setup.sh \
  | bash

# 4. Start using it
claude
> list workspaces
```

That's it. The script looks for `lightup-api-credential*.json` in common locations such as `~/Downloads`, reads the credential file, infers the MCP endpoint, and registers everything with Claude Code.

---

## Prerequisites

| Requirement | How to get it |
|---|---|
| Node.js 18+ | [nodejs.org](https://nodejs.org) — required by Claude Code and used by the session tracing hook |
| Lightup account | Contact your Lightup admin |
| API credential file | Lightup UI → Profile → API Credentials |

---

## 1. Confirm Claude Code Is Available

Claude Code is Anthropic's command-line AI assistant. It runs in your terminal and connects to external services (like Lightup) through MCP servers.

### 1.1 Check whether Claude Code is already installed

Run:

```bash
claude --version
```

If that returns a version number, Claude Code is already installed and you can skip to authentication.

If the command is not found, install it with npm:

```bash
npm install -g @anthropic-ai/claude-code
```

Then verify the installation:

```bash
claude --version
```

### 1.2 Authenticate if needed

Claude Code requires an Anthropic account. Run the login command and follow the browser-based authentication flow:

```bash
claude auth login
```

This opens your browser for authentication. If you are already signed in on this machine, you do not need to repeat this step.

### 1.3 Quick Smoke Test

```bash
claude
> What is 2 + 2?

# You should see Claude respond with: 4
# Type /exit to leave the session
```

---

## 2. Download Your Lightup API Credential

### 2.1 From the Lightup UI (Recommended)

1. Log in to your Lightup instance (e.g., `https://app.<your-environment>.lightup.ai`)
2. Click your profile icon in the top-right corner
3. Select **API Credentials** from the dropdown menu
4. Click **Create New Credential** or download an existing one
5. Save the file as `lightup-api-credential.json` in your Downloads folder

The credential file looks like this:

```json
{
  "apiVersion": "v1",
  "type": "apiCredential",
  "data": {
    "server": "https://app.<your-environment>.lightup.ai",
    "refresh": "eyJhbGciOiJIUzI1NiIs...",
    "expiredTs": 1805907702,
    "active": true
  }
}
```

### 2.2 Via the REST API (Alternative)

If you already have a username and password, you can obtain a refresh token programmatically:

```bash
# Step 1: Get initial tokens with username/password
curl -X POST https://app.<your-environment>.lightup.ai/api/v1/token/ \
  -H 'Content-Type: application/json' \
  -d '{"username": "you@company.com", "password": "your-password"}'

# Response:
# {"refresh": "eyJhbGci...", "access": "eyJhbGci..."}

# Step 2: Refresh the token (when the access token expires)
curl -X POST https://app.<your-environment>.lightup.ai/api/v1/token/refresh/ \
  -H 'Content-Type: application/json' \
  -d '{"refresh": "eyJhbGci..."}'

# Response:
# {"access": "eyJhbGci..."}
```

API Reference: [docs.lightup.ai/reference/post_api-v1-token-refresh](https://docs.lightup.ai/reference/post_api-v1-token-refresh)

> **Security Note:** The refresh token grants API access to your Lightup instance. Treat it like a password. Never commit it to version control or share it in plain text. The credential file should have restricted permissions (`chmod 600`).

---

## 3. Connect Lightup to Claude Code

### 3.1 One-Line Setup (Recommended)

Download and run the setup script. It automatically looks for `lightup-api-credential*.json` in common locations such as `~/Downloads`, infers the correct MCP endpoint from your hostname (`app.X.lightup.ai` → `mcp.X.lightup.ai`), and registers everything with Claude Code automatically.

```bash
curl -sL https://raw.githubusercontent.com/lightup-data/lightup/main/claude/setup.sh \
  | bash
```

Or if you already have the script locally:

```bash
chmod +x claude/setup.sh
./claude/setup.sh
```

If you prefer to be explicit, you can still pass the credential path as an argument:

```bash
./claude/setup.sh ~/Downloads/lightup-api-credential.json
```

The script performs these steps:
- Checks prerequisites (jq or python3 for JSON parsing, claude CLI)
- Finds and validates your credential JSON file
- Extracts the server host and refresh token
- Infers the MCP endpoint (`app.X.lightup.ai` → `mcp.X.lightup.ai`)
- Removes any previous Lightup MCP registration
- Registers the remote MCP server with Claude Code
- Writes `~/.lightup/log_turn_hook.js` and registers it as a Claude Code Stop hook for session tracing
- Verifies the registration was successful

### 3.2 Manual Setup

If you prefer to run the command yourself:

```bash
# Extract values from your credential file
HOST=$(jq -r '.data.server' lightup-api-credential.json)
TOKEN=$(jq -r '.data.refresh' lightup-api-credential.json)

# Infer MCP endpoint: app.X.lightup.ai → mcp.X.lightup.ai
MCP_HOST=$(echo "$HOST" | sed 's|https://app\.|mcp.|; s|http://app\.|mcp.|')

# Register the MCP server
claude mcp add --transport sse lightup \
  "https://${MCP_HOST}:8765/sse?host=${HOST}&refresh_token=${TOKEN}" \
  -s user
```

> **Tip:** The `-s user` flag stores the MCP configuration in your user-level Claude settings (`~/.claude.json`), so it persists across all projects and sessions.

### 3.3 Verify the Connection

1. Check that the MCP server is registered:

```bash
claude mcp list
```

You should see `lightup` listed with the SSE URL.

2. Start a Claude Code session and test:

```bash
claude
> list workspaces
```

You should see your Lightup workspaces listed. If you see an authentication error, double-check your credential file and re-run the setup.

---

## What You Can Ask

| Category | Example |
|---|---|
| Platform health | *"How many metrics do we have?"* |
| Workspaces | *"List workspaces"* / *"Create a workspace called Production"* |
| Metrics & monitors | *"Show failing monitors in workspace Acme"* |
| Incidents | *"List recent incidents"* / *"Diagnose monitor \<uuid\>"* |
| Datasources | *"Create a postgres datasource"* / *"Test datasource connection"* |
| Documentation | *"What is a slice?"* / *"How does monitor training work?"* |

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `Token refresh failed` | Download a new credential file from the Lightup UI and re-run the setup script |
| `Connection refused` | Verify the MCP server is reachable from your network. Check firewall/VPN. |
| `lightup` not in `mcp list` | Re-run the setup script or the `claude mcp add` command |
| Tools not appearing | Exit Claude Code (`/exit`) and start a new session |
| `HTTP 403` on tool calls | Your Lightup user may lack access to the workspace. Contact admin. |

To update credentials when your token expires:

```bash
./claude/setup.sh ~/Downloads/lightup-api-credential-new.json
```

## Related Guides

- Repository overview: [../README.md](../README.md)
- Gemini CLI: [../gemini-cli/README.md](../gemini-cli/README.md)
- Codex CLI: [../codex-cli/README.md](../codex-cli/README.md)

---

## License

Apache 2.0 — see [LICENSE](LICENSE).
