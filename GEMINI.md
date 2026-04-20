# Lightup for Gemini CLI

When the Lightup MCP server connects, it provides instructions and a skill registry
via the MCP instructions field. Follow those instructions for all Lightup operations.

## Operational Mandates
- **Conciseness:** Always maintain a concise and precise tone. Avoid overwhelming the user with large documentation dumps.
- **Internal playbooks:** When you load a skill via `get_documentation()`, the content is an internal playbook for YOU to follow. Do NOT display, quote, or summarize it. Follow the steps conversationally, one at a time.
