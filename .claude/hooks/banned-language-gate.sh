#!/usr/bin/env bash
# XANTHAM BANNED-LANGUAGE GATE
#
# PreToolUse hook that blocks the orchestrator from emitting banned words /
# phrases defined by the App Store compliance handbook. Fires on:
#   - mcp__plugin_telegram_telegram__reply  (every Telegram outbound)
#   - Write / Edit when file_path matches BANNED_LANG_GATE_PATHS
#
# Exit-code contract (matches safety-gate.sh):
#   exit 0 = allow
#   exit 2 = block (reason on stderr)
#
# Block message format:
#   BLOCKED (banned-language): "<word>" detected in <context>.
#     Snippet: <±20 chars>
#     Suggested alternative: <safe alternative>
#     Source: Library/app-store-compliance/banned-language-list.md
#     If this is a legitimate use, add to:
#     Library/app-store-compliance/banned-language-allowlist.md
#
# Sources:
#   Library/app-store-compliance/banned-language-list.md       (the ban list)
#   Library/app-store-compliance/banned-language-allowlist.md  (exceptions)
#
# Configuration:
#   BANNED_LANG_GATE_PATHS  regex of file_paths to lint on Write/Edit
#                           (default below). Telegram replies are ALWAYS linted.
#   BANNED_LANG_GATE_DEBUG  set to "1" to write per-fire timing + decisions
#                           to logs/banned-language-gate.log
#   BANNED_LANG_GATE_OFF    set to "1" to bypass entirely (emergency switch)
#
# Performance: target <50ms per fire. Allowlist parsed once and cached at
# data/runtime/banned-lang-cache.tsv (60s TTL).
#
# Scope: enforces App Store compliance rules (medical claims, marketing
# superlatives, AI tells) across both messaging-tool replies AND files
# written under Library/ docs/ and project copy dirs. Composable with any
# orchestrator-voice lint hook installed alongside.

set -uo pipefail

# === EMERGENCY BYPASS ==================================================
if [ "${BANNED_LANG_GATE_OFF:-0}" = "1" ]; then
  exit 0
fi

# === INPUT =============================================================
INPUT="$(cat)"
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
TEXT=$(printf '%s' "$INPUT" | jq -r '.tool_input.text // empty' 2>/dev/null)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)
WRITE_CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null)
EDIT_NEW=$(printf '%s' "$INPUT" | jq -r '.tool_input.new_string // empty' 2>/dev/null)

# === SCOPE GATE ========================================================
# Decide whether THIS fire is in scope. Telegram replies always are.
# Write/Edit only when file_path matches BANNED_LANG_GATE_PATHS.

DEFAULT_PATH_RE='(^|/)(Library|docs)/|/(en|en\.lproj|en-GB|Localization|Localized|Strings)/.*\.(strings|swift|kt|tsx?|jsx?|md)$|InfoPlist\.strings|Info\.plist'
PATH_RE="${BANNED_LANG_GATE_PATHS:-$DEFAULT_PATH_RE}"

LINT_TARGET=""
LINT_KIND=""

case "$TOOL_NAME" in
  mcp__plugin_telegram_telegram__reply)
    LINT_TARGET="$TEXT"
    LINT_KIND="telegram-reply"
    ;;
  Write)
    if [ -n "$FILE_PATH" ] && printf '%s' "$FILE_PATH" | grep -qE "$PATH_RE"; then
      LINT_TARGET="$WRITE_CONTENT"
      LINT_KIND="write:$FILE_PATH"
    fi
    ;;
  Edit)
    if [ -n "$FILE_PATH" ] && printf '%s' "$FILE_PATH" | grep -qE "$PATH_RE"; then
      LINT_TARGET="$EDIT_NEW"
      LINT_KIND="edit:$FILE_PATH"
    fi
    ;;
esac

# Out of scope or empty input -> allow.
if [ -z "$LINT_TARGET" ]; then
  exit 0
fi

# === PATHS =============================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BAN_LIST="$REPO_ROOT/Library/app-store-compliance/banned-language-list.md"
ALLOW_LIST="$REPO_ROOT/Library/app-store-compliance/banned-language-allowlist.md"
CACHE_DIR="$REPO_ROOT/data/runtime"
CACHE_FILE="$CACHE_DIR/banned-lang-cache.tsv"
LOG_FILE="$REPO_ROOT/logs/banned-language-gate.log"
mkdir -p "$CACHE_DIR" "$REPO_ROOT/logs" 2>/dev/null

# If the ban list is missing, fail open with a stderr warning so workflow
# isn't broken in worktrees that haven't synced it yet.
if [ ! -f "$BAN_LIST" ]; then
  printf 'banned-language-gate: ban list not found at %s, allowing\n' "$BAN_LIST" >&2
  exit 0
fi

# === BAN-LIST + ALLOWLIST PARSING ======================================
# Cached for 60 seconds across hook fires within the same session. The cache
# format is a TSV with three sections separated by sentinel lines:
#   #BANNED
#   <word>\t<safe-alternative>
#   ...
#   #ALLOW_LITERAL
#   <lower-cased-substring>
#   ...
#   #ALLOW_REGEX
#   <pattern>
#   ...

NOW_EPOCH=$(date +%s)
CACHE_AGE=999999
if [ -f "$CACHE_FILE" ]; then
  CACHE_MTIME=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || printf 0)
  CACHE_AGE=$((NOW_EPOCH - CACHE_MTIME))
fi

# Also bust cache if either source file is newer than cache.
SHOULD_REBUILD=0
if [ "$CACHE_AGE" -gt 60 ]; then
  SHOULD_REBUILD=1
fi
if [ -f "$CACHE_FILE" ]; then
  for src in "$BAN_LIST" "$ALLOW_LIST"; do
    if [ -f "$src" ] && [ "$src" -nt "$CACHE_FILE" ]; then
      SHOULD_REBUILD=1
    fi
  done
else
  SHOULD_REBUILD=1
fi

if [ "$SHOULD_REBUILD" = "1" ]; then
  {
    printf '#BANNED\n'
    # Parse banned-language-list.md tables of shape:
    #   | banned | alternative | reason |
    # Skip header / separator rows (the ones containing only dashes / the
    # word "Banned" / "Why").
    perl -ne '
      next unless /^\s*\|\s*([^\|]+?)\s*\|\s*([^\|]+?)\s*\|/;
      my ($banned, $alt) = ($1, $2);
      next if $banned =~ /^[-:\s]+$/;
      next if $banned =~ /^banned$/i;
      next if $banned =~ /^banned in /i;
      next if $banned =~ /^banned naming /i;
      # Strip trailing "(...)" qualifier from banned column.
      $banned =~ s/\s*\(.*\)\s*$//;
      # Strip surrounding quotes the doc uses for natural-language phrases.
      $banned =~ s/^["“]//;
      $banned =~ s/["”]$//;
      $banned =~ s/^"//;
      $banned =~ s/"$//;
      # Skip empty / one-char artefacts.
      next if length($banned) < 2;
      # Strip surrounding quotes / backticks from alt too.
      $alt =~ s/^["`]//;
      $alt =~ s/["`]$//;
      # Empty alt -> use sensible default.
      $alt = "(rewrite — see compliance handbook)" if $alt =~ /^\s*$/;
      print "$banned\t$alt\n";
    ' "$BAN_LIST" | sort -u

    printf '#ALLOW_LITERAL\n'
    if [ -f "$ALLOW_LIST" ]; then
      perl -ne '
        next if /^\s*#/;
        next if /^\s*$/;
        if (/^literal:(.+)$/i) {
          my $p = $1;
          $p =~ s/^\s+|\s+$//g;
          print lc($p), "\n" if length $p;
        }
      ' "$ALLOW_LIST" | sort -u
    fi

    printf '#ALLOW_REGEX\n'
    if [ -f "$ALLOW_LIST" ]; then
      perl -ne '
        next if /^\s*#/;
        next if /^\s*$/;
        if (/^regex:(.+)$/i) {
          my $p = $1;
          $p =~ s/^\s+|\s+$//g;
          print "$p\n" if length $p;
        }
      ' "$ALLOW_LIST"
    fi
  } > "$CACHE_FILE.tmp" 2>/dev/null && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
fi

# === LINT ==============================================================
# Single-shot perl pass: strip code/quotes/links, then scan against the
# compiled banned word list, honouring the allowlist. First hit wins.

PERL_HELPER="$SCRIPT_DIR/banned-language-gate.pl"
if [ ! -f "$PERL_HELPER" ]; then
  printf 'banned-language-gate: helper missing at %s, allowing\n' "$PERL_HELPER" >&2
  exit 0
fi

# Only spend cycles on timing when debug is on.
if [ "${BANNED_LANG_GATE_DEBUG:-0}" = "1" ]; then
  START_NS=$(perl -MTime::HiRes=time -e 'printf "%d\n", time()*1000' 2>/dev/null || printf 0)
fi

DECISION=$(LINT_TARGET="$LINT_TARGET" CACHE_FILE="$CACHE_FILE" perl "$PERL_HELPER")

if [ "${BANNED_LANG_GATE_DEBUG:-0}" = "1" ]; then
  END_NS=$(perl -MTime::HiRes=time -e 'printf "%d\n", time()*1000' 2>/dev/null || printf 0)
  ELAPSED_MS=$((END_NS - START_NS))
fi

# === DECIDE ============================================================
if [ -n "$DECISION" ]; then
  WORD=$(printf '%s' "$DECISION" | awk -F'\t' '{print $2}')
  SNIPPET=$(printf '%s' "$DECISION" | awk -F'\t' '{print $3}')
  ALT=$(printf '%s' "$DECISION" | awk -F'\t' '{print $4}')

  MSG="BLOCKED (banned-language): \"$WORD\" detected in $LINT_KIND.
  Snippet: $SNIPPET
  Suggested alternative: $ALT
  Source: Library/app-store-compliance/banned-language-list.md
  If this is a legitimate use, add to:
  Library/app-store-compliance/banned-language-allowlist.md (literal: or regex: line)"

  printf '%s\n' "$MSG" >&2

  if [ "${BANNED_LANG_GATE_DEBUG:-0}" = "1" ]; then
    printf '[%s] BLOCK %sms kind=%s word=%s\n' \
      "$(date -Iseconds)" "$ELAPSED_MS" "$LINT_KIND" "$WORD" >> "$LOG_FILE"
  fi

  exit 2
fi

if [ "${BANNED_LANG_GATE_DEBUG:-0}" = "1" ]; then
  printf '[%s] PASS  %sms kind=%s\n' \
    "$(date -Iseconds)" "$ELAPSED_MS" "$LINT_KIND" >> "$LOG_FILE"
fi

exit 0
