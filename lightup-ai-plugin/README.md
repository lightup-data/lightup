# lightup-ai Claude Code Plugin

Extends Claude Code with Lightup data quality tools — metrics, monitors, incidents, and datasources via MCP.

## Prerequisites

- Claude Code installed
- `lightup-api-credential.json` downloaded from your Lightup instance  
  (**Profile → API Credentials → Generate API Credentials → Download**)
- `jq` or `python3` for JSON parsing (`brew install jq` on macOS)

## Install

```bash
claude plugin marketplace add lightup-data/lightup
claude plugin install lightup-ai@lightup
```

That's it. The plugin automatically discovers your `lightup-api-credential.json` in `~/Downloads`, `~/Desktop`, or `~`, parses the credentials, and connects.

## Agent

`data-quality-investigator` — invoked automatically when you ask Claude to investigate a data issue. Runs a structured investigation: incidents → monitors → diagnosis → failing records → summary.

## Troubleshooting

**Credential file not found**  
Move your `lightup-api-credential.json` to `~/Downloads` or set the path explicitly:
```bash
export LIGHTUP_CREDENTIAL_FILE=/path/to/lightup-api-credential.json
```

**Custom MCP server URL**  
Override the inferred URL (default: `mcp.X.lightup.ai:8765`):
```bash
export LIGHTUP_MCP_SERVER=https://your-custom-mcp-server:8765
```

**Token expired** — download a new credential file and restart Claude Code.
