#!/usr/bin/env bash
# preflight-guard.sh — fresh-install SAFETY guard for the Xantham wizard.
#
# The Xantham fresh-install runs Claude Code with --dangerously-skip-permissions
# and writes hundreds of files. If it were pointed at a directory that ALREADY
# contains an install (or any of the operator's own work), a naive fresh-install
# would OVERWRITE their CLAUDE.md, settings, memory, bots, secrets, and chat.
#
# This guard makes "install into an empty directory" a HARD GATE, not a
# suggestion. It is:
#   - the standalone / CI / manual form of the check, and
#   - the canonical logic mirrored inline in the wizard's Q0 Step 1 (which runs
#     BEFORE any file is written, since an empty fresh dir won't contain this
#     script yet).
#
# Usage:
#   bash scripts/preflight-guard.sh [TARGET_DIR]     # default: current dir
#
# Exit codes:
#   0  SAFE     — target is empty; OK to fresh-install.
#   3  EXISTING — an existing Xantham/agent install was detected. Do NOT
#                 fresh-install (it would clobber). Use the customization-
#                 preserving upgrade path instead (`sync habits`, or the
#                 wizard's three-way-diff upgrade / `install-blueprint.sh --add`).
#   4  NONEMPTY — target is not empty (but no install detected). A fresh install
#                 must run in a brand-new EMPTY directory. Pick an empty dir.
#   2  usage    — bad arguments / target not a directory.

set -uo pipefail

TARGET="${1:-.}"

if [ ! -d "$TARGET" ]; then
  echo "preflight-guard: target is not a directory: $TARGET" >&2
  exit 2
fi

TARGET_ABS="$(cd "$TARGET" && pwd)"

# --- Strong "existing install" markers: any ONE means refuse the fresh install.
# These are files/dirs the wizard (or a prior install) creates and that hold the
# operator's own state — clobbering any of them is the exact harm we prevent.
INSTALL_MARKERS=(
  "CLAUDE.md"
  ".claude/settings.json"
  "memory"
  "data"
  ".env"
  "USER-GUIDE.md"
  "SETUP-CHECKLIST.md"
  "agent-memory"
  "HANDOFF.md"
)

FOUND_MARKERS=()
for m in "${INSTALL_MARKERS[@]}"; do
  if [ -e "$TARGET_ABS/$m" ]; then
    FOUND_MARKERS+=("$m")
  fi
done

# A blueprint version marker (.<name>-blueprint-version) is also a definitive
# "already installed" signal, whatever the orchestrator was named.
while IFS= read -r vm; do
  [ -n "$vm" ] && FOUND_MARKERS+=("$(basename "$vm")")
done < <(find "$TARGET_ABS" -maxdepth 1 -name '.*-blueprint-version' 2>/dev/null)

if [ "${#FOUND_MARKERS[@]}" -gt 0 ]; then
  echo "EXISTING INSTALL DETECTED in: $TARGET_ABS" >&2
  echo "  markers: ${FOUND_MARKERS[*]}" >&2
  echo "" >&2
  echo "REFUSING to fresh-install — that would OVERWRITE the operator's own" >&2
  echo "CLAUDE.md / settings / memory / bots / secrets / chat." >&2
  echo "Use the customization-preserving path instead:" >&2
  echo "  - to add/upgrade habits:   say 'sync habits' (or bash install-xantham-habits.sh --update)" >&2
  echo "  - to add an extension:     bash scripts/install-blueprint.sh --add E<N>" >&2
  echo "  - to upgrade the blueprint: run the wizard's three-way-diff upgrade path" >&2
  echo "    (it backs up + preserves USER-CUSTOM-SECTION blocks; it never blind-overwrites)." >&2
  exit 3
fi

# --- No install markers. Is the directory otherwise empty? A fresh install must
# start clean. Ignore only benign OS/VCS noise so a freshly `mkdir`ed dir (which
# may already be a git repo, or have a .DS_Store) still counts as empty.
NONEMPTY=0
LEFTOVER=()
while IFS= read -r entry; do
  base="$(basename "$entry")"
  case "$base" in
    .|..|.DS_Store|.git|.gitkeep) continue ;;
    *) NONEMPTY=1; LEFTOVER+=("$base") ;;
  esac
done < <(find "$TARGET_ABS" -mindepth 1 -maxdepth 1 2>/dev/null)

if [ "$NONEMPTY" -eq 1 ]; then
  echo "TARGET DIR NOT EMPTY: $TARGET_ABS" >&2
  echo "  contains: ${LEFTOVER[*]}" >&2
  echo "" >&2
  echo "A fresh install must run in a brand-new EMPTY directory so it cannot" >&2
  echo "overwrite existing files. Create a new empty dir and run there, e.g.:" >&2
  echo "  mkdir ~/Documents/MyAgent && cd ~/Documents/MyAgent" >&2
  exit 4
fi

echo "SAFE: $TARGET_ABS is empty — OK to fresh-install."
exit 0
