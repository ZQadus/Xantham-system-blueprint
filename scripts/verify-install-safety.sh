#!/usr/bin/env bash
# verify-install-safety.sh
# Regression guard for the three install/update safety properties this blueprint
# MUST hold so it is safe to hand to anyone (fix/install-safety-2026-07-13):
#
#   FIX 1  Updates are MANUAL + EXPLICIT. No auto-update-every-session
#          SessionStart hook, no self-installing autosync subsystem.
#   FIX 2  The banned-language gate is ADVISORY. It can never hard-deny the
#          operator's own Write / Edit / Read or their messaging (always exit 0).
#   FIX 3  The fresh install refuses to clobber: an existing install or a
#          non-empty directory is a HARD bail (scripts/preflight-guard.sh).
#
# Run from anywhere: bash scripts/verify-install-safety.sh
# Exit 0 = all properties hold. Exit 1 = at least one regressed.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "== FIX 1: updates are manual + explicit (no auto-update-every-session) =="
# The dangerous artifacts must be gone: the self-installer template and the
# "self-updating downstream hosts" live subsystem. Only 'REMOVED' stubs may
# mention them.
if grep -rqnE "One-time self-installer .*Registers a .SessionStart. hook .*runs" "$REPO"/*.md 2>/dev/null; then
  bad "an autosync SessionStart self-installer template is still present"
else
  ok "no autosync SessionStart self-installer template"
fi
if grep -rqnE "^# Xantham Auto-Sync subsystem \(self-updating downstream hosts\)" "$REPO"/*.md 2>/dev/null; then
  bad "the live 'self-updating downstream hosts' subsystem section is still present"
else
  ok "no live self-updating subsystem section (stub only)"
fi

echo "== FIX 2: banned-language gate is advisory (never hard-denies) =="
GATE="$REPO/.claude/hooks/banned-language-gate.sh"
if [ ! -f "$GATE" ]; then
  bad "banned-language-gate.sh missing"
else
  # Static: no 'exit 2' in code (comments describing safety-gate.sh are ok).
  if grep -nE "^[[:space:]]*exit 2([[:space:]]|$)" "$GATE" >/dev/null 2>&1; then
    bad "banned-language-gate.sh still has an 'exit 2' (blocking) code path"
  else
    ok "banned-language-gate.sh has no blocking exit 2 in code"
  fi
  # Behavioral: a Write to a docs/ file with a banned word must exit 0 (proceed).
  if command -v jq >/dev/null 2>&1 && [ -f "$REPO/.claude/hooks/banned-language-gate.pl" ] \
     && [ -f "$REPO/Library/app-store-compliance/banned-language-list.md" ]; then
    printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"docs/x.md","content":"this is clinically proven"}}' \
      | bash "$GATE" >/dev/null 2>&1
    rc=$?
    if [ "$rc" -eq 0 ]; then ok "Write with a banned word is NOT blocked (exit 0)"; else bad "Write with a banned word returned exit $rc (should be 0)"; fi
    # And a Telegram reply with a banned word must also exit 0.
    printf '%s' '{"tool_name":"mcp__plugin_telegram_telegram__reply","tool_input":{"text":"clinically proven"}}' \
      | bash "$GATE" >/dev/null 2>&1
    rc=$?
    if [ "$rc" -eq 0 ]; then ok "Telegram reply with a banned word is NOT blocked (exit 0)"; else bad "Telegram reply returned exit $rc (should be 0)"; fi
    # Clean up the runtime artifacts the gate wrote during this probe.
    rm -f "$REPO/data/runtime/banned-lang-cache.tsv" "$REPO/logs/banned-language-gate.log" 2>/dev/null
    rmdir "$REPO/data/runtime" "$REPO/data" "$REPO/logs" 2>/dev/null || true
  else
    echo "  SKIP: behavioral gate probe (needs jq + gate .pl + ban list)"
  fi
fi

echo "== FIX 3: fresh install refuses to clobber (preflight-guard hard bail) =="
GUARD="$REPO/scripts/preflight-guard.sh"
if [ ! -x "$GUARD" ]; then
  bad "scripts/preflight-guard.sh missing or not executable"
else
  T="$(mktemp -d)"
  bash "$GUARD" "$T" >/dev/null 2>&1; [ $? -eq 0 ] && ok "empty dir -> proceed (exit 0)" || bad "empty dir did not return 0"
  touch "$T/CLAUDE.md"
  bash "$GUARD" "$T" >/dev/null 2>&1; [ $? -eq 3 ] && ok "existing install (CLAUDE.md) -> bail (exit 3)" || bad "existing install did not return 3"
  rm "$T/CLAUDE.md"; touch "$T/random.txt"
  bash "$GUARD" "$T" >/dev/null 2>&1; [ $? -eq 4 ] && ok "non-empty dir -> bail (exit 4)" || bad "non-empty dir did not return 4"
  rm -rf "$T"
fi

echo ""
echo "verify-install-safety: $PASS pass, $FAIL fail"
[ "$FAIL" -gt 0 ] && exit 1 || exit 0
