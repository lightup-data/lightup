---
description: List recent Lightup incidents. Accepts optional arguments: a workspace name, a lookback period like "30d" or "last week", or both (e.g. "my-workspace 30d").
---

List recent Lightup incidents.

Parse "$ARGUMENTS" for:
- A workspace name or UUID (any word that looks like a name or UUID)
- A lookback period: "30d", "7d", "last week", "last month", "today" → convert to an integer number of days (default 7)

Steps:
1. If no workspace was given in "$ARGUMENTS", call `list_workspaces` first and ask the user to pick one, or use the first workspace if there is only one.
2. Call `list_incidents` with:
   - `workspace_name_or_uuid`: the resolved workspace
   - `lookback_days`: the resolved number (default 7)
3. Present results as a table with columns: Monitor | Status | Started At | Duration.
4. If there are no incidents, say so clearly — do not show an empty table.
5. If there are more than 20 incidents, show the 20 most recent and tell the user how many were omitted.
