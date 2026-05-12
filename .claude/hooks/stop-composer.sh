#!/usr/bin/env bash
# stop-composer — sequential runner of all Stop-time hooks.
#
# Claude Code settings.json Stop hook array runs hooks in order, but grouping
# them via a composer script gives us cleaner error-handling semantics AND
# documents the intended ordering in one place.
#
# Order:
#   1. session-end-verify.sh     — unpushed/uncommitted/drift check
#   2. stop-verify-contract.sh   — per-turn contract violations
#   3. session-end-sync.sh       — HANDOFF auto-write + sleep-time reflection
#
# Each hook has a HARD timeout (adversarial audit safety: a hung Stop hook
# could prevent session-end entirely, stranding Zaki). 30s per hook is
# generous — real hooks finish in <5s.
#
# All hooks MUST always exit 0 so they don't block session-end. Any non-zero
# exit or timeout is swallowed with `|| true`.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.claude/hooks"

# Helper: run a hook with a 30s hard timeout. macOS doesn't ship `timeout`
# or `gtimeout` by default — Kai Finding #K3 flagged that this meant the
# 30s guarantee was vapour on a stock Mac. Now we fall back to a
# bash-native timeout via background kill-watcher so the guarantee holds
# regardless of coreutils presence.
bash_timeout_run() {
  local duration=$1
  shift
  "$@" &
  local pid=$!
  ( sleep "$duration" && kill -9 "$pid" >/dev/null 2>&1 ) &
  local watcher=$!
  local rc=0
  wait "$pid" 2>/dev/null || rc=$?
  kill -9 "$watcher" >/dev/null 2>&1 || true
  wait "$watcher" 2>/dev/null || true
  return "$rc"
}

run_bounded() {
  local hook="$1"
  if command -v timeout >/dev/null 2>&1; then
    timeout 30 bash "$hook" || true
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout 30 bash "$hook" || true
  else
    bash_timeout_run 30 bash "$hook" || true
  fi
}

run_bounded "$HOOKS_DIR/session-end-verify.sh"
run_bounded "$HOOKS_DIR/stop-verify-contract.sh"

# S5 fix: session-end-sync.sh is wired to SessionEnd in settings.json. Stop
# fires on every assistant message — running the sync here would rebuild
# HANDOFF.md on every reply, producing dirty git diffs and wasted work. Stop
# hook is now per-turn safety (verify + contract) only. Session-close work
# runs exactly once via SessionEnd.

exit 0
