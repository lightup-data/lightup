# Lightup

Connect Lightup to MCP-compatible AI agents.

This repository is the entry point for using Lightup inside agentic workflows. Client-specific setup lives in dedicated folders so the structure stays stable as support expands across interfaces.

## Quick Start

Use the repo-level setup wrapper and pass the client you want to configure:

```bash
curl -sL https://raw.githubusercontent.com/lightup-data/lightup/main/setup.sh \
  | bash -s -- claude
```

```bash
curl -sL https://raw.githubusercontent.com/lightup-data/lightup/main/setup.sh \
  | bash -s -- gemini
```

The setup flow automatically looks for `lightup-api-credential*.json` in common locations such as `~/Downloads`. If multiple files are found it picks the most recently modified one and warns you. If no file is found, the script will ask whether you have a Lightup account — if not, it walks you through signing up for a 30-day free trial at [my.lightup.ai](https://my.lightup.ai).

To use a specific credential file, pass the path explicitly:

```bash
curl -sL https://raw.githubusercontent.com/lightup-data/lightup/main/setup.sh \
  | bash -s -- claude /path/to/lightup-api-credential.json
```

Client-specific installation and usage details live in the dedicated guides below.

## Claude Code Plugin (Alternative to setup.sh)

If you use [Claude Code](https://docs.anthropic.com/en/docs/claude-code), you can install Lightup as a **Claude Code plugin** instead of running the setup script. The plugin auto-discovers your `lightup-api-credential.json`, connects automatically, and adds built-in slash commands and a specialized data quality agent — no credential prompts.

```bash
claude plugin marketplace add lightup-data/lightup
claude plugin install lightup-ai@lightup
```

The plugin finds your credential file in `~/Downloads`, `~/Desktop`, or `~` automatically. See [lightup-ai-plugin/README.md](./lightup-ai-plugin/README.md) for full details.

| Skill | What it does |
|---|---|
| `/lightup-ai:health` | Verify connection and show platform summary |
| `/lightup-ai:incidents` | List recent incidents |
| `/lightup-ai:diagnose <monitor>` | Diagnose a failing monitor |
| `/lightup-ai:metrics <name>` | Search metrics by name |

## Available Guides

- [Claude Code](./claude/README.md)
- [Gemini CLI](./gemini-cli/README.md)
- <sub>Codex CLI (coming soon)</sub>

## Why This Repo Exists

Lightup helps teams bring trusted data quality context into the tools they already use to investigate issues, debug pipelines, and answer operational questions. This repo packages client-specific setup instructions and scripts in one place, starting with Claude Code and designed to extend cleanly to additional AI agent clients over time.

## Current Support

- Claude Code: available now
- Gemini CLI: available now
- Codex CLI: coming soon

## Setup Model

Each client guide is responsible for its own installation and connection flow. That keeps the top-level repository product-oriented, while letting each integration evolve independently.

Pick the guide for your preferred AI client to get started.

---

## What is Lightup Agentic

Lightup Agentic exposes your Lightup data quality platform as an MCP (Model Context Protocol) server — letting any MCP-compatible AI agent read metrics, monitor data quality, diagnose incidents, and create new monitors in plain English, without leaving your AI tool.

```
┌─────────────────────┐        MCP (SSE)        ┌─────────────────────┐
│   AI Agent Client   │ ◄─────────────────────► │  Lightup MCP Server │
│                     │                          │                     │
│  • Claude Code      │                          │  Exposes 41 tools   │
│  • Gemini CLI       │                          │  for metrics,       │
│  • Codex CLI        │                          │  monitors,          │
│                     │                          │  incidents, docs    │
│                     │                          └──────────┬──────────┘
└─────────────────────┘                                     │
                                                       REST API
                                                            │
                                               ┌────────────▼───────────┐
                                               │   Lightup Platform     │
                                               │   (your instance)      │
                                               └────────────────────────┘
```

---

## Prerequisites

| Requirement | Details |
|---|---|
| AI client | Claude Code, Gemini CLI, or Codex CLI |
| Lightup account | An active Lightup instance with at least Viewer access, or sign up for a [30-day free trial](https://my.lightup.ai) |
| API credential file | Download from Lightup UI → Profile → API Credentials → Download (setup will guide you if you don't have one yet) |
| Network access | Your machine must be able to reach the Lightup MCP server URL (provided by your Lightup team) |

---

## What You Can Ask

### Read — Explore your data quality

| Question | What it does |
|---|---|
| "How many metrics do we have?" | Count metrics across all workspaces |
| "List my workspaces" | Show all workspaces you have access to |
| "Show all metrics in workspace Acme" | List metrics in a specific workspace |
| "What monitors are failing in workspace Acme?" | Show monitors in error state |
| "List recent incidents" | Show data quality incidents from the last 7 days |
| "Show all datasources in workspace Acme" | List connected data sources |
| "Give me a health summary of workspace Acme" | Compact overview of metrics, monitors, incidents |
| "What's the overall platform status?" | Cross-workspace rollup for the entire instance |

### Diagnose — Understand what's wrong

| Question | What it does |
|---|---|
| "Diagnose monitor `<uuid>`" | Explains in plain English why a monitor is not working |
| "Why is monitor `<name>` getting false positives?" | Root cause analysis |
| "Get details for incident `<uuid>`" | Full incident breakdown |
| "Show system errors in workspace Acme from last 48 hours" | Recent platform events |

### Write — Create and configure

| Question | What it does |
|---|---|
| "Create a null check on the orders table" | Creates a null fraction metric + monitor |
| "Create a row count metric on the customers table" | Creates a data volume metric |
| "Create an anomaly detection monitor on metric X" | Sets up ML-based monitoring |
| "Create a manual threshold monitor with bounds 0 to 500" | Sets up fixed threshold monitoring |
| "Create a postgres datasource in workspace Acme" | Connects a new database |
| "Create a workspace called Production" | Creates a new workspace |

### Learn — Documentation

| Question | What it does |
|---|---|
| "What is Lightup?" | Overview of the platform |
| "What is a slice?" | Explains metric slicing |
| "How does anomaly detection work?" | Explains ML-based monitoring |
| "What metric types are available?" | Lists all metric types with descriptions |
| "How does monitor training work?" | Explains the training lifecycle |

---

## Available Tools

### Summary Tools (token-efficient)

| Tool | Description |
|---|---|
| `count_all_metrics` | Total metric count across all workspaces |
| `count_all_monitors` | Monitor count with live / training / paused / error breakdown |
| `count_all_incidents` | Total incident count (configurable lookback window) |
| `get_workspace_health` | Compact health summary for one workspace |
| `get_platform_summary` | Cross-workspace rollup for the entire Lightup instance |

### Workspace & Datasource Tools

| Tool | Description |
|---|---|
| `list_workspaces` | List all workspaces |
| `get_workspace` | Get workspace details |
| `create_workspace` | Create a new workspace |
| `list_datasources` | List datasources in a workspace |
| `get_datasource` | Get datasource details |
| `create_datasource` | Create a new datasource |
| `test_datasource_connection` | Test a datasource connection before creating |

### Metric Tools

| Tool | Description |
|---|---|
| `list_metrics` | List metrics in a workspace |
| `get_metric` | Get metric details |
| `search_metric` | Search for a metric by name across workspaces |
| `create_metric` | Create a new metric |
| `create_metrics_batch` | Create multiple metrics at once |
| `update_metric` | Update an existing metric |
| `delete_metric` | Delete a metric |
| `explore_metric_target` | Explore available tables and columns for a metric |
| `analyze_table` | Analyze a table's structure and data profile |
| `suggest_metrics` | Get AI-generated metric suggestions for a table |
| `preview_metric` | Preview metric results before creating |
| `validate_custom_sql` | Validate custom SQL before using in a metric |

### Monitor Tools

| Tool | Description |
|---|---|
| `list_monitors` | List monitors in a workspace |
| `get_monitor` | Get monitor details |
| `create_monitor` | Create a threshold or anomaly detection monitor |
| `update_monitor` | Update an existing monitor |
| `delete_monitor` | Delete a monitor |
| `diagnose_monitor` | Explain why a monitor is not working |

### Incident & Event Tools

| Tool | Description |
|---|---|
| `list_incidents` | List recent incidents in a workspace |
| `get_incident` | Get incident details |
| `list_events` | List system events (errors, warnings) |
| `list_recommendations` | AI-generated metric/monitor recommendations |

### Integration & User Tools

| Tool | Description |
|---|---|
| `list_integrations` | List integrations (Slack, PagerDuty, email, etc.) |
| `list_users` | List all users with roles and workspace memberships |
| `list_llm_connections` | List LLM connections configured in the instance |
| `list_catalog_integrations` | List catalog integrations (Atlan, Alation) |

### Documentation Tools

| Tool | Description |
|---|---|
| `get_documentation` | Fetch Lightup product documentation by topic |
| `list_documentation_topics` | List all available documentation topics |

---

## How It Works

The Lightup MCP server is **stateless**. Each connection carries its own credentials in the URL — no credentials are stored server-side.

```
Your AI client connects with:
  /sse?host=https://app.acme.lightup.ai&refresh_token=eyJ...
         │                                      │
         ▼                                      ▼
  Your Lightup instance URL         Your JWT refresh token
  (which Lightup instance to use)   (your identity)
```

Every session is fully isolated — the server only sees and accesses your Lightup instance using your credentials. No data is shared across sessions.

**Security:** Credentials travel over HTTPS only and are never logged or stored on the MCP server.

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `Token refresh failed` | Download a new credential file from Lightup UI and re-run setup |
| `Connection refused` | Verify the MCP server URL is reachable. Check firewall / VPN. |
| Tools not appearing in AI client | Exit and start a new session |
| `HTTP 403` on tool calls | Your Lightup user may lack access to that workspace. Contact your admin. |
| Wrong workspace data | Verify the `host` in your credential file matches your Lightup instance |
