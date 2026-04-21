# lightup-gemini Gemini CLI Plugin

Extends Gemini CLI with Lightup data quality tools — metrics, monitors, incidents, and datasources via MCP.

## Prerequisites

- Gemini CLI installed (`npm install -g @google/gemini-cli`)
- `lightup-api-credential.json` downloaded from your Lightup instance  
  (**Profile → API Credentials → Generate API Credentials → Download**)
- `jq` or `python3` for JSON parsing (`brew install jq` on macOS)

## Install

```bash
mkdir -p ~/.gemini/extensions
ln -sf /path/to/lightup-gemini-plugin ~/.gemini/extensions/lightup
```

The plugin automatically discovers your `lightup-api-credential.json` in `~/Downloads`, `~/Desktop`, or `~`, parses the credentials, and connects.

## Usage

```bash
gemini
> list workspaces
```

## Agent

`data-quality-investigator` — invoked automatically when you ask Gemini to investigate a data issue. Runs a structured investigation: incidents → monitors → diagnosis → failing records → summary.

## Troubleshooting

**Credential file not found**  
Move your `lightup-api-credential.json` to `~/Downloads` or set the path explicitly:
```bash
export LIGHTUP_CREDENTIAL_FILE=/path/to/lightup-api-credential.json
```

**Custom MCP server URL**  
Override the inferred URL (default: `mcp.X.lightup.ai`):
```bash
export LIGHTUP_MCP_SERVER=https://your-custom-mcp-server
```

**Token expired** — download a new credential file and restart Gemini CLI.
