#!/usr/bin/env bash
# agent-dispatch-post.sh
# PostToolUse hook on the Agent tool. Moves the matching active entry into
# history (or marks it failed). Caps history at 50 entries.
#
# Sister to agent-dispatch-pre.sh. Sub-100ms target, never blocks, exit 0.
#
# Stdin payload includes tool_result for terminal status.
#
# Shipped 2026-05-12.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_FILE="$REPO_ROOT/data/runtime/agent-dispatch-state.json"
LOCK_FILE="$STATE_FILE.lock"
HISTORY_CAP=50

PAYLOAD="$(cat 2>/dev/null || echo '{}')"

command -v jq >/dev/null 2>&1 || exit 0

TOOL_NAME=$(printf '%s' "$PAYLOAD" | jq -r '.tool_name // empty' 2>/dev/null)
[[ "$TOOL_NAME" != "Agent" && "$TOOL_NAME" != "Task" ]] && exit 0

TOOL_USE_ID=$(printf '%s' "$PAYLOAD" | jq -r '.tool_use_id // empty' 2>/dev/null)
[[ -z "$TOOL_USE_ID" ]] && exit 0

IS_ERROR=$(printf '%s' "$PAYLOAD" | jq -r '.tool_result.is_error // false' 2>/dev/null)
STATUS="completed"
[[ "$IS_ERROR" == "true" ]] && STATUS="failed"

ENDED_AT=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)

# No file yet means pre hook never fired. Nothing to do.
[[ ! -f "$STATE_FILE" ]] && exit 0

{
  flock -w 1 9 2>/dev/null || :

  if ! jq empty "$STATE_FILE" >/dev/null 2>&1; then
    exit 0
  fi
  CURRENT=$(cat "$STATE_FILE")

  # Find the matching active entry; if not found, synthesize a stub history
  # entry so the dashboard still records the completion.
  MATCH_FOUND=$(printf '%s' "$CURRENT" | jq --arg id "$TOOL_USE_ID" '[.active[]? | select(.id == $id)] | length > 0' 2>/dev/null)

  UPDATED=$(printf '%s' "$CURRENT" | jq -c \
    --arg id "$TOOL_USE_ID" \
    --arg ended_at "$ENDED_AT" \
    --arg status "$STATUS" \
    --argjson cap "$HISTORY_CAP" \
    --argjson match_found "${MATCH_FOUND:-false}" \
    '
    def to_epoch($iso): ($iso | sub("\\..*Z$"; "Z") | fromdateiso8601);

    . as $state
    | (if $match_found then
        ($state.active[] | select(.id == $id))
       else
        {id:$id, agent:"unknown", description:"", started_at:$ended_at, ttl_seconds:0}
       end
      ) as $entry
    | ((to_epoch($ended_at) - to_epoch($entry.started_at)) * 1000 | floor) as $duration_ms
    | .active  = [.active[]? | select(.id != $id)]
    | .history = (
        ([{
          id:          $entry.id,
          agent:       $entry.agent,
          description: $entry.description,
          started_at:  $entry.started_at,
          ended_at:    $ended_at,
          duration_ms: (if $duration_ms < 0 then 0 else $duration_ms end),
          status:      $status
        }] + (.history // []))
        | .[0:$cap]
      )
    | .last_updated = $ended_at
    ' 2>/dev/null) || UPDATED="$CURRENT"

  [[ -z "$UPDATED" ]] && exit 0

  TMP="$STATE_FILE.tmp.$$"
  printf '%s' "$UPDATED" > "$TMP" 2>/dev/null
  chmod 0600 "$TMP" 2>/dev/null
  mv -f "$TMP" "$STATE_FILE" 2>/dev/null
} 9>"$LOCK_FILE" 2>/dev/null

echo '{"suppressOutput": true}'
exit 0
