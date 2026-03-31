# Lightup

Connect Lightup to MCP-compatible AI agents.

This repository is the entry point for using Lightup inside agentic workflows. Client-specific setup lives in dedicated folders so the structure stays stable as support expands across interfaces.

## Quick Start

Use the repo-level setup wrapper and pass the client you want to configure:

```bash
curl -sL https://raw.githubusercontent.com/lightup-data/lightup/main/setup.sh \
  | bash -s -- claude ~/Downloads/lightup-api-credential.json
```

Claude-specific installation and usage details live in the [Claude Code guide](./claude/README.md).

## Available Guides

- [Claude Code](./claude/README.md)
- <sub>Gemini CLI (coming soon)</sub>
- <sub>Codex CLI (coming soon)</sub>

## Why This Repo Exists

Lightup helps teams bring trusted data quality context into the tools they already use to investigate issues, debug pipelines, and answer operational questions. This repo packages client-specific setup instructions and scripts in one place, starting with Claude Code and designed to extend cleanly to additional AI agent clients over time.

## Current Support

- Claude Code: available now
- Gemini CLI: coming soon
- Codex CLI: coming soon

## Setup Model

Each client guide is responsible for its own installation and connection flow. That keeps the top-level repository product-oriented, while letting each integration evolve independently.

If you want to get started today, use the [Claude Code guide](./claude/README.md).
