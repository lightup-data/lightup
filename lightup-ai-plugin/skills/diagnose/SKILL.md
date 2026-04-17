---
description: Diagnose a Lightup monitor that is failing, stuck in training, paused, or not alerting. Pass the monitor name (and optionally workspace) as arguments, e.g. "/lightup-ai:diagnose my-monitor" or "/lightup-ai:diagnose my-workspace/my-monitor".
---

Diagnose a Lightup monitor and explain what is wrong in plain English.

Parse "$ARGUMENTS" for:
- A workspace name or UUID (if the user wrote "workspace/monitor" or "workspace monitor")
- A monitor name or UUID (required)

Steps:
1. If no workspace was given, call `list_workspaces` to find available workspaces. If there is only one, use it. If there are multiple, ask the user which one.
2. Call `diagnose_monitor` with:
   - `workspace_name_or_uuid`: the resolved workspace
   - `monitor_name_or_uuid`: the monitor name or UUID from "$ARGUMENTS"
3. Present the diagnosis clearly:
   - What is wrong (the root cause)
   - When the problem started
   - What to do next (the recommended action)
4. Then call `list_incidents` for the same workspace with `lookback_days=7` and check if any open incidents are linked to this monitor. If yes, show them.
5. If `diagnose_monitor` returns a "not found" error, suggest the user check the monitor name by calling `list_monitors`.
