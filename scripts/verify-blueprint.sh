#!/usr/bin/env bash
# verify-blueprint.sh
# Downloads the Xantham blueprint files at a pinned commit SHA, computes SHA256
# checksums, and compares them against the CHECKSUMS.sha256 file in the repo.
#
# Run this BEFORE pasting the install prompt into Claude Code if you want
# cryptographic confirmation that the blueprint you are about to install
# matches the maintainer-published artifacts and has not been tampered with
# in transit or by a future-state repo compromise.
#
# Usage:
#   bash scripts/verify-blueprint.sh                 # verify latest (main)
#   bash scripts/verify-blueprint.sh <commit-sha>    # verify a pinned SHA
#
# Or one-line, no clone needed:
#   curl -fsSL https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/scripts/verify-blueprint.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/<sha>/scripts/verify-blueprint.sh | bash -s -- <sha>
#
# Exit codes:
#   0  every file matches its published checksum
#   1  one or more files diverged from the published checksum (do NOT install)
#   2  could not fetch a file or the checksums manifest (network or repo state)

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint"
REF="${1:-main}"
FILES=(
  "xantham-system-v35.md"
  "xantham-system-v34.md"
  "xantham-system-v32.md"
  "xantham-templates-v32.md"
  "LICENSE"
  "README.md"
  "SECURITY.md"
  "ARCHITECTURE.md"
  "COMPARISON.md"
)

# Cross-platform sha256 picker. macOS ships shasum; most Linux distros ship sha256sum.
if command -v sha256sum >/dev/null 2>&1; then
  SHA_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  SHA_CMD="shasum -a 256"
else
  echo "ERROR: neither sha256sum nor shasum is installed. Install one and retry." >&2
  exit 2
fi

WORK_DIR="$(mktemp -d -t xantham-verify-XXXXXX)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Xantham blueprint verifier"
echo "  ref:      $REF"
echo "  workdir:  $WORK_DIR"
echo "  hasher:   $SHA_CMD"
echo

# Fetch the published checksums manifest at the target ref.
MANIFEST_URL="$REPO_RAW/$REF/CHECKSUMS.sha256"
MANIFEST_PATH="$WORK_DIR/CHECKSUMS.sha256"
echo "Fetching manifest: $MANIFEST_URL"
if ! curl -fsSL "$MANIFEST_URL" -o "$MANIFEST_PATH"; then
  echo "ERROR: failed to fetch CHECKSUMS.sha256 from $MANIFEST_URL" >&2
  echo "  - If you pinned to a commit SHA, the SHA may not exist on the repo." >&2
  echo "  - If you pinned to 'main', check network connectivity." >&2
  exit 2
fi

# Fetch each blueprint file at the same ref.
echo
echo "Fetching blueprint files at ref=$REF ..."
for f in "${FILES[@]}"; do
  url="$REPO_RAW/$REF/$f"
  out="$WORK_DIR/$f"
  if ! curl -fsSL "$url" -o "$out"; then
    echo "ERROR: failed to fetch $f from $url" >&2
    exit 2
  fi
  echo "  pulled: $f ($(wc -c <"$out" | tr -d ' ') bytes)"
done

# Compute SHA256 for each and assemble an "actual" manifest in the canonical format.
echo
echo "Computing local SHA256 ..."
ACTUAL_PATH="$WORK_DIR/CHECKSUMS.actual"
( cd "$WORK_DIR" && $SHA_CMD "${FILES[@]}" ) >"$ACTUAL_PATH"

# Compare ONLY the file lines in the manifest (skip comment lines starting with #).
EXPECTED_PATH="$WORK_DIR/CHECKSUMS.expected"
grep -v '^#' "$MANIFEST_PATH" | grep -v '^$' >"$EXPECTED_PATH" || true

echo
echo "Expected (from CHECKSUMS.sha256 at ref=$REF):"
cat "$EXPECTED_PATH"
echo
echo "Actual (computed locally just now):"
cat "$ACTUAL_PATH"
echo

# Build a sorted comparison so file order does not matter.
if diff <(sort "$EXPECTED_PATH") <(sort "$ACTUAL_PATH") >/dev/null; then
  echo "OK: every file matches its published SHA256."
  echo "    Safe to proceed to install at ref=$REF."
  exit 0
else
  echo "MISMATCH: one or more files do NOT match the published checksum." >&2
  echo "          Diff (expected -> actual):" >&2
  diff <(sort "$EXPECTED_PATH") <(sort "$ACTUAL_PATH") >&2 || true
  echo >&2
  echo "Do NOT install this version. Possible causes:" >&2
  echo "  - The repo was compromised or files were edited after the manifest was signed." >&2
  echo "  - Your network is intercepting raw.githubusercontent.com (MITM)." >&2
  echo "  - You are pinning to a ref that pre-dates the current CHECKSUMS.sha256 format." >&2
  echo "  - The maintainer regenerated checksums on the same SHA without updating the manifest (open an issue)." >&2
  exit 1
fi
