#!/usr/bin/env bash
# install-xantham-habits.sh
#
# Manual CLI fallback for installing the Xantham orchestration habits +
# enforcement hooks on an existing Claude Code project.
#
# THE NORMAL PATH IS: tell your orchestrator "sync habits" and let the
# xantham-sync-habits skill do this work autonomously. This script exists
# only for CI / scripted installs / brand-new repos that do not yet have
# an orchestrator agent loaded.
#
# Usage:
#   bash install-xantham-habits.sh             # apply
#   bash install-xantham-habits.sh --update    # re-pull + re-wire
#   bash install-xantham-habits.sh --dry-run   # show what would change
#   bash install-xantham-habits.sh --uninstall # restore backups
#
# Windows users: run inside Git Bash. PowerShell-native variants are noted.

set -uo pipefail

REPO_BASE="${XANTHAM_REPO_BASE:-https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main}"
HOOK_FILES=(
  "telegram-reply-reminder.sh"
  "banned-language-gate.sh"
  "banned-language-gate.pl"
  "stop-verify-contract.sh"
  "stop-composer.sh"
  "agent-dispatch-pre.sh"
  "agent-dispatch-post.sh"
  "safety-gate.sh"
)
LIBRARY_FILES=(
  "Library/app-store-compliance/banned-language-list.md"
  "Library/app-store-compliance/banned-language-allowlist.md"
)
SKILL_FILES=(
  ".claude/skills/xantham-sync-habits/SKILL.md"
  ".claude/skills/xantham-21st-bridge/SKILL.md"
  ".claude/skills/xantham-ai-seo/SKILL.md"
  ".claude/skills/xantham-memory/SKILL.md"
  ".claude/skills/xantham-spec-kit-bridge/SKILL.md"
)
# NOTE: xantham-orchestration, xantham-reflection, and xantham-safety are NOT
# in this list on purpose. They are generated per-install by the full setup
# wizard (Q14+ in xantham-system-v35.md, bodies in xantham-templates-v32.md)
# because their content depends on your chosen orchestrator name and mode.
# This script only fetches the 5 skills that ship as static files in this repo.
HABITS_REL="blueprints/orchestration-habits.md"
DRY_RUN=0
UPDATE=0
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)   DRY_RUN=1; shift ;;
    --update)    UPDATE=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)   sed -n '1,25p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

PROJECT_ROOT="$(pwd)"
LOG="$PROJECT_ROOT/data/xantham-habits-install.log"

if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
  echo "error: CLAUDE.md not found in $PROJECT_ROOT" >&2
  echo "       run this from your orchestrator's repo root." >&2
  exit 1
fi

mkdir -p "$PROJECT_ROOT/data" "$PROJECT_ROOT/data/runtime" 2>/dev/null

say() { echo "[install-xantham-habits] $*"; }
log_action() {
  [ "$DRY_RUN" = "1" ] && return
  printf '%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" "$3" >> "$LOG"
}

# === Uninstall path ========================================================
if [ "$UNINSTALL" = "1" ]; then
  say "uninstalling habits"
  for f in "${HOOK_FILES[@]}"; do
    dest="$PROJECT_ROOT/.claude/hooks/$f"
    if [ -f "$dest.pre-install" ]; then
      mv "$dest.pre-install" "$dest"
    elif [ -f "$dest" ]; then
      rm "$dest"
    fi
  done
  [ -f "$PROJECT_ROOT/$HABITS_REL" ] && rm "$PROJECT_ROOT/$HABITS_REL"
  [ -f "$PROJECT_ROOT/CLAUDE.md.pre-habits" ] && mv "$PROJECT_ROOT/CLAUDE.md.pre-habits" "$PROJECT_ROOT/CLAUDE.md"
  # Restore settings.json from the pre-habits backup so the hook wiring (incl. the
  # banned-language-gate PreToolUse entry) is fully reversed. Without this, an
  # uninstall would leave the operator's settings.json patched.
  if [ -f "$PROJECT_ROOT/.claude/settings.json.pre-habits" ]; then
    mv "$PROJECT_ROOT/.claude/settings.json.pre-habits" "$PROJECT_ROOT/.claude/settings.json"
    say "restored .claude/settings.json from pre-habits backup"
  fi
  say "uninstall complete"
  exit 0
fi

# === Prereqs ===============================================================
for cmd in curl jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: missing prerequisite: $cmd" >&2
    echo "       Mac: brew install $cmd   Windows (Git Bash): pacman -S $cmd" >&2
    exit 1
  fi
done

# === Helper: download a file ==============================================
fetch_file() {
  local relpath="$1"
  local url="$REPO_BASE/$relpath"
  local dest="$PROJECT_ROOT/$relpath"
  mkdir -p "$(dirname "$dest")" 2>/dev/null

  if [ -f "$dest" ] && [ "$UPDATE" = "0" ]; then
    say "$relpath already present (use --update to refresh)"
    log_action "skip" "$relpath" "exists"
    return 0
  fi

  if [ "$DRY_RUN" = "1" ]; then
    say "[dry-run] would fetch $url -> $dest"
    return 0
  fi

  [ -f "$dest" ] && cp "$dest" "$dest.pre-install"

  if curl -fsSL "$url" -o "$dest" 2>/dev/null; then
    case "$relpath" in
      *.sh|*.pl) chmod +x "$dest" 2>/dev/null || true ;;
    esac
    say "installed $relpath"
    log_action "fetch" "$relpath" "installed"
    return 0
  else
    say "warn: failed to fetch $relpath from $url"
    log_action "fetch" "$relpath" "failed"
    return 1
  fi
}

# === Pull habits + hooks + library + skill =================================
# The habits file lives at the repo root; we install it locally to blueprints/
# so the @import in CLAUDE.md resolves cleanly.
mkdir -p "$PROJECT_ROOT/blueprints" 2>/dev/null
HABITS_DEST="$PROJECT_ROOT/$HABITS_REL"
HABITS_URL="$REPO_BASE/orchestration-habits.md"
if [ -f "$HABITS_DEST" ] && [ "$UPDATE" = "0" ]; then
  say "$HABITS_REL already present (use --update to refresh)"
elif [ "$DRY_RUN" = "1" ]; then
  say "[dry-run] would fetch $HABITS_URL -> $HABITS_DEST"
else
  [ -f "$HABITS_DEST" ] && cp "$HABITS_DEST" "$HABITS_DEST.pre-install"
  if curl -fsSL "$HABITS_URL" -o "$HABITS_DEST" 2>/dev/null; then
    say "installed $HABITS_REL"
    log_action "fetch" "$HABITS_REL" "installed"
  else
    say "warn: failed to fetch $HABITS_URL"
    log_action "fetch" "$HABITS_REL" "failed"
  fi
fi

for f in "${HOOK_FILES[@]}"; do
  fetch_file ".claude/hooks/$f"
done

for f in "${LIBRARY_FILES[@]}"; do
  fetch_file "$f"
done

for f in "${SKILL_FILES[@]}"; do
  fetch_file "$f"
done

# === Patch CLAUDE.md ======================================================
IMPORT_LINE="@import $HABITS_REL"
if grep -qF "$IMPORT_LINE" "$PROJECT_ROOT/CLAUDE.md" 2>/dev/null; then
  say "CLAUDE.md already imports the habits file"
else
  if [ "$DRY_RUN" = "0" ]; then
    cp "$PROJECT_ROOT/CLAUDE.md" "$PROJECT_ROOT/CLAUDE.md.pre-habits"
    printf '\n## Orchestration habits\n\n%s\n' "$IMPORT_LINE" >> "$PROJECT_ROOT/CLAUDE.md"
    say "appended @import to CLAUDE.md (backup at CLAUDE.md.pre-habits)"
    log_action "patch" "CLAUDE.md" "import-appended"
  else
    say "[dry-run] would append '$IMPORT_LINE' to CLAUDE.md"
  fi
fi

# === Settings.json wiring =================================================
SETTINGS="$PROJECT_ROOT/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  if [ "$DRY_RUN" = "0" ]; then
    [ ! -f "$SETTINGS.pre-habits" ] && cp "$SETTINGS" "$SETTINGS.pre-habits"
    TMP_OUT="$(mktemp)"
    jq '
      .hooks //= {} |
      .hooks.UserPromptSubmit //= [] |
      .hooks.UserPromptSubmit |= (
        if any(.hooks[]?.command == ".claude/hooks/telegram-reply-reminder.sh") then .
        else . + [{hooks: [{type: "command", command: ".claude/hooks/telegram-reply-reminder.sh"}]}]
        end
      ) |
      .hooks.Stop //= [] |
      .hooks.Stop |= (
        if any(.hooks[]?.command == ".claude/hooks/stop-composer.sh") then .
        else . + [{hooks: [{type: "command", command: ".claude/hooks/stop-composer.sh"}]}]
        end
      ) |
      .hooks.PreToolUse //= [] |
      .hooks.PreToolUse |= (
        if any(.matcher == "mcp__plugin_telegram_telegram__reply|Write|Edit") then .
        else . + [{matcher: "mcp__plugin_telegram_telegram__reply|Write|Edit", hooks: [{type: "command", command: ".claude/hooks/banned-language-gate.sh"}]}]
        end
      )
    ' "$SETTINGS" > "$TMP_OUT" && mv "$TMP_OUT" "$SETTINGS"
    say "patched .claude/settings.json (backup at settings.json.pre-habits)"
    log_action "patch" "settings.json" "hooks-wired"
  else
    say "[dry-run] would patch .claude/settings.json with 3 hook wirings"
  fi
else
  say "warn: no .claude/settings.json found. Run the v31 wizard first OR create the file manually."
fi

# === Verify ================================================================
PASS=0
FAIL=0
checks=(
  ".claude/hooks/telegram-reply-reminder.sh:x"
  ".claude/hooks/banned-language-gate.sh:x"
  ".claude/hooks/stop-verify-contract.sh:x"
  ".claude/hooks/stop-composer.sh:x"
  "Library/app-store-compliance/banned-language-list.md:f"
  ".claude/skills/xantham-memory/SKILL.md:f"
  "$HABITS_REL:f"
)
for c in "${checks[@]}"; do
  path="${c%:*}"; flag="${c#*:}"
  if [ "$flag" = "x" ]; then
    [ -x "$PROJECT_ROOT/$path" ] && PASS=$((PASS+1)) || { FAIL=$((FAIL+1)); say "fail: $path not executable"; }
  else
    [ -f "$PROJECT_ROOT/$path" ] && PASS=$((PASS+1)) || { FAIL=$((FAIL+1)); say "fail: $path missing"; }
  fi
done

say "verify: $PASS pass, $FAIL fail"
say "done. Restart any active Claude Code session so new hooks load."
say "Test the reply-discipline reminder: send a Telegram message; the hook should inject the TELEGRAM TURN context block."
[ "$FAIL" -gt 0 ] && exit 1 || exit 0
