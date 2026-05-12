#!/usr/bin/env bash
# telegram-reply-reminder — UserPromptSubmit hook.
#
# Two jobs:
#   1. When the incoming prompt contains a Telegram channel tag, inject a
#      loud additionalContext reminder forcing the reply tool.
#   2. Write a per-turn CONTRACT to data/runtime/turn-contract.json (0600
#      perms) with the required guarantees. stop-verify-contract.sh reads
#      this at turn end to detect contract violations (reply-tool skipped,
#      em-dashes used, etc.) and auto-log corrections.
#
# Pattern: Rose external-research Finding #4 (roborhythms Task Contract) +
# Kai Gap #8 (one-shot UserPromptSubmit reminder was incomplete without a
# Stop-side check).
#
# Output contract:
#   stdout → JSON hookSpecificOutput with additionalContext. Exit 0.
#
# Cost: ~60 tokens per Telegram turn. Skipped on non-Telegram prompts.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PAYLOAD=$(cat)
PROMPT=$(echo "$PAYLOAD" | jq -r '.prompt // empty' 2>/dev/null)

RUNTIME_DIR="$REPO_ROOT/data/runtime"
mkdir -p "$RUNTIME_DIR" 2>/dev/null
chmod 700 "$RUNTIME_DIR" 2>/dev/null || true
CONTRACT_FILE="$RUNTIME_DIR/turn-contract.json"

# Only fire when this turn clearly originates from the Telegram plugin.
# STRUCTURAL signal, not raw substring — fixes the false-positive case where
# a terminal prompt quotes the channel tag (security review, transcript
# review, memory dumps). A genuine Telegram inbound has the tag at the start
# of the prompt (or after a newline) AND followed immediately by chat_id +
# message_id attributes.
IS_TELEGRAM_TURN=0
if [[ "$PROMPT" =~ (^|$'\n')\<channel[[:space:]]+source=\"plugin:telegram:telegram\"[[:space:]]+chat_id=\"[0-9]+\"[[:space:]]+message_id=\"[0-9]+\" ]]; then
  IS_TELEGRAM_TURN=1
fi

if [ "$IS_TELEGRAM_TURN" = "1" ]; then

  # --- Capture raw inbound text for memory / active-recall (if installed) ---
  RAW_USER_TEXT="$(printf '%s' "$PROMPT" | awk '
    /<channel[[:space:]]+source="plugin:telegram:telegram"/ {
      sub(/.*<channel[^>]*>/, "");
      if (match($0, /<\/channel>/)) {
        sub(/<\/channel>.*/, "");
        print;
        exit;
      }
      capture = 1;
      print;
      next;
    }
    capture && /<\/channel>/ { sub(/<\/channel>.*/, ""); print; exit }
    capture { print }
  ')"

  # Write raw inbound to data/runtime/inbound.txt so other hooks / skills
  # (active-recall, memory) can read it. Force 0600 perms.
  printf '%s' "$RAW_USER_TEXT" > "$RUNTIME_DIR/inbound.txt" 2>/dev/null
  chmod 600 "$RUNTIME_DIR/inbound.txt" 2>/dev/null || true

  # --- Inject the reply-tool reminder ---
  REMINDER=$'⚠️ TELEGRAM TURN — REPLY DISCIPLINE\n\nThis prompt came from Telegram. Your reply MUST go via the `mcp__plugin_telegram_telegram__reply` tool. Terminal/stdout text is INVISIBLE to the user on their phone.\n\nThis applies even when a skill drives the format. Skill instructions shape the CONTENT of the reply, not the CHANNEL. Every question, multiple-choice prompt, design section, or clarification goes through the reply tool. No exceptions.\n\nIf you are about to output a question or prompt as plain text, STOP and route it through the reply tool instead.'

  jq -n --arg ctx "$REMINDER" '{
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: $ctx
    }
  }'

  # --- Write the per-turn contract (umask 077 -> 0600 perms) ---
  TURN_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  TURN_STARTED_EPOCH="$(date +%s)"
  (
    umask 077
    jq -n \
      --arg ts "$TURN_STARTED_AT" \
      --argjson ts_epoch "$TURN_STARTED_EPOCH" \
      '{
        origin: "telegram",
        turn_started_at: $ts,
        turn_started_epoch: $ts_epoch,
        guarantees: {
          must_use_reply_tool: true,
          no_em_dashes: true,
          no_signoff: true,
          attribute_agents_if_routed: true
        }
      }' > "$CONTRACT_FILE" 2>/dev/null
  )
else
  # Non-Telegram turn — clear any stale contract so Stop hook doesn't mis-fire.
  rm -f "$CONTRACT_FILE" 2>/dev/null || true
fi

exit 0
