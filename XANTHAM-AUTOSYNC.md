# Xantham Auto-Sync — self-updating downstream hosts

This lets a Claude Code agent that was bootstrapped from this public Xantham
repo keep itself up to date automatically. After **one** manual bootstrap, the
host pulls the latest Xantham and re-applies it to itself on **every session
start** — no more pasting the repo link and saying "upgrade".

It replaces the manual ritual: open the agent → paste
`github.com/ZQadus/Xantham-system-blueprint` → say "upgrade".

---

## What it does, each session

On every Claude Code session open, a `SessionStart` hook runs `xantham-sync`,
which:

1. Pulls this public repo into a local cache (`.xantham-cache/`) via
   `git pull --ff-only` — fast-forward only, never merges/rebases/resets.
2. Copies the refreshed blueprint docs into the host project's `blueprints/`.
3. Runs `install-blueprint.sh --auto` — a non-interactive clean-apply that bumps
   the blueprint version marker on a clean forward upgrade.
4. Logs one line to `data/runtime/xantham-sync.log`:
   `synced <old> -> <new>, copied N doc(s), applied: <summary>` or `no change`.

It is **idempotent** (a second run with nothing new = `no change`) and
**non-destructive**:

- A **diverged cache** (someone edited it, or upstream history was rewritten)
  → it STOPS with exit 3 and a message, instead of clobbering anything.
- An **ambiguous version state** (no marker, a downgrade, a malformed marker)
  → `install-blueprint.sh --auto` STOPS with exit 3 and a message.
- It **never installs an extension** on its own (those need your consent +
  brew/docker). New extensions are surfaced for a manual
  `bash scripts/install-blueprint.sh --add E<N>`.

So worst case, on any conflict you get a clear message and an untouched project,
not a silent mutation.

---

## One-time bootstrap

Run this **once** on the downstream host, after the host has been bootstrapped
from Xantham at least once (i.e. it already has `scripts/install-blueprint.sh`
and a blueprint version marker file).

### Prerequisites

- `git` on PATH.
- The host project already bootstrapped from Xantham (it has
  `scripts/install-blueprint.sh` and `.{{orchestrator_lower}}-blueprint-version`).
- **Windows:** install **Git for Windows** (gives you `git` + `bash`). With it
  you can use either the `.sh` or `.ps1` path. Without git-bash at all you
  cannot run git, so Git for Windows is required either way.

### Mac / Linux / Windows with git-bash

```bash
# from the host project root
bash scripts/install-xantham-autosync.sh
```

That registers the SessionStart hook. Verify:

```bash
bash scripts/install-xantham-autosync.sh --status   # -> INSTALLED
```

### Windows without a bash-friendly shell (PowerShell)

```powershell
# from the host project root, in PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install-xantham-autosync.ps1
```

This wires the **PowerShell** sync command by default, so the hook itself never
needs bash to run. (The sync step still shells out to `git` and to
`bash install-blueprint.sh --auto`; both ship with Git for Windows.) Verify:

```powershell
powershell -File scripts/install-xantham-autosync.ps1 -Status   # -> INSTALLED
```

### Make it go live

Restart the agent (start a fresh Claude Code session). On open, the SessionStart
hook fires and the first auto-sync runs. From then on it self-updates every
session.

You can also run a sync by hand any time:

```bash
bash scripts/xantham-sync.sh           # Mac/Linux/git-bash
# or
powershell -File scripts/xantham-sync.ps1   # Windows/PowerShell
```

---

## Config (optional)

Environment overrides, all optional:

| Var | Default |
|---|---|
| `XANTHAM_REPO_URL` | `https://github.com/ZQadus/Xantham-system-blueprint.git` |
| `XANTHAM_CACHE_DIR` | `<host>/.xantham-cache` |
| `XANTHAM_BRANCH` | `main` |

The self-installer respects `FORCE_VARIANT=sh|ps1` (bash) / `-Variant sh|ps1`
(PowerShell) if you want to force which sync command the hook runs.

---

## Uninstall

```bash
bash scripts/install-xantham-autosync.sh --uninstall
# or
powershell -File scripts/install-xantham-autosync.ps1 -Uninstall
```

Removes only the xantham-sync SessionStart entry; every other hook is left
intact. The `.xantham-cache/` directory is left on disk — delete it manually if
you want a clean slate.

---

## Troubleshooting

- **`STOP: ... cannot fast-forward ... (diverged)`** — the local cache has
  commits that aren't upstream. Easiest fix: delete `.xantham-cache/` and let
  the next run re-clone fresh.
- **`STOP: no ... -blueprint-version found`** — the host was never bootstrapped
  from Xantham. Run the interactive install first
  (`bash scripts/install-blueprint.sh`), then bootstrap auto-sync.
- **`STOP: marker version (...) is AHEAD of the shipped blueprint`** — the host
  is on a newer version than what the public repo currently ships. This is
  expected if you're testing locally ahead of a publish; it's a no-op-with-a-
  warning, not a failure to fix.
- **Nothing happens on session start** — confirm the hook is present
  (`--status`), and that your Claude Code version runs `SessionStart` hooks.
  Check `data/runtime/xantham-sync.log` for the last run's outcome.
