#!/usr/bin/env bash
# stop-verify-contract — Stop-side half of the Task Contract pattern.
#
# Reads data/runtime/turn-contract.json (written by telegram-reply-reminder
# on Telegram turns). For each guarantee:
#
#   must_use_reply_tool:       scan today's audit JSONL for any
#                              mcp__plugin_telegram_telegram__reply since
#                              turn_started_epoch. If zero calls, auto-log
#                              a forgot-telegram-reply correction.
#
# Writes findings to data/corrections.jsonl (via scripts/log-correction.sh)
# so the next greeting digest surfaces the breach.
#
# Always exits 0 — never blocks session-end.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" 2>/dev/null || exit 0

CONTRACT_FILE="$REPO_ROOT/data/runtime/turn-contract.json"
[ ! -f "$CONTRACT_FILE" ] && exit 0  # no contract for this turn

ORIGIN="$(jq -r '.origin // empty' "$CONTRACT_FILE" 2>/dev/null)"
TURN_EPOCH="$(jq -r '.turn_started_epoch // 0' "$CONTRACT_FILE" 2>/dev/null)"

# Only enforce Telegram contracts for now
if [ "$ORIGIN" != "telegram" ]; then
  rm -f "$CONTRACT_FILE"
  exit 0
fi

VIOLATIONS=()

# --- Check must_use_reply_tool ---
MUST_REPLY="$(jq -r '.guarantees.must_use_reply_tool // false' "$CONTRACT_FILE" 2>/dev/null)"
if [ "$MUST_REPLY" = "true" ]; then
  TURN_STARTED_AT="$(jq -r '.turn_started_at' "$CONTRACT_FILE" 2>/dev/null)"
  AUDIT_FILE="$REPO_ROOT/data/audit/$(date -u +%Y-%m-%d).jsonl"
  # Adversarial finding #2: guard against null/empty turn_started_at.
  # jq returns "null" for missing fields when piped through -r; treat that as empty.
  if [ "$TURN_STARTED_AT" = "null" ] || [ -z "$TURN_STARTED_AT" ]; then
    TURN_STARTED_AT=""
  fi
  if [ -n "$TURN_STARTED_AT" ]; then
    # ISO strings sort lexicographically. Count reply-tool calls with ts >= turn_started_at.
    # Normalize both sides to strip `.SSSZ` → `Z` so format mismatch between writers
    # (Kai audit finding #3) doesn't cause false comparisons at second boundaries.
    TURN_NORMALIZED="$(echo "$TURN_STARTED_AT" | sed -E 's/\.[0-9]+Z$/Z/')"

    # A16 fix: a turn that straddles UTC midnight has its reply-tool call in
    # yesterday's audit file, not today's. Read both the turn-start-day file
    # AND today's file. Dedupe if they're the same path.
    TURN_DAY="$(echo "$TURN_STARTED_AT" | cut -c1-10)"
    TODAY="$(date -u +%Y-%m-%d)"
    audit_paths=("$REPO_ROOT/data/audit/${TURN_DAY}.jsonl")
    if [ "$TURN_DAY" != "$TODAY" ]; then
      audit_paths+=("$REPO_ROOT/data/audit/${TODAY}.jsonl")
    fi

    REPLY_COUNT=0
    for ap in "${audit_paths[@]}"; do
      [ -f "$ap" ] || continue
      c="$(jq -rc --arg since "$TURN_NORMALIZED" '
        select(.tool == "mcp__plugin_telegram_telegram__reply") |
        select((.ts | sub("\\.[0-9]+Z$"; "Z")) >= $since)
      ' "$ap" 2>/dev/null | wc -l | tr -d ' ')"
      REPLY_COUNT=$((REPLY_COUNT + c))
    done

    if [ "$REPLY_COUNT" = "0" ]; then
      VIOLATIONS+=("must_use_reply_tool: zero reply-tool calls in audit after turn start ($TURN_STARTED_AT) — Telegram turn ended without replying on Telegram")
    fi
  fi
fi

# --- Log any violations ---
if [ ${#VIOLATIONS[@]} -gt 0 ]; then
  for v in "${VIOLATIONS[@]}"; do
    # Extract category hint from the violation message
    CATEGORY="forgot-telegram-reply"
    DESC="stop-verify-contract auto-detected: $v"
    bash "$REPO_ROOT/scripts/log-correction.sh" "$CATEGORY" "$DESC" >/dev/null 2>&1 || true
    echo "⚠️ contract violation logged: $CATEGORY" >&2
  done
fi

# Clean up for next turn
rm -f "$CONTRACT_FILE"
exit 0
