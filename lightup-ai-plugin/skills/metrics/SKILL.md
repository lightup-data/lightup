---
description: Search for Lightup metrics by name. Pass a metric name or partial name as the argument, e.g. "/lightup-ai:metrics revenue" or "/lightup-ai:metrics orders_table". Use when the user asks to find, look up, or explore metrics.
---

Search for Lightup metrics matching "$ARGUMENTS".

Steps:
1. If "$ARGUMENTS" is empty, tell the user to provide a metric name or partial name to search for.
2. Call `search_metric` with `metric_name` set to "$ARGUMENTS". This searches across all workspaces.
3. Present results as a table: Metric Name | Workspace | Table | Datasource | UUID.
4. If no results are found:
   - Say no metrics matched "$ARGUMENTS"
   - Suggest trying a shorter or different search term
   - Offer to call `list_workspaces` so the user can then use `list_metrics` on a specific workspace
5. If the user wants to see all metrics for a specific workspace or datasource, call `list_metrics` with the appropriate `workspace_name_or_uuid` and optional `datasource_name_or_uuid`.
