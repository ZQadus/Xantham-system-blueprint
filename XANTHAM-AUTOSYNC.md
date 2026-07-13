# Xantham Auto-Sync — REMOVED for safety

**This feature has been removed. Updates are now MANUAL and EXPLICIT only.**

Earlier versions of this file described a `SessionStart` hook (`xantham-sync`)
that ran `git pull --ff-only` on the public Xantham repo and re-applied it to
the host **on every single session open**, automatically, with no operator
gate. That was removed because auto-pulling upstream changes into a live system
(one that may be running bots, a Telegram channel, and real work) on every
session is unsafe: an operator could receive upstream changes they never chose,
at a moment they never chose, with no chance to review first.

There is no "self-updating host" and no auto-update SessionStart hook anymore.
Nothing pulls or applies upstream on its own.

## How to update — you choose when

Updates only ever happen when **you** ask for them:

- **Update the orchestration habits + enforcement hooks:** tell your
  orchestrator `sync habits` (the `xantham-sync-habits` skill applies the latest
  `orchestration-habits.md` manifest), or run the manual CLI fallback:

  ```bash
  bash install-xantham-habits.sh --update
  ```

  It backs up every file it touches (`.pre-install` / `.pre-habits`) and is
  reversible with `bash install-xantham-habits.sh --uninstall`.

- **Add a specific extension:** `bash scripts/install-blueprint.sh --add E<N>`
  (extensions still need your consent + any brew/docker prerequisites; nothing
  installs an extension on its own).

- **Upgrade the blueprint itself:** re-run the wizard's customization-preserving
  upgrade path (three-way diff; it backs up first and preserves your
  `USER-CUSTOM-SECTION` blocks). It never blind-overwrites your work, and it
  refuses to fresh-install over an existing install (see the wizard's Q0
  install-safety gate).

## Why the change

Automatic, unattended, every-session updates into a potentially live system are
a foot-gun for anyone who installs this blueprint. Keeping updates manual and
explicit means you always review and choose. The full manual upgrade path above
is intact — only the auto-pull-every-session behaviour is gone.
