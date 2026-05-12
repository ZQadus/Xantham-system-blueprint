---
name: xantham-sync-habits
description: Use when the user sends "sync habits", "install habits", "update habits", or any phrasing that asks for the orchestration-habits.md manifest to be applied. Fetches the latest orchestration-habits.md from the public Xantham repo, parses the embedded YAML manifest, runs every install command via Bash (skills, plugins, hooks, library files, settings.json patches), verifies each step, then reports back on the messaging channel with installed counts. Idempotent. Logs to data/xantham-habits-install.log.
---

# xantham-sync-habits

The orchestrator's autonomous habits installer. When the user says `sync habits` (or `install habits` / `update habits`), this skill runs every install step itself via the Bash tool. The user does not type install commands.

## Trigger

- `sync habits`
- `install habits`
- `update habits`
- `pull habits`
- "make sure my orchestrator has the latest discipline"
- any variation referencing the habits manifest

## The flow

1. **Acknowledge first** on the messaging channel: "Syncing habits. Pulling latest manifest from the Xantham public repo." Always reply-first per `[[orchestration-habits#reply-discipline]]`.

2. **Fetch the manifest**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/orchestration-habits.md \
     -o blueprints/orchestration-habits.md
   ```
   If the project does not have a `blueprints/` dir, `mkdir -p blueprints/` first.

3. **Parse the YAML manifest** embedded in the fenced ```yaml block under the `## Manifest` section. Two approaches:
   - **yq** if available: `yq eval '.skills, .hooks, .plugins, .library, .settings_patches, .verify' blueprints/orchestration-habits.md`
   - **python fallback**: extract the YAML fence with sed and parse with `python3 -c "import yaml,sys; print(yaml.safe_load(sys.stdin))"`. PyYAML ships with most Python installs; if not, fall back to manual grep + parsing.
   - **jq fallback** if YAML libraries are unavailable: convert the YAML to JSON via a tiny python one-liner first.

4. **Skills**: walk the `skills:` list. For each entry where `install: blueprint-generated`, check `.claude/skills/<name>/SKILL.md` exists. If missing, the user is on a partial install and should be told the full Xantham blueprint wizard generates these skills. Surface as a warning, do not attempt to fabricate skill bodies.

5. **Hooks**: walk the `hooks:` list. For each entry:
   - `curl -fsSL <src> -o <dest>`
   - `chmod +x <dest>`
   - If `requires:` lists peer files, install those too (already covered by the `library:` section in the manifest for banned-language).
   - Log each install to `data/xantham-habits-install.log` with timestamp + dest.

6. **Plugins**: walk the `plugins:` list. For each marketplace entry:
   - `claude plugin marketplace add <marketplace_repo>`
   - For each plugin slug in `plugins:`: `claude plugin install <slug>@<marketplace_repo>`
   - These are idempotent at the CLI level (re-running is safe).

7. **Library files**: walk the `library:` list. `curl -fsSL <src> -o <dest>` for each. Create parent directories first.

8. **Settings.json patches**: walk the `settings_patches:` list. For each entry's `jq:` block:
   - Backup current settings.json to `.claude/settings.json.pre-habits-<timestamp>` (idempotent: only if `.pre-habits` doesn't already exist)
   - `jq '<jq-expression>' .claude/settings.json > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json`
   - Each jq expression is idempotent (checks `any(...)` before appending).

9. **Verify**: walk the `verify:` list. Each entry is a shell test that should pass after install. Capture pass/fail counts.

10. **Patch CLAUDE.md** if not already done: append `@import blueprints/orchestration-habits.md` once. Check first with `grep -qF "@import blueprints/orchestration-habits.md" CLAUDE.md` before appending.

11. **Report back** on the messaging channel using the manifest's `report_template:` field. Substitute counts. Example:
    ```
    Habits synced. v1.0.0.
    Installed: 7 skills, 1 plugin, 5 hooks, 2 library files.
    Settings patches applied: 3.
    Verification: 7/7 passed.
    Restart the session to load new hooks.
    ```

12. **If anything failed**, list the failures explicitly in the report and write them to `data/xantham-habits-install.log`. Do not claim success when any verify step failed.

## Idempotency rules

- Hooks: re-running overwrites with the latest version. Acceptable — manifest is the source of truth.
- Skills: never overwrite an existing SKILL.md without telling the user. If a skill name collides with an existing one, warn and skip.
- Plugins: `claude plugin install` is a no-op for installed plugins. Safe to re-run.
- Library files: overwrite with the latest (these are reference data).
- Settings.json patches: each jq expression checks `any(...)` before mutating. Safe to re-run.
- CLAUDE.md `@import` line: `grep -qF` check prevents duplicate import.

## Cost guard

If the manifest grows to dispatch 20+ install steps in one run, batch the verify pass at the end rather than per-step. Each verify call is local and cheap.

## Logging

Append every action to `data/xantham-habits-install.log`:

```
<ISO-8601 timestamp>	<step>	<target>	<status>
```

Example:
```
2026-05-12T14:23:01Z	hook	telegram-reply-reminder.sh	installed
2026-05-12T14:23:02Z	hook	banned-language-gate.sh	installed
2026-05-12T14:23:02Z	library	banned-language-list.md	installed
2026-05-12T14:23:03Z	settings_patch	UserPromptSubmit	applied
2026-05-12T14:23:03Z	verify	test -x .claude/hooks/telegram-reply-reminder.sh	pass
```

## When NOT to use this skill

- The user is on a brand-new install and has not yet run the wizard. Direct them to clone the public repo and walk the v31 blueprint first; sync-habits installs the habits LAYER on top of a base install.
- The user explicitly asked for a manual review of what would change. Run with their explicit confirmation; never fire the install path on an "explain what habits would do" question.
- The user has local hook customisations they have not committed. Detect via `git status .claude/hooks/` — if dirty, warn and ask before overwriting.

## Cross-links

- `[[orchestration-habits#install-skills]]` is the source rule that this skill implements.
- `[[orchestration-habits#reply-discipline]]` for the always-reply-first rule that wraps every step.
- `[[orchestration-habits#verification-before-completion]]` for the verify pass after install.
