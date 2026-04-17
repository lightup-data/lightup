---
description: Check Lightup connection health and show a platform summary (workspace count, metric count, open incidents). Use when the user wants to verify the Lightup connection or see an overall status snapshot.
---

Check the Lightup connection and show a platform summary.

Steps:
1. Call `list_workspaces` with no arguments to verify connectivity and retrieve workspace names.
2. Call `get_platform_summary` with no arguments to get live counts across all workspaces.
3. Present the results clearly:
   - List workspace names
   - Show counts: metrics, monitors, open incidents, datasources
4. If either tool call fails, tell the user to check their MCP server URL and refresh token, and suggest running `claude plugin disable lightup-ai && claude plugin enable lightup-ai` to re-enter credentials.
