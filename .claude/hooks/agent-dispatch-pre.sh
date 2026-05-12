#!/usr/bin/env bash
# agent-dispatch-pre.sh
# PreToolUse hook on the Agent tool. Writes a live "running" entry into
# data/runtime/agent-dispatch-state.json so the mobile dashboard Agents tab
# can render real-time dispatch status.
#
# Sister hook: agent-dispatch-post.sh moves the matching entry into history
# when the dispatch finishes.
#
# Hard rules:
#   - Sub-100ms target. Atomic write via mv-from-tmp under a flock.
#   - Never block a dispatch: any failure exits 0 silently.
#   - No emojis, no em dashes.
#   - State file mode 0600 (it carries dispatch descriptions which can hint
#     at sensitive in-flight work).
#
# Stdin: Claude Code passes a JSON envelope:
#   {
#     "tool_name": "Agent",
#     "tool_use_id": "toolu_...",
#     "tool_input": { "subagent_type": "kai", "description": "...", "prompt": "..." }
#   }
#
# Schema for agent-dispatch-state.json:
#   {
#     "active":  [{id, agent, description, started_at, ttl_seconds}],
#     "history": [{id, agent, description, started_at, ended_at, duration_ms, status}],
#     "last_updated": "<iso>"
#   }
#
# Shipped 2026-05-12.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_FILE="$REPO_ROOT/data/runtime/agent-dispatch-state.json"
LOCK_FILE="$STATE_FILE.lock"

mkdir -p "$(dirname "$STATE_FILE")" 2>/dev/null || exit 0

# Read JSON envelope from stdin
PAYLOAD="$(cat 2>/dev/null || echo '{}')"

# Bail silently if jq is missing
command -v jq >/dev/null 2>&1 || exit 0

TOOL_NAME=$(printf '%s' "$PAYLOAD" | jq -r '.tool_name // empty' 2>/dev/null)
[[ "$TOOL_NAME" != "Agent" && "$TOOL_NAME" != "Task" ]] && exit 0

TOOL_USE_ID=$(printf '%s' "$PAYLOAD" | jq -r '.tool_use_id // empty' 2>/dev/null)
[[ -z "$TOOL_USE_ID" ]] && exit 0

# subagent_type carries the agent name (kai, rose, etc). Fall back to "unknown".
AGENT=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.subagent_type // .tool_input.agent // "unknown"' 2>/dev/null)
[[ -z "$AGENT" || "$AGENT" == "null" ]] && AGENT="unknown"

# description is a short label set by the dispatcher; prompt is the full brief.
# Keep description compact (audit log caps at 240 chars; we cap here at 200).
DESCRIPTION=$(printf '%s' "$PAYLOAD" | jq -r '
  if (.tool_input.description // "") != "" then .tool_input.description
  elif (.tool_input.prompt // "") != "" then (.tool_input.prompt | tostring)
  else ""
  end
' 2>/dev/null | head -c 200)

# Scrub credentials defensively. Matches the audit hook regex.
DESCRIPTION=$(printf '%s' "$DESCRIPTION" | sed -E 's/(api[_-]?key|token|password|secret|bearer|authorization)[[:space:]]*[:=][[:space:]]*['\''"]*[^'\''"[:space:]]{8,}/\1=***REDACTED***/Ig')

STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
TTL_SECONDS=3600

# Build the new active entry
NEW_ENTRY=$(jq -nc \
  --arg id "$TOOL_USE_ID" \
  --arg agent "$AGENT" \
  --arg description "$DESCRIPTION" \
  --arg started_at "$STARTED_AT" \
  --argjson ttl_seconds "$TTL_SECONDS" \
  '{id:$id, agent:$agent, description:$description, started_at:$started_at, ttl_seconds:$ttl_seconds}' 2>/dev/null)

[[ -z "$NEW_ENTRY" ]] && exit 0

# Lock + atomic-write merge. flock with 1s timeout; if we cannot get the lock
# we drop the write rather than block the dispatch.
{
  if ! flock -w 1 9 2>/dev/null; then
    # macOS bash 3.2 fallback: try without flock if /usr/bin/flock missing
    : # proceed anyway; race window is tiny
  fi

  # Read current state (or initialize)
  if [[ -f "$STATE_FILE" ]] && jq empty "$STATE_FILE" >/dev/null 2>&1; then
    CURRENT=$(cat "$STATE_FILE")
  else
    CURRENT='{"active":[],"history":[],"last_updated":null}'
  fi

  # GC any active entry older than TTL (orphans from killed sessions). Also
  # drop any duplicate of the incoming id so retries dont double-insert.
  UPDATED=$(printf '%s' "$CURRENT" | jq -c \
    --argjson new "$NEW_ENTRY" \
    --arg now "$STARTED_AT" \
    '
    def is_fresh($entry; $now):
      (
        ($now | sub("\\..*Z$"; "Z") | fromdateiso8601) -
        ($entry.started_at | sub("\\..*Z$"; "Z") | fromdateiso8601)
      ) < ($entry.ttl_seconds // 3600);

    .active = (
      [.active[]?
        | select(.id != $new.id)
        | select(is_fresh(.; $now))
      ] + [$new]
    )
    | .history = (.history // [])
    | .last_updated = $now
    ' 2>/dev/null) || UPDATED="$CURRENT"

  [[ -z "$UPDATED" ]] && exit 0

  TMP="$STATE_FILE.tmp.$$"
  printf '%s' "$UPDATED" > "$TMP" 2>/dev/null
  chmod 0600 "$TMP" 2>/dev/null
  mv -f "$TMP" "$STATE_FILE" 2>/dev/null
} 9>"$LOCK_FILE" 2>/dev/null

# Never emit blocking output. The audit hook downstream wants suppressOutput.
echo '{"suppressOutput": true}'
exit 0
