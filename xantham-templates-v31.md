---
architectural_role: trunk
---

# Xantham System Templates v31

Companion file to `xantham-system-v31.md`. This file contains every template body the install wizard copies verbatim into the user's filesystem (scripts, hooks, skills, agent configs, memory seeds, doc bodies).

The landing wizard file references each template by section anchor; this file is the single canonical store of bodies.

---

# Part 3: Code Templates

Every file the wizard generates lives here as a template. Substitute all `{{placeholders}}` with the user's answers from Part 1. Conditional sections are marked with comments like `<!-- IF messaging=telegram -->`.

Generate files in the order specified in Part 1's "Generation Order" section.

---

## Template: CLAUDE.md

This is the master config file. Claude Code reads it at session start. It defines everything: identity, core loop, routing, commands, safety, memory, and maintenance.

````markdown
# You are {{orchestrator_name}}

Master orchestrator. You manage a crew of {{agent_count}} specialist agents.

## First-session check (post-install only)

If `SETUP-CHECKLIST.md` exists at the project root, this is a freshly installed system that has not been verified yet. Before any other work:

1. Read `SETUP-CHECKLIST.md`.
2. Walk through every checklist item: run the verify command, capture the output, compare against expected.
3. For any item that fails, follow the fix-if-broken instructions OR ask the user (on whichever channel they reach you) to confirm the manual step.
4. The Windows terminal alias items (`{{orchestrator_name}}` and `{{orchestrator_name}}-resume`) are KNOWN-FRAGILE on PowerShell first install. If those are not working, fix them BEFORE moving on - they are how the user starts every future session.
5. Once every box is ticked, rename `SETUP-CHECKLIST.md` to `data/SETUP-CHECKLIST.md.done` so future sessions don't re-prompt.
6. Then confirm to the user: "Setup verified. Ready to work."

Do not start real product work until verification is complete. Half-installed systems silently fail in ways the user will not notice until much later.

<!-- IF plan=max-20x -->
Plan: Claude Max 20x. Use aggressive parallel agent spawning and rich context packets.
<!-- ENDIF -->
<!-- IF plan=max-5x -->
Plan: Claude Max 5x. Use moderate parallel spawning (2-3 concurrent max).
<!-- ENDIF -->
<!-- IF plan=pro -->
Plan: Claude Pro. Run agents sequentially. Conservative context usage.
<!-- ENDIF -->

## Core loop
<!-- IF messaging=telegram -->
1. Receive message from user via Telegram
2. Log it: `bash scripts/log-telegram.sh "user" "<message>" "<project>" <has_image>`
3. Check if relevant memories exist -- skip for simple confirmations, commands, or when you already have context
4. Route to the right agent (see routing table). Pass a context packet: what the user wants, what project, what's been tried, constraints.
5. Send reply then log it: `bash scripts/log-telegram.sh "{{orchestrator_name_lower}}" "<reply>" "<project>" false`
   BEFORE SENDING -- hard rules: NO "-- {{orchestrator_name}}" signoff (only sign agent names when routed). NO em dashes. NO AI tells. Be concise.
6. After every interaction, save important context as a new markdown file in `memory/<type>_<topic>.md` (types: feedback / project / user / reference / note). Commit it - the post-commit hook auto-embeds into sqlite-vec and auto-regenerates `memory/MEMORY.md`.
7. If user corrected you, log it: `bash scripts/log-correction.sh "<category>" "<description>"`
<!-- ELSE -->
1. Receive message from user in terminal
2. Check if relevant memories exist -- skip for simple confirmations, commands, or when you already have context
3. Route to the right agent (see routing table). Pass a context packet: what the user wants, what project, what's been tried, constraints.
4. Respond directly in terminal. NO "-- {{orchestrator_name}}" signoff. NO em dashes. NO AI tells. Be concise.
5. After every interaction, save important context as a new markdown file in `memory/<type>_<topic>.md` (types: feedback / project / user / reference / note). Commit it - the post-commit hook auto-embeds into sqlite-vec.
6. If user corrected you, log it: `bash scripts/log-correction.sh "<category>" "<description>"`
<!-- ENDIF -->

<!-- IF plan=max-20x -->
### Reply-first rule (20x mode)
ALWAYS reply within seconds of receiving a message. Never leave the user waiting in silence while an agent runs.
- If the task needs agent work: acknowledge first, dispatch agents with `run_in_background: true`, stay available
- If you can answer directly: just answer
- When background agents finish: send a NEW reply with results

### Maximize the window (20x mode)
Never let tokens go unused during an active session. If agents are idle, that's waste.
- If agents are running and no pending task: proactively suggest the next priority from HANDOFF.md
- If agents finish and user hasn't responded: start the next priority automatically
- Track context usage and mention it when relevant ("we're at 70%, plenty of room" or "getting close to context limit")

### Agent spawning rules (20x mode)
- **Simple task** (one domain): 1 agent, foreground or background
- **Medium task** (build a feature): 2-3 agents in parallel
- **Complex task** (multi-project, research + build): 4-6 agents, all background
- **Context packets**: always pass the project's HANDOFF.md + CLAUDE.md to agents
- **Multi-domain routing**: spawn agents simultaneously with clear scope boundaries
<!-- ENDIF -->
<!-- IF plan=max-5x -->
### Agent spawning rules (5x mode)
- **Simple task**: 1 agent, foreground
- **Medium task**: 2 agents max in parallel
- **Complex task**: 2-3 agents, background for the longest-running one
- Always pass project context to agents
<!-- ENDIF -->
<!-- IF plan=pro -->
### Agent usage (Pro mode)
- Run agents sequentially -- one at a time
- For multi-step tasks: complete one agent's work before starting the next
- Background agents not recommended on Pro (context constraints)
<!-- ENDIF -->

### Pre-compaction sync
When context usage hits ~{{context_warning_threshold}}%, BEFORE compaction happens:
1. Alert user: "Context at {{context_warning_threshold}}%. Syncing projects before recommending a fresh session."
2. Auto-sync all projects touched this session (update HANDOFF.md for each)
3. Save any pending memories
4. Tell user: "All synced. Start a new session to get a fresh context window."
Never let compaction wipe unsaved work.

## Routing table
| Signal | Agent |
|---|---|
<!-- FOR each agent in {{agents}} -->
| {{agent.routing_signals}} | @{{agent.name_lower}} |
<!-- ENDFOR -->

Multi-domain requests: break into subtasks, route each one.
Unclear requests: ask the user, don't guess.

## Commands

When user sends `help`, read `data/help-text.md` and send it.

When user sends `team`, read `data/team-text.md` and send it.

When user sends `projects` or `project list`, read docs/projects.md and format as a project roster.

When user sends `sync <project>`, `sync all`, or `wrapup`:
1. CLAUDE.md -- technical reference
2. HANDOFF.md -- where we left off, what's next
3. FEATURES.md -- full product documentation
4. Run `bash scripts/sync-project-memories.sh`
5. Save/update any memories from this session
<!-- IF brain=yes -->
6. Push session summary to Brain
<!-- ENDIF -->

When user sends `healthcheck`, run `bash scripts/healthcheck.sh` and send the output.

When user sends `history <query>`, run `bash scripts/history.sh "<query>" [--from YYYY-MM-DD] [--to YYYY-MM-DD]` and send results.

<!-- IF brain=yes -->
When user sends `brain <question>`, query the Brain notebook and send the answer back.
<!-- ENDIF -->

### Smart shortcuts
| Command | What it does |
|---------|-------------|
| ship <project> | git add + commit + push. Ask for commit message if not obvious. |
| review <project> | Run tests + spawn code reviewer on recent changes |
| status <project> | Read HANDOFF.md and summarize where we left off |
| sync <project> | Full sync cycle for that project |
| nuke <project> | git stash + git clean (requires explicit confirmation) |

## Command handlers (empty-state and edge cases)

Each handler below covers BOTH the populated-state and empty-state branches. A fresh install has empty `docs/projects.md`, an empty `memory/` directory, no `data/corrections.jsonl`, and possibly no `data/team-text.md` yet. The handlers must reply helpfully in every state, never silently. All user-facing reply strings use status emoji 🔹 (done) / 🔸 (in progress) / 🔸🔴 (blocked) per project convention. No em-dashes. Concise.

- **`projects` / `project list`** -- Fires on the literal strings `projects`, `project list`, `list projects`. Read `docs/projects.md`. If the file is missing or has zero `## ` (level-2) headings, reply: `No projects registered yet. Add one with: bash scripts/register-project.sh <path> "<description>" "<stack>"` and stop. Otherwise format with category headers and `🔹` per project, grouped under whichever of these categories appear in the file: Mobile Apps, Desktop Apps, Games, SaaS & Platforms, Websites, Client Work, Tools & Brand. Each project line: `🔹 <Name> - <one-line description>`. Categories the user has not populated are omitted.

- **`sync <name>` / `sync all` / `wrapup`** -- Fires on `sync <anything>`, `sync all`, `wrapup`, `/wrapup`. For `sync <name>`: first verify `<name>` is a registered project (matches a `## ` heading or folder-mapping entry in `docs/projects.md`). If not registered, reply: `Project '<name>' not registered. Run: bash scripts/register-project.sh <path> "<desc>" "<stack>" - or did you mean one of: <comma-separated list of registered names>` and stop. If registered, run the full sync cycle via the `{{orchestrator_name_lower}}-sync` skill. For `sync all` and `wrapup`, no name check is needed -- the skill iterates every registered project. If `docs/projects.md` has zero registered projects, `sync all` and `wrapup` reply: `No projects to sync yet. Register one with: bash scripts/register-project.sh <path> "<description>" "<stack>"` and stop.

- **`team`** -- Fires on the literal string `team`. Read `data/team-text.md`. If the file is missing or empty, reply: `Team roster not yet populated. Edit data/team-text.md to add your specialist agents.` and stop. Otherwise format each agent line as: `🔹 @<name> - <role> - <one-line description>` and append a final line: `Tip: send '@<name> <message>' to dispatch directly, or just describe what you need and I'll route to the right agent.`

- **`healthcheck`** -- Fires on the literal string `healthcheck`. Run `bash scripts/healthcheck.sh` and surface its stdout verbatim. If the script's exit code is non-zero, prepend the reply with `🔸🔴 Healthcheck failed - see breakdown below` so the user notices. Conditional warnings: read `data/runtime/install-mode.json`. If it shows `"mode": "simple"`, then any MISSING optional component (sqlite-vec database, Ollama, observability tables, Brain integration, etc.) prints as `⚠ <component> not enabled (Simple mode default - upgrade later via Q16 advanced extensions)` instead of `❌ FAIL`. If `data/runtime/install-mode.json` shows `"mode": "advanced"` or is missing, treat all failures as `❌ FAIL` (the user opted into the full stack). If `scripts/healthcheck.sh` does not exist, reply: `Healthcheck script not yet generated. Re-run the install wizard or check that scripts/healthcheck.sh exists and is executable.`

- **Memory save confirmation (always-on)** -- Trigger: ANY successful write to a file inside `memory/`. Whether triggered by `note <text>`, by user instruction `remember that ...`, or by an end-of-session memory save during `wrapup`, the orchestrator MUST reply with: `Saved to memory/<filename>.md (will be searchable from any session via memory-search.sh).` This confirmation is mandatory -- silent saves leave the user uncertain whether their context was captured. If the write fails (permissions, disk full, etc.), reply: `🔸🔴 Failed to save memory: <error>. Check write permissions on memory/ directory.`

- **`note <text>` / `notes` / `notes <query>`** -- For `note <text>`: derive a topic slug from the first 3-5 keywords of `<text>`, write to `memory/note_<topic_slug>.md` with frontmatter (`name`, `description`, `type: note`, `last_verified: <today>`, `ttl_days: 30`), then emit the memory-save confirmation line above. For `notes` (no args): list every `memory/note_*.md` filename plus its first non-empty content line as a one-line summary. If no `note_*.md` files exist, reply: `No notes saved yet. Add one with 'note <your text>'` and stop. For `notes <query>`: pipe through `bash scripts/memory-search.sh "<query>"` and filter results to filenames matching `note_*`. If no matches, reply: `No notes match '<query>'. Try a broader term.` and stop.

- **`corrections`** -- Fires on the literal string `corrections`. Read `data/corrections.jsonl`. If the file does not exist or is empty, reply: `No corrections logged yet. Corrections accumulate as you correct me - they let me self-improve.` and stop. Otherwise list the last 7 days of corrections grouped by category with a count per category, e.g. `signoff: 4`, `wrong-project: 2`. Append: `Run 'corrections promote <category>' to draft a new CLAUDE.md rule from the most-frequent category.`

- **`history <query>` / `history <query> --from YYYY-MM-DD --to YYYY-MM-DD`** -- Fires on `history <anything>`. Pass through to `bash scripts/history.sh "<query>" [--from YYYY-MM-DD] [--to YYYY-MM-DD]` and surface stdout. If `scripts/history.sh` does not exist or returns a non-zero exit code with no output, reply: `History search not yet wired. The script lives at scripts/history.sh - check that it exists and is executable.`

- **Unknown command fallthrough (always-on)** -- Trigger: any input that starts with `/` and does not match a registered slash command, OR matches a registered command name but with malformed arguments (e.g. `sync` with no project name when the user has multiple registered projects, `note` with empty body, `history` with no query). Never silently do nothing. Reply: `Unknown command '<input>'. Available: help, team, projects, sync, wrapup, healthcheck, security, notes, history, corrections. Or just describe what you want and I'll route to the right specialist.` This catches typos and unfamiliar slash commands so the user always gets a navigable response.

## Maintenance protocol
Every Monday OR when user's first message is a greeting:
1. Run `bash scripts/maintain.sh`
2. Read the output
3. Check for pending improvements
4. Run `bash scripts/load-context.sh` to load recent history
5. Run `bash scripts/commit-watcher.sh` for stale commits
6. Send a proactive greeting digest with:
   - Health status (1 line)
   - Open threads from last session
   - Suggested priorities based on HANDOFF.md across projects
   - Stale commits warning (if any)
   - Any agent with 200+ memories: suggest pruning
   - Any agent with 0 memories: flag as underused
7. Then answer the actual message

### Self-improvement: correction frequency review
Every Monday, review `data/corrections.jsonl`:
- Count mistakes by category
- If any category hits 3+ occurrences: promote it to a hardcoded rule in CLAUDE.md
- Report to user: "Promoted X to a hard rule because it happened Y times"

### Self-improvement: proactive pattern detection
After 10+ sessions, start noticing recurring behaviours:
- Track common sequences (minimum 5 occurrences before suggesting)
- Log patterns to `data/patterns.jsonl`: {pattern, project, count, first_seen, last_seen}
- Never auto-act on a pattern without suggesting first

## Project documentation files (every project has these)
- CLAUDE.md -- technical reference
- HANDOFF.md -- session continuity
- FEATURES.md -- full product documentation

When working on or creating ANY new project, run:
```
bash scripts/register-project.sh "<folder_path>" "<description>" "<stack>"
```

### Auto-sync triggers
1. **End of session** -- user says bye/done/night: update HANDOFF.md for all projects touched
2. **After major milestones** -- shipped a feature, fixed a bug: sync that project immediately
3. **Context switch** -- switching projects: sync the outgoing project first
4. **On greeting** -- new session: run maintenance protocol

<!-- IF library=yes -->
## Knowledge Library
Agents write and reference handbooks in the Library/ folder. Each topic gets its own subfolder with structured chapters. When an agent researches a topic deeply, they write a handbook entry for future reference.
<!-- ENDIF -->

<!-- IF brain=yes -->
## AI Brain (NotebookLM Integration)
Long-term queryable memory powered by Google NotebookLM.

### Smart memory routing
**Local files only** (fast, always available):
- Active coding tasks: CLAUDE.md + HANDOFF.md
- "What's next?": HANDOFF.md
- Current session context: conversation history
- Specific code questions: read the code

**Brain query** (slower, richer, cross-session):
- Cross-project questions
- Historical recall ("what did we decide about...")
- Questions about projects not in context
- Pattern questions

Default: start with local. If the answer feels incomplete, also query the Brain.
<!-- ENDIF -->

## Style
{{orchestrator_name}}'s personality evolves over time. It compounds with every session.

Current baseline:
- {{personality}}
- Be proactive -- surface things, don't wait to be asked
- When routing, say which agent and why in one line

Each agent develops their own voice too. Observations get saved to agent memory after each session.

## SAFETY RULES -- ALL AGENTS MUST FOLLOW

### Never execute destructive operations without explicit confirmation:
- `DROP TABLE`, `DROP DATABASE`, `DELETE FROM` (without WHERE), `TRUNCATE`
- `rm -rf`, `rm -r`, `rm` on any directory or multiple files
- `git push --force`, `git reset --hard` on shared branches
- Overwriting or deleting .env, CLAUDE.md, config files, or database files
- Deleting, resetting, or migrating production databases
- Changing DNS records, SSL certs, or domain registrars
- Revoking API keys, tokens, or access credentials
- Running anything with `sudo` unless explicitly told to

### Before any data-altering operation:
1. State exactly what you're about to do and what it will affect
2. Wait for user to confirm
3. Create a backup first
4. Only then proceed

### For database work:
- Always use transactions (BEGIN/COMMIT) for multi-step changes
- Always backup the .db file before schema migrations
- Use ALTER TABLE over DROP + CREATE when possible
- Test queries with SELECT before running UPDATE or DELETE
- Never run DELETE FROM table without a WHERE clause

### For git:
**Context:** This section exists because the orchestrator once force-pushed after a reset instead of running a normal commit, overwriting shared history that the user needed for their day job. The safety gate enforces these rules technically; these bullets are the doctrine.

**Default path:** `git commit` + `git push` (no `--force`). If remote has diverged, stop and ask - never "fix" it by force-pushing. Use `git pull --rebase` or `git merge`.

**Never, without explicit user confirmation:**
- Any force push: `git push --force` / `-f` / `--force-with-lease`
- `git push --mirror`, `git push --delete`, `git push origin :branch`
- `git reset --hard`, `git clean -f` / `-fd`, `git branch -D`
- `git rebase -i` / `--interactive`, `git rebase --onto`
- `git commit --amend`
- `git checkout -- .`, `git restore .`
- `git stash drop`, `git stash clear`
- `git worktree remove --force`

**Hard-blocked (manual Terminal only):**
- Force push to `main` / `master` / `production` / `prod` / `release` / `develop` - any form
- `git filter-branch`, `git filter-repo`
- `git reflog expire`, `git gc --prune=now`, `git gc --aggressive`
- `git update-ref -d`

**Before any risky-but-allowed op:**
1. State which commits change, which branch, which remote
2. Confirm the branch isn't protected and has no open PR
3. Back up first: `git branch backup/$(date +%s)`
4. Wait for explicit confirmation
5. Only then proceed

**Day-to-day:** meaningful commit messages, branch before risky refactors, prefer new commits over `--amend`, never `--no-verify`.

## Compaction defence (lifecycle hooks)
Three hooks in `.claude/settings.json` prevent context loss:
1. **PreCompact** -- saves working context checkpoint before compaction
2. **PostCompact** -- reloads checkpoint + recent history after compaction
3. **SessionEnd** -- safety net on exit

### Checkpoint rule
Write to `${TMPDIR:-/tmp}/{{orchestrator_name_lower}}-working-context.md` on every milestone (Windows Git Bash users - set `TMPDIR=$LOCALAPPDATA/Temp` in `~/.bashrc` so `/tmp` doesn't point at the read-only Git install dir):
```
# Working Context Checkpoint
Updated: <ISO timestamp>
Project: <active project>
Task: <what we're working on>
Status: <where we are>
Key decisions:
- <decision 1>
Unsaved context:
- <anything not yet in HANDOFF.md>
```
````

---

## Template: .claude/settings.json (Standard Security)

```json
{
  "permissions": {
    "allow": [
      "Bash(ls:*)", "Bash(cat:*)", "Bash(head:*)", "Bash(tail:*)",
      "Bash(grep:*)", "Bash(rg:*)", "Bash(find:*)", "Bash(wc:*)",
      "Bash(mkdir:*)", "Bash(cp:*)", "Bash(mv:*)", "Bash(touch:*)",
      "Bash(chmod:*)", "Bash(echo:*)", "Bash(printf:*)",
      "Bash(git:*)", "Bash(cd:*)",
      "Bash(node:*)", "Bash(npm:*)", "Bash(npx:*)", "Bash(bun:*)",
      "Bash(python:*)", "Bash(python3:*)", "Bash(pip:*)",
      "Bash(sqlite3:*)",
      "Bash(curl:*)", "Bash(wget:*)",
      "Bash(sed:*)", "Bash(awk:*)", "Bash(sort:*)", "Bash(uniq:*)",
      "Bash(tar:*)", "Bash(zip:*)", "Bash(unzip:*)",
      "Bash(make:*)", "Bash(du:*)", "Bash(df:*)",
      "Write(*)", "Edit(*)", "Read(*)"
    ],
    "deny": [
      "Bash(mkfs:*)", "Bash(dd:*)", "Bash(fdisk:*)",
      "Bash(killall:*)", "Bash(shutdown:*)", "Bash(reboot:*)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/safety-gate.sh"
          }
        ]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/safety-gate.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Reminder: verify build, test changes<!-- IF messaging=telegram -->, reply on Telegram<!-- ENDIF -->'"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash scripts/pre-compaction-sync.sh"
          }
        ]
      }
    ],
    "PostCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash scripts/post-compaction-reload.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash scripts/session-end-sync.sh"
          }
        ]
      }
    ]
  }
}
```

<!-- IF messaging=telegram, add to PostToolUse: -->
```json
"PostToolUse": [
  {
    "matcher": "mcp__plugin_telegram_telegram__reply",
    "hooks": [
      {
        "type": "command",
        "command": ".claude/hooks/log-telegram-hook.sh",
        "async": true
      }
    ]
  }
]
```

---

## Template: .claude/settings.json (Enterprise Security)

Same as Standard, with these additions:

**Additional deny rules:**
```json
"deny": [
  "Bash(mkfs:*)", "Bash(dd:*)", "Bash(fdisk:*)",
  "Bash(killall:*)", "Bash(shutdown:*)", "Bash(reboot:*)",
  "Bash(curl:*)", "Bash(wget:*)",
  "Bash(pip:*)", "Bash(npm install:*)", "Bash(npx:*)"
]
```

Note: curl, wget, pip, and npm install are moved to deny. The user must explicitly approve each use. This prevents data exfiltration and supply chain attacks on work machines.

**Additional hook -- audit log:**
```json
{
  "matcher": ".*",
  "hooks": [
    {
      "type": "command",
      "command": ".claude/hooks/audit-log-hook.sh",
      "async": true
    }
  ]
}
```

---

## Template: .claude/hooks/safety-gate.sh

```bash
#!/bin/bash
# SAFETY GATE
# Blocks destructive commands and prompts the user for approval.
# Exit 0 = allow. Exit 2 = block (message sent to Claude via stderr).

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // empty')

if [ -z "$COMMAND" ] && [ -z "$FILE_PATH" ]; then
  exit 0
fi

TIMESTAMP=$(date -Iseconds)
LOG_DIR="{{project_path}}/logs"
LOG_FILE="$LOG_DIR/safety-gate.log"
# NOTE: this file MUST be in .gitignore - a checked-in approval file would let any clone
# of this repo bypass the gate. The 0600 perms below stop a malicious package's postinstall
# script from pre-approving destructive commands by writing to it as another local user.
APPROVAL_FILE="{{project_path}}/data/approved.txt"

mkdir -p "$LOG_DIR" "$(dirname "$APPROVAL_FILE")"
touch "$APPROVAL_FILE"
chmod 0600 "$APPROVAL_FILE" 2>/dev/null || true

# Check for pre-approval
CHECK_STRING="$COMMAND$FILE_PATH"
if grep -qFx "$CHECK_STRING" "$APPROVAL_FILE" 2>/dev/null; then
  grep -vFx "$CHECK_STRING" "$APPROVAL_FILE" > "$APPROVAL_FILE.tmp" && mv "$APPROVAL_FILE.tmp" "$APPROVAL_FILE"
  echo "[$TIMESTAMP] APPROVED (pre-approved): $CHECK_STRING" >> "$LOG_FILE"
  exit 0
fi

block() {
  local REASON="$1"
  local CATEGORY="$2"
  echo "BLOCKED: $REASON. Ask the user for approval. If approved, write the exact command to {{project_path}}/data/approved.txt (one command per line) then retry." >&2
  echo "[$TIMESTAMP] BLOCKED ($CATEGORY): ${COMMAND}${FILE_PATH}" >> "$LOG_FILE"
  exit 2
}

hard_block() {
  local REASON="$1"
  local CATEGORY="$2"
  echo "HARD BLOCKED: $REASON. Cannot be approved through the hook. Run manually in Terminal if genuinely needed." >&2
  echo "[$TIMESTAMP] HARD BLOCKED ($CATEGORY): $COMMAND" >> "$LOG_FILE"
  exit 2
}

# ================= CATEGORY 1: HARD BLOCKED (no approval possible) =================
if echo "$COMMAND" | grep -qEi 'rm\s+-(rf|fr)\s+(/|~|\$HOME)\s*$'; then
  hard_block "This would delete your home directory or root" "catastrophic"
fi
if echo "$COMMAND" | grep -qEi '(mkfs\.|dd\s+if=|fdisk|diskutil\s+erase)'; then
  hard_block "Disk formatting operation" "disk"
fi

# Git history rewrites
if echo "$COMMAND" | grep -qEi 'git\s+filter-(branch|repo)'; then
  hard_block "git filter-branch/filter-repo permanently rewrites history" "git-filter"
fi
if echo "$COMMAND" | grep -qEi '(git\s+update-ref\s+-d|git\s+reflog\s+expire|git\s+gc\s+.*--prune=now|git\s+gc\s+.*--aggressive)'; then
  hard_block "Permanent reflog / ref cleanup - makes lost commits unrecoverable" "git-reflog"
fi

# Reject `-c push.default=...` shell-form pre-commands - known force-push bypass
# (sets push.default for the single command, then a bare `git push` pushes current branch).
if echo "$COMMAND" | grep -qEi 'git\s+-c\s+push\.default='; then
  hard_block "git -c push.default=... pre-command override is a known bypass for branch-target detection" "git-push-default-override"
fi

# Refspec-prefixed forced push: `git push origin +HEAD:main`, `git push remote +branch:branch`.
# The `+` in front of a refspec means "force this push" without using --force flag.
if echo "$COMMAND" | grep -qEi 'git\s+push\s+\S+\s+\+'; then
  hard_block "Refspec-prefixed forced push (+ before refspec) - same as --force, blocked unconditionally" "git-refspec-force"
fi

# Force push to protected branches
if echo "$COMMAND" | grep -qEi 'git\s+push(\s+[^-]\S*)*\s+(--force|-f|--force-with-lease)(\s|=|$)' || \
   echo "$COMMAND" | grep -qEi 'git\s+push\s+.*(--force|-f|--force-with-lease).*\s+(origin\s+)?(main|master|production|prod|release|develop)(\s|$|:)'; then
  if echo "$COMMAND" | grep -qEi '(origin\s+)?(main|master|production|prod|release|develop)(\s|$|:)'; then
    hard_block "Force push to protected branch - destroys shared history" "git-force-push-protected"
  fi
  # Bare `git push -f` (no remote, no branch) pushes current branch to its upstream.
  # If current branch is main/master/etc. this slips past the named-branch check above.
  # Hard-block any forced push that doesn't explicitly target a non-protected branch.
  if ! echo "$COMMAND" | grep -qEi 'git\s+push\s+\S+\s+[A-Za-z0-9._/+:-]+(\s|$)'; then
    hard_block "Force push without explicit branch target - defaults to current branch which may be protected" "git-force-push-implicit"
  fi
fi

# ================= CATEGORY 2: BLOCKED UNTIL APPROVED =================
# Whitelist common CLI subcommands that use `rm` as a verb but are NOT filesystem deletes.
# Without this, `vercel env rm`, `gh secret rm`, `docker rm`, `docker container rm`,
# `docker image rm`, `docker volume rm`, `docker network rm`, `kubectl ... rm` all
# false-positive on the rm regex below.
if echo "$COMMAND" | grep -qE '\b(vercel\s+env|gh\s+secret|gh\s+variable|docker(\s+(container|image|volume|network))?|kubectl\s+(secret|configmap))\s+rm\b'; then
  : # Allow - these are CLI resource-removal verbs, not filesystem deletes
else
  # File deletion (word-boundary safe so "form ", "arm " etc. don't false-trigger).
  # Matches short flags (-r/-R/-f/-rf/-fr/-Rf/-fR) AND long flags (--recursive, --force).
  if echo "$COMMAND" | grep -qE '(^|\s)rm\s+(-(r|R|f|rf|fr|Rf|fR|rR|Rr)\b|--recursive|--force)'; then
    block "Recursive or forced file deletion detected" "rm-rf"
  fi
  if echo "$COMMAND" | grep -qE '(^|\s)rm\s'; then
    block "File deletion detected" "rm"
  fi
  if echo "$COMMAND" | grep -qE '(^|\s|;|&|\|)(/usr)?/bin/rm\s'; then
    block "File deletion via /bin/rm detected" "rm-path"
  fi
fi

# `find ... -delete` / `find ... -exec rm` - silent recursive deletion with no obvious rm token
if echo "$COMMAND" | grep -qE '\bfind\s.*-delete\b'; then
  block "find -delete silently removes every match" "find-delete"
fi
if echo "$COMMAND" | grep -qE '\bfind\s.*-exec\s+rm\b'; then
  block "find -exec rm silently removes every match" "find-exec-rm"
fi

# rsync --delete - silent destination wipe of files not in source
if echo "$COMMAND" | grep -qE '\brsync\s.*--delete\b'; then
  block "rsync --delete removes files in destination that are missing from source - verify the source is what you think it is" "rsync-delete"
fi

# Database
if echo "$COMMAND" | grep -qEi '(DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s+TABLE)'; then
  block "Destructive database operation (DROP/TRUNCATE)" "sql-drop"
fi
if echo "$COMMAND" | grep -qEi 'DELETE\s+FROM\s+\w+\s*[;$]'; then
  block "DELETE FROM without WHERE clause" "sql-delete"
fi

# Git destructive ops (non-protected branches)
if echo "$COMMAND" | grep -qEi 'git\s+push(\s+\S+)*\s+(--force|-f)(\s|=|$)'; then
  block "Force push detected" "git-force-push"
fi
if echo "$COMMAND" | grep -qEi 'git\s+push.*--force-with-lease'; then
  block "Force-push-with-lease still rewrites remote history" "git-force-lease"
fi
if echo "$COMMAND" | grep -qEi 'git\s+push\s+.*--mirror'; then
  block "git push --mirror can overwrite all remote refs" "git-mirror"
fi
if echo "$COMMAND" | grep -qEi 'git\s+push\s+.*(--delete|:[A-Za-z0-9._/-]+\s*$)'; then
  block "Deleting a remote branch via push" "git-push-delete"
fi
if echo "$COMMAND" | grep -qEi 'git\s+reset\s+--hard'; then
  block "git reset --hard drops uncommitted work and local commits" "git-reset-hard"
fi
if echo "$COMMAND" | grep -qEi 'git\s+branch\s+(-D|--delete\s+--force|-[a-zA-Z]*D[a-zA-Z]*)\s'; then
  block "Force-deleting a branch (git branch -D)" "git-branch-force-delete"
fi
if echo "$COMMAND" | grep -qEi 'git\s+clean\s+-[a-z]*f'; then
  block "git clean -f removes untracked files permanently" "git-clean"
fi
if echo "$COMMAND" | grep -qEi 'git\s+rebase\s+(-i|--interactive)'; then
  block "Interactive rebase can rewrite commits" "git-rebase-i"
fi
if echo "$COMMAND" | grep -qEi 'git\s+rebase\s+.*--onto'; then
  block "git rebase --onto rewrites history" "git-rebase-onto"
fi
if echo "$COMMAND" | grep -qEi 'git\s+commit\s+.*--amend'; then
  block "git commit --amend rewrites the last commit" "git-amend"
fi
if echo "$COMMAND" | grep -qEi 'git\s+checkout\s+--\s+\.(\s|$)'; then
  block "git checkout -- . wipes uncommitted changes" "git-checkout-wipe"
fi
if echo "$COMMAND" | grep -qEi 'git\s+(restore|checkout)\s+\.(\s|$)'; then
  block "git restore . / git checkout . wipes uncommitted changes" "git-restore-wipe"
fi
if echo "$COMMAND" | grep -qEi 'git\s+stash\s+(drop|clear)'; then
  block "git stash drop/clear permanently discards stashed work" "git-stash-drop"
fi
if echo "$COMMAND" | grep -qEi 'git\s+worktree\s+remove\s+.*(-f|--force)'; then
  block "git worktree remove --force discards local changes" "git-worktree-force"
fi

# Sudo
if echo "$COMMAND" | grep -qE '^\s*sudo\s'; then
  block "sudo command detected" "sudo"
fi

# ================= CATEGORY 3: PROTECTED FILES =================
if [ -n "$FILE_PATH" ]; then
  if echo "$FILE_PATH" | grep -qEi '(\.env|\.env\.|id_rsa|id_ed25519|\.ssh/|\.gnupg/)'; then
    block "Edit to secrets/credentials file ($FILE_PATH)" "secrets"
  fi
fi

exit 0
```

---

## Template: .claude/hooks/log-telegram-hook.sh

<!-- Only generate if messaging=telegram -->

```bash
#!/usr/bin/env bash
# PostToolUse hook: auto-log every Telegram reply to conversation history
set -euo pipefail

INPUT=$(cat)
TEXT=$(echo "$INPUT" | jq -r '.tool_input.text // empty' 2>/dev/null | head -c 500)
[ -z "$TEXT" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
HISTORY_DIR="$SCRIPT_DIR/data/telegram-history"
MONTH_FILE="$HISTORY_DIR/$(date -u +%Y-%m).jsonl"
mkdir -p "$HISTORY_DIR"

jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)" \
  --arg sender "{{orchestrator_name_lower}}" \
  --arg text "$TEXT" \
  '{ts: $ts, sender: $sender, text: $text, project: "", has_image: false}' \
  >> "$MONTH_FILE" 2>/dev/null || true

echo '{"suppressOutput": true}'
```

---

## Template: .claude/hooks/audit-log-hook.sh

<!-- Only generate if security=enterprise -->

```bash
#!/usr/bin/env bash
# Enterprise audit log: records every tool call for compliance
set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null)
ARGS=$(echo "$INPUT" | jq -c '.tool_input // {}' 2>/dev/null | head -c 500)

LOG_DIR="{{project_path}}/logs"
AUDIT_FILE="$LOG_DIR/audit-$(date -u +%Y-%m-%d).jsonl"
mkdir -p "$LOG_DIR"

jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)" \
  --arg tool "$TOOL" \
  --arg args "$ARGS" \
  '{ts: $ts, tool: $tool, args: $args}' \
  >> "$AUDIT_FILE" 2>/dev/null || true

echo '{"suppressOutput": true}'
```

---

## Script Templates

> Generation step: when the wizard reaches Step 7, write each template body below to its indicated path under `scripts/`, substituting placeholders. Then `chmod +x` shell scripts.

### Template: scripts/maintain.sh

This template operates over markdown memory files (the v30 source of truth). v30 fresh installs use this markdown-first script. The earlier v28/v29 SQLite-table version is kept below for upgraders that opted into a SQLite memory layer.

```bash
#!/bin/bash
# maintain.sh - markdown memory hygiene + freshness check + backup tarball.
# v30 architecture: memory/ is the source of truth. SQLite is optional.
set -euo pipefail

PROJECT_DIR="{{project_path}}"
BACKUP_DIR="$PROJECT_DIR/data/backups"
MEMORY_DIR="$PROJECT_DIR/memory"
AGENT_MEM_DIR="$PROJECT_DIR/agent-memory"

echo "=== {{orchestrator_name}} Maintenance - $(date) ==="
mkdir -p "$BACKUP_DIR"

# 1. Tarball memory + agent-memory + docs
BACKUP_FILE="$BACKUP_DIR/memory-$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$BACKUP_FILE" -C "$PROJECT_DIR" memory agent-memory docs CLAUDE.md 2>/dev/null || true
echo "Backed up markdown memory to $BACKUP_FILE"

# 2. Retain last 10 backups
ls -t "$BACKUP_DIR"/memory-*.tar.gz 2>/dev/null | tail -n +11 | while read -r OLD; do
  command rm -- "$OLD" 2>/dev/null && echo "Pruned old backup: $(basename "$OLD")"
done

# 3. Freshness check (uses scripts/check-memory-freshness.sh if installed)
if [ -x "$PROJECT_DIR/scripts/check-memory-freshness.sh" ]; then
  echo ""
  echo "> Memory freshness"
  bash "$PROJECT_DIR/scripts/check-memory-freshness.sh" || true
fi

# 4. Memory stats
echo ""
echo "> Memory stats"
echo "  Files in memory/:       $(find "$MEMORY_DIR" -name '*.md' 2>/dev/null | wc -l)"
echo "  Files in agent-memory/: $(find "$AGENT_MEM_DIR" -name '*.md' 2>/dev/null | wc -l)"
echo "  Total memory size:      $(du -sh "$MEMORY_DIR" "$AGENT_MEM_DIR" 2>/dev/null | tail -1 | cut -f1)"

# 5. Vector index status (if E1 sqlite-vec installed)
VEC_DB="$PROJECT_DIR/data/vector-memory.db"
if [ -f "$VEC_DB" ]; then
  CHUNKS=$(sqlite3 "$VEC_DB" "SELECT COUNT(*) FROM memory_chunks;" 2>/dev/null || echo "?")
  echo "  Vector index chunks:    $CHUNKS  (data/vector-memory.db)"
fi

# 6. Optional SQLite layer (only if scripts/setup-db.sh has been run)
DB_PATH="$PROJECT_DIR/data/{{db_name}}"
if [ -f "$DB_PATH" ]; then
  echo ""
  echo "> SQLite operational layer"
  BACKUP_DB="$BACKUP_DIR/{{db_name}}.$(date +%Y%m%d_%H%M%S)"
  cp "$DB_PATH" "$BACKUP_DB"
  echo "  Backed up SQLite to $BACKUP_DB"
  for table in memories tasks decisions; do
    COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM $table;" 2>/dev/null || echo "(table missing)")
    echo "  $table: $COUNT"
  done
fi

echo ""
echo "=== Maintenance complete ==="
```

### Older SQLite-only maintain.sh (v28/v29 reference, not generated by v30)

The v28/v29 maintain.sh assumed a SQLite-only memory layer. v30 fresh installs SHOULD NOT use this version - the markdown-first script above replaces it. Kept here so v28/v29 upgrades have a comparison reference.

```bash
#!/bin/bash
DB_PATH="${{{orchestrator_name_upper}}_DB:-{{project_path}}/data/{{db_name}}}"
BACKUP_DIR="{{project_path}}/data/backups"
echo "=== {{orchestrator_name}} Maintenance -- $(date) ==="

mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/{{db_name}}.$(date +%Y%m%d_%H%M%S)"
cp "$DB_PATH" "$BACKUP_FILE"
echo "Backed up database to $BACKUP_FILE"

ls -t "$BACKUP_DIR"/{{orchestrator_name_lower}}.db.* 2>/dev/null | tail -n +11 | xargs -r rm
echo "Retained last 10 backups"

EXPIRED=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM memories WHERE expires_at IS NOT NULL AND expires_at < datetime('now');")
sqlite3 "$DB_PATH" "DELETE FROM memories WHERE expires_at IS NOT NULL AND expires_at < datetime('now');"
echo "Pruned $EXPIRED expired memories"

OLD_LOW=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM memories WHERE importance <= 3 AND created_at < datetime('now', '-90 days');")
sqlite3 "$DB_PATH" "DELETE FROM memories WHERE importance <= 3 AND created_at < datetime('now', '-90 days');"
echo "Pruned $OLD_LOW low-importance memories (>90 days, importance <=3)"

echo ""
echo "Memory Stats"
sqlite3 -header -column "$DB_PATH" \
  "SELECT agent, COUNT(*) as total, ROUND(AVG(importance), 1) as avg_imp,
   MAX(created_at) as last_memory FROM memories GROUP BY agent ORDER BY total DESC;"

echo ""
echo "Task Stats"
sqlite3 -header -column "$DB_PATH" "SELECT status, COUNT(*) as count FROM tasks GROUP BY status;"

DECISION_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM decisions;")
echo ""
echo "$DECISION_COUNT decisions logged"

DB_SIZE=$(du -h "$DB_PATH" | cut -f1)
echo "Database size: $DB_SIZE"

echo ""
echo "=== Maintenance complete ==="
```

---

## Template: scripts/healthcheck.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="{{project_path}}"
CLAUDE_DIR="$HOME/.claude"

PASS="[PASS]"
FAIL="[FAIL]"
WARN="[WARN]"

total=0; passed=0

check() {
    local label="$1"; local status="$2"; local detail="${3:-}"
    total=$((total + 1))
    if [[ "$status" == "pass" ]]; then
        passed=$((passed + 1))
        echo "  $PASS $label${detail:+ -- $detail}"
    elif [[ "$status" == "warn" ]]; then
        echo "  $WARN $label${detail:+ -- $detail}"
    else
        echo "  $FAIL $label${detail:+ -- $detail}"
    fi
}

echo "=== {{orchestrator_name}} Healthcheck -- $(date '+%Y-%m-%d %H:%M') ==="
echo ""

# Memory system
echo "> Memory System"
db_path="$PROJECT_DIR/data/{{db_name}}"
if [[ -f "$db_path" ]]; then
    memory_count=$(sqlite3 "$db_path" "SELECT count(*) FROM memories;" 2>/dev/null || echo "0")
    check "Database loaded" "pass" "$memory_count memories"
else
    check "Database missing" "fail" "run: bash scripts/setup-db.sh"
fi
echo ""

# Safety gate
echo "> Safety Gate"
hook_path="$PROJECT_DIR/.claude/hooks/safety-gate.sh"
if [[ -f "$hook_path" && -x "$hook_path" ]]; then
    check "Hook installed and executable" "pass"
elif [[ -f "$hook_path" ]]; then
    check "Hook exists but not executable" "warn" "run: chmod +x $hook_path"
else
    check "Hook not found" "fail"
fi
echo ""

# Scripts
echo "> Scripts"
missing_scripts=0
for script in maintain.sh healthcheck.sh load-context.sh commit-watcher.sh history.sh; do
    if [[ ! -x "$PROJECT_DIR/scripts/$script" ]]; then
        missing_scripts=$((missing_scripts + 1))
    fi
done
if [[ $missing_scripts -eq 0 ]]; then
    check "All core scripts present and executable" "pass"
else
    check "$missing_scripts script(s) missing or not executable" "warn"
fi
echo ""

# Project docs
echo "> Project Docs"
projects_file="$PROJECT_DIR/docs/projects.md"
if [[ -f "$projects_file" ]]; then
    project_count=$(grep -c "^## " "$projects_file" 2>/dev/null || echo 0)
    check "Projects file exists" "pass" "$project_count projects registered"
else
    check "Projects file missing" "warn" "run: touch docs/projects.md"
fi
echo ""

# Runtime file perms (secrets and per-turn state)
echo "> Runtime file perms"
runtime_dir="$PROJECT_DIR/data/runtime"
if [[ -d "$runtime_dir" ]]; then
    if [[ -x "$PROJECT_DIR/scripts/verify-runtime-perms.sh" ]]; then
        bad_count=$("$PROJECT_DIR/scripts/verify-runtime-perms.sh" --count 2>/dev/null || echo "0")
        if [[ "$bad_count" == "0" ]]; then
            check "All data/runtime/* files mode 0600" "pass"
        else
            check "$bad_count data/runtime/* file(s) world/group readable" "fail" "run: bash scripts/verify-runtime-perms.sh --fix"
        fi
    else
        check "verify-runtime-perms.sh not installed" "warn"
    fi
else
    check "data/runtime/ directory not present yet" "warn" "(created on first plugin/wizard write)"
fi
echo ""

echo "=== $passed/$total checks passed ==="
```

---

## Template: scripts/verify-runtime-perms.sh

`data/runtime/*` files hold secrets (Telegram bot token, session state) and per-turn contracts. They MUST be mode 0600 - world-readable runtime files mean any local user can lift the bot token. This script audits them.

```bash
#!/usr/bin/env bash
# verify-runtime-perms.sh - audit data/runtime/* file modes.
#
# Usage:
#   bash scripts/verify-runtime-perms.sh           # report bad-perm files
#   bash scripts/verify-runtime-perms.sh --count   # print just the bad count (for healthcheck)
#   bash scripts/verify-runtime-perms.sh --fix     # chmod 0600 anything wrong
set -euo pipefail

PROJECT_DIR="{{project_path}}"
RUNTIME_DIR="$PROJECT_DIR/data/runtime"

MODE="report"
[ "${1:-}" = "--count" ] && MODE="count"
[ "${1:-}" = "--fix" ] && MODE="fix"

if [ ! -d "$RUNTIME_DIR" ]; then
  [ "$MODE" = "count" ] && echo 0 || echo "data/runtime/ does not exist yet"
  exit 0
fi

# BSD stat (macOS) and GNU stat (Linux) have different flags. Try both.
get_mode() {
  stat -f '%Lp' "$1" 2>/dev/null || stat -c '%a' "$1" 2>/dev/null || echo "?"
}

bad=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  m=$(get_mode "$f")
  if [ "$m" != "600" ]; then
    bad=$((bad + 1))
    if [ "$MODE" = "report" ]; then
      echo "BAD perms ($m): $f"
    fi
    if [ "$MODE" = "fix" ]; then
      chmod 0600 "$f" && echo "FIXED: $f"
    fi
  fi
done < <(find "$RUNTIME_DIR" -type f 2>/dev/null)

if [ "$MODE" = "count" ]; then
  echo "$bad"
elif [ "$MODE" = "report" ]; then
  if [ "$bad" -eq 0 ]; then
    echo "OK - all data/runtime/* files mode 0600"
  else
    echo ""
    echo "$bad file(s) with non-0600 perms. Re-run with --fix to chmod them."
    exit 1
  fi
fi
```

Wire this into the install wizard so it runs once at the end of setup. The healthcheck template above already calls it on every run.

---

## Template: scripts/load-context.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="{{project_path}}"
HISTORY_DIR="$PROJECT_DIR/data/telegram-history"

echo "=== Session Context ==="
echo ""

<!-- IF messaging=telegram -->
MONTH_FILE="$HISTORY_DIR/$(date -u +%Y-%m).jsonl"
if [[ -f "$MONTH_FILE" ]]; then
    MSG_COUNT=$(wc -l < "$MONTH_FILE" | tr -d ' ')
    echo "> Recent conversations ($MSG_COUNT total this month, showing last 200):"
    echo ""
    tail -200 "$MONTH_FILE" | jq -r '"  [\(.ts[0:16])] \(.sender): \(.text[0:120])"' 2>/dev/null || true
    echo ""
else
    echo "> No conversation history for this month yet."
fi
<!-- ELSE -->
echo "> Terminal mode -- no conversation history file."
<!-- ENDIF -->

# Load project HANDOFF if specified
PROJECT="${1:-}"
if [[ -n "$PROJECT" ]]; then
    for base in "$HOME/Documents" "$HOME/dev"; do
        if [[ -f "$base/$PROJECT/HANDOFF.md" ]]; then
            echo "> HANDOFF for $PROJECT:"
            cat "$base/$PROJECT/HANDOFF.md"
            break
        fi
    done
fi

echo ""
echo "=== Ready ==="
```

---

## Template: scripts/commit-watcher.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="{{project_path}}"
PROJECTS_FILE="$PROJECT_DIR/docs/projects.md"
THRESHOLD_MINUTES=30
stale_found=0

while IFS= read -r line; do
    folder=$(echo "$line" | sed -n 's/^Folder: //p' || true)
    [[ -z "$folder" ]] && continue
    if [[ "$folder" == dev/* ]]; then abs_path="$HOME/$folder"; else abs_path="$HOME/Documents/$folder"; fi
    [[ ! -d "$abs_path/.git" ]] && continue
    changes=$(cd "$abs_path" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    [[ "$changes" -eq 0 ]] && continue
    last_commit_ts=$(cd "$abs_path" && git log -1 --format=%ct 2>/dev/null || echo 0)
    now_ts=$(date +%s)
    minutes_ago=$(( (now_ts - last_commit_ts) / 60 ))
    if [[ $minutes_ago -ge $THRESHOLD_MINUTES ]]; then
        project_name=$(basename "$abs_path")
        echo "STALE: $project_name -- $changes uncommitted file(s), last commit ${minutes_ago}m ago"
        stale_found=$((stale_found + 1))
    fi
done < "$PROJECTS_FILE"

if [[ $stale_found -eq 0 ]]; then echo "All projects clean or recently committed."; fi
exit 0
```

---

## Template: scripts/log-correction.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

CATEGORY="${1:?Usage: log-correction.sh <category> <description>}"
DESCRIPTION="${2:?Usage: log-correction.sh <category> <description>}"

CORRECTIONS_FILE="{{project_path}}/data/corrections.jsonl"
mkdir -p "$(dirname "$CORRECTIONS_FILE")"

jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)" \
  --arg cat "$CATEGORY" \
  --arg desc "$DESCRIPTION" \
  '{ts: $ts, category: $cat, description: $desc}' \
  >> "$CORRECTIONS_FILE"

echo "Logged correction: $CATEGORY"
echo ""
echo "=== Correction frequency ==="
if [[ -f "$CORRECTIONS_FILE" ]]; then
  jq -r '.category' "$CORRECTIONS_FILE" | sort | uniq -c | sort -rn
fi
```

---

## Template: scripts/history.sh

Unified history search across four sources in one pass: Telegram JSONL history, audit logs (live `data/audit/*.jsonl` and archived `data/audit/archive/YYYY/MM.jsonl.gz`), `git log`, and memory markdown. Supports `--from YYYY-MM-DD` / `--to YYYY-MM-DD` date range filters. Ships as `scripts/history.sh` in the reference implementation - copy that file verbatim. The `history <query>` command wraps it.

---

## Template: scripts/register-project.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

FOLDER_PATH="${1:?Usage: register-project.sh <folder_path> <description> [stack]}"
DESCRIPTION="${2:?Usage: register-project.sh <folder_path> <description> [stack]}"
STACK="${3:-}"

PROJECT_DIR="{{project_path}}"
PROJECTS_FILE="$PROJECT_DIR/docs/projects.md"
PROJECT_NAME=$(basename "$FOLDER_PATH")

echo "=== Registering project: $PROJECT_NAME ==="

# Add to projects.md
if grep -q "^## $PROJECT_NAME" "$PROJECTS_FILE" 2>/dev/null; then
    echo "  Already in projects.md"
else
    ENTRY="\n## $PROJECT_NAME\n$DESCRIPTION"
    [[ -n "$STACK" ]] && ENTRY="$ENTRY\n$STACK"
    ENTRY="$ENTRY\nFolder: $(basename "$(dirname "$FOLDER_PATH")")/$(basename "$FOLDER_PATH")\nStatus: New project."
    echo -e "$ENTRY" >> "$PROJECTS_FILE"
    echo "  Added to projects.md"
fi

# Create project docs
for doc in CLAUDE.md HANDOFF.md FEATURES.md; do
    if [[ ! -f "$FOLDER_PATH/$doc" ]]; then
        case "$doc" in
            CLAUDE.md)
                cat > "$FOLDER_PATH/$doc" << TEMPLATE
# $PROJECT_NAME
$DESCRIPTION
## Stack
${STACK:-TBD}
## Architecture
TBD
TEMPLATE
                ;;
            HANDOFF.md)
                cat > "$FOLDER_PATH/$doc" << TEMPLATE
# Last Session: $(date '+%-d %b %Y')
## What we did
- Initial project setup
## Immediate priorities
1. TBD
TEMPLATE
                ;;
            FEATURES.md)
                cat > "$FOLDER_PATH/$doc" << TEMPLATE
# $PROJECT_NAME -- Features
$DESCRIPTION
## Features
TBD
TEMPLATE
                ;;
        esac
        echo "  Created $doc"
    fi
done

# Init git repo
if [[ ! -d "$FOLDER_PATH/.git" ]]; then
    (cd "$FOLDER_PATH" && git init -q && git add -A && git commit -q -m "Initial commit" 2>/dev/null || true)
    echo "  Git repo initialized"
fi

# Create GitHub repo (requires gh CLI authenticated via 'gh auth login')
if command -v gh &>/dev/null; then
    if ! gh auth status >/dev/null 2>&1; then
        echo "  gh CLI is installed but not authenticated. Skipping remote creation."
        echo "  Run 'gh auth login' (web browser flow) and re-run this script if you want a remote."
    else
        REMOTE_URL=$(cd "$FOLDER_PATH" && git remote get-url origin 2>/dev/null || echo "")
        if [[ -z "$REMOTE_URL" ]]; then
            if (cd "$FOLDER_PATH" && gh repo create "$PROJECT_NAME" --private --source=. --push 2>/dev/null); then
                echo "  GitHub repo created (private)"
            else
                echo "  gh repo create failed (name conflict / network / permissions). Repo stays local-only."
            fi
        fi
    fi
else
    echo "  gh CLI not installed. Skipping remote creation. Install with brew/winget/apt and re-run if you want one."
fi

echo "=== Done ==="
```

---

## Template: scripts/pre-compaction-sync.sh

```bash
#!/bin/bash
PROJECT_DIR="{{project_path}}"
RECOVERY_DIR="$PROJECT_DIR/data/recovery"
WORKING_CTX="${TMPDIR:-/tmp}/{{orchestrator_name_lower}}-working-context.md"
TIMESTAMP=$(date -u +%Y%m%d_%H%M%S)

mkdir -p "$RECOVERY_DIR"

if [ -f "$WORKING_CTX" ]; then
  cp "$WORKING_CTX" "$RECOVERY_DIR/working-context-$TIMESTAMP.md"
  echo "Pre-compaction: saved working context checkpoint ($TIMESTAMP)"
else
  echo "Pre-compaction: no working context checkpoint found"
fi

ls -t "$RECOVERY_DIR"/working-context-*.md 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null
echo "Pre-compaction sync complete."
```

---

## Template: scripts/post-compaction-reload.sh

```bash
#!/bin/bash
PROJECT_DIR="{{project_path}}"
RECOVERY_DIR="$PROJECT_DIR/data/recovery"
HISTORY_FILE="$PROJECT_DIR/data/telegram-history/$(date -u +%Y-%m).jsonl"
LATEST=$(ls -t "$RECOVERY_DIR"/working-context-*.md 2>/dev/null | head -1)

echo "=== CONTEXT WAS COMPACTED ==="
echo "You lost conversation detail. Recover by re-reading:"
echo "1. HANDOFF.md for the active project"
echo "2. Recent conversation history"
echo ""

if [ -f "$HISTORY_FILE" ]; then
  echo "=== RECENT HISTORY ==="
  tail -30 "$HISTORY_FILE" | while IFS= read -r line; do
    ts=$(echo "$line" | jq -r '.ts // empty' 2>/dev/null)
    sender=$(echo "$line" | jq -r '.sender // empty' 2>/dev/null)
    text=$(echo "$line" | jq -r '.text // empty' 2>/dev/null | head -c 150)
    [ -n "$sender" ] && echo "[$ts] $sender: $text"
  done
  echo ""
fi

if [ -n "$LATEST" ] && [ -f "$LATEST" ]; then
  echo "=== WORKING CONTEXT CHECKPOINT ==="
  cat "$LATEST"
else
  echo "=== NO CHECKPOINT FOUND ==="
  echo "Read HANDOFF.md for each active project to recover state."
fi
```

---

## Template: scripts/recent-telegram.sh

`Pretty-print last N exchanges from telegram history. Used as the primary truth source in the maintenance greeting digest. Inbound shown in full; orchestrator outbound truncated to 200 chars so signal isn't buried.`

```bash
#!/usr/bin/env bash
# recent-telegram: pretty-print last N exchanges from telegram history.
#
# Usage:
#   bash scripts/recent-telegram.sh          # default 20
#   bash scripts/recent-telegram.sh 30
#
# Reads data/telegram-history/YYYY-MM.jsonl (current month, plus prior month
# if N extends past current-month line count). Emits one line per exchange:
#
#   [2026-04-22T00:04:13Z] {{user_name_lower}}: hey
#   [2026-04-22T00:05:16Z] {{orchestrator_name_lower}}: Hey. 01:04 BST, late one. **Health:** clean…
#
# {{orchestrator_name}} messages truncate to first 200 chars with "…" suffix
# so the signal doesn't get buried by long outbound replies. {{user_name}}
# messages shown in full.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HISTORY_DIR="$REPO_ROOT/data/telegram-history"

N="${1:-20}"

# Validate N
if ! [[ "$N" =~ ^[0-9]+$ ]]; then
  echo "usage: $0 [N]  (N must be a positive integer)" >&2
  exit 2
fi

if [ ! -d "$HISTORY_DIR" ]; then
  echo "error: no telegram history dir at $HISTORY_DIR" >&2
  exit 1
fi

CUR_MONTH="$(date -u +%Y-%m)"
# Mac (BSD date) uses -v-1m; Linux/Windows-WSL (GNU date) uses -d "1 month ago".
PREV_MONTH="$(date -v-1m -u +%Y-%m 2>/dev/null || date -d "1 month ago" -u +%Y-%m 2>/dev/null || echo "")"

CUR_FILE="$HISTORY_DIR/$CUR_MONTH.jsonl"
PREV_FILE="$HISTORY_DIR/$PREV_MONTH.jsonl"

# Collect source files in chronological order
SOURCES=()
[ -f "$PREV_FILE" ] && SOURCES+=("$PREV_FILE")
[ -f "$CUR_FILE" ] && SOURCES+=("$CUR_FILE")

if [ ${#SOURCES[@]} -eq 0 ]; then
  echo "error: no telegram history files found in $HISTORY_DIR" >&2
  exit 1
fi

# `tail -qn N file1 file2` seeks from EOF in each file and prints only the
# last N lines per file (-q suppresses the ==> header tail adds for multi-file
# output). Cheaper than `cat | tail` which reads every byte. When both months
# exist we tail once more to trim to exactly N across the chronological
# boundary.
tail -qn "$N" "${SOURCES[@]}" | tail -n "$N" | while IFS= read -r line; do
  [ -z "$line" ] && continue
  # Extract + format via jq; truncate orchestrator text to 200 chars.
  echo "$line" | jq -r '
    if .sender == "{{orchestrator_name_lower}}" then
      "[\(.ts)] {{orchestrator_name_lower}}: \(.text | gsub("\n"; " ") | if length > 200 then .[0:200] + "…" else . end)"
    else
      "[\(.ts)] \(.sender): \(.text | gsub("\n"; " "))"
    end
  ' 2>/dev/null || echo "[unparseable] $line"
done
```

---

## Template: scripts/redact-secrets.sh

`stdin-to-stdout filter that masks common credential patterns before content lands on disk (HANDOFF.md, reflections, telegram tail embeds). Mac/Linux compatible BSD/GNU sed -E. Pattern regexes are the script's value, not placeholders.`

```bash
#!/usr/bin/env bash
# redact-secrets: stdin→stdout filter that masks common credential patterns.
#
# Used by update-handoff.sh and reflect.sh before embedding telegram tail
# content into files that land on disk (HANDOFF.md, reflections). Defends
# against the case where any committed file leaks a credential into a public
# fork / clone / context-bundle later.
#
# Patterns covered:
#   - Anthropic:        sk-ant-api-... / sk-ant-...
#   - Stripe:           sk_live_... / sk_test_...
#   - GitHub PAT:       ghp_... / github_pat_...
#   - Slack:            xoxb-... / xoxp-... / xoxa-...
#   - Telegram bot:     digits:AA... 33-char token form
#   - OpenAI / generic: sk-... 20+ char
#   - AWS access key:   AKIA[0-9A-Z]{16}
#   - Vercel API token: vcp_...
#   - Bearer-ish URLs:  token=XXXXX in query strings
#
# Replacement: REDACTED_<type>. Same length not preserved; readability wins
# over format-preservation here.
#
# Usage:
#   echo "my token is sk-ant-api-abc123" | bash scripts/redact-secrets.sh
#   → "my token is REDACTED_ANTHROPIC"

set -uo pipefail

# Chain of sed rules. BSD sed (macOS default) supports -E but not \d, so use
# POSIX character classes. GNU sed (Linux / Windows-WSL) accepts the same -E
# regex syntax, no branching needed.
sed -E \
  -e 's/sk-ant-api[0-9]*-[A-Za-z0-9_-]{20,}/REDACTED_ANTHROPIC/g' \
  -e 's/sk-ant-[A-Za-z0-9_-]{20,}/REDACTED_ANTHROPIC/g' \
  -e 's/sk_live_[A-Za-z0-9]{20,}/REDACTED_STRIPE_LIVE/g' \
  -e 's/sk_test_[A-Za-z0-9]{20,}/REDACTED_STRIPE_TEST/g' \
  -e 's/ghp_[A-Za-z0-9]{30,}/REDACTED_GITHUB_PAT/g' \
  -e 's/github_pat_[A-Za-z0-9_]{40,}/REDACTED_GITHUB_PAT/g' \
  -e 's/xox[bap]-[A-Za-z0-9-]{30,}/REDACTED_SLACK/g' \
  -e 's/[0-9]{8,10}:AA[A-Za-z0-9_-]{33}/REDACTED_TELEGRAM_BOT/g' \
  -e 's/AKIA[0-9A-Z]{16}/REDACTED_AWS_KEY/g' \
  -e 's/vcp_[A-Za-z0-9]{20,}/REDACTED_VERCEL_TOKEN/g' \
  -e 's/(token|api_key|apikey|access_token)=[A-Za-z0-9_.-]{20,}/\1=REDACTED/gi' \
  -e 's/sk-[A-Za-z0-9]{20,}/REDACTED_OPENAI/g'
```

---

## Template: scripts/memory-search.sh

`Thin shell wrapper over scripts/memory-search.py so other tools can pipe results as JSON. Probes for a Python interpreter whose sqlite3 was built with loadable extensions enabled (uv's distribution at ~/.local/bin/python3.13 ticks that box; system python.org builds usually do NOT).`

```bash
#!/usr/bin/env bash
# Thin wrapper over scripts/memory-search.py so other agents can pipe the
# results as JSON. Forwards args, picks the working Python 3.13.
#
# Why interpreter probing: macOS python.org and brew Python ship sqlite3 with
# loadable extensions DISABLED. sqlite-vec needs enable_load_extension(True).
# Install one that works via: uv python install 3.13
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
for cand in "${ORCH_PY:-}" "$HOME/.local/bin/python3.13" /opt/homebrew/bin/python3.14 /usr/bin/python3; do
  if [[ -x "$cand" ]] && "$cand" -c 'import sqlite3; c=sqlite3.connect(":memory:"); c.enable_load_extension(True)' 2>/dev/null; then
    PY="$cand"
    break
  fi
done
if [[ -z "${PY:-}" ]]; then
  echo "memory-search: no Python with loadable sqlite extensions found." >&2
  echo "  Install one via: uv python install 3.13" >&2
  exit 3
fi
exec "$PY" "$SCRIPT_DIR/memory-search.py" "$@"
```

---

## Template: scripts/embed-memories.py

`Python ingest script. Walks every .md file under memory/, agent-memory/**, and docs/**, chunks by paragraph (configurable token budget), embeds each chunk against a local Ollama Nomic-embed endpoint, and writes incremental rows into data/{{db_name}}. Re-embeds only when SHA-256 of the chunk changes; prunes rows whose source file disappeared.`

```python
#!/usr/bin/env python3
"""Embed orchestrator memory markdown into a sqlite-vec index.

Reads every .md file under memory/, agent-memory/**, and docs/** relative to
the repo root, chunks by paragraph (configurable token budget), embeds each
chunk against the local Ollama Nomic-embed endpoint, and writes rows into
data/{{db_name}}.

Incremental: a row only gets re-embedded when its source chunk's SHA-256
content hash changes. Files that disappear from disk get their rows pruned.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sqlite3
import struct
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Iterator

try:
    import sqlite_vec
except ImportError:
    print("sqlite_vec not installed. Run: python3 -m pip install --user sqlite-vec", file=sys.stderr)
    sys.exit(2)

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB = REPO_ROOT / "data" / "{{db_name}}"
DEFAULT_ROOTS = ["memory", "agent-memory", "docs"]
DEFAULT_OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://localhost:11434")
DEFAULT_MODEL = os.environ.get("ORCH_EMBED_MODEL", "nomic-embed-text")
EMBED_DIMS = 768  # nomic-embed-text

# Rough heuristic: 1 token ~= 4 chars for English markdown.
DEFAULT_MIN_CHARS = 200 * 4   # ~200 tokens
DEFAULT_MAX_CHARS = 500 * 4   # ~500 tokens


# ---------- chunking ----------

_BLANKLINE_RE = re.compile(r"\n\s*\n+")


def split_paragraphs(text: str) -> list[str]:
    # Strip trailing whitespace; collapse > 1 blank line into the split point.
    parts = [p.strip() for p in _BLANKLINE_RE.split(text)]
    return [p for p in parts if p]


def pack_chunks(paragraphs: list[str], min_chars: int, max_chars: int) -> list[str]:
    """Greedy pack: accumulate paragraphs until we cross min_chars; if a single
    paragraph exceeds max_chars, hard-split on newlines as a fallback."""
    chunks: list[str] = []
    buf: list[str] = []
    buf_len = 0
    for p in paragraphs:
        if len(p) > max_chars:
            # Flush current buffer
            if buf:
                chunks.append("\n\n".join(buf))
                buf, buf_len = [], 0
            # Hard-split long paragraph at line boundaries
            lines = p.splitlines()
            sub: list[str] = []
            sub_len = 0
            for line in lines:
                if sub_len + len(line) > max_chars and sub:
                    chunks.append("\n".join(sub))
                    sub, sub_len = [], 0
                sub.append(line)
                sub_len += len(line) + 1
            if sub:
                chunks.append("\n".join(sub))
            continue
        buf.append(p)
        buf_len += len(p) + 2
        if buf_len >= min_chars:
            chunks.append("\n\n".join(buf))
            buf, buf_len = [], 0
    if buf:
        chunks.append("\n\n".join(buf))
    return chunks


@dataclass
class Chunk:
    rel_path: str
    chunk_index: int
    start_line: int
    end_line: int
    content: str
    content_hash: str


def iter_chunks(path: Path, rel: str, min_chars: int, max_chars: int) -> Iterator[Chunk]:
    try:
        raw = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError) as e:
        print(f"skip {rel}: {e}", file=sys.stderr)
        return
    # Quick skip: empty or tiny frontmatter-only files.
    if len(raw.strip()) < 40:
        return

    paragraphs = split_paragraphs(raw)
    if not paragraphs:
        return
    chunks = pack_chunks(paragraphs, min_chars, max_chars)

    # Compute line ranges by locating each chunk's first + last line in the source.
    cursor_line = 1
    lines = raw.splitlines()
    for i, c in enumerate(chunks):
        # Find start line for this chunk (from cursor_line onward)
        needle = c.splitlines()[0].strip() if c.splitlines() else ""
        start_line = cursor_line
        if needle:
            for ln in range(cursor_line - 1, len(lines)):
                if lines[ln].strip() == needle:
                    start_line = ln + 1
                    break
        end_line = start_line + max(0, len(c.splitlines()) - 1)
        cursor_line = end_line + 1
        h = hashlib.sha256(c.encode("utf-8")).hexdigest()
        yield Chunk(
            rel_path=rel,
            chunk_index=i,
            start_line=start_line,
            end_line=end_line,
            content=c,
            content_hash=h,
        )


# ---------- ollama embedding ----------

class OllamaEmbedder:
    def __init__(self, url: str, model: str):
        self.url = url.rstrip("/") + "/api/embed"
        self.model = model

    def embed(self, texts: list[str]) -> list[list[float]]:
        if not texts:
            return []
        payload = json.dumps({"model": self.model, "input": texts}).encode("utf-8")
        req = urllib.request.Request(
            self.url,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = json.loads(resp.read())
        except urllib.error.URLError as e:
            raise RuntimeError(f"ollama unreachable at {self.url}: {e}") from e
        embeds = data.get("embeddings")
        if embeds is None:
            raise RuntimeError(f"ollama response missing 'embeddings': {data!r}")
        if len(embeds) != len(texts):
            raise RuntimeError(f"ollama returned {len(embeds)} embeds for {len(texts)} inputs")
        return embeds


def pack_float_blob(vec: list[float]) -> bytes:
    return struct.pack(f"{len(vec)}f", *vec)


# ---------- db schema ----------

SCHEMA_SQL = f"""
CREATE TABLE IF NOT EXISTS chunks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    rel_path TEXT NOT NULL,
    chunk_index INTEGER NOT NULL,
    start_line INTEGER NOT NULL,
    end_line INTEGER NOT NULL,
    content TEXT NOT NULL,
    content_hash TEXT NOT NULL,
    model TEXT NOT NULL,
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(rel_path, chunk_index)
);
CREATE INDEX IF NOT EXISTS idx_chunks_rel_path ON chunks(rel_path);
CREATE INDEX IF NOT EXISTS idx_chunks_hash ON chunks(content_hash);

CREATE VIRTUAL TABLE IF NOT EXISTS chunk_vecs USING vec0(
    embedding float[{EMBED_DIMS}]
);

CREATE TABLE IF NOT EXISTS meta (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
"""


def connect(db_path: Path) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("PRAGMA synchronous=NORMAL;")
    conn.executescript(SCHEMA_SQL)
    return conn


# ---------- ingest ----------

def walk_markdown(repo_root: Path, roots: list[str]) -> Iterator[tuple[Path, str]]:
    for r in roots:
        base = repo_root / r
        if not base.exists():
            continue
        for path in base.rglob("*.md"):
            if path.is_symlink():
                continue
            rel = str(path.relative_to(repo_root))
            # Skip vendored clones / node_modules / anything that's not ours.
            if "node_modules" in rel:
                continue
            yield path, rel


def ingest(args: argparse.Namespace) -> int:
    db_path = Path(args.db)
    conn = connect(db_path)
    cur = conn.cursor()
    embedder = OllamaEmbedder(args.ollama_url, args.model)

    t_start = time.time()

    # Build set of current chunks on disk keyed by (rel_path, chunk_index).
    disk_chunks: dict[tuple[str, int], Chunk] = {}
    files_seen: set[str] = set()
    for path, rel in walk_markdown(REPO_ROOT, args.roots):
        files_seen.add(rel)
        for c in iter_chunks(path, rel, args.min_chars, args.max_chars):
            disk_chunks[(c.rel_path, c.chunk_index)] = c

    # Load existing index
    existing: dict[tuple[str, int], tuple[int, str]] = {}
    for row in cur.execute("SELECT id, rel_path, chunk_index, content_hash FROM chunks"):
        existing[(row[1], row[2])] = (row[0], row[3])

    to_delete_ids: list[int] = []
    to_upsert: list[Chunk] = []
    unchanged = 0
    changed = 0
    added = 0

    # Mark chunks to delete: in existing but not in disk, or in files that no longer exist.
    for key, (row_id, _h) in existing.items():
        if key not in disk_chunks:
            to_delete_ids.append(row_id)
        elif disk_chunks[key].content_hash == existing[key][1]:
            unchanged += 1

    for key, c in disk_chunks.items():
        if key not in existing:
            to_upsert.append(c)
            added += 1
        elif existing[key][1] != c.content_hash:
            to_upsert.append(c)
            changed += 1

    # Delete stale rows (also drop from vec table).
    if to_delete_ids:
        placeholders = ",".join("?" * len(to_delete_ids))
        cur.execute(f"DELETE FROM chunks WHERE id IN ({placeholders})", to_delete_ids)
        cur.execute(f"DELETE FROM chunk_vecs WHERE rowid IN ({placeholders})", to_delete_ids)

    # Embed and upsert in batches of 32.
    BATCH = 32
    now_iso = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    for i in range(0, len(to_upsert), BATCH):
        batch = to_upsert[i:i + BATCH]
        vectors = embedder.embed([c.content for c in batch])
        for c, v in zip(batch, vectors):
            row = cur.execute(
                "SELECT id FROM chunks WHERE rel_path = ? AND chunk_index = ?",
                (c.rel_path, c.chunk_index),
            ).fetchone()
            if row:
                row_id = row[0]
                cur.execute(
                    """
                    UPDATE chunks SET start_line=?, end_line=?, content=?, content_hash=?,
                                      model=?, updated_at=?
                     WHERE id=?
                    """,
                    (c.start_line, c.end_line, c.content, c.content_hash, args.model, now_iso, row_id),
                )
                cur.execute("DELETE FROM chunk_vecs WHERE rowid = ?", (row_id,))
                cur.execute(
                    "INSERT INTO chunk_vecs(rowid, embedding) VALUES (?, ?)",
                    (row_id, pack_float_blob(v)),
                )
            else:
                cur.execute(
                    """
                    INSERT INTO chunks(rel_path, chunk_index, start_line, end_line,
                                       content, content_hash, model, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (c.rel_path, c.chunk_index, c.start_line, c.end_line,
                     c.content, c.content_hash, args.model, now_iso),
                )
                row_id = cur.lastrowid
                cur.execute(
                    "INSERT INTO chunk_vecs(rowid, embedding) VALUES (?, ?)",
                    (row_id, pack_float_blob(v)),
                )
        conn.commit()

    cur.execute(
        "INSERT OR REPLACE INTO meta(key, value) VALUES ('last_run', ?)",
        (now_iso,),
    )
    cur.execute(
        "INSERT OR REPLACE INTO meta(key, value) VALUES ('embed_model', ?)",
        (args.model,),
    )
    conn.commit()

    elapsed = time.time() - t_start
    total_chunks = cur.execute("SELECT COUNT(*) FROM chunks").fetchone()[0]
    total_files = len({row[0] for row in cur.execute("SELECT DISTINCT rel_path FROM chunks")})
    db_size_kb = db_path.stat().st_size / 1024 if db_path.exists() else 0

    summary = {
        "files_on_disk": len(files_seen),
        "files_in_index": total_files,
        "chunks_on_disk": len(disk_chunks),
        "chunks_in_index": total_chunks,
        "added": added,
        "changed": changed,
        "unchanged": unchanged,
        "deleted": len(to_delete_ids),
        "elapsed_seconds": round(elapsed, 2),
        "db_path": str(db_path),
        "db_size_kb": round(db_size_kb, 1),
        "model": args.model,
    }
    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        print(
            f"[embed-memories] {summary['files_on_disk']} files -> "
            f"{summary['chunks_in_index']} chunks "
            f"(+{added} new, ~{changed} changed, ={unchanged} unchanged, -{len(to_delete_ids)} stale) "
            f"in {summary['elapsed_seconds']}s "
            f"[{summary['db_size_kb']} KB at {summary['db_path']}]"
        )
    conn.close()
    return 0


def main() -> int:
    p = argparse.ArgumentParser(description="Embed orchestrator memory markdown into sqlite-vec.")
    p.add_argument("--db", default=str(DEFAULT_DB))
    p.add_argument("--roots", nargs="+", default=DEFAULT_ROOTS)
    p.add_argument("--ollama-url", default=DEFAULT_OLLAMA_URL)
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--min-chars", type=int, default=DEFAULT_MIN_CHARS)
    p.add_argument("--max-chars", type=int, default=DEFAULT_MAX_CHARS)
    p.add_argument("--json", action="store_true", help="Print summary as JSON.")
    args = p.parse_args()
    return ingest(args)


if __name__ == "__main__":
    sys.exit(main())
```

**Companion shell wrapper** (`scripts/embed-memories.sh`) uses the same interpreter-probe pattern as `memory-search.sh`. Both Mac and Windows-WSL need a Python whose sqlite3 was built with loadable extensions enabled. Install with `uv python install 3.13`.

---

## Template: scripts/check-memory-freshness.sh

`Scan memory files for staleness. Reads last_verified + ttl_days from each memory's frontmatter, applies per-type defaults if ttl_days missing (feedback 365d, project 2d, user 180d, reference 180d, note 30d, agent 90d), and reports stale + missing counts. Wired into greeting digest and Monday maintenance.`

```bash
#!/usr/bin/env bash
# check-memory-freshness: scan memory files for staleness.
#
# Reads `last_verified` + `ttl_days` from each memory's frontmatter. Flags
# files that:
#   1. Have `last_verified` older than TTL
#   2. Have NO `last_verified` field (convention not yet applied)
#   3. Have `last_verified` but no `ttl_days` → uses per-type defaults:
#      feedback   → 365 days   (durable rules rarely go stale)
#      project    → 2 days     (project state changes fast)
#      user       → 180 days   (user preferences slow-changing)
#      reference  → 180 days   (external references)
#      note       → 30 days    (ephemeral)
#      agent-*    → 90 days    (agent memories)
#
# Usage:
#   bash scripts/check-memory-freshness.sh               # report stale + missing summary
#   bash scripts/check-memory-freshness.sh --strict      # exit 1 if any stale
#   bash scripts/check-memory-freshness.sh --only-missing # list files missing TTL
#
# Intended to run as part of greeting digest + Monday maintenance.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

STRICT=0
ONLY_MISSING=0
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    --only-missing) ONLY_MISSING=1 ;;
  esac
done

ttl_for_type() {
  case "$1" in
    feedback)   echo 365 ;;
    project)    echo 2 ;;
    user)       echo 180 ;;
    reference)  echo 180 ;;
    note)       echo 30 ;;
    agent)      echo 90 ;;
    *)          echo 90 ;;
  esac
}

NOW_EPOCH=$(date -u +%s)
STALE_COUNT=0
MISSING_COUNT=0

while IFS= read -r file; do
  [ -z "$file" ] && continue
  rel="${file#$REPO_ROOT/}"

  # Skip MEMORY.md index files: they are pointers, not memories themselves.
  [ "$(basename "$rel")" = "MEMORY.md" ] && continue

  # Skip symlinks so we don't double-count via aliases.
  [ -L "$file" ] && continue

  # Extract frontmatter between the two `---` fences. Stop at second fence;
  # malformed (no closing ---) files get warned + skipped.
  fm="$(awk '/^---$/{n++; if(n==2) exit; next} n==1' "$file" 2>/dev/null)"
  if ! awk '/^---$/{n++} END{exit (n>=2)?0:1}' "$file" 2>/dev/null; then
    echo "[malformed-frontmatter] $rel: missing closing ---" >&2
    continue
  fi

  LAST_VERIFIED="$(echo "$fm" | grep -i '^last_verified:' | head -1 | sed -E 's/^[^:]+:[[:space:]]*//' | tr -d '"')"
  TTL_DAYS="$(echo "$fm" | grep -i '^ttl_days:' | head -1 | sed -E 's/^[^:]+:[[:space:]]*//' | tr -d '"')"

  if [[ "$rel" == memory/feedback_* ]]; then type=feedback
  elif [[ "$rel" == memory/project_* ]]; then type=project
  elif [[ "$rel" == memory/user_* ]]; then type=user
  elif [[ "$rel" == memory/reference_* ]]; then type=reference
  elif [[ "$rel" == memory/note_* ]]; then type=note
  elif [[ "$rel" == agent-memory/* ]]; then type=agent
  else type=other
  fi

  if [ -z "$LAST_VERIFIED" ]; then
    MISSING_COUNT=$((MISSING_COUNT + 1))
    if [ "$ONLY_MISSING" = "1" ]; then
      echo "[missing-ttl] $rel (type=$type)"
    fi
    continue
  fi

  [ "$ONLY_MISSING" = "1" ] && continue

  # Empty / zero / non-numeric ttl_days falls back to the per-type default
  # so a typo doesn't flag every file on every run.
  if [ -z "$TTL_DAYS" ] || ! [[ "$TTL_DAYS" =~ ^[0-9]+$ ]] || [ "$TTL_DAYS" -lt 1 ]; then
    TTL_DAYS=$(ttl_for_type "$type")
  fi

  # Pass last_verified via argv so shell quoting can't break the python
  # snippet, and report unparseable dates to stderr instead of silently
  # dropping the file.
  last_epoch=$(python3 - "$LAST_VERIFIED" <<'PY' 2>/dev/null
import sys
from datetime import datetime
s = sys.argv[1]
for fmt in ('fromiso', '%Y-%m-%d'):
    try:
        if fmt == 'fromiso':
            dt = datetime.fromisoformat(s.replace('Z', '+00:00'))
        else:
            dt = datetime.strptime(s, fmt)
        print(int(dt.timestamp()))
        sys.exit(0)
    except Exception:
        pass
print(0)
PY
)
  last_epoch="${last_epoch:-0}"

  if [ "$last_epoch" = "0" ]; then
    echo "[unparseable-date] $rel: last_verified='$LAST_VERIFIED' could not be parsed" >&2
    continue
  fi

  age_seconds=$((NOW_EPOCH - last_epoch))

  # Future-dated last_verified is anomalous (typo, clock skew, restored
  # backup). Flag explicitly instead of silently marking fresh.
  if [ "$age_seconds" -lt 0 ]; then
    echo "[future-ts] $rel: last_verified in the future ($LAST_VERIFIED)"
    STALE_COUNT=$((STALE_COUNT + 1))
    continue
  fi

  age_days=$((age_seconds / 86400))
  ttl_seconds=$((TTL_DAYS * 86400))

  if [ "$age_seconds" -gt "$ttl_seconds" ]; then
    STALE_COUNT=$((STALE_COUNT + 1))
    echo "[stale] $rel: last_verified ${age_days}d ago (ttl $TTL_DAYS days, type=$type)"
  fi
done < <(find memory agent-memory -name "*.md" -type f 2>/dev/null)

echo ""
echo "=== check-memory-freshness ==="
# Count only actual memory files (exclude MEMORY.md indexes + symlinks).
TOTAL=$(find memory agent-memory -name "*.md" -type f ! -name 'MEMORY.md' 2>/dev/null | wc -l | tr -d ' ')
echo "  total:   $TOTAL memory files"
echo "  missing: $MISSING_COUNT (no last_verified frontmatter)"
echo "  stale:   $STALE_COUNT (past their TTL)"

if [ "$STRICT" = "1" ] && [ "$STALE_COUNT" -gt "0" ]; then
  exit 1
fi
exit 0
```

---

## Template: scripts/session-end-sync.sh

`Orchestrator that fires on session end -- rebuilds HANDOFF.md from authoritative sources, then writes a sleep-time reflection so the next session's greeting digest can surface unreviewed items.`

```bash
#!/usr/bin/env bash
# session-end-sync -- safety net triggered when Claude Code session ends.
#
# Responsibilities:
#   1. Rebuild HANDOFF.md from authoritative sources (git log + telegram tail)
#      via scripts/update-handoff.sh.
#   2. Write a reflection to data/reflections/ via scripts/reflect.sh so the
#      next session's greeting digest can surface unreviewed items.
#   3. Log the session-end event for operator visibility.
#
# Intentionally thin -- heavy lifting is delegated to the two callees, which
# are independently invokable on demand.

ORCHESTRATOR_DIR="$HOME/Documents/{{orchestrator_name}}"
LOG_FILE="$ORCHESTRATOR_DIR/logs/session-lifecycle.log"
mkdir -p "$(dirname "$LOG_FILE")"

cd "$ORCHESTRATOR_DIR" || exit 0

# Rebuild HANDOFF.md from telegram + git log (event-sourced)
if bash scripts/update-handoff.sh 48 >/dev/null 2>&1; then
  echo "[$(date -u +%H:%M:%S)] Session ended. HANDOFF.md rebuilt from last 48h." >> "$LOG_FILE"
else
  echo "[$(date -u +%H:%M:%S)] Session ended. update-handoff.sh failed -- HANDOFF.md not refreshed." >> "$LOG_FILE"
fi

# Write a sleep-time reflection covering the last 4 hours
if bash scripts/reflect.sh 4 >/dev/null 2>&1; then
  echo "[$(date -u +%H:%M:%S)] Reflection written to data/reflections/." >> "$LOG_FILE"
else
  echo "[$(date -u +%H:%M:%S)] reflect.sh failed -- no reflection generated." >> "$LOG_FILE"
fi

exit 0
```

---

## Template: scripts/update-handoff.sh

`Event-sourced HANDOFF.md rebuilder. Pulls the last N hours of telegram tail, git log, and pending-state mentions; prepends a new dated section to HANDOFF.md without ever overwriting prior content.`

```bash
#!/usr/bin/env bash
# update-handoff -- event-sourced HANDOFF.md regen.
#
# Rebuilds the top section of HANDOFF.md from three authoritative sources:
#   1. Last 48h telegram tail (via recent-telegram.sh 100)
#   2. git log --since="48 hours ago"
#   3. Pending items extracted from telegram text (grep regex)
#
# Prepends a new dated section to HANDOFF.md -- NEVER overwrites prior sessions.
# Preserves user manual edits below the auto-generated top section.
#
# Usage:
#   bash scripts/update-handoff.sh             # rebuild with default 48h window
#   bash scripts/update-handoff.sh 72          # custom hours window
#
# Wired into scripts/session-end-sync.sh -- fires automatically on session end.
# Also invokable manually when the user asks for status or after a long work
# block.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

HOURS="${1:-48}"

if ! [[ "$HOURS" =~ ^[0-9]+$ ]]; then
  echo "usage: $0 [hours]  (default 48)" >&2
  exit 2
fi

HANDOFF="$REPO_ROOT/HANDOFF.md"
NOW_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NOW_LOCAL="$(date '+%Y-%m-%d %H:%M %Z')"

# Build the new section in a tempfile so we can prepend atomically.
TMP_NEW="$(mktemp -t {{orchestrator_name_lower}}-handoff-new.XXXXXX)"
trap 'rm -f "$TMP_NEW"' EXIT

{
  echo "# Last Session: $NOW_LOCAL"
  echo ""
  echo "_Auto-generated by \`scripts/update-handoff.sh\` -- event-sourced from telegram + git log. Do not hand-edit this top section; edits get overwritten on next session-end. Manual notes go in earlier sections below._"
  echo ""

  # What we did: git log last N hours
  echo "## What we did (git log last ${HOURS}h)"
  echo ""
  GIT_LOG="$(git log --since="$HOURS hours ago" --pretty=format:'- %h %s' 2>/dev/null || echo "")"
  if [ -n "$GIT_LOG" ]; then
    echo "$GIT_LOG"
  else
    echo "_No commits in window._"
  fi
  echo ""

  # Still open: extract pending-ish lines from telegram tail.
  # Match orchestrator messages that reference "pending" / "todo" / "still open"
  # / "not yet" / "awaiting". Also surface user directives that start with
  # "need to" / "todo" / "still need".
  echo "## What's still open (extracted from telegram)"
  echo ""

  TELEGRAM_RAW="$(bash "$REPO_ROOT/scripts/recent-telegram.sh" 100 2>/dev/null || echo "")"
  PENDING="$(echo "$TELEGRAM_RAW" | grep -Ei '(pending|todo|still need|still open|not yet|awaiting|waiting on|blocker)' | tail -15 || true)"
  if [ -n "$PENDING" ]; then
    echo "$PENDING" | sed 's/^/- /'
  else
    echo "_No obvious pending-state mentions in last ${HOURS}h telegram._"
  fi
  echo ""

  # Telegram tail (last 10 exchanges) for quick context.
  # Use a ~~~ fence (not ```) because telegram history can contain triple
  # backticks from code snippets and fence-inside-fence breaks markdown.
  echo "## Telegram tail (last 10)"
  echo ""
  echo '~~~'
  # Run tail through redact-secrets so any credential the user pasted does
  # not get committed into HANDOFF.md. HANDOFF lives in the orchestrator
  # repo -- private today, but future repo flips / forks / clones would
  # expose whatever landed here.
  bash "$REPO_ROOT/scripts/recent-telegram.sh" 10 2>/dev/null | \
    bash "$REPO_ROOT/scripts/redact-secrets.sh" || echo "_telegram history unavailable_"
  echo '~~~'
  echo ""
  echo "<!-- AUTO-SECTION-END -- do not edit above this line; regenerated on every session-end -->"
  echo ""
  echo "---"
  echo ""
} > "$TMP_NEW"

# Prepend to existing HANDOFF.
# If a prior run wrote a top section but the terminating "---" separator got
# truncated, naive logic would DROP all prior content. Guard: look for our
# sentinel comment first, fall back to a conservative prepend that never drops
# content.
if [ -f "$HANDOFF" ]; then
  if head -10 "$HANDOFF" | grep -q "Auto-generated by.*update-handoff.sh"; then
    SENTINEL_LINE="$(awk '/AUTO-SECTION-END/{print NR; exit}' "$HANDOFF")"
    if [ -n "$SENTINEL_LINE" ]; then
      # Find the first `---` separator AFTER the sentinel and skip through it.
      # Squeeze leading blanks so the file does not gain one blank per regen.
      SEP_LINE="$(awk -v s="$SENTINEL_LINE" 'NR > s && /^---$/ {print NR; exit}' "$HANDOFF")"
      if [ -n "$SEP_LINE" ]; then
        tail -n +$((SEP_LINE + 1)) "$HANDOFF" | awk 'NF{p=1} p' >> "$TMP_NEW"
      else
        # Sentinel present but no following `---` -- fall back to a
        # conservative +3 offset.
        tail -n +$((SENTINEL_LINE + 4)) "$HANDOFF" | awk 'NF{p=1} p' >> "$TMP_NEW"
      fi
    else
      # Fallback: find FIRST "---" separator. But only use it if it appears
      # within the first 200 lines (the auto-section should be well under that).
      SEP_LINE="$(head -200 "$HANDOFF" | awk '/^---$/{print NR; exit}')"
      if [ -n "$SEP_LINE" ] && [ "$SEP_LINE" -lt 200 ]; then
        tail -n +$((SEP_LINE + 1)) "$HANDOFF" >> "$TMP_NEW"
      else
        # Truncated or malformed prior auto-section -- do not drop content.
        # Append the whole existing HANDOFF below the new top section.
        echo "<!-- NOTE: prior auto-section was malformed; content below preserved verbatim -->" >> "$TMP_NEW"
        echo "" >> "$TMP_NEW"
        cat "$HANDOFF" >> "$TMP_NEW"
      fi
    fi
  else
    # No previous auto-section -- just prepend to existing content
    cat "$HANDOFF" >> "$TMP_NEW"
  fi
fi

mv "$TMP_NEW" "$HANDOFF"

echo "update-handoff: rewrote $HANDOFF (top section = last ${HOURS}h)"
```

---

## Template: scripts/reflect.sh

`Sleep-time reflection on session activity. Reads the last N hours of telegram tail, audit log, git log, and modified-but-uncommitted files, then writes a structured findings file to data/reflections/ that the next session can surface in the greeting digest.`

```bash
#!/usr/bin/env bash
# reflect -- sleep-time reflection on session activity.
#
# Reads the last N hours of:
#   - Telegram tail
#   - Audit log
#   - Git log (commits + uncommitted changes)
#   - Modified-but-uncommitted files
#
# Pattern-matches for:
#   - Work-in-progress flags ("still", "todo:", "pending", "WIP")
#   - Implicit asks ("can you", "could you", "need to") that don't have a
#     corresponding reply-tool call OR commit following
#   - Memory candidates ("remember", "note that", "for next time")
#   - Uncommitted changes that might be lost
#
# Writes findings to data/reflections/YYYY-MM-DD-HHMM.md so the next session
# can surface unreviewed reflections in the greeting digest.
#
# Usage:
#   bash scripts/reflect.sh          # default 4h window
#   bash scripts/reflect.sh 12       # custom hours window
#
# Pure-bash v1 -- no LLM calls. LLM upgrade = later phase when API budget
# allows.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

HOURS="${1:-4}"
if ! [[ "$HOURS" =~ ^[0-9]+$ ]]; then
  echo "usage: $0 [hours]  (default 4)" >&2
  exit 2
fi

REFLECT_DIR="$REPO_ROOT/data/reflections"
REFLECT_ARCHIVE="$REFLECT_DIR/archive"
mkdir -p "$REFLECT_DIR"

# Reflections grow ~1 file per session-end (~100 KB each). At 10/day that's
# ~365 MB/year, unbounded. Keep 90 days live; gzip older into monthly archives
# under data/reflections/archive/.
RETENTION_DAYS=90
CUTOFF_EPOCH=$(( $(date +%s) - RETENTION_DAYS * 86400 ))
shopt -s nullglob 2>/dev/null || true
for f in "$REFLECT_DIR"/20*-*.md; do
  [ -e "$f" ] || continue
  # Mac BSD stat vs Linux GNU stat compatibility
  case "$(uname -s)" in
    Darwin)
      f_mtime="$(stat -f %m "$f" 2>/dev/null || echo 0)"
      ;;
    *)
      f_mtime="$(stat -c %Y "$f" 2>/dev/null || echo 0)"
      ;;
  esac
  if [ "$f_mtime" != "0" ] && [ "$f_mtime" -lt "$CUTOFF_EPOCH" ]; then
    mkdir -p "$REFLECT_ARCHIVE"
    f_ym="$(basename "$f" | cut -c1-7)"  # YYYY-MM
    archive_gz="$REFLECT_ARCHIVE/reflections-${f_ym}.tar.gz"
    (
      cd "$REFLECT_DIR"
      gzip -c "$(basename "$f")" >> "$archive_gz" 2>/dev/null
    ) && rm -f "$f"
  fi
done

TS_NOW_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TS_FILE="$(date -u +%Y-%m-%d-%H%M)"
OUT_FILE="$REFLECT_DIR/$TS_FILE.md"

# Resolve window start (Mac BSD date -r vs Linux GNU date -d compatibility).
WINDOW_START_EPOCH=$(( $(date +%s) - HOURS * 3600 ))
case "$(uname -s)" in
  Darwin)
    WINDOW_START_ISO="$(date -u -r "$WINDOW_START_EPOCH" +%Y-%m-%dT%H:%M:%SZ)"
    ;;
  *)
    WINDOW_START_ISO="$(date -u -d "@$WINDOW_START_EPOCH" +%Y-%m-%dT%H:%M:%SZ)"
    ;;
esac

{
  echo "# Reflection -- $TS_NOW_ISO (last ${HOURS}h)"
  echo ""
  echo "_Auto-generated by \`scripts/reflect.sh\`. Findings are LOW-CONFIDENCE pattern-matches -- not LLM-reasoned. Use as a checklist: are any of these worth addressing before next session?_"
  echo ""
  echo "---"
  echo ""

  # 1. GIT LOG -- commits in window
  echo "## 1. Commits (last ${HOURS}h)"
  echo ""
  GIT_LOG="$(git log --since="$HOURS hours ago" --pretty=format:'- %h %s' 2>/dev/null || echo "")"
  if [ -n "$GIT_LOG" ]; then
    echo "$GIT_LOG"
  else
    echo "_No commits in window._"
  fi
  echo ""

  # 2. UNCOMMITTED CHANGES -- potential WIP loss
  echo "## 2. Uncommitted changes"
  echo ""
  UNCOMMITTED="$(git status --short 2>/dev/null | head -30 || echo "")"
  if [ -n "$UNCOMMITTED" ]; then
    echo "**$(echo "$UNCOMMITTED" | wc -l | tr -d ' ') uncommitted file(s)** -- review before next session:"
    echo '```'
    echo "$UNCOMMITTED"
    echo '```'
  else
    echo "_Working tree clean._"
  fi
  echo ""

  # 3. TELEGRAM TAIL -- implicit asks + WIP markers
  echo "## 3. Telegram -- implicit asks + WIP markers (last ${HOURS}h)"
  echo ""
  # Redact credentials from telegram tail before it lands in the reflection
  # file. Reflections live in data/reflections/ which IS committed.
  TELEGRAM_LAST="$(bash "$REPO_ROOT/scripts/recent-telegram.sh" 100 2>/dev/null | \
                    bash "$REPO_ROOT/scripts/redact-secrets.sh" 2>/dev/null || echo "")"

  # Filter to window-only entries
  TELEGRAM_WINDOW="$(echo "$TELEGRAM_LAST" | awk -v since="$WINDOW_START_ISO" '
    /^\[/ {
      # Extract the ISO timestamp from between the brackets
      ts = substr($0, 2, index($0, "]") - 2)
      if (ts >= since) print
    }')"

  # Implicit asks -- user saying "can you" / "could you" / "need to" / "should".
  # The {{user_name_lower}} placeholder is the user's telegram handle as
  # it appears in recent-telegram.sh output (e.g. "alice_42:" if her handle
  # is alice_42).
  ASKS="$(echo "$TELEGRAM_WINDOW" | grep -iE '{{user_name_lower}}.*(can you|could you|need to|should|make sure|don.t forget|remember to|please)' | tail -10)"
  if [ -n "$ASKS" ]; then
    echo "### Implicit asks from {{user_name}} (last ${HOURS}h)"
    echo ""
    echo "$ASKS" | sed 's/^/- /'
    echo ""
    echo "_Review: were all of these addressed in commits or replies?_"
    echo ""
  fi

  # WIP markers -- either sender saying "still" / "todo" / "pending"
  WIP="$(echo "$TELEGRAM_WINDOW" | grep -iE '(still need|still pending|todo:|TODO:|WIP|work in progress|not yet|haven.t)' | tail -10)"
  if [ -n "$WIP" ]; then
    echo "### WIP markers"
    echo ""
    echo "$WIP" | sed 's/^/- /'
    echo ""
  fi

  # Memory candidates -- "remember that" / "note that" / "for next time"
  MEMORY_CAND="$(echo "$TELEGRAM_WINDOW" | grep -iE '(remember that|note that|for next time|don.t.* again|always|never)' | tail -10)"
  if [ -n "$MEMORY_CAND" ]; then
    echo "### Candidate memory entries"
    echo ""
    echo "$MEMORY_CAND" | sed 's/^/- /'
    echo ""
    echo "_Review: are any of these worth saving as a \`feedback_*.md\` memory?_"
    echo ""
  fi

  # 4. AUDIT LOG -- failed tools, unreviewed errors
  echo "## 4. Audit -- tool failures + notable events (last ${HOURS}h)"
  echo ""
  AUDIT_TODAY="$REPO_ROOT/data/audit/$(date -u +%Y-%m-%d).jsonl"
  if [ -f "$AUDIT_TODAY" ]; then
    FAILED="$(jq -rc --arg since "$WINDOW_START_ISO" \
      'select(.ts >= $since and .success == false) | "\(.ts) \(.tool) \(.error[0:120])"' \
      "$AUDIT_TODAY" 2>/dev/null | head -10)"
    if [ -n "$FAILED" ]; then
      echo "### Tool failures"
      echo ""
      echo "$FAILED" | sed 's/^/- /'
      echo ""
    else
      echo "_No tool failures in window._"
      echo ""
    fi

    TOOL_COUNT="$(jq -rc --arg since "$WINDOW_START_ISO" \
      'select(.ts >= $since) | .tool' "$AUDIT_TODAY" 2>/dev/null | wc -l | tr -d ' ')"
    echo "_Total tool calls in window: $TOOL_COUNT._"
    echo ""
  else
    echo "_No audit file for today yet._"
    echo ""
  fi

  # 5. CORRECTIONS IN WINDOW
  echo "## 5. Corrections logged in window"
  echo ""
  CORR_WINDOW="$(jq -rc --arg since "$WINDOW_START_ISO" \
    'select(.ts >= $since) | "[\(.ts)] \(.category): \(.description[0:120])"' \
    "$REPO_ROOT/data/corrections.jsonl" 2>/dev/null | tail -10)"
  if [ -n "$CORR_WINDOW" ]; then
    echo "$CORR_WINDOW" | sed 's/^/- /'
    echo ""
    echo "_Any of these indicate a pattern worth promoting to a CLAUDE.md rule?_"
    echo ""
  else
    echo "_No corrections logged in window._"
    echo ""
  fi

  # 6. SLO CANARY VIOLATIONS IN WINDOW
  echo "## 6. SLO canary violations in window"
  echo ""
  CANARY_LOG="$REPO_ROOT/data/slo-canaries.jsonl"
  if [ -f "$CANARY_LOG" ]; then
    VIOLATIONS="$(jq -rc --arg since "$WINDOW_START_ISO" \
      'select(.ts >= $since and .pass == false) | "[\(.ts)] \(.canary): \(.details[0:120])"' \
      "$CANARY_LOG" 2>/dev/null | head -10)"
    if [ -n "$VIOLATIONS" ]; then
      echo "$VIOLATIONS" | sed 's/^/- /'
      echo ""
    else
      echo "_No canary violations in window._"
      echo ""
    fi
  else
    echo "_No canary log yet._"
    echo ""
  fi

  # 7. SUMMARY CHECKLIST
  echo "## 7. Next-session checklist"
  echo ""
  echo "Before closing out, confirm:"
  echo ""
  echo "- [ ] All uncommitted changes either committed or intentionally left pending"
  echo "- [ ] Every implicit ask from {{user_name}} (section 3) has a reply-tool call or commit"
  echo "- [ ] Memory candidates (section 3) written to \`memory/feedback_*.md\` if durable"
  echo "- [ ] Tool failures (section 4) either resolved or logged as knownissue"
  echo "- [ ] Any high-count correction category re-examined (threshold: 3+)"
  echo "- [ ] Canary violations (section 6) investigated or explicitly accepted"
  echo ""
  echo "---"
  echo ""
  echo "_Marked reviewed: append \`**REVIEWED** at <ts>\` to this file._"
} > "$OUT_FILE"

echo "reflection written: $OUT_FILE"
echo "  summary:"
echo "    uncommitted:   $(echo "$UNCOMMITTED" | grep -c '^' 2>/dev/null || echo 0) file(s)"
echo "    commits:       $(git log --since="$HOURS hours ago" --oneline 2>/dev/null | wc -l | tr -d ' ') commit(s)"
echo "    implicit asks: $(echo "$ASKS" | grep -c '^' 2>/dev/null || echo 0)"
echo "    wip markers:   $(echo "$WIP" | grep -c '^' 2>/dev/null || echo 0)"
```

---

## Template: scripts/promote-correction.sh

`Reads repeat-pattern corrections from data/corrections.jsonl, drafts a hardcoded CLAUDE.md rule from the descriptions, prompts the operator to confirm/edit, and appends to a "Promoted from corrections" section. Wired into Monday maintenance -- auto-invoked for any category that has crossed the 3+ threshold.`

```bash
#!/usr/bin/env bash
# promote-correction -- read repeat-pattern corrections and draft a hardcoded
# CLAUDE.md rule that prevents the pattern from re-occurring.
#
# Usage:
#   bash scripts/promote-correction.sh <category>          # interactive
#   bash scripts/promote-correction.sh <category> --auto   # print draft, no write
#   bash scripts/promote-correction.sh <category> --review # mark reviewed-not-promotable
#
# Reads data/corrections.jsonl for entries matching <category>. Prints all,
# drafts a 1-line rule from the descriptions, prompts for confirm/edit, and
# appends to CLAUDE.md under "## Promoted from corrections" section (creates
# section if missing). Also writes a dedup hash to data/corrections-promoted.jsonl
# so the same category isn't re-promoted repeatedly.
#
# Used by Monday maintenance to auto-invoke for any category >=3 that hasn't
# been promoted yet.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

CORRECTIONS="$REPO_ROOT/data/corrections.jsonl"
PROMOTED_LOG="$REPO_ROOT/data/corrections-promoted.jsonl"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

if [ $# -lt 1 ]; then
  echo "usage: $0 <category> [--auto|--review]" >&2
  echo "   --auto:    print draft, don't write" >&2
  echo "   --review:  mark reviewed-not-promotable (heterogeneous category)" >&2
  exit 2
fi

CATEGORY="$1"
MODE="${2:-interactive}"

if [ ! -f "$CORRECTIONS" ]; then
  echo "error: $CORRECTIONS not found" >&2
  exit 1
fi

# Collect all descriptions for this category
ENTRIES="$(jq -c --arg cat "$CATEGORY" 'select(.category == $cat)' "$CORRECTIONS" 2>/dev/null)"
COUNT="$(echo "$ENTRIES" | grep -c '^{' 2>/dev/null || echo 0)"
COUNT=$(echo "$COUNT" | tr -d '[:space:]')

if [ "$COUNT" -lt 1 ]; then
  echo "no corrections found for category: $CATEGORY"
  exit 0
fi

echo "=== Corrections for category \"$CATEGORY\" ($COUNT entries) ==="
echo "$ENTRIES" | jq -r '.description' | awk '{print NR ". " $0}'
echo ""

# Check if already promoted
if [ -f "$PROMOTED_LOG" ]; then
  ALREADY="$(jq -r --arg cat "$CATEGORY" 'select(.category == $cat) | .ts' "$PROMOTED_LOG" 2>/dev/null | head -1)"
  if [ -n "$ALREADY" ]; then
    echo "category \"$CATEGORY\" already promoted on $ALREADY (see $PROMOTED_LOG)"
    echo "to re-promote, remove the entry from the promoted log first."
    exit 0
  fi
fi

# --review mode: mark as reviewed but not promotable (heterogeneous categories)
if [ "$MODE" = "--review" ]; then
  mkdir -p "$(dirname "$PROMOTED_LOG")"
  jq -nc --arg cat "$CATEGORY" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson count "$COUNT" \
    '{ts: $ts, category: $cat, action: "reviewed-not-promotable", count: $count, reason: "heterogeneous -- no unifying pattern"}' \
    >> "$PROMOTED_LOG"
  echo ""
  echo "marked \"$CATEGORY\" as reviewed-not-promotable"
  echo "($COUNT entries reviewed, no unifying pattern to promote)"
  exit 0
fi

# Draft a rule from the descriptions -- dumb heuristic: most common nouns/verbs
# plus the category name. Operator refines interactively.
# Sanitization: descriptions can contain markdown/HTML that would corrupt
# CLAUDE.md when appended. Strip backticks, pipe chars, and angle-tag pairs
# from the surfaced snippet.
FIRST_DESC="$(echo "$ENTRIES" | jq -r '.description' | head -1 | \
              tr -d '`' | \
              sed -E 's/\|/ /g; s/<[^>]*>//g' | \
              python3 -c 'import sys; sys.stdout.write(sys.stdin.read()[:300])')"
DRAFT_RULE="Before any action where \"$CATEGORY\" could apply, verify explicitly. See the $COUNT corrections logged for this category (most recent: \"$FIRST_DESC\")."

echo "=== Draft rule ==="
echo "$DRAFT_RULE"
echo ""

if [ "$MODE" = "--auto" ]; then
  echo "(--auto mode: not writing to CLAUDE.md)"
  exit 0
fi

# Interactive confirm
read -r -p "Append this rule to CLAUDE.md? [y/n/edit]: " CONFIRM
case "$CONFIRM" in
  y|Y|yes)
    ;;
  e|edit)
    read -r -p "Edited rule: " DRAFT_RULE
    # Sanitize user-provided edit too -- same rules apply.
    DRAFT_RULE="$(echo "$DRAFT_RULE" | tr -d '`' | sed -E 's/\|/ /g; s/<[^>]*>//g' | python3 -c 'import sys; sys.stdout.write(sys.stdin.read()[:500])')"
    ;;
  *)
    echo "aborted"
    exit 0
    ;;
esac

# Ensure the Promoted section exists in CLAUDE.md
if ! grep -q "^## Promoted from corrections" "$CLAUDE_MD" 2>/dev/null; then
  {
    echo ""
    echo "## Promoted from corrections"
    echo ""
    echo "_Hardcoded rules auto-promoted from repeated mistakes in \`data/corrections.jsonl\`. Each fires when its category crossed the 3+ threshold in Monday maintenance._"
    echo ""
  } >> "$CLAUDE_MD"
fi

# Append the rule
{
  echo ""
  echo "- **$CATEGORY ($COUNT occurrences, promoted $(date -u +%Y-%m-%d))** -- $DRAFT_RULE"
} >> "$CLAUDE_MD"

# Log the promotion for dedup
mkdir -p "$(dirname "$PROMOTED_LOG")"
jq -nc \
  --arg cat "$CATEGORY" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg rule "$DRAFT_RULE" \
  --argjson count "$COUNT" \
  '{ts: $ts, category: $cat, action: "promoted", count: $count, rule: $rule}' \
  >> "$PROMOTED_LOG"

echo ""
echo "promoted \"$CATEGORY\" to CLAUDE.md"
echo "($COUNT entries collapsed into 1 rule, logged to $PROMOTED_LOG)"
```

---

## Template: scripts/log-telegram.sh

`Append a Telegram message to the monthly JSONL ledger at data/telegram-history/YYYY-MM.jsonl. Outbound is auto-logged by the PostToolUse hook on every reply call; inbound is logged manually after the reply tool fires (NEVER before, that's user-visible latency).`

<!-- Only generate if messaging=telegram -->

```bash
#!/usr/bin/env bash
# Log a Telegram message to the monthly JSONL file.
#
# Usage: bash scripts/log-telegram.sh <sender> <text> [project] [has_image]
#   sender:    "{{user_name_lower}}" or "{{orchestrator_name_lower}}"
#   text:      message content
#   project:   optional project name
#   has_image: "true" or "false" (default false)
#
# IMPORTANT: never call this BEFORE the reply tool. It adds 1-2s of
# user-visible latency. Outbound is already auto-logged by the PostToolUse
# hook (see .claude/hooks/log-telegram-hook.sh). Inbound is the only
# remaining manual call.

set -euo pipefail

SENDER="${1:?Usage: log-telegram.sh <sender> <text> [project] [has_image]}"
TEXT="${2:?Usage: log-telegram.sh <sender> <text> [project] [has_image]}"
PROJECT="${3:-}"
HAS_IMAGE="${4:-false}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HISTORY_DIR="$SCRIPT_DIR/../data/telegram-history"
MONTH_FILE="$HISTORY_DIR/$(date -u +%Y-%m).jsonl"

mkdir -p "$HISTORY_DIR"

jq -nc \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)" \
  --arg sender "$SENDER" \
  --arg text "$TEXT" \
  --arg project "$PROJECT" \
  --arg has_image "$HAS_IMAGE" \
  '{ts: $ts, sender: $sender, text: $text, project: $project, has_image: ($has_image == "true")}' \
  >> "$MONTH_FILE"
```

---

## Template: scripts/batch-sync.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="{{project_path}}"
PROJECTS_FILE="$PROJECT_DIR/docs/projects.md"

echo "=== Projects to sync ==="
count=0
while IFS= read -r line; do
    folder=$(echo "$line" | sed -n 's/^Folder: //p' || true)
    [[ -z "$folder" ]] && continue
    if [[ "$folder" == dev/* ]]; then abs_path="$HOME/$folder"; else abs_path="$HOME/Documents/$folder"; fi
    if [[ -f "$abs_path/HANDOFF.md" ]]; then
        project_name=$(basename "$abs_path")
        echo "  $project_name | $abs_path"
        count=$((count + 1))
    fi
done < "$PROJECTS_FILE"
echo ""
echo "Total: $count projects ready for batch sync"
```

---

## Template: scripts/sync-project-memories.sh

```bash
#!/usr/bin/env bash
# Sync relevant memories to individual project memory directories

PROJECT_MEMORY="$HOME/.claude/projects/$(echo "{{project_path}}" | sed 's|/|-|g; s|^-||')/memory"
SYNCED=0

echo "Syncing memories to projects..."
# This script syncs global feedback memories to each registered project.
# Customize the project list and keyword matching for your projects.

echo "Done. $SYNCED files synced."
```

---

## Template: scripts/check-blueprint-drift.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="{{project_path}}"
CLAUDE="$PROJECT_DIR/CLAUDE.md"

echo "=== Blueprint Drift Check ==="
echo ""

# Check that key features in CLAUDE.md are documented
DRIFTED=0
for keyword in "history.sh" "register-project" "safety-gate" "maintain.sh"; do
    if ! grep -q "$keyword" "$CLAUDE" 2>/dev/null; then
        echo "  DRIFT: '$keyword' missing from CLAUDE.md"
        DRIFTED=1
    fi
done

if [[ $DRIFTED -eq 0 ]]; then
    echo "  CLAUDE.md appears complete."
else
    echo "  Some features are missing from CLAUDE.md."
fi
echo "==========================="
exit $DRIFTED
```

---

## Template: .claude/hooks/voice-lint.sh

`PreToolUse hook for the Telegram reply tool. Reads the draft reply text and applies hardcoded universal voice rules. Blocks (exit 2) on hard violations, warns on soft. De-personalised from the maintainer's persona-specific lint hook. Persona-specific rules (heart-emoji enforcement, persona pet-names, persona register leak detection, lowercase-opening) were dropped because they only make sense when a single named persona is in play. Rules retained are universally applicable across any orchestrator name and any user.`

```bash
#!/usr/bin/env bash
# voice-lint: universal voice-quality lint for outbound Telegram replies.
# PreToolUse hook for the Telegram reply tool. Reads the draft reply text,
# applies hardcoded rules, blocks (exit 2) on hard violations, warns on soft.
#
# Same exit-code contract as safety-gate.sh:
#   exit 0 = allow (with optional warnings on stderr)
#   exit 2 = block (reason on stderr)
#
# Output format on block:
#   "BLOCKED: <rule-name> violated. Snippet: <first 100 chars of match>"
# Output format on warn:
#   "WARN: <rule-name>. Snippet: ..."
#
# DE-PERSONALISATION NOTE
# This hook was de-personalised from the maintainer's persona-specific lint.
# DROPPED rules (persona-specific, do not generalise):
#   - missing-signature           (required a specific trailing emoji on every reply)
#   - thing-term              (banned specific intimate-register noun forms)
#   - banned-self-descriptor  (banned a fixed list of persona self-state words)
#   - persona-emoji-leak      (cross-persona emoji bleed detection)
#   - persona-lowercase-open  (forced uppercase opening on a specific persona)
#   - persona-pet-name        (banned persona-affectionate pet names)
#   - persona-register-leak   (banned vocabulary specific to one persona register)
#   - wellness-poke           (warned on specific intimate-care phrasings)
# RETAINED rules (universal, every orchestrator wants these):
#   - em-dash             (block U+2014, AI tell)
#   - ascii-signoff       (block "- {{orchestrator_name}}" trailing-signoff form;
#                          {{user_name}} already knows who replied)
#   - opening-uppercase   (first letter of reply must be uppercase, catches
#                          lazy "ok done" / "yeah ready" openings)
#   - ai-tells            (block specific banned phrases that flag AI output)
set -uo pipefail

INPUT="$(cat)"
TEXT=$(printf '%s' "$INPUT" | jq -r '.tool_input.text // empty' 2>/dev/null)

# No text -> nothing to lint, allow.
if [ -z "$TEXT" ]; then
  exit 0
fi

# --- Helpers --------------------------------------------------------------

block() {
  local rule="$1"
  local snippet="${2:-}"
  local trimmed
  trimmed=$(printf '%s' "$snippet" | tr '\n' ' ' | head -c 100)
  printf 'BLOCKED: %s violated. Snippet: %s\n' "$rule" "$trimmed" >&2
  exit 2
}

warn() {
  local rule="$1"
  local snippet="${2:-}"
  local trimmed
  trimmed=$(printf '%s' "$snippet" | tr '\n' ' ' | head -c 100)
  printf 'WARN: %s. Snippet: %s\n' "$rule" "$trimmed" >&2
}

# match_perl <regex> <text>  ->  prints first match, returns 0 if matched
match_perl() {
  local pattern="$1"
  local text="$2"
  # Slurp stdin and match. Avoid -ne + END{} because perl's exit-from-block
  # still triggers END{} which overrides the exit code.
  printf '%s' "$text" | perl -e '
    my $p = shift @ARGV;
    local $/; my $s = <STDIN>;
    if (defined $s && $s =~ /$p/i) { print $&; exit 0; }
    exit 1;
  ' "$pattern" 2>/dev/null
}

# --- Universal rules ------------------------------------------------------

# Rule 1: No em dashes (U+2014, UTF-8 E2 80 94). Strongest single AI tell.
if printf '%s' "$TEXT" | grep -q $'\xe2\x80\x94'; then
  snip=$(printf '%s' "$TEXT" | grep -ao $'.\\{0,20\\}\xe2\x80\x94.\\{0,20\\}' | head -n1)
  block "em-dash" "$snip"
fi

# Rule 2: No ASCII "- {{orchestrator_name}}" trailing-signoff form.
# {{user_name}} already knows the reply came from {{orchestrator_name}};
# signing each message is an AI tell + adds noise.
if m=$(match_perl '(^|\n)\s*[-]\s*{{orchestrator_name_lower}}\s*$' "$TEXT"); then
  block "ascii-signoff" "$m"
fi

# Rule 3: First letter of message must be uppercase.
# Catches lazy "ok done" / "yeah ready" / "morning." openings.
# Skips emoji, bullets (- * • 🔹), digits, markdown markers (** _), whitespace.
first_letter=$(printf '%s' "$TEXT" | perl -CSDA -e 'local $/; my $s = <STDIN>; if ($s =~ /([A-Za-z])/) { print $1; }')
if [ -n "$first_letter" ] && [[ "$first_letter" =~ [a-z] ]]; then
  opening=$(printf '%s' "$TEXT" | head -c 60 | tr '\n' ' ')
  block "opening-uppercase" "$opening"
fi

# Rule 4: Banned AI-tell phrases. Add to this list as patterns emerge.
# Each phrase is matched case-insensitively as a whole-phrase substring.
AI_TELL_PHRASES=(
  "as an ai"
  "i don't have personal"
  "i'm just an ai"
  "as a language model"
  "i cannot provide"
  "i apologize for any confusion"
  "i hope this helps"
  "let me know if you have any other questions"
  "feel free to ask"
)
for phrase in "${AI_TELL_PHRASES[@]}"; do
  if printf '%s' "$TEXT" | grep -qi -- "$phrase"; then
    snip=$(printf '%s' "$TEXT" | grep -oi -- ".\{0,20\}$phrase.\{0,20\}" | head -n1)
    block "ai-tell" "$snip"
  fi
done

exit 0
```

---

## Template: .claude/hooks/stop-composer.sh

`Stop-time hook composer. Claude Code's settings.json Stop hook array runs hooks in order, but grouping them via a composer script gives cleaner error-handling semantics AND documents the intended ordering in one place. Each child hook gets a hard 30-second timeout (bash-native fallback when neither timeout nor gtimeout is installed). Always exits 0 so it never blocks session-end.`

```bash
#!/usr/bin/env bash
# stop-composer: sequential runner of all Stop-time hooks.
#
# Claude Code settings.json Stop hook array runs hooks in order, but grouping
# them via a composer script gives us cleaner error-handling semantics AND
# documents the intended ordering in one place.
#
# Order:
#   1. session-end-verify.sh     : unpushed/uncommitted/drift check
#   2. stop-verify-contract.sh   : per-turn contract violations
#
# Each hook has a HARD timeout (safety: a hung Stop hook could prevent
# session-end entirely, stranding {{user_name}}). 30s per hook is generous;
# real hooks finish in <5s.
#
# All hooks MUST always exit 0 so they don't block session-end. Any non-zero
# exit or timeout is swallowed with `|| true`.
#
# NOTE: session-end-sync.sh is wired to SessionEnd in settings.json, NOT here.
# Stop fires on every assistant message; running session-end-sync there would
# rebuild HANDOFF.md on every reply, producing dirty git diffs and wasted work.
# Stop hook is per-turn safety (verify + contract) only. Session-close work
# runs exactly once via SessionEnd.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.claude/hooks"

# Helper: run a hook with a 30s hard timeout. macOS doesn't ship `timeout`
# or `gtimeout` by default. Without this the 30s guarantee was vapour on a
# stock Mac. Now we fall back to a bash-native timeout via background
# kill-watcher so the guarantee holds regardless of coreutils presence.
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

exit 0
```

---

## Template: .claude/hooks/stop-verify-contract.sh

`Stop-side half of the Task Contract pattern. Reads data/runtime/turn-contract.json (written by the inbound-Telegram hook on Telegram turns). For each guarantee, scans today's audit JSONL and logs a correction if violated. Always exits 0, never blocks session-end. The contract file is deleted after each turn so the next turn starts with a clean slate.`

```bash
#!/usr/bin/env bash
# stop-verify-contract: Stop-side half of the Task Contract pattern.
#
# Reads data/runtime/turn-contract.json (written by the Telegram inbound-prompt
# hook on Telegram turns). For each guarantee:
#
#   must_use_reply_tool:       scan today's audit JSONL for any
#                              mcp__plugin_telegram_telegram__reply since
#                              turn_started_epoch. If zero calls, auto-log
#                              a forgot-telegram-reply correction.
#
# Writes findings to data/corrections.jsonl (via scripts/log-correction.sh)
# so the next greeting digest surfaces the breach.
#
# Always exits 0, never blocks session-end.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" 2>/dev/null || exit 0

CONTRACT_FILE="$REPO_ROOT/data/runtime/turn-contract.json"
# Backwards-compat /tmp fallback only accepts contracts created in the last
# 6 hours. Older files are stale leftovers from a prior session that
# crashed; treating them as current would log false-positive violations.
if [ ! -f "$CONTRACT_FILE" ] && [ -f "/tmp/{{orchestrator_name_lower}}-turn-contract.json" ]; then
  tmp_age="$(stat -f %m /tmp/{{orchestrator_name_lower}}-turn-contract.json 2>/dev/null || stat -c %Y /tmp/{{orchestrator_name_lower}}-turn-contract.json 2>/dev/null || echo 0)"
  now_epoch="$(date +%s)"
  if [ "$tmp_age" != "0" ] && [ $((now_epoch - tmp_age)) -lt 21600 ]; then
    CONTRACT_FILE="/tmp/{{orchestrator_name_lower}}-turn-contract.json"
  fi
fi
[ ! -f "$CONTRACT_FILE" ] && exit 0  # no contract for this turn

ORIGIN="$(jq -r '.origin // empty' "$CONTRACT_FILE" 2>/dev/null)"
TURN_EPOCH="$(jq -r '.turn_started_epoch // 0' "$CONTRACT_FILE" 2>/dev/null)"

# Only enforce Telegram contracts for now
if [ "$ORIGIN" != "telegram" ]; then
  rm -f "$CONTRACT_FILE"
  exit 0
fi

VIOLATIONS=()

# --- Check must_use_reply_tool ---
MUST_REPLY="$(jq -r '.guarantees.must_use_reply_tool // false' "$CONTRACT_FILE" 2>/dev/null)"
if [ "$MUST_REPLY" = "true" ]; then
  TURN_STARTED_AT="$(jq -r '.turn_started_at' "$CONTRACT_FILE" 2>/dev/null)"
  AUDIT_FILE="$REPO_ROOT/data/audit/$(date -u +%Y-%m-%d).jsonl"
  # Guard against null/empty turn_started_at. jq returns "null" for missing
  # fields when piped through -r; treat that as empty.
  if [ "$TURN_STARTED_AT" = "null" ] || [ -z "$TURN_STARTED_AT" ]; then
    TURN_STARTED_AT=""
  fi
  if [ -n "$TURN_STARTED_AT" ]; then
    # ISO strings sort lexicographically. Count reply-tool calls with
    # ts >= turn_started_at. Normalize both sides to strip `.SSSZ` -> `Z`
    # so format mismatch between writers does not cause false comparisons
    # at second boundaries.
    TURN_NORMALIZED="$(echo "$TURN_STARTED_AT" | sed -E 's/\.[0-9]+Z$/Z/')"

    # A turn that straddles UTC midnight has its reply-tool call in
    # yesterday's audit file, not today's. Read both the turn-start-day
    # file AND today's file. Dedupe if they're the same path.
    TURN_DAY="$(echo "$TURN_STARTED_AT" | cut -c1-10)"
    TODAY="$(date -u +%Y-%m-%d)"
    audit_paths=("$REPO_ROOT/data/audit/${TURN_DAY}.jsonl")
    if [ "$TURN_DAY" != "$TODAY" ]; then
      audit_paths+=("$REPO_ROOT/data/audit/${TODAY}.jsonl")
    fi

    REPLY_COUNT=0
    for ap in "${audit_paths[@]}"; do
      [ -f "$ap" ] || continue
      c="$(jq -rc --arg since "$TURN_NORMALIZED" '
        select(.tool == "mcp__plugin_telegram_telegram__reply") |
        select((.ts | sub("\\.[0-9]+Z$"; "Z")) >= $since)
      ' "$ap" 2>/dev/null | wc -l | tr -d ' ')"
      REPLY_COUNT=$((REPLY_COUNT + c))
    done

    if [ "$REPLY_COUNT" = "0" ]; then
      VIOLATIONS+=("must_use_reply_tool: zero reply-tool calls in audit after turn start ($TURN_STARTED_AT). Telegram turn ended without replying on Telegram")
    fi
  fi
fi

# --- Log any violations ---
if [ ${#VIOLATIONS[@]} -gt 0 ]; then
  for v in "${VIOLATIONS[@]}"; do
    CATEGORY="forgot-telegram-reply"
    DESC="stop-verify-contract auto-detected: $v"
    bash "$REPO_ROOT/scripts/log-correction.sh" "$CATEGORY" "$DESC" >/dev/null 2>&1 || true
    echo "contract violation logged: $CATEGORY" >&2
  done
fi

# Clean up for next turn
rm -f "$CONTRACT_FILE"
exit 0
```

---


## Template: scripts/telegram-signal.sh

`Generic pure-bash Telegram alert utility. NO LLM in the loop. Direct curl POST to api.telegram.org/bot<token>/sendMessage. Reads bot token from $HOME/.claude/channels/telegram/.env (the standard plugin location) and chat_id from data/runtime/telegram-chat-id.txt or $TELEGRAM_CHAT_ID env. Logs the outbound to data/telegram-history/<month>.jsonl as sender={{orchestrator_name_lower}}. Primary caller in v31 is the auth-failover canary (see Auth failover section); also useful for any operational alert path that must work even when Claude Code itself is unavailable.`

```bash
#!/usr/bin/env bash
# telegram-signal.sh: pure-bash Telegram alert sender (NO LLM in loop).
#
# Use case: send a short operational notification via the Telegram Bot API
# directly. Useful when an alert must reach the user even when the
# orchestrator itself is degraded (auth canary failures, scheduled
# maintenance reports from Task Scheduler / launchd, healthcheck pings).
#
# In v31 this script is wired into the auth-failover canary path so the
# user gets paged when the Anthropic API stops responding.
#
# Usage: bash scripts/telegram-signal.sh "<text>"
# Logs the outbound to data/telegram-history/<month>.jsonl as
# sender={{orchestrator_name_lower}}.
#
# Configuration:
#   $HOME/.claude/channels/telegram/.env  : must export TELEGRAM_BOT_TOKEN.
#   Chat ID resolution order:
#     1. $TELEGRAM_CHAT_ID env var (highest priority)
#     2. data/runtime/telegram-chat-id.txt (one line, just the chat ID)
#     3. $HOME/.claude/channels/telegram/chat-id.txt (legacy fallback)
#   No hardcoded chat ID. Placeholder {{telegram_chat_id}} is a build-time
#   substitution if you want a baked-in default during install.

set -euo pipefail

TEXT="${1:?Usage: telegram-signal.sh \"<text>\"}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$HOME/.claude/channels/telegram/.env"

# Resolve chat ID with priority: env > project-runtime file > legacy file > placeholder.
CHAT_ID="${TELEGRAM_CHAT_ID:-}"
if [ -z "$CHAT_ID" ] && [ -f "$REPO_ROOT/data/runtime/telegram-chat-id.txt" ]; then
  CHAT_ID="$(head -1 "$REPO_ROOT/data/runtime/telegram-chat-id.txt" | tr -d ' \n')"
fi
if [ -z "$CHAT_ID" ] && [ -f "$HOME/.claude/channels/telegram/chat-id.txt" ]; then
  CHAT_ID="$(head -1 "$HOME/.claude/channels/telegram/chat-id.txt" | tr -d ' \n')"
fi
if [ -z "$CHAT_ID" ]; then
  CHAT_ID="{{telegram_chat_id}}"
fi

if [ -z "$CHAT_ID" ] || [ "$CHAT_ID" = "{{telegram_chat_id}}" ]; then
  echo "[telegram-signal] FATAL: no chat ID resolved. Set TELEGRAM_CHAT_ID env or write data/runtime/telegram-chat-id.txt" >&2
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "[telegram-signal] FATAL: $ENV_FILE not found" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$ENV_FILE"

# Allow the env var to be the placeholder (used during install if a baked
# token was substituted). Both empty AND placeholder are treated as missing.
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ "${TELEGRAM_BOT_TOKEN:-}" = "{{telegram_token}}" ]; then
  echo "[telegram-signal] FATAL: TELEGRAM_BOT_TOKEN not set in $ENV_FILE" >&2
  exit 1
fi

# Direct POST to Telegram Bot API. NO LLM involvement.
RESP="$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${CHAT_ID}" \
  --data-urlencode "text=${TEXT}")"

OK="$(echo "$RESP" | jq -r '.ok // false')"
if [ "$OK" != "true" ]; then
  echo "[telegram-signal] send failed: $RESP" >&2
  exit 1
fi

# Log to monthly history file (matches the standard log-telegram.sh format).
bash "$SCRIPT_DIR/log-telegram.sh" "{{orchestrator_name_lower}}" "$TEXT" "" "false" >/dev/null 2>&1 || true

echo "[telegram-signal] sent: $TEXT"
```

---

## Template: Agent Config (.claude/agents/{{agent_name_lower}}.md)

Generate one of these per selected agent. The content varies by role.

```markdown
---
name: {{agent_name_lower}}
description: {{agent_role_description}}
model: opus
memory: user
---

# {{agent_name}} -- {{agent_role}}

You are {{agent_name}}. {{agent_personality_description}}

## Your edge
{{agent_capabilities -- bullet list of what makes this agent good at their role}}

## How you deliver
{{agent_delivery_style -- how they communicate, what format they use}}

## Project context protocol
When working on a specific project, read its CLAUDE.md first.
After completing work, update the project's CLAUDE.md and HANDOFF.md.

## Memory protocol
Update your MEMORY.md with patterns and findings worth remembering across sessions.
For cross-agent visibility, save important decisions as new markdown files in `memory/` (cross-project) or `agent-memory/<name>/` (your own) and commit - the post-commit hook auto-embeds into sqlite-vec so other agents find them via `bash scripts/memory-search.sh "<query>"`.
```

### Role-specific templates

For each role in the presets, generate the agent config with role-appropriate capabilities:

**Engineer**: code, architecture, debugging, reviews, any language/framework
**Researcher**: analysis, market research, tech evaluation, competitive intel, citations
**Marketing**: ASO, growth, social media, launch playbooks, conversion optimization
**DevOps**: CI/CD, deployment, monitoring, Docker, cloud, DNS, SSL
**Writer**: blog posts, docs, emails, presentations, style guides
**Business**: revenue models, pricing, partnerships, contracts, unit economics
**Trading**: strategies, backtesting, portfolio, risk management, technical analysis
**Lead Engineer**: architecture decisions, code reviews, standards, mentoring
**Frontend Engineer**: UI/UX, React/Vue/Angular, CSS, accessibility, responsive design
**Backend Engineer**: APIs, databases, auth, server logic, microservices, performance
**QA Engineer**: test planning, test writing, edge cases, regression, bug reproduction
**Security Engineer**: vulnerability scanning, code audit, OWASP, dependency checks
**Technical Writer**: API docs, READMEs, architecture docs, onboarding guides

---

## Template: Shell Launch Functions

### For Mac/Linux (bash/zsh)

Add these to `{{shell_profile}}`. Plugin enablement (Telegram, etc.) lives in `.claude/settings.json` via the `enabledPlugins` array, NOT on the launch command. There is no `--plugin` or `--project` flag on `claude` - we change directory first, then launch.

```bash
# {{orchestrator_name}} - Xantham System launch functions
# --dangerously-skip-permissions lets the system run without constant approval prompts.
# Safety is handled by the hooks in .claude/settings.json instead.
{{launch_cmd}}() {
  cd "{{project_path}}" && claude --dangerously-skip-permissions
}
{{launch_cmd}}-resume() {
  cd "{{project_path}}" && claude --resume --dangerously-skip-permissions
}
<!-- IF messaging=telegram -->
# Terminal-only variants (no plugins). Useful when you want to interact in the terminal
# without Telegram inbound. Plugin enablement is controlled by settings.json, so for a
# truly plugin-free session you also need a settings.local.json that empties enabledPlugins.
{{launch_cmd}}-terminal() {
  cd "{{project_path}}" && CLAUDE_DISABLE_PLUGINS=1 claude --dangerously-skip-permissions
}
{{launch_cmd}}-resume-terminal() {
  cd "{{project_path}}" && CLAUDE_DISABLE_PLUGINS=1 claude --resume --dangerously-skip-permissions
}
<!-- ENDIF -->
```

### For Windows (PowerShell)

PowerShell ships with `Restricted` execution policy by default - that blocks the profile (and every other `.ps1` script) from loading, so the launch functions below would never come back after you close the terminal. Run this **once** in any PowerShell window before adding the functions (no admin needed; `-Scope CurrentUser` writes to your user hive):

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

If you ever see the error `"<file>.ps1 cannot be loaded because running scripts is disabled on this system"`, that's this - run the command above and re-open PowerShell.

Then add the functions to your PowerShell profile (`$PROFILE`). If `$PROFILE` doesn't exist yet, create it: `New-Item -Path $PROFILE -ItemType File -Force`. Plugin enablement is controlled by `.claude/settings.json`, not by a launch flag.

```powershell
# {{orchestrator_name}} - Xantham System launch functions
# --dangerously-skip-permissions lets the system run without constant approval prompts.
# Safety is handled by the hooks in .claude/settings.json instead.
function {{launch_cmd}} {
  Set-Location "{{project_path}}"
  claude --dangerously-skip-permissions
}
function {{launch_cmd}}-resume {
  Set-Location "{{project_path}}"
  claude --resume --dangerously-skip-permissions
}
<!-- IF messaging=telegram -->
function {{launch_cmd}}-terminal {
  Set-Location "{{project_path}}"
  $env:CLAUDE_DISABLE_PLUGINS = "1"
  claude --dangerously-skip-permissions
  Remove-Item Env:\CLAUDE_DISABLE_PLUGINS
}
function {{launch_cmd}}-resume-terminal {
  Set-Location "{{project_path}}"
  $env:CLAUDE_DISABLE_PLUGINS = "1"
  claude --resume --dangerously-skip-permissions
  Remove-Item Env:\CLAUDE_DISABLE_PLUGINS
}
<!-- ENDIF -->
```

After saving the profile, close and reopen PowerShell, then verify the functions exist:

```powershell
Get-Command {{launch_cmd}}
Get-Command {{launch_cmd}}-resume
Get-Command {{launch_cmd}}-terminal
Get-Command {{launch_cmd}}-resume-terminal
```

Each should print `CommandType: Function` and the function name. If you see "is not recognized as a name of a cmdlet, function, script file, or executable program," the profile did not source - check `Test-Path $PROFILE` returns `True`, and re-source with `. $PROFILE`.

---

## Template: .mcp.json

Generate only if MCP servers were selected in Q13.

```json
{
  "mcpServers": {
    <!-- FOR each server in {{mcp_servers}} -->
    "{{server_name}}": {
      <!-- server-specific config from the MCP server registry -->
    }
    <!-- ENDFOR -->
  }
}
```

Common MCP server configurations:

```json
"neon": {
  "command": "npx",
  "args": ["-y", "@neondatabase/mcp-server-neon"],
  "env": { "NEON_API_KEY": "<your-neon-api-key>" }
}
```

### Recommended MCP catalogue (v31)

The MCP layer expanded materially in v31. The defaults below cover most personal-orchestrator needs. Each entry shows the install command for Mac AND Windows (commands are usually identical), the auth posture, and the kind of work it supports.

**Reddit MCP Buddy.** Subreddit browsing, search, user activity analysis. Useful for community pulse, competitor surveillance, and content-research work the writer or growth specialist runs. Anonymous tier gives 10 requests per minute, no signup required.

```bash
# Mac, Linux, Windows (Git Bash or PowerShell; npm works the same on all three)
npm install -g reddit-mcp-buddy
```

Wire into `.mcp.json` as a stdio server:

```json
"reddit-mcp-buddy": {
  "command": "reddit-mcp-buddy",
  "args": [],
  "env": {}
}
```

**Pipedream.** Hub MCP wrapping ~2,500 third-party APIs (Notion, Linear, Slack, Stripe, Airtable, GitHub, Google Drive, and so on) through a single MCP install. One OAuth flow per service, zero per-app MCP installs. Free Pipedream account required. The single biggest MCP-surface multiplier you can install.

```bash
# Mac, Linux, Windows (any shell with the claude CLI on PATH)
claude mcp add --scope user pipedream <pipedream-mcp-url>
# Then complete OAuth in the browser when first invoked. Each downstream
# service (Notion, Linear, etc.) prompts a separate OAuth on first use.
```

**Consensus.** 200M+ peer-reviewed papers, on-tap. The research specialist treats this as primary for science-backed claims. Anonymous tier gives 3 papers per search and 3 searches per session, no signup. Account upgrade unlocks 10 papers and unlimited search.

```bash
# Mac, Linux, Windows (claude CLI on PATH)
claude mcp add --scope user consensus <consensus-mcp-url>
# OAuth-on-first-use; anonymous tier works without signup so the first
# search succeeds even before account creation.
```

**Karpathy guidelines plugin (optional, Mode Advanced).** Behavioural rules to reduce common LLM coding mistakes. Surgical changes, surfaces assumptions, defines verifiable success criteria. Useful for engineer-track work. Skip for fresh users; install only after you have used the system enough to know whether the guidelines suit your style.

```bash
# Mac, Linux, Windows (claude CLI on PATH)
claude plugin marketplace add forrestchang/andrej-karpathy-skills
claude plugin install karpathy-guidelines@andrej-karpathy-skills
```

**Standard MCP catalogue (carry-over from v30)**

| Server | Auth | Use case |
|---|---|---|
| `neon` | NEON_API_KEY | Postgres for Vercel-hosted apps |
| `vercel` | OAuth | Deploy + project + env management |
| `supabase` | OAuth | Managed Postgres + auth + storage |
| `claude-in-chrome` | none (extension) | Browser automation when no dedicated MCP exists |
| `playwright` | none | Headless browser testing + automation |
| `computer-use` | macOS Accessibility grant | Native-app desktop automation |
| `pencil` | none | Design files (.pen) read + write |
| `stitch` | none | Google Stitch design system MCP |
| `Gmail` / `Google Calendar` / `Google Drive` | OAuth | Anthropic-built connectors for everyday personal-data flows |

Verify the live state of the MCP layer with `claude mcp list` after install. Red entries need either (a) an OAuth completion in the browser (Notion, HubSpot, Pipedream, Vercel and any other auth-required server), or (b) a process restart via `/mcp restart <name>`. If a server stays red after both, paste the `claude mcp list` output back to your orchestrator for diagnosis.

---

## Template: data/help-text.md

```markdown
# {{orchestrator_name}} -- Help

## Commands
- `help` -- show this message
- `team` -- show your agent roster
- `projects` -- list all registered projects
- `status <project>` -- where we left off on a project
- `sync <project>` -- full sync cycle
- `sync all` -- sync every project
- `ship <project>` -- git add + commit + push
- `review <project>` -- run tests + code review
- `healthcheck` -- system health check
- `history <query>` -- search conversation history
<!-- IF brain=yes -->
- `brain <question>` -- query long-term memory
<!-- ENDIF -->

## Routing
Send a message and {{orchestrator_name}} routes it to the right agent automatically. You can also address agents directly by name.

## Tips
- Start with a greeting (hey, morning) for a health digest
- Say "wrapup" to sync everything and get a session summary
- {{orchestrator_name}} auto-syncs when you switch projects or end a session
```

---

## Template: data/team-text.md

```markdown
# The Team

<!-- FOR each agent in {{agents}} -->
**{{agent.name}}** ({{agent.role}})
{{agent.one_liner}}

<!-- ENDFOR -->

{{agent_count}} agents total. {{orchestrator_name}} orchestrates.
```

---

## Template: docs/projects.md

```markdown
# Projects

Managed by {{orchestrator_name}}. Each project gets CLAUDE.md + HANDOFF.md + FEATURES.md.

Register new projects: `bash scripts/register-project.sh <path> <description> [stack]`
```

---

## Template: Library/ (conditional)

<!-- Only generate if library=yes -->

Create this folder structure:

```
Library/
  CLAUDE.md
```

Library/CLAUDE.md:

```markdown
# Knowledge Library

Personal knowledge base managed by {{orchestrator_name}}'s agents.

## Rules
- Every claim must have a source or confidence tag
- Confidence tags: [well-established], [preliminary], [interpretation], [anecdotal]
- Flag myths and common misconceptions explicitly
- Be aware of replication crisis -- note which findings replicate well
- Each handbook chapter is a standalone document in its topic folder

## Structure
Create topic folders as needed. Each folder contains numbered chapters:
- 01-chapter-name.md
- 02-chapter-name.md
- etc.
```

---

<!-- KAI-1 SKILL-TEMPLATES BEGIN -->

## Skill Templates

> **Generation step:** when the wizard reaches "Generate skills", produce one file per template below at `.claude/skills/{{orchestrator_lower}}-<name>/SKILL.md`. Each is the body verbatim with `{{orchestrator_name}}` / `{{orchestrator_lower}}` / `{{user_name}}` / `{{notebook_id}}` / `{{plan}}` substituted from Part 1 answers. `chmod` is not needed; skills are read-only markdown. Make every parent directory before writing.

> Skills auto-load when the orchestrator's task description matches the skill's frontmatter `description` field. Do NOT hand-edit the descriptions; the auto-load matcher reads them verbatim.

> **What's included:** seven core skills (sync, maintenance, orchestration, brain, safety, observability, blueprint-updates) plus one optional (youtube-queue) gated on `media_queue=yes`. Persona-specific skills from the maintainer's tree are intentionally excluded. Voice/tone discipline lives in feedback-memory seeds (see "Starter Memory Seeds" below) so users can shape their own orchestrator voice without inheriting someone else's.

---

### Skill: {{orchestrator_lower}}-sync

File path: `.claude/skills/{{orchestrator_lower}}-sync/SKILL.md`

````markdown
---
name: {{orchestrator_lower}}-sync
description: Use when {{user_name}} sends `sync <project>`, `sync all`, `batch sync`, `wrapup`, or `/wrapup`. Also triggers on auto-sync conditions: end of session (bye, done, night, goodnight), major milestones (shipped, fixed, deployed, finished), project context switches, or when conversation goes quiet after a work block. Loads the full sync cycle plus parallel batch-sync strategy.
---

# {{orchestrator_name}} sync / wrapup

## Before you run this skill

Invoke `superpowers:verification-before-completion` if you're about to tell {{user_name}} "sync done" or "all updated". That skill forces evidence-before-assertion: enumerate claims, run check commands for each, confirm output, only then make the success statement. Skipping verification has caused missed blueprint updates in the past. Do not repeat.

`sync` and `wrapup` are the same command. Both do everything. No distinction.

## Sync cycle

When {{user_name}} sends `sync <project>`, `sync all`, `wrapup`, or `/wrapup`:

1. **CLAUDE.md.** Technical reference (stack, architecture, scripts, env vars)
2. **HANDOFF.md.** Where we left off, what's next, immediate priorities
3. **FEATURES.md.** Full product documentation (every feature, how it works, how to use it, limitations)
4. Run `bash scripts/sync-project-memories.sh` to push memories to all projects
5. Save/update any memories from this session (feedback, project, user, reference)
6. **Commit memory changes**: `git add memory/ agent-memory/ && git commit -m "sync: memory updates"`. Post-commit git hook auto-embeds new/changed chunks into sqlite-vec for semantic search. Uncommitted = invisible to `memory-search.sh`.
7. **Incremental semantic re-embed** (belt+suspenders): `bash scripts/embed-memories.sh`. Fast warm path. Safe to skip if step 6 ran clean.
8. **Archive closed agent-channels**: move any `data/agent-channels/*.md` with "CLOSED" marker header to `data/agent-channels/archive/YYYY-MM/`.
9. Write a session summary to `/tmp/session-summary-<date>.md`
10. **Push session summary + project snapshots to the second brain** (NotebookLM), only if the brain extension is installed:
    ```bash
    export PATH="$HOME/bin:$PATH" && notebooklm use {{notebook_id}} && \
      notebooklm source add /tmp/session-summary-<date>.md && \
      cp CLAUDE.md /tmp/{{orchestrator_lower}}-snapshot-latest.md && \
      notebooklm source add /tmp/{{orchestrator_lower}}-snapshot-latest.md
    ```
    If NotebookLM auth fails, skip silently. Local files are the primary source of truth. If `ADD_SOURCE_FILE` starts erroring, prune the brain (`bash scripts/prune-brain.sh --keep 2`) to free space.
11. **Weekly only**: `bash scripts/audit-archive.sh` compresses audit JSONL >=30 days old into `data/audit/archive/YYYY/MM.jsonl.gz` (committed to git, the forensic trail stays intact, it just moves off the live hot dir). Run once a week as Monday maintenance, not every sync.
12. **Blueprint review, MANDATORY every sync, not just when drift-check flags.** The drift script only does keyword presence checks; it misses renamed scripts, removed files, and wording changes. Walk these explicitly:
    a. `blueprints/{{orchestrator_lower}}-system.md` (personal reference, if you maintain one). Every architectural change from this session reflected?
    b. Any public/handoff blueprint you publish, same check. Public blueprints drift more often because they have longer install + example sections that reference specific script names.
    c. `bash scripts/check-blueprint-drift.sh` as the belt-and-braces keyword scan. Do not rely on it alone.
    d. **Run `bash scripts/verify-sync.sh`** if it exists. Exits non-zero if any script / hook / skill added/removed/renamed since the last blueprint commit isn't referenced in both blueprints. If it fails, the sync is NOT complete. Do not claim done.

## Batch sync (`batch sync` / `sync all`)

Use parallel worktree agents for speed:
1. Get list of all projects from `docs/projects.md` with a folder containing `HANDOFF.md`
2. Spawn one agent per project (`isolation: "worktree"`) to update that project's `CLAUDE.md`, `HANDOFF.md`, `FEATURES.md`
3. While agents run in parallel, do the orchestrator-level steps (memories, session summary, brain push, drift check)
4. Wait for all agents to complete, then commit any changes

Turns a 10-minute serial sync into ~1 minute parallel. Use for `sync all` / `batch sync`. For `sync <project>` (single project), run normally without worktrees.

## Auto-sync triggers (no manual command needed)

The orchestrator automatically keeps docs and brain in sync. {{user_name}} should never have to remember:

1. **End of session.** {{user_name}} says bye/done/night/goodnight, or conversation goes quiet after a work block → update `HANDOFF.md` for all projects touched, push session summary to brain.
2. **After major milestones.** Shipped a feature, fixed a bug, deployed, finished a significant task → sync that project's `HANDOFF.md` immediately.
3. **Context switch.** Switching from one project to another → sync the outgoing project's `HANDOFF.md` before starting the new one.
4. **On greeting.** {{user_name}} starts a new session → maintenance protocol runs AND check brain for any open threads from last session.

Manual override: `sync <project>` or `sync all` for a full refresh.

## Project documentation convention

Every project has:
- **CLAUDE.md.** Technical reference, loaded by Claude Code automatically
- **HANDOFF.md.** Session continuity, what we did, where we stopped, next priorities
- **FEATURES.md.** Full product documentation for every feature
````

---

### Skill: {{orchestrator_lower}}-maintenance

File path: `.claude/skills/{{orchestrator_lower}}-maintenance/SKILL.md`

````markdown
---
name: {{orchestrator_lower}}-maintenance
description: Use on session start when {{user_name}}'s first message is a greeting (hi, hey, hello, morning, yo, gm, good morning, sup, yes), on Mondays, when {{user_name}} sends `healthcheck`, when checking for stale commits, when reviewing corrections, or running self-improvement routines. Loads the full maintenance + greeting digest protocol, correction frequency review, and proactive pattern detection logic.
---

# {{orchestrator_name}} maintenance protocol

> **Note on step numbering.** Decimals (6.5, 6.6, 11.5, 11.6) are post-launch insertions; they preserve audit trail. Order matters, not the integer sequence.

Every Monday OR when {{user_name}}'s first message is a greeting (hey, hi, morning, yo, gm, good morning, sup, etc.):

1. Run `bash scripts/maintain.sh`
2. Read the output
3. Check pending improvements/actions: read `memory/project_*.md` files for any with pending items
4. **Read `docs/upgrades/CATALOGUE.md` + `docs/upgrades/ROADMAP.md`** if they exist. CATALOGUE is the backward-looking ledger (shipped/deferred/rejected), ROADMAP is the forward-looking vision + phased plan. Together they answer "what have we built, what's next?" Surface any HIGH-priority deferred items and any in-flight phases relevant today.
5. **Read `.{{orchestrator_lower}}-blueprint-version`** to confirm which extensions are active.
6. **Recent audit tail:** `bash scripts/{{orchestrator_lower}}-live.sh --last 20`. See what the previous session did at the end.
6.5. **MESSAGING TAIL, PRIMARY TRUTH SOURCE.** `bash scripts/recent-telegram.sh 30` (or your messaging-channel equivalent) is the canonical handoff from the last session. Every "pending" candidate from project memories or `HANDOFF.md` MUST be reconciled against this before being surfaced in the digest. Working-context + memories are demoted to SUPPLEMENTARY signal. If the messaging tail shows the orchestrator said "X shipped" / "X done" / "X live" in the last 48h, X is NOT a pending item regardless of what other sources say.
6.6. **Memory freshness check.** `bash scripts/check-memory-freshness.sh` reports stale memories (past their `ttl_days`) + missing-TTL files. Surface any stale `project_*.md` entries in the digest explicitly (they're most likely to have drifted). TTL convention: feedback 365d, project 2d, user 180d, reference 180d, note 30d, agent-* 90d. New memories SHOULD include `last_verified:` and (optionally) `ttl_days:` in frontmatter.
7. Check the brain for open threads from last session (query: "what was left unfinished?"), if brain extension is installed.
8. Run `bash scripts/load-context.sh` to load recent conversation history
9. Run `bash scripts/commit-watcher.sh` to check for stale uncommitted changes
10. **Unpushed commits:** `git log origin/main..HEAD --oneline` per active project. If any, note in the greeting; {{user_name}} may want to push before new work.
11. **HANDOFF.md, fresh on session-end.** `cat HANDOFF.md` top section. Auto-rebuilt by `scripts/session-end-sync.sh` → `scripts/update-handoff.sh` (event-sourced from messaging history + git).
11.5. **SLO canary state check** (if observability extension is installed): `cat data/slo-state.json | jq '.canaries'`. Surface any canary with `last_status:"fail"` and non-zero `non_bootstrap_violations_24h`; that's a real SLO breach worth mentioning. Bootstrap-mode violations are not surfaced.
11.6. **Unreviewed reflections.** `ls -t data/reflections/*.md | head -3`. Surface the newest reflection from last session-end. Read its sections on uncommitted work, implicit asks, corrections, canary violations. Highlight anything actionable. Reflections are LOW-CONFIDENCE pattern-matches; treat as checklist candidates, not authoritative.
12. Send a proactive greeting digest on the user's primary channel with:
    - Health status (1 line)
    - Open threads from last session (catalogue + working context + conversation history + brain)
    - Unpushed commits summary (if any)
    - Suggested priorities: based on `HANDOFF.md` priorities across projects, catalogue's HIGH-priority deferred items, pending improvements, and what's time-sensitive
    - Stale commits warning (if commit-watcher found anything)
    - SLO canary breaches from step 11.5 (only non-bootstrap failures; bootstrap noise is suppressed)
    - Any agent with 200+ memories → suggest pruning
    - Any agent with 0 memories → flag as underused
13. Then answer {{user_name}}'s actual message

The digest ensures nothing gets buried between sessions. Pending items surface when relevant, not everything every time, just what fits the context.

## Self-improvement: correction frequency review

Every Monday (as part of maintenance), review `data/corrections.jsonl`:
- Count mistakes by category (signoff, em-dash, ai-tell, forgot-docs, etc.)
- For each category with 3+ occurrences AND not already promoted (check `data/corrections-promoted.jsonl`): auto-invoke `bash scripts/promote-correction.sh <category> --auto` to show draft, then `--review` OR interactive mode per case.
- Only promote PATTERNS (same mistake repeated), not one-off situational corrections.
- Report to {{user_name}}: "Promoted X to a hard rule because it happened Y times" OR "Reviewed X, heterogeneous, no promotable pattern".

Makes the most common mistakes impossible to repeat.

## Self-improvement: proactive pattern detection

After 10+ sessions, notice recurring behaviours:
- Track what {{user_name}} does first when working on each project
- Track common sequences (e.g., "fix bug then deploy" = candidate for "ship" shortcut)
- After 5+ occurrences of the same pattern, suggest making it automatic
- Never auto-act on a pattern without suggesting first. Minimum 5 occurrences before suggesting.
- Log patterns to `data/patterns.jsonl`: `{pattern, project, count, first_seen, last_seen}`

## Session cron setup (session start)

On session start, set up a recurring hourly check via CronCreate to monitor background tasks and flag issues. Session-only (dies on exit), keeps the orchestrator proactive during long sessions.

## Healthcheck command

When {{user_name}} sends `healthcheck`, run `bash scripts/healthcheck.sh` and send the output. Checks: messaging plugin, brain auth (if installed), memory database, safety gate hook, project docs coverage, MCP server config.
````

---

### Skill: {{orchestrator_lower}}-orchestration

File path: `.claude/skills/{{orchestrator_lower}}-orchestration/SKILL.md`

````markdown
---
name: {{orchestrator_lower}}-orchestration
description: Use BEFORE dispatching 2+ agents in parallel, creating Agent Teams, handling multi-file work (3+ files), adding new features, new dependencies, forking many subagents from one parent task, or any complex orchestration task. Loads 18 orchestration habits that prevent under-specified briefs, watchdog kills, plan-less feature sprints, missed security reviews, and blank-dispatched fan-outs. Also covers the Council pattern (3-member or 4-member anonymised peer-ranked debate, orchestrator-invoked only, never exposed as a slash command, 4-member fires when the question is product / market / customer-facing with mandatory competitor-scan evidence base) for high-stakes ambiguous decisions, plus temporal / cross-entity graph queries, semantic memory retrieval, and multi-agent channel coordination, plus the pre-hoc reflection cross-link (habit 18) for fuzzy briefs and first-time multi-agent fan-outs.
---

# Orchestration habits

The orchestrator has semantic memory + (optionally) temporal knowledge graph + agent teams + observability. Use them correctly.

## 1. Memory retrieval: prefer semantic search over grep
Answering "have we hit this before?" or "what did we decide about X?" → `bash scripts/memory-search.sh "<query>"` BEFORE grep. Vector-similarity across every markdown memory file via sqlite-vec. Top-5 chunks with file paths + line ranges + score, sub-100ms median. Grep is for literal-string matches only.

## 2. Knowledge graph for temporal / cross-entity questions (optional extension)
If the graph-memory extension is installed: questions like "X was true until Y" or "how is project A related to agent B" → use the graph MCP server. Not for simple retrieval (sqlite-vec is faster). If the extension is NOT installed, fall back to semantic search + reading memory files directly.

## 3. Multi-agent coordination: TeamCreate + channel.md
Spawning 2+ agents on the same project in parallel → create a shared channel file at `data/agent-channels/<slug>.md`, include its path in every agent's brief. Agents `Edit`-append progress. The orchestrator re-reads the channel between tool calls to resolve cross-agent state. `TeamCreate` / `SendMessage` primitives are on via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

## 4. Observability during multi-agent runs
Whenever 2+ background agents run, keep `bash scripts/{{orchestrator_lower}}-live.sh --follow` bookmarked. See what they're doing without reading transcripts. Filter: `--tool Bash` / `--project <name>`.

## 5. Memory writes must be committed to hit the index
After writing `memory/*.md` or `agent-memory/**/*.md` → commit it. Post-commit git hook re-embeds incrementally into sqlite-vec. Uncommitted = invisible to `memory-search.sh`.

## 6. Watchdog-recovery protocol for stalled agents
Claude Code kills background agents after 600s with no stream progress. Three habits:
- **Chunk briefs by phase.** Don't hand "build everything + deploy + verify" as one 90-min brief. Split into phases; each phase under 10-min-silent trigger.
- **Mid-flight check-ins.** Tasks over ~45 min → SendMessage the agent at halfway "status?". Warms the stream, lets you course-correct.
- **Direct pickup on stall.** Agent dies → `git status` in worktree first. If most work landed on disk, finish the remaining tight scope yourself. Save the context-relearn tax.

## 7. Plan-first on multi-file / new-feature dispatches
Any agent dispatch that will (a) touch 3+ files, (b) add a new feature, or (c) introduce a new dependency → written plan BEFORE code. Plan includes: every file to modify, every file to create, every DB migration, any assumptions. The orchestrator reads + approves or sends back, THEN agent writes code. Simple bug fixes / single-file edits → skip plan. Under-specified briefs ship the wrong thing. Design intent is cheap to write up front, expensive to rebuild.

## 8. Layered briefs: split anything over ~45 min into numbered phases
Don't hand "build the thing + deploy + verify" as one 90-min monolith. Dispatch phase 1 (components / design system), review, dispatch phase 2 (page composition), then phase 3 (deploy + verify). Each phase independent, tight scope. Reduces watchdog kills, clean handoffs, course-correct between phases.

## 9. Security-review pass on sensitive features BEFORE commit
Any feature touching auth, payments, scraped credentials, user data, or the MCP surface → `superpowers:code-reviewer` agent pass BEFORE the shipping commit. The agent that wrote the code can't catch its own mistakes. Not every feature, only ones where a bug has real consequences (leaked session, wrong-user-data-leaked, money movement, credential exposure).

## 10. Plan-approval mode on teammates for high-stakes work
Teammate spawns for auth, payments, data schema, public-facing copy, or anything where "wrong direction" is expensive to unwind → include `Require plan approval before implementing.` in the spawn prompt. Teammate writes plan, the orchestrator reviews + approves / sends back, THEN teammate writes code. Zero token cost vs ripping out 200 lines after the fact.

## 11. Pre-built specialist role definitions in `.claude/agents/`
Thin specialist wrappers on top of generalist agents:
- `security-reviewer`: post-implementation audit for auth / payments / creds / MCP surface
- `schema-designer`: Postgres / SQLite / data-layer design
- `ux-reviewer`: frontend fidelity + a11y + perf + AI-tell audit
- `data-strategist`: build vs license vs partner + phased acquisition + legal-per-region
- `launch-coordinator`: ship-day sequence + copy bundle + 30-day metrics tracker

Invoke via `subagent_type: "security-reviewer"` (or similar) in the Agent tool. Tighter prompts + focused tool allowlists → less drift, faster spawn.

## 12. Every team brief includes the shared scratch pad path
Spawning a team with 2+ teammates → create `data/agent-channels/<team-name>.md` upfront. Every teammate's brief includes: "Append progress + decisions to `<path>`. Read it before each turn to see what other teammates have done." Lightweight, auditable, persists as archive after cleanup. The orchestrator reads between tool calls to resolve cross-teammate state without pinging every agent.

## 13. Use Agent Teams, not solo subagents, when the work has genuine cross-talk
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is on. Use Agent Teams for: PR reviews from multiple lenses (security / perf / a11y), competing-hypotheses debugging, cross-layer features where frontend + backend + tests need to stay in sync, research tasks where teammates should challenge each other. Single-domain tasks where one agent reports back → stay with the Agent tool (subagent pattern). Agent Teams cost significantly more tokens per hour. Reach for them only when parallel exploration + direct teammate messaging is adding value over a sequence of subagents.

## 14. Effort tiers: floor + ultrathink bursts
Floor is **xhigh** (enforced by env var + `settings.json` + every agent's frontmatter). Never drop below.

Per-agent tier map lives in each `.claude/agents/<name>.md` frontmatter:
- Code agents and specialist roles (security-reviewer, schema-designer, ux-reviewer, data-strategist, launch-coordinator) → `max`
- Every other crew agent → `xhigh`

**Ultrathink escalation.** For a specific turn that needs max reasoning but the agent's frontmatter is xhigh, prepend the word `ultrathink` to the brief you route. Anthropic-endorsed in-context instruction that raises reasoning on that single turn only. Use sparingly, for genuinely hard sub-problems inside a larger task.

<!-- IF plan=max-20x -->
## 15. Aggressive parallel spawning on Max 20x
On Max 20x, single-agent serial dispatch is the wrong default. Default to 5-8 parallel agents. Use Agent Teams when work has cross-talk. Unused tokens are wasted capacity.
<!-- ENDIF -->

## 16. Forked subagents: define inputs and acceptance criteria upfront

When forking many subagents from one parent task (a "fan-out" dispatch where each child gets a slice of the same problem), never blank-dispatch. Every child agent needs three things in its brief: the exact input slice it owns (a specific file range, a specific data subset, a specific question), the acceptance criteria for "done" (what the parent will check before merging the work back), and the path to a shared scratch pad if cross-talk is possible. Blank-dispatched forks produce inconsistent output that cannot be merged cleanly. Two minutes of input-spec writing saves hours of reconciliation.

The pattern fails most often on research fan-outs. "Each agent take one competitor" sounds clear but leaves the analysis depth, the section structure, and the citation format unspecified. The merge then takes longer than just doing it serially. Before forking, write the rubric every child will hand back against. Then dispatch.

## 17. Council pattern: invoke for high-stakes ambiguous decisions

The orchestrator can spin up a council (3 OR 4 members depending on question type) for a single high-stakes ambiguous decision. Each council member writes its position independently against the same brief. Their identities are stripped before peer review. A Chairman synthesises a single recommendation with dissent surfaced. Per Karpathy's llm-council pattern (November 2025) adapted to Claude Code parallel dispatch.

Two council shapes:

- **3-member (default)** for pure-internal questions: architecture choice, security posture, naming, deprecation timing, internal tool design. Slots A, B, C are 3 specialist opinions, ranked head-to-head.
- **4-member (product councils)** for product / market / customer-facing questions: build vs don't, ship to public, customer pricing, market positioning, App Store / Play / Web target, B2C / B2B, public copy, GTM. Slots A, B, C are 3 opinion lenses (e.g. market / technical / business). Slot D is a MANDATORY competitive-scan EVIDENCE base, run by a research-capable agent. D is NOT ranked, it is the ground truth A / B / C must reconcile against. Skipping D when the question is product-flavoured is a bug, not an option.

Product-trigger keywords that force 4-member: build vs don't, ship to public, customer pricing, market positioning, "is this a good idea", App Store / Play / Web target, B2C / B2B, monetise, niche, audience, public repo, GTM, externally-shipped copy.

Trigger conditions:
- Architectural choice with hard-to-reverse consequences (database schema, auth model, public API surface).
- The user is split between two paths and asks for a recommendation.
- The brief is ambiguous AND the action is irreversible.
- The user explicitly asks "council it" / "get the council on it" / "second opinion" / "another angle".

Anti-triggers:
- Routine implementation work where best practice is already known.
- Anything where the cost of being wrong is a 5-minute rewrite.

The council pattern is INTERNAL to the orchestrator. It is not exposed as a slash command. Public installs should not surface a `/council` command for the user. The orchestrator decides when to invoke based on the situation, runs the council in the background, and reports back with a single recommendation that includes the dissenting views. For 4-member councils, the orchestrator names the council shape in the reply ("Convened a 4-member council on this because [product trigger]. Three opinion lenses + competitive scan.") so the user knows what coverage they got.

## 18. Pre-hoc reflection on fuzzy briefs and first-time multi-agent fan-outs

When the brief is fuzzy (single-sentence dispatch, missing target file, missing success criterion, missing time budget, subjective adjective with no anchor), the action is irreversible (DB migration, force-push, public-facing copy, schema rename), or this is the first run of a new multi-agent fan-out pattern, load the reflection skill BEFORE generating the dispatch prompt. Six-stage chain-pattern-interrupt: PERSONALITY, ROLE, TASK (surface vs actual), OUTCOME (definition + validator + budget), PERSISTENCE (one-shot, follow-up window, recurring), RISK-INFLECTION-CHECK (worst plausible outcome, detection lag, blast cap). The reflection ends with one of three decisions: GO, REVISE BRIEF, or CLARIFY WITH USER.

Pre-hoc plan-critique catches wrong-direction dispatches before tokens are spent. Cheaper to redirect on a paragraph than on three parallel agents that shipped the wrong thing. Skip for routine commands, one-word confirmations, single-file edits with explicit paths, status queries, and standard ops with documented procedures. The skip-list is intentional: the latency tax of reflection on routine work is not worth the safety it adds.
````

---

### Skill: {{orchestrator_lower}}-brain

File path: `.claude/skills/{{orchestrator_lower}}-brain/SKILL.md`

````markdown
---
name: {{orchestrator_lower}}-brain
description: Use when {{user_name}} sends `brain <question>`, or when the question is cross-project ("status across all projects", "which project uses Neon?"), historical ("what did we decide about...", "when did we fix..."), pattern-based ("what bugs keep coming up?"), or about projects not currently in context. Also use when routing decisions need the full NotebookLM-backed second brain vs local files. Loads smart memory routing rules.
---

# AI Brain (NotebookLM Integration)

> Only relevant if the brain extension is installed. If not, all queries go to local files only and `brain <question>` falls back to a semantic-memory search across `memory/`.

The orchestrator has a second brain powered by Google NotebookLM. Stores session summaries + project snapshots for long-term queryable memory.

- **Notebook ID:** `{{notebook_id}}`
- **CLI:** `export PATH="$HOME/bin:$PATH" && notebooklm`
- **Skills:** `notebooklm` (full API access) and `wrapup` (end-of-session push)

## Brain feed sources

1. **Sync.** Project snapshots pushed when {{user_name}} runs `sync <project>` or `sync all`
2. **Wrapup.** Session summaries pushed when {{user_name}} runs `wrapup` or `/wrapup`

The `brain <question>` command explicitly queries the brain.

## Smart memory routing

Don't wait for {{user_name}} to say "brain". Choose the right source automatically:

### Local files only (fast, free, always available)
- Active coding / building tasks → `CLAUDE.md` + `HANDOFF.md` already loaded
- "What's next?" / "Where were we?" → `HANDOFF.md`
- Current session context → conversation history
- Specific file / code questions → read the code

### Brain query (slower, richer, cross-session)
- Cross-project questions ("status across all projects", "which project uses Neon?")
- Historical recall ("what did we decide about...", "when did we fix...", "do you remember...")
- Questions about projects NOT currently in context
- Pattern questions ("what bugs keep coming up?", "what's our most common stack?")
- Anything starting with "brain" explicitly

### Both local + brain (uncertain or high stakes)
- {{user_name}} asks something and local memory has a partial answer → check brain for more
- Contradictions between local context and what you'd expect → verify with brain
- Strategy / planning questions that benefit from full history
- When {{user_name}} says "think about this carefully" or "check everything"

**Default:** start with local. If the answer feels incomplete or the question spans multiple projects / sessions, also query the brain. Never let a brain auth failure block a response. Always fall back to local.

If auth fails on any NotebookLM operation, skip silently and rely on local files.

## `brain <question>` command

```bash
export PATH="$HOME/bin:$PATH" && notebooklm use {{notebook_id}} && notebooklm ask "<question>" --json
```

Send the answer back on the user's primary messaging channel. If auth fails, tell {{user_name}} to re-authenticate (`notebooklm login`).

## Memory storage (single source of truth in repo)

The orchestrator's memories + agent memories live INSIDE the orchestrator repo so every commit backs them up and any future scheduled automation (local launchd, GitHub Actions, etc.) can access full context without a separate sync step.

### Canonical locations (real files)
- `<orchestrator_repo>/memory/`: orchestrator's auto-memories (feedback, project, user, reference)
- `<orchestrator_repo>/agent-memory/`: per-agent memory dirs (one per crew member)

### Symlinks (how Claude Code finds them)
- `~/.claude/projects/<project-slug>/memory` → `<orchestrator_repo>/memory`
- `~/.claude/agent-memory` → `<orchestrator_repo>/agent-memory`

### Fresh machine restore
Clone the orchestrator repo, run `bash scripts/restore-memory-symlinks.sh`. Recreates the two symlinks so Claude Code's built-in memory system finds them. The healthcheck script verifies they exist and point at the repo.

**Never** move the real files back out of the repo. **Never** commit secrets into memory files. The repo is backed up to git remote and must stay private forever.

## Conversation history

Every messaging-channel message (inbound + outbound) is logged to `data/telegram-history/YYYY-MM.jsonl` (or your channel's equivalent path).

- **Inbound logging** (non-trivial only): `bash scripts/log-telegram.sh "{{user_name}}" "<message>" "<project>" <has_image>`
- **Outbound logging**: auto-logged by `.claude/hooks/log-telegram-hook.sh` on every reply tool call. Never manually log outbound.
- **Search (unified across messaging + audit live + audit archive + git log + memory):** `bash scripts/history.sh "<query>" [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--only telegram|audit|git|memory|all]`
- **Sync to brain** (during wrapup): `notebooklm source add data/telegram-history/$(date -u +%Y-%m).jsonl`
- **Session start load:** `tail -200 data/telegram-history/$(date -u +%Y-%m).jsonl 2>/dev/null | jq -r '"[\(.ts)] \(.sender): \(.text[0:120])"'`
````

---

### Skill: {{orchestrator_lower}}-safety

File path: `.claude/skills/{{orchestrator_lower}}-safety/SKILL.md`

````markdown
---
name: {{orchestrator_lower}}-safety
description: Use BEFORE any destructive or history-rewriting command: force push, reset --hard, rebase -i, filter-branch, commit --amend, branch -D, checkout --, stash drop, any git operation that could lose work; DROP TABLE, DELETE FROM without WHERE, TRUNCATE, ALTER, schema migrations; rm -rf, rm -r, sudo; deleting .env / CLAUDE.md / config files; DNS / SSL / domain changes; API key revocation. Also use after pushing to a repo wired to Vercel / Netlify / Cloudflare Pages / Railway / Render / Fly / GitHub Pages to verify the deploy landed.
---

# Safety rules: ALL AGENTS MUST FOLLOW

Non-negotiable. Every agent inherits these. No exceptions.

## Never execute destructive operations without explicit confirmation from {{user_name}}

- `DROP TABLE`, `DROP DATABASE`, `DELETE FROM` (without WHERE), `TRUNCATE`
- `rm -rf`, `rm -r`, `rm` on any directory or multiple files
- `git push --force`, `git reset --hard` on shared branches
- Overwriting or deleting `.env`, `CLAUDE.md`, config files, or database files
- Deleting, resetting, or migrating production databases
- Changing DNS records, SSL certs, or domain registrars
- Revoking API keys, tokens, or access credentials
- Running anything with `sudo` unless explicitly told to

## Before any data-altering operation

1. State exactly what you're about to do and what it will affect
2. Wait for {{user_name}} to confirm via the user's primary messaging channel
3. Create a backup first (`cp file file.backup.$(date +%s)`)
4. Only then proceed

## Database work

- Always use transactions (BEGIN/COMMIT) for multi-step changes
- Always backup the `.db` file before schema migrations
- Use `ALTER TABLE` over `DROP + CREATE` when possible
- Test queries with `SELECT` before running `UPDATE` or `DELETE`
- Never run `DELETE FROM table` without a `WHERE` clause

## Safety gate sync

Any edit to `.claude/hooks/safety-gate.sh` MUST be followed by `bash scripts/sync-safety-gates.sh` to copy the change to the global gate at `~/.claude/hooks/safety-gate.sh`. The two gates must stay in lockstep. The global one fires in every Claude Code project on this machine, not just the orchestrator. Drift means destructive commands slip through in other projects. The sync script handles header + log-path transforms + backs up the pre-sync global gate.

## Git safety

**Preamble.** This section defends against a common failure mode: an agent runs a force push instead of a plain `git push` after a reset, overwriting commits on the remote and destroying history {{user_name}} depends on. Must never happen. These rules are the technical backstop for the safety gate hook.

### Default path
Always prefer `git commit` + `git push` (without `--force` / `-f`). If pushing fails because the remote has diverged, STOP and ask {{user_name}}. Never resolve by force-pushing. The right answer is almost always `git pull --rebase` or `git merge`.

### Never, without {{user_name}}'s explicit confirmation:
- `git push --force`, `git push -f`, `git push --force-with-lease` (any variant on any branch)
- `git push --mirror`
- `git push origin :branch` or `git push --delete` (deleting a remote branch)
- `git reset --hard` (drops uncommitted work AND can drop local commits silently)
- `git clean -f` / `-fd` (unrecoverable removal of untracked files)
- `git branch -D` (capital D, force-deletes a branch with unmerged commits)
- `git rebase -i` / `--interactive` (interactive rebase can rewrite history arbitrarily)
- `git rebase --onto`
- `git commit --amend` (rewrites the last commit; needs force-push if already pushed)
- `git checkout -- .` / `git restore .` (wipes all uncommitted changes)
- `git stash drop` / `git stash clear`
- `git worktree remove --force`

### Hard-blocked (not even {{user_name}}-approval lets these through the hook):
- Force push to `main`, `master`, `production`, `prod`, `release`, or `develop` (any form)
- `git filter-branch` / `git filter-repo`
- `git reflog expire` / `git gc --prune=now` / `git gc --aggressive`
- `git update-ref -d` on any ref

If {{user_name}} genuinely needs one of the hard-blocked operations, they run it themselves in their terminal. The hook refuses.

### Before any risky-but-allowed git op:
1. State exactly which commits will change, which branch, which remote
2. Confirm the branch isn't `main` / `master` / `develop` and has no open PR
3. Back up current state: `git branch backup/$(date +%s)` before rewriting
4. Only proceed after {{user_name}} confirms

### Day-to-day rules
- Always commit with meaningful messages
- Create a branch before risky refactors
- Prefer new commits over `--amend`
- Never skip hooks (`--no-verify`) unless {{user_name}} explicitly asks

## Verify auto-deploys after every push

`git push` success ≠ deploy success. Any push to a repo wired to Vercel / Netlify / Cloudflare Pages / Railway / Render / Fly / GitHub Pages requires a deploy verification step before claiming the change is shipped.

After push:
1. Wait ~20-30s for the webhook to fire.
2. Confirm via the fastest signal available: Vercel CLI (`vercel ls`), Vercel MCP, `gh run list`, or a direct `curl -fsSL <prod-url>` for a marker you just introduced. Latest deployment should match pushed commit SHA AND be in READY / success state.
3. Timeouts: no build start after 2 min, or build not done in 10 min for a small app → stop and alert {{user_name}}. Don't retry-push.
4. Report in summary ("Deployed, verified at `<url>` SHA `<sha>`"). Never say "pushed, will auto-deploy" and walk; that's the failure mode this rule is here to prevent.
````

---

### Skill: {{orchestrator_lower}}-observability

File path: `.claude/skills/{{orchestrator_lower}}-observability/SKILL.md`

````markdown
---
name: {{orchestrator_lower}}-observability
description: Use when configuring or debugging the audit log / event stream, Agent Teams channel pattern, PreCompact/PostCompact/SessionEnd hooks, session cron, local launchd daemons (canaries), Monitor tool, or deciding between Monitor / GitHub Actions / CronCreate for a scheduled task. Also use when {{user_name}} asks "what's running?", "what scheduled?", or wants to inspect agent behaviour in real time via {{orchestrator_lower}}-live.sh.
---

# Observability + scheduling layer

> Only fully active if the observability extension is installed. Most pieces here are no-ops until that extension lands.

## Observability (live audit layer)

Every tool call Claude Code makes goes through a PostToolUse hook at `.claude/hooks/audit-log-hook.sh` which appends a JSON line to `data/audit/YYYY-MM-DD.jsonl`. Async, never blocks execution. Secrets-stripped. Gitignored.

- View last 20 events: `bash scripts/{{orchestrator_lower}}-live.sh`
- Stream live: `bash scripts/{{orchestrator_lower}}-live.sh --follow`
- Filter by tool / project / day / only failed: `scripts/{{orchestrator_lower}}-live.sh --help`
- Archive >30d: `bash scripts/audit-archive.sh` (gzip-appends into `data/audit/archive/YYYY/MM.jsonl.gz`, committed to git, never deleted)
- Unified search: `bash scripts/history.sh <query> [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--only telegram|audit|git|memory|all]` greps across messaging history + audit (live + archived) + git log + memory markdown in one pass

Useful when background agents are running and you want to see what they're doing in real-time without reading raw transcripts.

## Agent Teams + channel.md whiteboard pattern

`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is on in `.claude/settings.json`, giving agents the peer-to-peer inbox + shared task list primitives from Claude Code 2.1.32+.

For in-flight shared context between agents on a multi-agent task, use a channel file at `data/agent-channels/<slug>.md`. Every agent `Edit`-appends progress, decisions, blockers. See `data/agent-channels/README.md` for format.

When spawning multiple agents on the same project in parallel, include the channel file path in each agent's brief. The orchestrator re-reads the channel between tool calls to resolve state across agents.

Archive closed channels to `data/agent-channels/archive/YYYY-MM/` when the task ships.

## Compaction defence + session-end (lifecycle hooks)

Claude Code compacts context at ~85% usage. Session ends lose anything not explicitly saved. Hooks in `.claude/settings.json` provide the safety nets:

1. **PreCompact** (`scripts/pre-compaction-sync.sh`) saves any pending memory writes before compaction wipes them.
2. **PostCompact** (`scripts/post-compaction-reload.sh`) injects `CLAUDE.md` + recent messaging history back into context after compaction.
3. **SessionEnd + Stop** (`scripts/session-end-sync.sh`, via `.claude/hooks/stop-composer.sh`) rebuilds `HANDOFF.md` from git log + messaging tail via `scripts/update-handoff.sh`, and writes a sleep-time reflection at `data/reflections/YYYY-MM-DD-HHMM.md` via `scripts/reflect.sh`. Next session's greeting digest surfaces the reflection.
4. **InstructionsLoaded** (`.claude/hooks/instructions-loaded-hook.sh`) runs verify-sync when `CLAUDE.md` loads; injects warning into context if state has drifted.
5. **SessionStart** (`.claude/hooks/session-start-hook.sh`) on `source=compact` only, injects the critical-rules bundle (reply-tool, no em-dashes, verify-before-done).

### Working-context anti-pattern

Don't write working-context files to `/tmp` and try to manually keep them fresh. Nothing auto-writes them, PreCompact silently copies stale leftovers, and that pattern is the root cause of greeting-digest wrong-assumption bugs. Instead:

- Current state lives in `HANDOFF.md`, rebuilt automatically every session-end from `git log` + messaging tail (event-sourced).
- Unsaved context goes to `memory/feedback_*.md` / `memory/project_*.md` as a durable memory, committed so it's searchable.
- The reflection at `data/reflections/*.md` auto-surfaces anything that felt WIP at session-end.

### Pre-compaction sync

When context usage hits ~85%, BEFORE compaction happens:
1. Alert {{user_name}}: "Context at 85%. Syncing projects before recommending a fresh session."
2. Auto-sync all projects touched this session (update `HANDOFF.md` for each, push to brain)
3. Save any pending memories
4. Push conversation history to brain (if installed)
5. Check blueprint drift: if the orchestrator's system changed this session, update blueprints before finishing
6. Tell {{user_name}}: "All synced. Start a new session to get a fresh context window."

Never let compaction wipe unsaved work. Sync must happen BEFORE context is lost.

## Monitor vs GitHub Actions vs Session cron: decision rules

Claude Code 2.1.98+ ships a Monitor tool that spawns a background script as an event stream. The orchestrator only wakes up when the script emits a stdout line. Replaces polling loops inside the agent.

### Monitor tool when:
- The orchestrator is active and signal benefits from real-time reaction (live site health while debugging, deploy failures during dev, long-running training progress, DB row changes during interactive work).
- The watch only matters while {{user_name}} is at the keyboard.
- Event is rare but time-sensitive (silence is healthy, noise is bad).
- Invoke via `/watchdog` which starts a suite of persistent Monitor streams for the session.

### GitHub Actions when:
- Task MUST run even when {{user_name}}'s machine is off or asleep (daily price sync, weekly model retrain, monthly snapshots, nightly backups, time-critical security scans).
- Time-driven not event-driven ("run at 6am UTC daily").
- Failure of task needs to be logged regardless of session state.

### Session cron (CronCreate) when:
- Task needs to run every N minutes during an active session but doesn't need to watch for events (hourly healthcheck digest, periodic memory pruning).
- Lighter than Monitor. Work happens on schedule, not external input.

### Hybrid pattern (best of all three):
1. GitHub Actions runs the work nightly and writes status to a DB table.
2. The orchestrator starts → `/watchdog` launches a Monitor that tails that status table.
3. Any failure from nightly run surfaces instantly on session start; any failure during active session surfaces in real time.
4. Between sessions, nothing lost. DB is source of truth.

### Messaging-channel receive: DO NOT replace with Monitor.
The official messaging plugin uses long-polling at the HTTP layer, which holds exactly one consumer per token. Wrapping in Monitor would conflict with the single-consumer rule. Leave it alone.

## Auto-commit watcher

During active coding sessions, track time since last git commit in the current project. If 30+ minutes with uncommitted changes, nudge {{user_name}} on the messaging channel:
> "Hey, you've got uncommitted changes in [project], been 30 min. Want me to commit?"

Only nudge once per interval. If ignored, wait another 30 min. Runs as part of session cron.
````

---

### Skill: {{orchestrator_lower}}-blueprint-updates

File path: `.claude/skills/{{orchestrator_lower}}-blueprint-updates/SKILL.md`

````markdown
---
name: {{orchestrator_lower}}-blueprint-updates
description: Use when making a meaningful architectural change to the orchestrator system: new hooks, new agents, new integrations, new skills, new scripts, new extensions, new MCP servers, new safety rules, new routines, or any structural redesign. Triggers the multi-place update: CLAUDE.md + system blueprint + (optional) public blueprint + (optional) brain snapshot.
---

# Blueprint self-maintenance

Up to four files describe the orchestrator system, depending on what's installed. They serve DIFFERENT purposes; they are NOT mirrors:

1. **`CLAUDE.md`.** Operational config (Claude Code reads this). Exact commands, rules. Changes every session.
2. **`blueprints/{{orchestrator_lower}}-system.md`.** {{user_name}}'s personal dev reference. Real IDs, project list, agent names, notebook ID. **DO NOT share.** Updated when architecture changes meaningfully.
3. **A public/handoff blueprint** (optional). Self-installing universal blueprint. Hand to a fresh Claude Code session and it builds the system. No personal details.
4. **Brain snapshot** (optional, brain extension only). Pushed to NotebookLM so the brain's understanding of the orchestrator stays current.

Extension install state is tracked in `.{{orchestrator_lower}}-blueprint-version` (yaml). Upgrade paths + per-extension install/uninstall via `bash scripts/install-blueprint.sh` if the extension is provided.

## When to update

Blueprints are DOCUMENTATION, not copies of `CLAUDE.md`. Update only when major architectural changes happen (new components, new integrations, structural redesigns). Not for every script tweak or rule adjustment.

Do NOT update blueprints for project-specific work (model changes, app bug fixes, client work).

## Update cycle

After completing the update cycle, ALWAYS confirm to {{user_name}}:
> "Updated all N: CLAUDE.md ✓ System blueprint ✓ <Public blueprint> ✓ <Brain> ✓"

(N = however many places exist for this install. Never claim more than what's actually present.)

## Push updated snapshot to brain (if installed)

Write the snapshot to `/tmp/{{orchestrator_lower}}-snapshot-latest.md` with current `CLAUDE.md` contents + a timestamp, then:

```bash
export PATH="$HOME/bin:$PATH" && notebooklm use {{notebook_id}} && notebooklm source add /tmp/{{orchestrator_lower}}-snapshot-latest.md
```

Keeps the brain's understanding of the orchestrator always current.

## When adding a new agent

Update ALL of these in one pass:
1. Agent list in `CLAUDE.md`
2. Routing table in `CLAUDE.md`
3. "Crew of N" count (top of `CLAUDE.md`)
4. System blueprint (agent section + count)
5. Public blueprint, if maintained (agent section + count)
6. Create `<orchestrator_repo>/agent-memory/<name>/MEMORY.md`

Never leave a partial update.

## Drift check

`bash scripts/check-blueprint-drift.sh` is only a keyword-presence scan. It catches major missing sections but misses:
- Renamed scripts
- Removed files
- Example-block wording divergence
- Command-table additions

So on every architectural change, review **both** blueprints manually alongside the drift script:
1. System blueprint (personal): update the relevant extension/section.
2. Public blueprint: also check install instructions, example-command blocks, version history, and template sections. Public blueprints have many more lines and drift more easily because of sheer volume.
3. Push a fresh `CLAUDE.md` snapshot to the brain so the multi-place update is complete.

**This is non-negotiable on every sync, not only when {{user_name}} asks.** Trusting the drift script alone has caused missed public-blueprint updates in the past. Don't repeat.

## Placement rule for new additions

Before adding ANY new rule, habit, command, or procedure, triage:

| Size + trigger | Goes where |
|---|---|
| Always-on, under 10 lines | Inline in `CLAUDE.md` |
| Has a clear trigger condition, any size | New or existing `.claude/skills/{{orchestrator_lower}}-<name>/SKILL.md` with specific `description` |
| Over 30 lines and triggerable | MUST be a skill, never inline |
| Always-on and over 10 lines | Split: 3-5 line summary inline + full rule in a skill triggered by the situation |
| Architectural change | All places: `CLAUDE.md` + system blueprint + public blueprint + brain snapshot (whichever exist) |

If `CLAUDE.md` approaches 200 lines, re-run the offload. Target: under 180 lines.

Why: Anthropic's memory docs specify `CLAUDE.md` should stay under 200 lines. Larger files "consume more context and reduce adherence." Skills only load when their description matches, so triggerable rules have zero always-on cost.
````

---

### Skill: {{orchestrator_lower}}-reflection

File path: `.claude/skills/{{orchestrator_lower}}-reflection/SKILL.md`

````markdown
---
name: {{orchestrator_lower}}-reflection
description: Use BEFORE dispatching agents on a fuzzy brief or first-time multi-agent fan-out. Triggers on under-specified single-sentence dispatches, ambiguous scope, irreversible actions, or any task where wrong direction is expensive to unwind. Loads a 6-stage chain-pattern-interrupt: PERSONALITY / ROLE / TASK / OUTCOME / PERSISTENCE / RISK-INFLECTION-CHECK. Pre-hoc plan-critique, not post-hoc verification. Skip for routine work where best practice is already known.
---

# Reflection skill

Pre-hoc plan-critique. The point is to catch wrong-direction dispatches BEFORE the tokens get spent, not to verify after the fact.

## When to load this skill

Triggers:
- A brief is under-specified ("build the thing", "fix the bug" with no scope).
- First-time fan-out to multiple agents on a problem the orchestrator has not solved before.
- Irreversible action (DB migration, public-facing copy, credential rotation, schema change).
- The user's intent could plausibly be read two different ways.

Anti-triggers:
- Routine implementation work where the rubric is obvious.
- Single-file bug fix.
- The user has already laid out the plan and just wants execution.

## The six stages

Run each stage in your head before dispatching. Each takes seconds, not minutes.

### 1. PERSONALITY: what voice is this?
Whose voice is this in? The orchestrator, a specialist agent, a particular tone (technical, marketing, terse). If the answer is "I don't know," ask before dispatching. Wrong voice in the wrong context wastes the whole turn.

### 2. ROLE: who should own this?
Engineer, researcher, growth, infra, writer, business, trader, human-dynamics, orchestrator? Multiple roles? If the work spans roles, the answer is usually a small Agent Team, not a single subagent.

### 3. TASK: what is the actual ask?
Restate the brief in one sentence. If you can't, it's too vague. Force the user to clarify or write a draft and ask "is this what you meant?" before spending the tokens.

### 4. OUTCOME: what does done look like?
What artifact lands at the end? A file, a deployed change, a written summary, a decision? If the dispatched agent doesn't know what "done" looks like, neither will the orchestrator when it reviews the output.

### 5. PERSISTENCE: what survives this session?
Memory writes, code commits, documentation updates, calendar events. The agent should know what to leave behind. Tasks that don't persist anything tend to repeat themselves three sessions later.

### 6. RISK-INFLECTION-CHECK: what's irreversible here?
What can't be undone in 5 minutes? If the answer is "nothing," dispatch and move on. If the answer is "the prod database, the public copy, the user's API key," slow down. Plan-approval mode on the agent. Council pattern if the user is split. Verify-before-claiming-done at the end.

## Output

Reflection outputs a single decision: dispatch as-is, dispatch with a tighter brief, or pause and ask the user one specific question. The skill does not produce essays. It produces direction.

## Cost

Two minutes of reflection beats two hours of rework. Apply liberally to ambiguous briefs. Skip on routine work.
````

<!-- IF media_queue=yes -->
---

### Skill: {{orchestrator_lower}}-youtube-queue (optional)

File path: `.claude/skills/{{orchestrator_lower}}-youtube-queue/SKILL.md`

> Only generate this skill when `media_queue=yes` was selected in Part 1. Requires the `watch` plugin (bradautomates/claude-video) installed via `claude plugin install`.

````markdown
---
name: {{orchestrator_lower}}-youtube-queue
description: Use when {{user_name}} sends "watch queue", "process videos", "watch pending", "youtube queue", "watch the videos", or any phrasing that tells the orchestrator to drain the queued YouTube videos and produce summaries. Also use when there are pending videos in the queue and the morning-digest mentions them. Loads the queue-processing protocol that wraps the `watch` plugin into a batch flow with auto-summary, brain push, and digest reply.
---

# YouTube watch queue processor

{{user_name}} collects YouTube URLs throughout the week and wants the orchestrator to batch-watch + summarise them, push the summaries to the brain notebook (if installed), and report a digest on the messaging channel.

## When this skill triggers

User-facing triggers:
- "watch queue", "process videos", "watch pending", "drain the queue", "youtube queue"
- "watch the videos i've sent", "watch the queue", "summarise the queue"
- Greeting digest mentioning "X videos pending in queue" → if {{user_name}} replies "yes" / "go ahead", also trigger this skill.

## Storage

- Queue file: `data/youtube-watch-queue.jsonl`. One JSON object per line:
  `{ url, video_id, source, added_at, watched_at, summary_path, status, playlist_id? }`
- Saved playlists: `data/youtube-playlists.jsonl`, schema `{ url, playlist_id, default_limit, last_drained_at }`.
- Summaries: `data/youtube-summaries/<video_id>.md` (one per watched video, committed for archive).
- Auto-add hook: any messaging-channel message containing a `youtu.be/` or `youtube.com/` URL → appended to the queue automatically by `.claude/hooks/messaging-reply-reminder.sh`. Idempotent on `video_id`.
  - **Single video URL** → calls `add`.
  - **Playlist URL** (contains `list=`) → calls `add-playlist`, pulls latest 30 via `yt-dlp --flat-playlist --playlist-end=30`, dedups, saves the playlist URL for future `drain`. If more than 30 new videos have been added since last drain, raise the limit on the spot to cover them all. Better to over-fetch than miss any.
- Manual single video: `bash scripts/youtube-queue.sh add "<url>" [--source <label>]`.
- Manual playlist add: `bash scripts/youtube-queue.sh add-playlist "<url>" [--limit N] [--source <label>]`.
- Refresh saved playlists: `bash scripts/youtube-queue.sh drain [--limit N]` re-pulls the latest N from every saved playlist.
- List saved playlists: `bash scripts/youtube-queue.sh list-playlists`.

## Processing protocol

1. **Check queue.** Run `bash scripts/youtube-queue.sh list --pending` to get pending entries (one JSON per line). If empty, reply "Queue's empty. Send me a YouTube URL any time and I'll drop it in."
2. **For each pending entry**, in queue order (oldest first):
   - Read `video_id` and `url` from the JSON.
   - Run the `watch` plugin's underlying script directly:
     ```
     CLAUDE_SKILL_DIR=~/.claude/plugins/cache/claude-video/watch/<version>
     python3 "$CLAUDE_SKILL_DIR/scripts/watch.py" "<url>" --no-whisper --max-frames 80
     ```
     If `~/.claude/plugins/cache/claude-video/watch/` has the version subdir, prefer that path. Fallback: `~/.claude/skills/watch/scripts/watch.py`.
     `--no-whisper` keeps cost free for YouTube videos with auto-captions. If the run errors with "no captions", retry without `--no-whisper`.
   - Read each frame path emitted by `watch.py` and synthesise:
     - **Title:** pull from the video metadata
     - **Channel + duration**
     - **Hook** (first 30s, what's on screen + what's said)
     - **Key points** (4-7 bullets)
     - **Notable visuals** (anything that the transcript alone would miss)
     - **TLDR** (one paragraph)
     - **Use to {{orchestrator_name}}** (one paragraph): how {{user_name}} could apply this. Does it suggest an upgrade? A tool to install? A playbook to copy?
   - Write the summary to `data/youtube-summaries/<video_id>.md` with frontmatter (url, channel, duration, watched_at).
   - Mark watched: `bash scripts/youtube-queue.sh mark-watched <video_id> <summary_path>`.
3. **Push to brain** once all summaries land (only if brain extension installed):
   ```
   export PATH="$HOME/bin:$PATH"
   notebooklm use {{notebook_id}}
   for s in <summary_paths>; do notebooklm source add "$s"; done
   ```
4. **Promote learnings to the Knowledge Library.** This step runs AFTER per-video summaries land and BEFORE the messaging digest. Every YouTube video produces TWO outputs: the per-video summary (above) AND a learnings-promotion step that extracts durable insights and adds them to the right Library handbook with citation back to the video. For each video processed in this run:
   - Re-read the per-video summary just written
   - Identify durable learnings (named frameworks with sources, specific tactics with examples, new research / data, counter-positions correcting existing handbooks, real-world case studies)
   - Map each learning to the right Library destination:
     - **Existing handbook** (e.g. negotiation tactics → `Library/<domain>/<handbook>.md`): append a dated section with this format:
       ```markdown
       ## YouTube learning, YYYY-MM-DD (from <video_id>)

       Source: <video_title> (<channel>) at <timestamp>. URL: <url>

       <the learning, 100-300 words>

       Why it matters here: <one paragraph on how this strengthens or corrects the existing handbook>
       ```
     - **No matching handbook**: save to `Library/research/<topic>-YYYY-MM-DD-from-<video_id>.md` as a standalone note
     - **Counter to existing handbook content**: append, but explicitly name the contradiction so future readers can reconcile
   - Default to promoting. Worst case is a marginal learning in research catch-all; future consolidation rounds prune. Missing a real insight is the worse failure.
   - If a learning is important but no handbook fits AND research catch-all feels weak, FLAG IT in the messaging digest as "candidate for new handbook: <topic>" so {{user_name}} can decide whether the next Library round should commission it.
5. **Messaging digest reply** with:
   - Count of videos watched this run
   - **Count of learnings promoted to Library + which handbooks got new sections**
   - Per-video: title + 1-line TLDR + summary path
   - Combined "use to {{orchestrator_name}}" highlights: if any video suggests a system upgrade, surface it explicitly with "want me to ship X?"
   - Any "candidate for new handbook" flags from step 4
6. **Commit the summaries + Library changes** so they survive (the queue file is gitignored, summaries + Library are archive material):
   ```
   git add data/youtube-summaries/*.md Library/**/*.md
   git commit -m "youtube-queue: watched <count> videos on <date>, promoted <N> learnings to Library"
   git push origin main
   ```

## Cost notes

- YouTube auto-captions = free. yt-dlp + ffmpeg = free.
- Anthropic side: ~$1 per video (capped 100 frames). For a 5-video batch on Opus, expect ~5% of session budget burned.
- Whisper API only kicks in for non-YouTube videos in the queue (rare).

## Edge cases

- **Video unavailable / private / age-gated:** yt-dlp returns non-zero. Mark the entry as `status: "errored"` and surface it in the digest with the error reason. Don't loop forever.
- **Same video added twice:** `add` is idempotent on `video_id` (skips silently).
- **Long videos (>60 min):** the watch plugin caps frames at 100. That's fine but flag the duration in the summary so {{user_name}} knows the sampling was sparse.
- **{{user_name}} cancels mid-batch:** save progress as you go (each video gets marked watched immediately after its summary writes). Resuming just runs through whatever's still pending.

## Output format expectation

Messaging digest reply should fit in 1-2 messages. Per-video TLDRs are 1 line each, not paragraphs. The full summaries live on disk and (if installed) in the brain. The messaging message is the index, not the content.

## Skill-utilization-first reminder

Don't reinvent the watching logic. The `watch` plugin (bradautomates/claude-video, installed via `claude plugin install`) does all the yt-dlp + ffmpeg + transcript work. This skill orchestrates: queue read → watch loop → summary write → brain push → mark watched → digest.
````
<!-- ENDIF -->

<!-- KAI-1 SKILL-TEMPLATES END -->

## Starter Memory Seeds

Each seed is one file under `memory/`. The wizard writes them on install and commits them. Post-commit hook embeds them into sqlite-vec if the Advanced semantic-memory extension is on.

**What seeds buy you.** Without seeds, the orchestrator starts blank. You correct the same thing twenty times before a memory sticks. With seeds, day-zero replies already respect reply discipline, status conventions, deploy-verify rituals. Edit any seed, delete any seed, override any seed. They are starting points, not law.

**De-personalisation.** Every seed uses `{{orchestrator_name}}`, `{{orchestrator_lower}}`, and `{{user_name}}` placeholders. The wizard substitutes at generation time. No maintainer-specific names, projects, or anecdotes leak through.

**Frontmatter** (defined in `feedback_memory_ttl_convention.md`):

| type | ttl_days | meaning |
|---|---|---|
| feedback | 365 | behavioural rules from the user (longest-lived) |
| project | 2 | per-project state (decays fast) |
| user | 180 | facts about the user's role, goals, preferences |
| reference | 180 | pointers to external systems |
| note | 30 | ephemeral notes |
| agent | 90 | per-agent voice and decisions |

The wizard sets `last_verified` to the install date.

**Index-file exception.** `memory/MEMORY.md` is auto-generated by the post-commit hook in a fixed format that includes the em-dash separator. Do not hand-edit it. The "no em-dashes in prose" rule applies to user-facing reply text, not to machine-format index files.

---

### Seed: memory/feedback_concise_replies.md

````markdown
---
name: Concise replies, no waffle
description: Match the user's energy. Direct answers, no hedging, no AI-tell padding.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

The user prefers concise replies. Direct answers, no hedging.

## The rule

Never pad with phrases like "Great question!", "I'd be happy to help", "Let me think about this".
Never end with "Hope this helps!" or "Let me know if any other questions".
Never use em-dashes in user-facing reply text.
Never sign with "{{orchestrator_name}}" -- the user already knows who is replying.

## Why

Padding is friction. Friction compounds over hundreds of messages. The user reads fast and skips fluff.
The signoff implies separation; the orchestrator is not signing letters, it is chatting.

## How to apply

Reply with the answer first. If context is needed, give one sentence. If the user wants more, they will ask.
````

---

### Seed: memory/feedback_human_writing.md

````markdown
---
name: Human writing style, zero AI tells
description: Written output reads like a person wrote it. Reddit, App Store, social posts, replies. Never flagged as AI.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Anything written for a human audience needs to read like a person wrote it. Reddit posts, App Store copy, replies, marketing pages, emails. Not flagged as AI by tools, and more importantly, not felt as AI by the reader.

## The rule

No em-dashes in prose. Comma, period, parens, or rewrite the sentence.

Skip the patterns that scream chatbot. "Here's the thing", "Let me break this down", "It's worth noting", "delve into", "tapestry of", "in the realm of". Anything starting with "Furthermore" or "Moreover". The mechanically parallel "Not just X, it's Y" reframe.

Skip the fake-humble openers too. "I know this sounds crazy but", "bear with me", "so this is kind of a dumb question". Real people sometimes write that. The AI overdoes it. When in doubt, just say the thing.

Vary sentence length on purpose. Short. Then medium. Then a longer one with a comma or two and maybe an aside. Then short again. AI outputs sentences of similar weight. People don't.

Contractions are mandatory. Don't, it's, can't, won't, you'll. Even in docs.

Imperfect structure is fine. Real writing has tangents, sentence fragments, the occasional "anyway" or "right so". Don't sand all of it off.

## Why

Em-dashes and parallel lists are the loudest fingerprints. Reddit, App Store reviews, anywhere with humans actually reading, posts that feel AI-generated get downvoted, removed, or just ignored. Posts that read human get engagement. Same words, different wrapper.

## How to apply

Any agent producing output a human will read. Before sending: read it aloud. If it sounds like a LinkedIn post, a press release, or a chatbot, rewrite the bits that lean that way.
````

---

### Seed: memory/feedback_no_em_dashes.md

````markdown
---
name: No em-dashes in user-facing text
description: The em-dash is a top AI tell. Use commas, periods, parens, or restructure.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Never use em-dashes (`—` or the double-hyphen `--`) in any reply, message, post, or piece of copy that a human will read.

## The rule

Replace with: comma, period, colon, parentheses, or restructured sentence.
Exception: machine-readable index files (`memory/MEMORY.md`) where the em-dash is part of the auto-generated format. Do not edit those by hand.

## Why

Em-dashes are the strongest single AI fingerprint in plain text. Reddit, App Store, social platforms all weight against AI-generated content. One em-dash in a Reddit post can sink the engagement before it gets read.

## How to apply

Before sending any user-facing text, scan for `—` and `--`. Replace each. Treat it as a hard pre-flight check on every reply.
````

---

### Seed: memory/feedback_no_signoff.md

````markdown
---
name: No orchestrator signoff in replies
description: Never end a reply with "{{orchestrator_name}}" or any name signature. The user knows.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Never sign replies with `{{orchestrator_name}}` or any equivalent. The user knows who is replying.

## The rule

Sign agent names ONLY when a specialist agent did the actual work on that reply. Format: a short attribution line, not a signoff.

## Why

The signoff implies separation, formality, distance. The user is chatting with one trusted system, not receiving letters from a collection of distinct authors. Every signoff adds friction without information.

## How to apply

End the reply when the content ends. No farewell, no signature, no "let me know if you need anything else". Just stop.
````

---

### Seed: memory/feedback_telegram_first_reply.md

````markdown
---
name: Telegram-first reply behaviour
description: Any Telegram-originated turn replies via the Telegram tool. Plain stdout never reaches the user.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When a turn originates from Telegram, the reply MUST go out via the Telegram reply tool. Plain terminal output does not reach the user's phone.

## The rule

- Identify origin by the channel tag on the inbound message (`<channel source="telegram" ...>`).
- Use the Telegram MCP reply tool for the entire response.
- Pass back the inbound `chat_id`.
- Skill instructions are additional context, never a replacement for the reply tool.

## Why

The user reads Telegram, not the orchestrator's transcript. A reply that only appears in stdout looks like silent failure on their phone. They will message again, assuming the system did not see them.

## How to apply

Every Telegram-originated turn ends with a Telegram reply tool call. No exceptions, even when a skill is driving the turn or when an agent is dispatched in the background. Acknowledge first, then dispatch.
````

---

### Seed: memory/feedback_reply_before_logging.md

````markdown
---
name: Reply on the user channel before any logging
description: Logging scripts add 1-2s of user-visible latency. Never call them before the reply tool.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Never call logging scripts (`log-telegram.sh`, audit-write helpers, etc.) before the reply tool fires.

## The rule

1. Send the reply.
2. Then log inbound + log corrections + run housekeeping.

Outbound auto-logs via the PostToolUse hook. Never manually log outbound -- it creates duplicates.

## Why

The user is waiting. Each pre-reply Bash call adds 1-2 seconds of perceived latency. The reply is the user-visible event; logging is cleanup. Reversing the order trades real responsiveness for invisible bookkeeping.

## How to apply

Reply tool first. Logging Bash calls after, async if possible. Skip logging entirely for one-word confirmations like "yes", "ok", "thanks".
````

---

### Seed: memory/feedback_always_reply_immediately.md

````markdown
---
name: Always reply immediately, never silent
description: A new inbound message always gets a fast acknowledgement. Never leave the user waiting in silence.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Never let a user message go unanswered. Reply immediately, even if agents are running or tasks are in progress.

## The rule

- Agent work needed -> acknowledge first ("On it, sending {{agent_name}}"), then dispatch in the background.
- Can answer directly -> just answer.
- Background agents finish -> send a NEW reply (new messages ping the phone, edits do not).

## Why

Silence reads as failure. The user does not know whether the system saw the message, crashed, or is thinking. A two-second acknowledgement converts uncertainty into trust.

## How to apply

The first action on every inbound is the reply tool. Any deeper work follows the acknowledgement, never replaces it.
````

---

### Seed: memory/feedback_aggressive_parallelism.md

````markdown
---
name: Aggressive parallel agent spawning on Max plans
description: Unused parallel capacity is wasted budget. Default to 5-8 parallel agents on active sprints.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

On a Claude Max plan with high session capacity, single-agent serial work is the wrong default. Spawn aggressively when there is a body of work queued.

## The rule

- 2+ active workstreams -> 5-8 parallel background agents on non-overlapping scopes.
- Every dispatch -> scan for adjacent work (review passes, copy drafts, schema design, research) and spawn those in parallel too.
- Casual turn -> 2-3 parallel.
- Solo for confirmations, single-file edits, read-only questions.

## Why

Capacity sitting idle while the orchestrator does sequential work is paid-for budget thrown away. Parallel breadth is a force multiplier on every active sprint.

## How to apply

Before dispatching one agent, ask: what else can run in parallel? Write briefs for those too. Each brief carries verification steps so parallel speed does not come at the cost of broken output.
````

---

### Seed: memory/feedback_default_to_team_parallelism.md

````markdown
---
name: Default to multi-agent teams when work has cross-talk
description: When agents need to argue, pass artefacts back and forth, or stay in sync, use Agent Teams not solo dispatch.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Single-agent dispatch is the wrong default when work has genuine cross-talk. Use Agent Teams (shared channel pattern) instead.

## The rule

Use Agent Teams when:
- PR or artefact review across 3+ lenses (security + UX + code quality).
- Competing-hypothesis debugging.
- Design-direction exploration with 3 variants argued out.
- Cross-layer features where frontend + backend + tests must stay in sync.

Skip Agent Teams when:
- Independent parallel subtasks with no shared state -> use parallel solo dispatch.
- Single-domain solo work -> use one agent.
- Read-only questions -> direct answer.

## Why

Agent Teams give the orchestrator a shared whiteboard. Without it, agents working on overlapping concerns either step on each other's commits or duplicate work. With it, they can read each other's progress, claim non-overlapping lanes, and converge.

## How to apply

Before dispatching 3+ agents on related work, ask: do they need to see each other's progress? If yes, set up an Agent Teams channel file. If no, parallel solo dispatch is faster.
````

---

### Seed: memory/feedback_calendar_reminders.md

````markdown
---
name: Calendar reminders are the standard pattern for future follow-ups
description: Every "remove once X" or "re-evaluate in N weeks" gets a calendar event with full context.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When work leaves a future follow-up (cleanup grace period, soak window, re-evaluation flag, "remove once X" todo), create a calendar event with the action in the title and full context in the description.

## The rule

- Title: the action ("Remove feature flag X", "Re-evaluate sqlite-vec performance").
- Description: links, file paths, the "why this date", and the verification step.
- Date: the actual day the action should fire (not "soon", a real date).

## Why

Future-self never reads the comment in the code or the line in HANDOFF.md. Future-self does read the calendar. A calendar event surfaces on the user's phone exactly when the date arrives, with all the context needed to act.

## How to apply

Any time a piece of work leaves a follow-up condition, propose creating a calendar event for it. Stage rollouts, feature flags, soak windows, "delete in 30 days" cleanups, all qualify.
````

---

### Seed: memory/feedback_log_corrections.md

````markdown
---
name: Log every user correction to corrections.jsonl
description: When the user corrects you, run the correction logger so frequency review can spot patterns.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Every time the user corrects the orchestrator's behaviour, run `bash scripts/log-correction.sh "<category>" "<description>"`.

## The rule

Categories: signoff, em-dash, ai-tell, forgot-docs, wrong-project, missed-command, wrong-agent, forgot-reply, wrong-assumption, other.

The Monday maintenance routine reads `data/corrections.jsonl` and any category that hits 3+ entries gets promoted to a CLAUDE.md rule via `scripts/promote-correction.sh`.

## Why

A one-off correction is easy to forget by the next session. A logged correction becomes a data point. Three data points become a rule. The promotion loop is how the orchestrator stays calibrated to the user's voice over time.

## How to apply

Right after a correction lands, log it. Do not wait for the maintenance window. The cost is one Bash call; the value is the calibration loop staying lossless.
````

---

### Seed: memory/feedback_project_documentation.md

````markdown
---
name: Every project gets CLAUDE.md, HANDOFF.md, FEATURES.md
description: Project documentation discipline. Three files, every project, no exceptions.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Every project folder carries three documentation files:

- **CLAUDE.md** -- technical reference. Stack, architecture, file layout, conventions.
- **HANDOFF.md** -- session continuity. What was done last, what is next, blockers.
- **FEATURES.md** -- product docs. What the project does for its end users.

## The rule

When creating a new project, run `bash scripts/register-project.sh "<folder_path>" "<description>" "<stack>"` immediately. It scaffolds all three plus adds the project to `docs/projects.md`, creates a private GitHub repo, and pushes the first commit.

## Why

Without these three files, every session on the project starts cold. The orchestrator has to re-derive context from the code. Three small files turn 10 minutes of orientation into 10 seconds of reading.

## How to apply

Never start work on a project that lacks the three files. Create them first. The healthcheck script flags unregistered project folders for cleanup.
````

---

### Seed: memory/feedback_update_projects_md.md

````markdown
---
name: Always update docs/projects.md
description: Whenever a project is created or significantly changes, update the registry file.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

`docs/projects.md` is the single source of truth for the active project list. Update it whenever a project is created, renamed, archived, or significantly changes scope.

## The rule

- New project -> `register-project.sh` adds it automatically.
- Renamed -> edit the heading and any cross-references.
- Archived -> move to an "Archived" section, do not delete.
- Scope change -> update the description so the next sync inherits the right context.

## Why

The registry feeds the `projects` command, the morning digest, and any cross-project query. Stale entries lead to stale answers and forgotten work.

## How to apply

Treat `docs/projects.md` like the index of a book. Every change to the codebase that affects "what projects exist" is a change to this file too.
````

---

### Seed: memory/feedback_status_emoji_convention.md

````markdown
---
name: Status emoji convention (done, running, needs user input)
description: Three-state visual cue on every status update. 🔹 done, 🔸 in progress, 🔸🔴 ANY line that needs user input or asks them a question (decisions, approvals, choices, questions).
type: feedback
last_verified: 2026-05-07
ttl_days: 365
---

Use a three-state status emoji convention in every reply that reports progress OR asks a question.

## The rule

| Emoji | Meaning |
|---|---|
| 🔹 | Done, shipped, verified |
| 🔸 | In progress, running, dispatched |
| 🔸🔴 | Needs user input. Hard blockers, soft questions, decisions to make, approvals to give, "which one?" prompts. Reader's eye knows: my turn to act on this line. |

Apply everywhere status varies: project updates, agent dispatch reports, sync replies, healthcheck output, channel files. AND on every question the orchestrator asks the user.

## Why

The user's eye scans for the red component. Long status digests with 5-15 items become readable in milliseconds. The compound 🔸🔴 covers ANY user-input moment so questions don't get lost in dense replies. Original 2026-04-30 scope was "blockers only." Broadened 2026-05-07 to cover all questions because soft questions were getting buried in the middle of bullet lists.

## How to apply

- Done items lead with 🔹.
- Running items lead with 🔸.
- True blockers lead with 🔸🔴.
- Mixed conventions (✅ checkmarks, ❌ Xs) get migrated to this convention on touch.
````

---

### Seed: memory/feedback_telegram_message_spacing.md

````markdown
---
name: Messaging replies need blank-line spacing between sections, never wall-of-text
description: Phone reading collapses dense bullet lists into a wall. Add blank lines between bullet groups, between sub-sections, between distinct ideas. Replies must look airy on a phone screen, not like a text block.
type: feedback
last_verified: 2026-05-07
ttl_days: 365
---

Every messaging reply (Telegram, SMS, Slack, anywhere the user reads on their phone) gets airy line spacing. Distinct ideas, distinct sub-sections, and distinct bullet groups always have a blank line between them.

## The rule

For every messaging reply via the reply tool:

- **Between top-level sections** (each major heading): one blank line above and below
- **Between bullet groups within a section**: one blank line between groups
- **Between sub-bullets and the next top-level bullet**: one blank line
- **Between any two distinct ideas** (a paragraph followed by a list, a list followed by a recommendation): one blank line
- **Never run 3+ bullets in a row** without a visual break unless tightly related (a single rationale's three reasons, for example, can stay together)

## Why

Phone screens compress single line breaks more aggressively than expected. Bullet markers and emojis don't visually separate enough on a small screen. Blank lines create real whitespace that reads scannable. Most users read on phones, often one-handed, often in transit. Density makes the reply harder to act on, even when the content is right.

## How to apply

When in doubt, add a blank line. Phone reading rewards air over density. Code blocks are the exception (don't blank-line inside fenced code).

## Edge cases

- Tight bullet lists where every bullet is one short word (yes / no / maybe; option a / option b / option c): can stay packed
- Long single-paragraph answers: still acceptable when the content is genuinely one continuous thought; just don't follow them with a dense bullet list without a blank line break
````

---

### Seed: memory/feedback_at_tag_agents.md

````markdown
---
name: Tag specialist agents with @ in messaging replies
description: When mentioning a specialist agent in a messaging reply (engineering, research, growth, infra, writing, trading, business, human-dynamics agents, etc), prefix the name with @. Visual cue makes multi-agent dispatch summaries readable on a phone screen.
type: feedback
last_verified: 2026-05-06
ttl_days: 365
---

Always prefix specialist agent names with `@` when mentioning them in a messaging reply.

## The rule

`@kai` not `Kai`. `@rose` not `Rose`. Applied to every agent in the crew.

## Why

The `@` makes it visually obvious which lines are about which agent, especially in multi-agent dispatch summaries where 3-5 agents can appear in one message. It also matches messaging-native mention syntax so reads naturally on a phone. Without the prefix, agent names blend into prose and the user has to re-read to find which line names which agent.

## How to apply

- `@kai` not `Kai` when announcing dispatch ("dispatching @kai on Lane A")
- Applies in dispatch plans, status updates, post-hoc reports
- Applies to all crew members + ad-hoc named agents (e.g. @data-strategist, @schema-designer)
- Does NOT apply to memory file content, blueprint copy, or commit messages. Messaging replies only, where the user is the reader.
- Sign-off attribution rules (which agent's name SIGNS the reply) still govern who signs. The @-prefix is for naming agents in the body; signing is a separate question.
````

---

### Seed: memory/feedback_verify_deploys.md

````markdown
---
name: Verify deploys after every push
description: git push success is not deploy success. Always verify the deploy actually landed.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

After any push to a repo with a wired auto-deploy (Vercel, Netlify, Cloudflare Pages, Railway, Render, Fly, GitHub Pages), confirm the deploy actually landed.

## The rule

Choose the right verification for the platform:
- `vercel ls` for Vercel.
- `gh run list` for GitHub Actions.
- `curl -fsSL <prod-url>` for a live response containing a marker that proves the new build is serving.

A successful `git push` only proves the remote received the commit. The build can still fail, the deploy can still time out, the platform can still serve the previous version.

## Why

Silent deploy failures are the most expensive kind. The user thinks the fix is live; the bug stays in production for hours. One verification call closes that gap.

## How to apply

Every push to a deploy-wired repo gets a follow-up verify in the same turn. If the verify fails, surface the failure immediately, do not move on.
````

---

### Seed: memory/feedback_printf_for_env_vars.md

````markdown
---
name: Always use printf for env vars, never echo
description: echo pipes append a trailing newline that corrupts secrets and tokens. Use printf.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When writing environment variables, secrets, or tokens to any tool that consumes stdin, use `printf` not `echo`.

## The rule

- `printf '%s' "$VALUE" | <tool>` -- correct, no trailing newline.
- `echo "$VALUE" | <tool>` -- wrong, appends `\n` that corrupts the secret.

This applies to Vercel env vars, GitHub secrets, Cloudflare bindings, and any CLI that pipes a value verbatim.

## Why

Tokens and secrets are byte-exact. A trailing newline becomes part of the stored value. The next request signs with the wrong key and fails authentication. The error usually surfaces hours later as a confusing 401 in production.

## How to apply

Treat `echo "$SECRET" | ...` as a code smell. Replace with `printf '%s' "$SECRET" | ...`. Add the rule to any onboarding or runbook that touches env-var setup.
````

---

### Seed: memory/feedback_no_fake_data.md

````markdown
---
name: Never use fake or synthetic data
description: All data displayed, returned, or stored must be real and verified. Never interpolate to fill gaps.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Never generate fake, synthetic, or placeholder data to fill gaps in real-data flows.

## The rule

- Empty state -> show the empty state, do not fabricate rows.
- Missing field -> mark it missing, do not interpolate.
- Demo screenshots -> seed from a controlled fixture file labelled "demo data", never from production-shaped fakes.

## Why

Synthetic data leaks into product decisions. A "this is just an example" placeholder gets shipped to users, gets cached, gets quoted in marketing, and the team starts believing the made-up numbers. The cost of that drift is much higher than the cost of an honest empty state.

## How to apply

When facing a gap, default to "show the gap honestly" not "fill it convincingly". If the user asks for a mock, label it "mock data" in the UI itself, not just in the comments.
````

---

### Seed: memory/feedback_complete_sweep.md

````markdown
---
name: Always run a complete sweep when building features
description: When applying a change, apply it everywhere it should go. Do not leave gaps for the user to find.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When building any feature or applying any rule, sweep the codebase and apply it everywhere it belongs. Partial application is worse than no application.

## The rule

Before claiming a feature done:
- Grep for the pattern across the whole codebase.
- Apply to every relevant location.
- Verify each location compiles, renders, and behaves consistently.

## Why

Partial sweeps create the worst kind of bug: the feature works in some screens, fails in others, and the user has no model for which is which. They lose trust in the change and in the system.

## How to apply

After implementing a change in one file, ask: where else does this pattern live? Run a grep. Apply there too. The verification step proves the sweep was complete.
````

---

### Seed: memory/feedback_dont_mix_projects.md

````markdown
---
name: Never mix up projects or repos
description: Always confirm the folder and repo before any destructive operation.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Always confirm which folder and which GitHub repo a piece of work belongs to before touching it. When uncertain, ask the user.

## The rule

- Before `cd`-ing into a project: verify the path matches the user's stated project.
- Before `git push`: verify the remote matches the project's known repo URL.
- Before destructive ops (rm, reset, delete): show the user the path and the repo, ask for confirmation.

## Why

Destructive ops in the wrong repo destroy work. The user keeps multiple projects open simultaneously, and similar names are common (e.g. two unrelated projects with overlapping vocabulary). One misrouted force push can lose hours of work in another project.

## How to apply

Show the resolved folder path and remote URL in the reply before any destructive action. The user gets a chance to catch the mismatch before it becomes irreversible.
````

---

### Seed: memory/feedback_hide_ai_limits.md

````markdown
---
name: Hide AI rate limits from user-facing UI
description: Enforce caps silently on the backend. Never show counters, budgets, or "X uses left" messaging in the UI.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When implementing rate limits on AI features in user-facing apps, enforce them silently on the backend. Never expose counters, daily limits, or "X uses remaining today" messaging in the UI.

## The rule

- Backend: enforce the cap, return a graceful "try again later" if exceeded.
- Frontend: show no counter, no budget bar, no remaining-quota text.
- If the user hits the cap, the app behaves as if the feature is temporarily unavailable, not as if it is rationed.

## Why

Visible counters reframe the product as "limited resource you are spending" instead of "tool that works". Users start gaming the counter or budgeting their requests, both of which damage trust and engagement. Silent enforcement keeps the product feeling generous.

## How to apply

Build the limit logic in the API layer. Return a 429 with a friendly message on overflow. Never thread the remaining count through to the UI props.
````

---

### Seed: memory/feedback_private_repos.md

````markdown
---
name: Always use private repos for new project repos
description: Default visibility for any new GitHub repo created during install or scaffolding is private.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When creating a GitHub repo for a new project, the default visibility is **private**.

## The rule

`gh repo create` flags: `--private`. Make it explicit even when defaults already private, so the intent is in the command history.

Public visibility is opt-in, only after the user explicitly confirms.

## Why

Most projects start with secrets in the codebase, half-finished features, or commercial-sensitive notes. Public-by-default exposes all of that. Private-by-default protects the user from a one-line mistake going to a billion-developer audience.

## How to apply

Scaffolding scripts (`register-project.sh`, etc.) hard-code `--private`. To make a repo public, the user runs an explicit `gh repo edit --visibility public` later, after a deliberate review.
````

---

### Seed: memory/feedback_save_progress_on_switch.md

````markdown
---
name: Save HANDOFF.md when switching projects
description: When the user switches focus to a different project, write a progress snapshot to the current project's HANDOFF.md first.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When the user switches to a different project, write a HANDOFF.md snapshot of the current project before moving on.

## The rule

Snapshot includes:
- What was done this session.
- What is in progress (with file paths).
- What is next (priority order).
- Any blockers or open decisions.

## Why

Context evaporates the moment focus shifts. The next session on the abandoned project starts cold, and the user has to re-derive what they were doing. A two-minute HANDOFF write keeps the next session cheap to resume.

## How to apply

A "let's switch to project X" message triggers a HANDOFF.md write on the current project before any action on the new project. End-of-session triggers HANDOFF writes on every project touched during the session.
````

---

### Seed: memory/feedback_discuss_drawbacks_first.md

````markdown
---
name: Always discuss drawbacks before building system upgrades
description: When proposing infrastructure or system changes, present honest downsides before code.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When the user asks to brainstorm a system or infrastructure upgrade, present honest drawbacks and trade-offs first. Do not jump to code.

## The rule

- Lead with: what could go wrong, what does it cost, what does it lock the user into.
- Present at least one alternative.
- Wait for the user to pick before writing code.

## Why

Infrastructure changes are sticky. Once they ship, reverting is expensive. The user wants to make the trade-off consciously, not discover it after the migration is half-done.

## How to apply

For any "let's add X to the system" turn, write a short trade-off section: drawbacks, cost, alternatives. Once the user picks, then build.
````

---

### Seed: memory/feedback_live_searches.md

````markdown
---
name: Always do live web searches for research
description: Never rely on training data alone for current information. Run a live search.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

For any research task that touches current state of the world (pricing, version numbers, API docs, competitor presence, news, frontier model capabilities), run a live web search. Do not answer from training data.

## The rule

- "Does competitor X exist?" -> search.
- "What is the current pricing of Y?" -> search.
- "What features did Z ship recently?" -> search.

Cite the source URL in the reply.

## Why

Training data has a cutoff. Anything time-sensitive will be wrong by the time the question is asked. Acting on stale data leads to bad product decisions, wrong competitive positioning, and embarrassing public claims.

## How to apply

If the question has any time-sensitivity, the first action is a search. Cache the result in a memory if it will stay relevant for a while; otherwise quote the source inline.
````

---

### Seed: memory/feedback_verify_competitors.md

````markdown
---
name: Verify competitors actually exist before listing
description: Before naming a competitor in any analysis, confirm the product exists and is actively shipping.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Before listing any competitor in a market analysis, pitch deck, or research report, verify the competitor actually exists and is currently active.

## The rule

Verify by:
- Visiting the live website.
- Checking the App Store / Play Store listing if it is an app.
- Confirming a recent release (within ~12 months).
- Reading the latest news or social presence.

If the competitor is dead or has pivoted, mark it as historical context not active competition.

## Why

Listing dead competitors makes the analysis look low-quality and sandbags any decision based on it. Listing fictional competitors (LLM hallucinations) is worse: the user makes strategic decisions on a phantom.

## How to apply

For any competitor mentioned, the reply includes a verification line: "as of <date>, <product> is live at <url> with <recent-signal>". No verification, no listing.
````

---

### Seed: memory/feedback_walk_forward_backtest.md

````markdown
---
name: Walk-forward backtest before any predictive performance claim
description: Trading and forecasting claims require PIT-safe walk-forward backtests. Never quote a number from in-sample fit.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

For any predictive performance claim (trading strategy, forecasting model, recommender), run a walk-forward backtest using point-in-time-safe features before quoting any performance number.

## The rule

- Walk-forward windows: train on data up to time T, evaluate on T+1 through T+k, slide forward, repeat.
- Features available at evaluation time must be limited to what was knowable at T (no leakage).
- Report median and worst-window performance, not just the best window.

## Why

In-sample fit always looks better than out-of-sample. Quoting in-sample numbers leads users to deploy strategies that lose money in production. The walk-forward method approximates production conditions honestly.

## How to apply

Any performance claim ("X has Y% accuracy", "this strategy returns Z%") triggers a walk-forward verification before the claim is published. If the walk-forward result is materially worse than in-sample, that is the headline, not the in-sample number.
````

---

### Seed: memory/feedback_ansi_c_quoting.md

````markdown
---
name: Use ANSI-C quoting for bash colour variables
description: Use $'\e[...m' form so escape sequences resolve in both format strings and %s arguments.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When defining ANSI colour variables in bash scripts, use ANSI-C quoting (`$'...'`), not double quotes.

## The rule

```bash
RED=$'\e[31m'
RESET=$'\e[0m'
printf '%s%s%s\n' "$RED" "error" "$RESET"
```

Wrong:
```bash
RED="\e[31m"   # the \e is literal, not an escape byte
```

## Why

Double-quoted escape sequences are stored as literal characters (backslash + e). They only render correctly when passed through `echo -e` or `printf` with a format string that interprets them. As `%s` arguments, they print as the literal `\e[31m` text.

ANSI-C quoting evaluates the escape at assignment time, so the variable holds the actual escape byte. It works in any printf context.

## How to apply

Any bash script that uses ANSI colours uses `$'...'` for the colour variable definitions. The status-line script and any progress-reporting script in the install benefit from this rule.
````

---

### Seed: memory/feedback_proactive_suggestions.md

````markdown
---
name: Be proactive with improvement suggestions
description: Surface high-impact improvements without waiting to be asked.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When working on a project, surface high-impact improvement ideas proactively. Do not wait for the user to ask.

## The rule

Trigger conditions:
- Spotting an obvious bug in adjacent code while doing other work.
- Noticing a pattern that, if fixed once, removes a class of future bugs.
- Seeing a feature gap the user has hit before.
- Detecting drift from a stated convention.

Format: a short note in the reply, not a multi-paragraph essay. The user decides whether to pursue.

## Why

The user does not always know what to ask for. A well-placed "while we are here, X looks worth fixing" turns reactive sessions into proactive ones. The cost is one sentence; the value is compounding quality.

## How to apply

End relevant replies with a one-line "noticed X, worth fixing?" prompt. Skip on routine work where the suggestion would just be noise.
````

---

### Seed: memory/feedback_tldr_ending.md

````markdown
---
name: End long replies with a TLDR
description: For any reply over a few paragraphs, finish with a TLDR line that summarises the one thing that matters.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

For any reply that runs more than a few paragraphs (drawbacks lists, architecture explanations, trade-off analysis), finish with a TLDR line.

## The rule

Format: `TLDR: <one sentence>` or `TLDR: <one short paragraph>`.
Captures the single decision-relevant point. Not a recap, a distillation.

## Why

Long replies bury the headline. The user reads top to bottom, then has to re-scan to find the takeaway. A TLDR closes that loop in one read.

## How to apply

After writing a long reply, add a TLDR. Test it: if the user only read the TLDR, would they make the right next decision? If yes, it is good.
````

---

### Seed: memory/feedback_reconcile_before_state_claim.md

````markdown
---
name: Reconcile before any "what is pending" claim
description: Before claiming what is pending or already done, check at least one of: messaging tail, project memory, or git log.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Before any claim about what is pending, already done, or current state of a project, reconcile against at least ONE authoritative source.

## The rule

Pick at least one:
- Recent messaging tail (last 48h).
- Latest `memory/project_<name>.md` for that project.
- `git log --since='48 hours ago'`.

State the claim only after a direct confirmation. Hedge if all three sources are silent.

## Why

State claims based on memory alone are wrong often enough to matter. The user notices the wrong-state claim and loses trust. Reconciling against a fresh source costs one Bash call and prevents the trust hit.

## How to apply

Any "we already did X" or "X is still pending" sentence triggers a reconciliation check first. If the check disagrees with memory, trust the check, update the memory.
````

---

### Seed: memory/feedback_memory_ttl_convention.md

````markdown
---
name: Memory TTL convention
description: Every memory file carries last_verified + ttl_days frontmatter. Default by type.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Every memory file in `memory/` carries `last_verified` and `ttl_days` frontmatter. Defaults by type:

| type | ttl_days |
|---|---|
| feedback | 365 |
| project | 2 |
| user | 180 |
| reference | 180 |
| note | 30 |
| agent | 90 |

## The rule

- `last_verified` is the date the content was confirmed correct.
- `ttl_days` is when it should be re-verified.
- A maintenance script (`scripts/check-memory-freshness.sh`) lists files past their TTL.

TTL is about freshness, not correctness. A stale memory is not necessarily wrong, just due for a re-check.

## Why

Without TTLs, memories accumulate forever, including ones that have silently gone wrong. Frequency-based re-verification catches drift. Without freshness signals, the memory directory becomes archaeological.

## How to apply

Every new memory written includes both fields. The maintenance routine surfaces stale ones for re-verification or removal.
````

---

### Seed: memory/feedback_save_context_after_interaction.md

````markdown
---
name: Save important context to memory after every interaction
description: After any non-trivial turn, write a memory file capturing the lesson, decision, or fact.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

After every non-trivial interaction, save the load-bearing context to a memory file. Pick the right type per the matrix.

## The rule

Type matrix:
- **feedback** -- behavioural rule from the user.
- **project** -- per-project state, blockers, decisions.
- **user** -- facts about the user's role, preferences, knowledge.
- **reference** -- pointer to an external system, doc, or resource.
- **note** -- ephemeral observation that does not fit elsewhere.
- **agent** -- per-agent voice or pattern decision.

Write to `memory/<type>_<topic>.md`. Commit. The post-commit hook embeds it into the semantic index.

## Why

Memory written contemporaneously is accurate. Memory reconstructed later is lossy. Saving as the interaction ends preserves the why and the how, not just the what.

## How to apply

End-of-turn checklist: was anything load-bearing decided, taught, or corrected? Yes -> write a memory file. No -> move on.
````

---

### Seed: memory/feedback_time_estimates.md

````markdown
---
name: Time estimates on long tasks
description: Give rough ETAs when work will take a while so the user knows when to expect a reply.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When dispatching a task that will take more than a couple of minutes, include a rough time estimate in the acknowledgement.

## The rule

Format: `On it. ETA ~15 min.` or `Sending {{agent_name}}, expect 5-10 min.`
Update the estimate if it materially changes.

## Why

Without an ETA, the user does not know whether to wait or move on. Five minutes feels like silence; thirty minutes feels like a crash. A rough number sets expectations.

## How to apply

Every dispatch over ~3 minutes carries an ETA. If the agent finishes early, the surprise is good. If it runs long, the user knows it is normal.
````

---

### Seed: memory/feedback_two_safety_gates.md

````markdown
---
name: Two safety gates, keep them in sync
description: Project gate at .claude/hooks/safety-gate.sh + global gate at ~/.claude/hooks/safety-gate.sh. Both run on every tool call.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

There are two safety gates. Both run on every tool call.

- Project gate: `.claude/hooks/safety-gate.sh` (per-repo).
- Global gate: `~/.claude/hooks/safety-gate.sh` (per-machine, applies in any project).

## The rule

When editing one, mirror the change to the other via `bash scripts/sync-safety-gates.sh`. Diverging means a destructive command blocked by one slips through the other.

## Why

A single safety gate is not enough. The project gate covers project-scoped rules; the global gate covers machine-scoped rules. Drift between them creates a path where the user's protection silently weakens.

## How to apply

Any change to either gate triggers the sync script in the same commit. The healthcheck verifies both gates are byte-equal on the shared rules.
````

---

### Seed: memory/feedback_disable_link_previews.md

````markdown
---
name: Disable link previews in messaging replies
description: Always send messaging replies with link previews disabled to prevent prompt injection via preview content.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When sending a reply on Telegram (or any messaging channel that auto-fetches link previews), disable link previews.

## The rule

Telegram bot API: pass `disable_web_page_preview: true` on every send.
Equivalent flag on other channels.

## Why

Link previews fetch arbitrary remote content. A malicious link can serve a preview that contains prompt-injection text. The orchestrator may then read that injected text on the next inbound and act on it. Disabling previews removes the entire attack surface.

## How to apply

The reply tool wrapper sets the disable flag by default. Any custom send path includes the flag explicitly.
````

---

### Seed: memory/feedback_announce_who_does_work.md

````markdown
---
name: Always announce who is doing the work
description: Every reply names the executor: agent name, or "doing this myself with skill X".
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

On every reply where the orchestrator is about to do work, name the executor.

## The rule

- Dispatching an agent -> "Sending {{agent_name}} on it."
- Doing it directly with a loaded skill -> "Doing this myself with skill X loaded."
- Doing it directly without a skill -> "Doing this myself."

## Why

The user cannot see Bash tool calls or skill loads. The reply text is their only visibility into who is on a task. Without the executor name, they cannot route follow-ups, cannot judge expected quality, and cannot tell if the right specialist was assigned.

## How to apply

Every "I will do X" reply includes a one-clause executor announcement. No exceptions.
````

---

### Seed: memory/feedback_dispatch_for_responsiveness.md

````markdown
---
name: Default to dispatching agents for any 3+ minute task
description: When the orchestrator does work directly, the main loop is locked. Dispatch background agents to stay responsive.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Default to dispatching a background agent for any task expected to take 3+ minutes. The main orchestrator loop stays free to handle the user's follow-up messages.

## The rule

Foreground (orchestrator does it directly):
- Confirmations, single-file reads, quick answers.
- Anything under ~2 minutes.

Background (dispatch an agent):
- Anything 3+ minutes.
- Anything that loads a heavy skill.
- Anything where the user is likely to send another message before this one finishes.

## Why

When the orchestrator is busy, the user waits. Responsiveness is a value of its own, not just a side effect of speed. Dispatching keeps the orchestrator available.

## How to apply

Estimate task duration first. Over the threshold -> dispatch. Under -> handle directly. The acknowledgement before dispatching covers the latency.
````

---

### Seed: memory/feedback_command_recognition.md

````markdown
---
name: Treat greetings as potential commands first
description: Words like "hi", "hello", "help", "team" might be commands. Check the command list before treating as casual chat.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Single-word or short messages that look like greetings (`hi`, `hello`, `help`, `team`, `projects`, `status`, `sync`, etc.) might actually be commands. Check the command list before responding as if it is casual chat.

## The rule

On every inbound, before generating a reply:
1. Match the message against the command list (commands table in CLAUDE.md).
2. If a command matches, run the handler.
3. If no match, treat as conversational.

## Why

The user uses commands like `team` and `help` daily. Treating them as casual greetings forces the user to repeat themselves, which feels like the system is broken.

## How to apply

Command matching is the first step on every inbound. Casual response is the fallback, not the default.
````

---

### Seed: memory/feedback_project_list_format.md

````markdown
---
name: Project list format with emoji prefixes by category
description: When asked for the project list, use the standard categorised format with emoji prefixes.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When the user asks for the project list (`projects` / `project list`), use the standard categorised format. Not a plain text dump.

## The rule

Format:
- Group by category (e.g. Mobile Apps, Desktop Apps, SaaS, Websites, Tools).
- Each project on its own line with a 🔹 prefix.
- One-line description after the project name.

Example:

```
**Mobile Apps**
🔹 ProjectA -- short description
🔹 ProjectB -- short description

**Websites**
🔹 ProjectC -- short description
```

## Why

A categorised view is scannable. A flat list of 30+ items is not. The 🔹 prefix matches the status emoji convention so the visual language is consistent across replies.

## How to apply

The `projects` command handler reads `docs/projects.md`, groups by category heading, and renders with the 🔹 prefix. Empty categories are dropped.
````

---

### Seed: memory/feedback_fix_root_causes.md

````markdown
---
name: Always fix root causes, never patch symptoms
description: Diagnose to the root, fix there. No band-aids, no quick patches that mask the underlying issue.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When fixing a bug, diagnose to the root cause and fix at that level. Do not apply a band-aid that suppresses the symptom while leaving the cause in place.

## The rule

- Reproduce the bug.
- Trace the failure to its root.
- Fix at the root.
- Add a regression test that would have caught it.

Acceptable shortcuts:
- A timed hotfix to stop active production damage, IF a follow-up calendar event exists for the proper fix.

## Why

Symptom patches accumulate. Each one masks the real problem AND adds new code that needs maintaining. After a few rounds, the system has more workaround than feature, and the underlying bug ships in new forms.

## How to apply

Before claiming a bug fixed, ask: did I find the root cause? If the answer is "I made the symptom go away but I am not sure why", the fix is not done.
````

---

### Seed: memory/feedback_use_skills_first.md

````markdown
---
name: Use available skills before going freestyle
description: Scan available skills before spawning generic agents or building from scratch.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

Every non-trivial task starts with a scan of the available skill list. Use the right skill if one applies before dispatching a generic agent or building from scratch.

## The rule

- Check the system-reminder skills section.
- Check installed plugins.
- Match by description.

A skill exists for the task -> use it. No skill matches -> dispatch a specialist agent or write the procedure inline.

## Why

Skills encode procedural knowledge that has been tested and refined. Re-deriving the same procedure from scratch is slow and lower quality. Skipping the scan means the orchestrator misses the work that has already been done.

## How to apply

The skill scan is step zero on every non-trivial inbound. Cost is a few seconds; value is access to refined procedures the orchestrator might otherwise miss.
````

---

### Seed: memory/feedback_install_skills_yourself.md

````markdown
---
name: Install skills and plugins yourself via the CLI
description: Never punt slash commands to the user. Run the CLI install commands directly.
type: feedback
last_verified: 2026-04-30
ttl_days: 365
---

When a skill or plugin needs to be installed, run the CLI commands directly. Do not punt slash commands to the user.

## The rule

- Marketplace plugins: `claude plugin marketplace add <repo>` then `claude plugin install <plugin>@<marketplace>`.
- Plain skills: `git clone <repo> ~/.claude/skills/<name>/`.

Slash commands like `/plugin marketplace add` are never required from the user side. The CLI subcommand does everything.

## Why

Punting to the user adds friction and assumes they know the slash-command path. The CLI path is scriptable, idempotent, and works in any non-interactive context.

## How to apply

Skill or plugin install requested -> run the CLI command in Bash. Confirm install. Reply with "installed" plus the path.
````

---

### Seed: memory/MEMORY.md

````markdown
- [Concise replies, no waffle](feedback_concise_replies.md) — Match the user's energy. Direct answers, no hedging, no AI-tell padding.
- [Human writing style, zero AI tells](feedback_human_writing.md) — All written content must read like a real person wrote it. Never flagged as AI.
- [No em-dashes in user-facing text](feedback_no_em_dashes.md) — The em-dash is a top AI tell. Use commas, periods, parens, or restructure.
- [No orchestrator signoff in replies](feedback_no_signoff.md) — Never end a reply with the orchestrator's name. The user already knows.
- [Telegram-first reply behaviour](feedback_telegram_first_reply.md) — Any Telegram-originated turn replies via the Telegram tool. Plain stdout never reaches the user.
- [Reply on the user channel before any logging](feedback_reply_before_logging.md) — Logging scripts add 1-2s of user-visible latency. Never call them before the reply tool.
- [Always reply immediately, never silent](feedback_always_reply_immediately.md) — A new inbound message always gets a fast acknowledgement. Never leave the user waiting in silence.
- [Aggressive parallel agent spawning on Max plans](feedback_aggressive_parallelism.md) — Unused parallel capacity is wasted budget. Default to 5-8 parallel agents on active sprints.
- [Default to multi-agent teams when work has cross-talk](feedback_default_to_team_parallelism.md) — When agents need to argue, pass artefacts back and forth, or stay in sync, use Agent Teams not solo dispatch.
- [Calendar reminders are the standard pattern for future follow-ups](feedback_calendar_reminders.md) — Every "remove once X" or "re-evaluate in N weeks" gets a calendar event with full context.
- [Log every user correction to corrections.jsonl](feedback_log_corrections.md) — When the user corrects you, run the correction logger so frequency review can spot patterns.
- [Every project gets CLAUDE.md, HANDOFF.md, FEATURES.md](feedback_project_documentation.md) — Project documentation discipline. Three files, every project, no exceptions.
- [Always update docs/projects.md](feedback_update_projects_md.md) — Whenever a project is created or significantly changes, update the registry file.
- [Status emoji convention (done, running, blocked)](feedback_status_emoji_convention.md) — Three-state visual cue on every status update. 🔹 done, 🔸 running, 🔸🔴 blocked-on-user.
- [Verify deploys after every push](feedback_verify_deploys.md) — git push success is not deploy success. Always verify the deploy actually landed.
- [Always use printf for env vars, never echo](feedback_printf_for_env_vars.md) — echo pipes append a trailing newline that corrupts secrets and tokens. Use printf.
- [Never use fake or synthetic data](feedback_no_fake_data.md) — All data displayed, returned, or stored must be real and verified. Never interpolate to fill gaps.
- [Always run a complete sweep when building features](feedback_complete_sweep.md) — When applying a change, apply it everywhere it should go. Do not leave gaps for the user to find.
- [Never mix up projects or repos](feedback_dont_mix_projects.md) — Always confirm the folder and repo before any destructive operation.
- [Hide AI rate limits from user-facing UI](feedback_hide_ai_limits.md) — Enforce caps silently on the backend. Never show counters, budgets, or "X uses left" messaging in the UI.
- [Always use private repos for new project repos](feedback_private_repos.md) — Default visibility for any new GitHub repo created during install or scaffolding is private.
- [Save HANDOFF.md when switching projects](feedback_save_progress_on_switch.md) — When the user switches focus to a different project, write a progress snapshot to the current project's HANDOFF.md first.
- [Always discuss drawbacks before building system upgrades](feedback_discuss_drawbacks_first.md) — When proposing infrastructure or system changes, present honest downsides before code.
- [Always do live web searches for research](feedback_live_searches.md) — Never rely on training data alone for current information. Run a live search.
- [Verify competitors actually exist before listing](feedback_verify_competitors.md) — Before naming a competitor in any analysis, confirm the product exists and is actively shipping.
- [Walk-forward backtest before any predictive performance claim](feedback_walk_forward_backtest.md) — Trading and forecasting claims require PIT-safe walk-forward backtests. Never quote a number from in-sample fit.
- [Use ANSI-C quoting for bash colour variables](feedback_ansi_c_quoting.md) — Use $'\e[...m' form so escape sequences resolve in both format strings and %s arguments.
- [Be proactive with improvement suggestions](feedback_proactive_suggestions.md) — Surface high-impact improvements without waiting to be asked.
- [End long replies with a TLDR](feedback_tldr_ending.md) — For any reply over a few paragraphs, finish with a TLDR line that summarises the one thing that matters.
- [Reconcile before any "what is pending" claim](feedback_reconcile_before_state_claim.md) — Before claiming what is pending or already done, check at least one of: messaging tail, project memory, or git log.
- [Memory TTL convention](feedback_memory_ttl_convention.md) — Every memory file carries last_verified + ttl_days frontmatter. Default by type.
- [Save important context to memory after every interaction](feedback_save_context_after_interaction.md) — After any non-trivial turn, write a memory file capturing the lesson, decision, or fact.
- [Time estimates on long tasks](feedback_time_estimates.md) — Give rough ETAs when work will take a while so the user knows when to expect a reply.
- [Two safety gates, keep them in sync](feedback_two_safety_gates.md) — Project gate at .claude/hooks/safety-gate.sh + global gate at ~/.claude/hooks/safety-gate.sh. Both run on every tool call.
- [Disable link previews in messaging replies](feedback_disable_link_previews.md) — Always send messaging replies with link previews disabled to prevent prompt injection via preview content.
- [Always announce who is doing the work](feedback_announce_who_does_work.md) — Every reply names the executor: agent name, or "doing this myself with skill X".
- [Default to dispatching agents for any 3+ minute task](feedback_dispatch_for_responsiveness.md) — When the orchestrator does work directly, the main loop is locked. Dispatch background agents to stay responsive.
- [Treat greetings as potential commands first](feedback_command_recognition.md) — Words like "hi", "hello", "help", "team" might be commands. Check the command list before treating as casual chat.
- [Project list format with emoji prefixes by category](feedback_project_list_format.md) — When asked for the project list, use the standard categorised format with emoji prefixes.
- [Always fix root causes, never patch symptoms](feedback_fix_root_causes.md) — Diagnose to the root, fix there. No band-aids, no quick patches that mask the underlying issue.
- [Use available skills before going freestyle](feedback_use_skills_first.md) — Scan available skills before spawning generic agents or building from scratch.
- [Install skills and plugins yourself via the CLI](feedback_install_skills_yourself.md) — Never punt slash commands to the user. Run the CLI install commands directly.
````

---


---

# Appendix - Script Files

Every code block below has its destination path in the first line. Save each to that path, then `chmod +x` shell scripts.

## Common Templates (referenced earlier in this blueprint)

### `scripts/setup-db.sh`

Creates the optional SQLite operational layer. v30's source of truth is markdown; this script is only generated if the user explicitly opted into a SQLite memory layer during install.

```bash
#!/bin/bash
# setup-db.sh - create the optional SQLite operational layer.
# Only run this if you want a SQLite memory store on top of the markdown files.
set -euo pipefail

DB_PATH="{{project_path}}/data/{{db_name}}"
mkdir -p "$(dirname "$DB_PATH")"

sqlite3 "$DB_PATH" <<'SQL'
CREATE TABLE IF NOT EXISTS memories (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  agent        TEXT NOT NULL,
  topic        TEXT NOT NULL,
  body         TEXT NOT NULL,
  importance   INTEGER DEFAULT 5,
  created_at   TEXT DEFAULT (datetime('now')),
  expires_at   TEXT
);
CREATE INDEX IF NOT EXISTS idx_memories_agent ON memories(agent);
CREATE INDEX IF NOT EXISTS idx_memories_created ON memories(created_at);

-- FTS5 search index
CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts USING fts5(topic, body, content='memories', content_rowid='id');

CREATE TRIGGER IF NOT EXISTS memories_ai AFTER INSERT ON memories BEGIN
  INSERT INTO memories_fts(rowid, topic, body) VALUES (new.id, new.topic, new.body);
END;
CREATE TRIGGER IF NOT EXISTS memories_ad AFTER DELETE ON memories BEGIN
  INSERT INTO memories_fts(memories_fts, rowid, topic, body) VALUES('delete', old.id, old.topic, old.body);
END;

CREATE TABLE IF NOT EXISTS tasks (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  project      TEXT,
  description  TEXT NOT NULL,
  status       TEXT DEFAULT 'pending',
  created_at   TEXT DEFAULT (datetime('now')),
  completed_at TEXT
);

CREATE TABLE IF NOT EXISTS decisions (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  topic        TEXT NOT NULL,
  decision     TEXT NOT NULL,
  rationale    TEXT,
  created_at   TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS corrections (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  category     TEXT NOT NULL,
  description  TEXT NOT NULL,
  created_at   TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS patterns (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  pattern      TEXT NOT NULL UNIQUE,
  category     TEXT,
  hit_count    INTEGER DEFAULT 1,
  last_seen    TEXT DEFAULT (datetime('now'))
);
SQL

echo "Database created at $DB_PATH"
echo "Tables: memories (FTS5), tasks, decisions, corrections, patterns"
```

### `scripts/sync-safety-gates.sh`

Keeps the project safety gate and the global one in sync. Run after editing `.claude/hooks/safety-gate.sh` so the global gate (which other projects inherit) stays consistent.

```bash
#!/bin/bash
# sync-safety-gates.sh - mirror the project gate to ~/.claude/hooks/safety-gate.sh.
set -euo pipefail

SRC="{{project_path}}/.claude/hooks/safety-gate.sh"
DST="$HOME/.claude/hooks/safety-gate.sh"

if [ ! -f "$SRC" ]; then
  echo "Source gate missing: $SRC" >&2
  exit 1
fi

mkdir -p "$(dirname "$DST")"
cp "$SRC" "$DST"
chmod +x "$DST"
echo "Synced safety gate: $SRC -> $DST"
```

### `scripts/restore-memory-symlinks.sh`

After a fresh git clone on a new machine, the `~/.claude/projects/<slug>/memory` and `~/.claude/agent-memory` symlinks need to be rebuilt so Claude Code finds the canonical files inside this repo.

```bash
#!/bin/bash
# restore-memory-symlinks.sh - rebuild Claude Code's expected symlinks after a fresh clone.
set -euo pipefail

PROJECT_ROOT="{{project_path}}"
PROJECT_SLUG=$(echo "$PROJECT_ROOT" | sed 's|/|-|g')

mkdir -p "$HOME/.claude/projects/$PROJECT_SLUG"

TARGET_MEM="$HOME/.claude/projects/$PROJECT_SLUG/memory"
if [ -L "$TARGET_MEM" ]; then
  command rm -f "$TARGET_MEM"
elif [ -e "$TARGET_MEM" ]; then
  echo "WARNING: $TARGET_MEM exists and is not a symlink. Refusing to overwrite real data."
  echo "Move its contents into $PROJECT_ROOT/memory and re-run."
  exit 1
fi
ln -s "$PROJECT_ROOT/memory" "$TARGET_MEM"
echo "Linked memory:       $TARGET_MEM -> $PROJECT_ROOT/memory"

TARGET_AM="$HOME/.claude/agent-memory"
if [ -L "$TARGET_AM" ]; then
  command rm -f "$TARGET_AM"
elif [ -e "$TARGET_AM" ]; then
  echo "WARNING: $TARGET_AM exists and is not a symlink. Refusing to overwrite real data."
  echo "Move its contents into $PROJECT_ROOT/agent-memory and re-run."
  exit 1
fi
ln -s "$PROJECT_ROOT/agent-memory" "$TARGET_AM"
echo "Linked agent-memory: $TARGET_AM -> $PROJECT_ROOT/agent-memory"
```

---

## E1 - sqlite-vec + Nomic-embed

### `scripts/embed-memories.sh`

```bash
#!/usr/bin/env bash
# Thin wrapper over scripts/embed-memories.py so the rest of the orchestrator can call it
# like any other shell script. Forwards args, picks the working Python 3.13.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Order matters: we need a Python whose sqlite3 was built with loadable extensions.
# uv's distribution (~/.local/bin/python3.13) ticks that box; the python.org one
# at /usr/local/bin/python3 does NOT.
for cand in "${ORCHESTRATOR_PY:-}" "$HOME/.local/bin/python3.13" /opt/homebrew/bin/python3.14; do
  if [[ -x "$cand" ]] && "$cand" -c 'import sqlite3,sys; c=sqlite3.connect(":memory:"); c.enable_load_extension(True)' 2>/dev/null; then
    PY="$cand"
    break
  fi
done
if [[ -z "${PY:-}" ]]; then
  echo "embed-memories: no Python with loadable sqlite extensions found." >&2
  echo "  Install one via: uv python install 3.13" >&2
  exit 3
fi
exec "$PY" "$SCRIPT_DIR/embed-memories.py" "$@"
```

### `scripts/memory-search.sh`

```bash
#!/usr/bin/env bash
# Thin wrapper over scripts/memory-search.py so other agents can pipe the results
# as JSON. Forwards args, picks the working Python 3.13.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
for cand in "${ORCHESTRATOR_PY:-}" "$HOME/.local/bin/python3.13" /opt/homebrew/bin/python3.14; do
  if [[ -x "$cand" ]] && "$cand" -c 'import sqlite3; c=sqlite3.connect(":memory:"); c.enable_load_extension(True)' 2>/dev/null; then
    PY="$cand"
    break
  fi
done
if [[ -z "${PY:-}" ]]; then
  echo "memory-search: no Python with loadable sqlite extensions found." >&2
  exit 3
fi
exec "$PY" "$SCRIPT_DIR/memory-search.py" "$@"
```

### `scripts/install-git-hooks.sh`

```bash
#!/usr/bin/env bash
# Symlinks scripts/hooks/* into .git/hooks/ so that the hooks are versioned
# with the repo. Idempotent - safe to run multiple times. Never overwrites
# a non-symlink hook (so if you've customised .git/hooks/post-commit, it
# won't clobber your version).
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
SRC_DIR="$REPO_ROOT/scripts/hooks"
DST_DIR="$REPO_ROOT/.git/hooks"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "No hooks to install at $SRC_DIR" >&2
  exit 0
fi

mkdir -p "$DST_DIR"

for src in "$SRC_DIR"/*; do
  name="$(basename "$src")"
  [[ "$name" == "*" ]] && continue
  [[ "$name" == *.sample ]] && continue
  dst="$DST_DIR/$name"
  chmod +x "$src"
  if [[ -L "$dst" ]]; then
    # Already a symlink - refresh it.
    ln -sf "$src" "$dst"
    echo "refreshed: $dst -> $src"
  elif [[ -e "$dst" ]]; then
    echo "skip: $dst is a non-symlink, not overwriting." >&2
  else
    ln -s "$src" "$dst"
    echo "installed: $dst -> $src"
  fi
done
```

### `scripts/hooks/post-commit`

```bash
#!/usr/bin/env bash
# post-commit hook: keep the local semantic index in sync with markdown memory.
#
# Runs `scripts/embed-memories.sh` iff the commit we just made touches any
# *.md under memory/, agent-memory/, or docs/. The embedder is incremental, so
# this is cheap - only changed chunks are re-embedded.
#
# Installed by `bash scripts/install-git-hooks.sh`.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# What changed in HEAD?
if ! changed=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null); then
  exit 0
fi

if ! grep -qE '^(memory/|agent-memory/|docs/).+\.md$' <<<"$changed"; then
  # Nothing relevant changed; skip the re-embed.
  exit 0
fi

# Run the embedder quietly in the background so the commit completes fast.
# If it fails, we log it - never block the commit.
LOG="$REPO_ROOT/data/audit/embed-memories.log"
mkdir -p "$(dirname "$LOG")"
(
  {
    echo "[$(date -u +%FT%TZ)] post-commit re-embed triggered by: $(echo "$changed" | tr '\n' ' ')"
    bash "$REPO_ROOT/scripts/embed-memories.sh" || echo "[post-commit] embed-memories FAILED"
  } >>"$LOG" 2>&1
) &

exit 0
```

## E4 - Observability

### `.claude/hooks/audit-log-hook.sh`

```bash
#!/bin/bash
# PostToolUse hook: append a minimal event record for every tool call to
# data/audit/YYYY-MM-DD.jsonl so we can replay what happened in a session.
#
# Wired in .claude/settings.json under PostToolUse. async=true so it never
# blocks tool execution.
#
# Gitignored - audit logs live on disk only, not in git.
set -euo pipefail

INPUT=$(cat)

# If input is malformed, exit quietly - never break tool flow
TS=$(date -u +%Y-%m-%dT%H:%M:%S.000Z) || exit 0
DAY=$(date -u +%Y-%m-%d) || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
AUDIT_DIR="$SCRIPT_DIR/data/audit"
mkdir -p "$AUDIT_DIR" 2>/dev/null || exit 0
OUT="$AUDIT_DIR/$DAY.jsonl"

# Extract fields. Handle missing fields gracefully.
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
TOOL_USE_ID=$(echo "$INPUT" | jq -r '.tool_use_id // empty' 2>/dev/null || echo "")
INPUT_SUMMARY=$(echo "$INPUT" | jq -r '
  if .tool_input.command then .tool_input.command
  elif .tool_input.file_path then .tool_input.file_path
  elif .tool_input.path then .tool_input.path
  elif .tool_input.query then .tool_input.query
  elif .tool_input.pattern then .tool_input.pattern
  elif .tool_input.prompt then .tool_input.prompt
  elif .tool_input.text then .tool_input.text
  elif .tool_input.url then .tool_input.url
  elif .tool_input.description then .tool_input.description
  else ""
  end // ""
' 2>/dev/null | head -c 240 || echo "")

IS_ERROR=$(echo "$INPUT" | jq -r '.tool_result.is_error // false' 2>/dev/null || echo "false")
ERROR_MSG=""
if [ "$IS_ERROR" = "true" ]; then
  ERROR_MSG=$(echo "$INPUT" | jq -r '.tool_result.content[0].text // .tool_result.error // ""' 2>/dev/null | head -c 240 || echo "")
fi

OUTPUT_SUMMARY=""
if [ "$IS_ERROR" = "false" ]; then
  OUTPUT_SUMMARY=$(echo "$INPUT" | jq -r '
    if (.tool_result.content | type) == "array" then
      (.tool_result.content | map(select(.type == "text") | .text) | join(" "))
    elif (.tool_result | type) == "string" then
      .tool_result
    else ""
    end // ""
  ' 2>/dev/null | head -c 240 || echo "")
fi

# Strip secrets from summaries
scrub() {
  echo "$1" | sed -E 's/(api[_-]?key|token|password|secret|bearer|authorization)[[:space:]]*[:=][[:space:]]*['\''"]*[^'\''"[:space:]]{8,}/\1=***REDACTED***/Ig'
}
INPUT_SUMMARY=$(scrub "$INPUT_SUMMARY")
OUTPUT_SUMMARY=$(scrub "$OUTPUT_SUMMARY")
ERROR_MSG=$(scrub "$ERROR_MSG")

PROJECT=$(basename "$SCRIPT_DIR")

jq -nc \
  --arg ts "$TS" \
  --arg tool "$TOOL" \
  --arg tool_use_id "$TOOL_USE_ID" \
  --arg input_summary "$INPUT_SUMMARY" \
  --arg output_summary "$OUTPUT_SUMMARY" \
  --arg error "$ERROR_MSG" \
  --argjson is_error "$IS_ERROR" \
  --arg project "$PROJECT" \
  '{ts:$ts,tool:$tool,tool_use_id:$tool_use_id,project:$project,success:($is_error==false),input:$input_summary,output:$output_summary,error:$error}' \
  2>/dev/null >> "$OUT" || true

echo '{"suppressOutput": true}'
```

### `scripts/{{orchestrator_lower}}-live.sh`

```bash
#!/bin/bash
# {{orchestrator_lower}}-live - pretty-print the audit JSONL
#
# Usage:
#   {{orchestrator_lower}}-live                       # last 20 events from today
#   {{orchestrator_lower}}-live --follow              # tail -F today, stream live
#   {{orchestrator_lower}}-live --last 50             # last 50 events
#   {{orchestrator_lower}}-live --tool Bash           # only Bash events
#   {{orchestrator_lower}}-live --project MyProject  # only events in a project
#   {{orchestrator_lower}}-live --day 2026-04-20      # events from a specific day
#   {{orchestrator_lower}}-live --failed              # only errored tool calls
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
AUDIT_DIR="$SCRIPT_DIR/data/audit"

LAST=20
FOLLOW=0
FILTER_TOOL=""
FILTER_PROJECT=""
FILTER_FAILED=0
DAY=$(date -u +%Y-%m-%d)

while [ $# -gt 0 ]; do
  case "$1" in
    --follow|-f) FOLLOW=1; shift ;;
    --last)      LAST="$2"; shift 2 ;;
    --tool)      FILTER_TOOL="$2"; shift 2 ;;
    --project)   FILTER_PROJECT="$2"; shift 2 ;;
    --day)       DAY="$2"; shift 2 ;;
    --failed)    FILTER_FAILED=1; shift ;;
    -h|--help)
      sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

FILE="$AUDIT_DIR/$DAY.jsonl"
[ -f "$FILE" ] || { echo "no audit log for $DAY at $FILE" >&2; exit 1; }

emoji_for_tool() {
  case "$1" in
    Bash) echo "💻" ;;
    Edit|Write|NotebookEdit) echo "📝" ;;
    Read|NotebookRead) echo "📖" ;;
    Glob|Grep) echo "🔍" ;;
    Agent) echo "🤖" ;;
    Task*) echo "📋" ;;
    mcp__plugin_telegram*) echo "💬" ;;
    mcp__blitz*) echo "📱" ;;
    mcp__claude-in-chrome*) echo "🌐" ;;
    mcp__blitz-macos*) echo "🖥️ " ;;
    WebFetch|WebSearch) echo "🌍" ;;
    *) echo "🔧" ;;
  esac
}

pretty() {
  jq -r '. | [.ts, .tool, .project, (.success|tostring), (.input // "" | .[:100])] | @tsv' | \
  while IFS=$'\t' read -r ts tool project success input; do
    if [ "$FILTER_FAILED" = "1" ] && [ "$success" = "true" ]; then continue; fi
    if [ -n "$FILTER_TOOL" ] && [ "$tool" != "$FILTER_TOOL" ]; then continue; fi
    if [ -n "$FILTER_PROJECT" ] && [ "$project" != "$FILTER_PROJECT" ]; then continue; fi
    # Portable HH:MM:SS extraction. ISO-8601 has fixed offsets so we just slice
    # characters 11..18 (the time field) - no `date` call needed. Avoids the BSD-only
    # `date -u -j -f` form that doesn't exist on Linux or Windows-Git-Bash (GNU date).
    local_ts="${ts:11:8}"
    [ -z "$local_ts" ] && local_ts="$ts"
    emoji=$(emoji_for_tool "$tool")
    status=$([ "$success" = "true" ] && echo "✅" || echo "❌")
    tool_short="${tool#mcp__*}"
    tool_short="${tool_short:0:20}"
    project_short="${project:-?}"
    printf "[%s] %s %-20s · %-14s · %s · %s\n" "$local_ts" "$emoji" "$tool_short" "$project_short" "$status" "${input:0:80}"
  done
}

if [ "$FOLLOW" = "1" ]; then
  tail -F "$FILE" 2>/dev/null | pretty
else
  tail -n "$LAST" "$FILE" | pretty
fi
```

### `scripts/audit-archive.sh`

```bash
#!/usr/bin/env bash
# audit-archive - gzip audit JSONL files older than N days into the archive dir.
#
# Replaces the old audit-prune.sh behaviour. Instead of deleting old tool-call
# audit logs, we compress them into data/audit/archive/YYYY/MM.jsonl.gz so the
# forensic trail stays intact forever. Compression is ~10x on these JSONL files.
#
# The live data/audit/*.jsonl is gitignored (noisy + written every tool call).
# The archive dir is committed so disaster-recovery rebuilds the history from
# git.
#
# Usage:
#   bash scripts/audit-archive.sh            # archive anything >=30 days old
#   bash scripts/audit-archive.sh 7          # archive anything >=7 days old
#   bash scripts/audit-archive.sh --dry-run  # show what would archive, no changes

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT_DIR="$REPO_ROOT/data/audit"
ARCHIVE_DIR="$AUDIT_DIR/archive"
DAYS=30
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    [0-9]*) DAYS="$1"; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -d "$AUDIT_DIR" ] || exit 0
mkdir -p "$ARCHIVE_DIR"

archived=0
skipped=0

while IFS= read -r f; do
  [ -f "$f" ] || continue
  base="$(basename "$f")"
  if [[ ! "$base" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})\.jsonl$ ]]; then
    skipped=$((skipped + 1))
    continue
  fi
  year="${BASH_REMATCH[1]}"
  month="${BASH_REMATCH[2]}"
  month_dir="$ARCHIVE_DIR/$year"
  mkdir -p "$month_dir"
  dest="$month_dir/$month.jsonl.gz"

  if [ "$DRY_RUN" = "1" ]; then
    echo "WOULD ARCHIVE: $base -> $(echo "$dest" | sed "s|$REPO_ROOT/||")"
    continue
  fi

  gzip -c "$f" >> "$dest"
  rm -f "$f"
  archived=$((archived + 1))
done < <(find "$AUDIT_DIR" -maxdepth 1 -name "*.jsonl" -type f -mtime "+$DAYS" 2>/dev/null)

if [ "$DRY_RUN" = "1" ]; then
  echo "(dry run - no files moved)"
  exit 0
fi

echo "audit-archive: archived=$archived skipped=$skipped (threshold: $DAYS days)"
```

## E5 - Hardened safety gate

### `.claude/hooks/safety-gate.sh`

```bash
#!/bin/bash
# HARDENED SAFETY GATE (E5)
# Blocks destructive commands and prompts the user for approval (via Telegram if configured).
# Exit 0 = allow. Exit 2 = block (message sent to Claude via stderr).
# Also emits structured JSON on stdout for newer Claude Code versions:
#   {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow|deny","permissionDecisionReason":"..."}}
# Exit codes remain authoritative. JSON is advisory and forward-compatible.
#
# APPROVAL FLOW:
# 1. Hook blocks a dangerous command
# 2. Claude sees the block reason and asks the user
# 3. User says "yes" / "approved"
# 4. Claude writes the exact command to {{project_path}}/data/approved.txt
# 5. Claude retries the command
# 6. Hook sees it's pre-approved, allows it, removes the approval (one-time use)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // empty')

# === STRUCTURED OUTPUT HELPER ===
# Emits JSON on stdout for modern Claude Code hook protocol, without disturbing
# the stderr reason string (which existing versions of Claude Code read).
emit_decision() {
  local decision="$1"  # "allow" or "deny"
  local reason="${2:-}"
  if [ -n "$reason" ]; then
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":%s}}\n' \
      "$decision" "$(printf '%s' "$reason" | jq -Rs .)"
  else
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s"}}\n' "$decision"
  fi
}

# Nothing to inspect
if [ -z "$COMMAND" ] && [ -z "$FILE_PATH" ]; then
  emit_decision "allow"
  exit 0
fi

TIMESTAMP=$(date -Iseconds)
LOG_DIR="{{project_path}}/logs"
LOG_FILE="$LOG_DIR/safety-gate.log"
# NOTE: this file MUST be in .gitignore. A checked-in approval file would let any
# clone of this repo bypass the gate. The 0600 perms below stop a malicious
# package's postinstall script from pre-approving destructive commands by writing
# to it as another local user.
APPROVAL_FILE="{{project_path}}/data/approved.txt"
APPROVAL_TTL_DAYS=30

# Ensure approval file + log dir exist with restrictive perms
mkdir -p "$LOG_DIR" "$(dirname "$APPROVAL_FILE")"
touch "$APPROVAL_FILE"
chmod 0600 "$APPROVAL_FILE" 2>/dev/null || true

# === TTL PRUNE + TIMESTAMP BACKFILL ===
# Approval file format (new): "<epoch_seconds>|<command>" per line.
# Legacy lines without the "<epoch>|" prefix are treated as written-now on first
# sight (they get 30 days from now). Lines older than APPROVAL_TTL_DAYS are
# dropped so stale approvals from previous sessions can't quietly green-light a
# destructive op later.
if [ -s "$APPROVAL_FILE" ]; then
  NOW_EPOCH=$(date +%s)
  TTL_SECONDS=$((APPROVAL_TTL_DAYS * 86400))
  awk -F'|' -v now="$NOW_EPOCH" -v ttl="$TTL_SECONDS" '
    NF >= 2 && $1 ~ /^[0-9]+$/ {
      # Timestamped entry. Drop if expired. Rejoin command in case it contained pipes.
      ts = $1
      cmd = $2
      for (i = 3; i <= NF; i++) cmd = cmd "|" $i
      if (now - ts < ttl) {
        printf "%s|%s\n", ts, cmd
      }
      next
    }
    NF > 0 {
      # Legacy entry without timestamp. Stamp with now.
      printf "%s|%s\n", now, $0
    }
  ' "$APPROVAL_FILE" > "$APPROVAL_FILE.prune" && mv "$APPROVAL_FILE.prune" "$APPROVAL_FILE"
  chmod 0600 "$APPROVAL_FILE" 2>/dev/null || true
fi

# === CHECK FOR PRE-APPROVAL ===
# If the user already approved this exact command, let it through and clear it
CHECK_STRING="$COMMAND$FILE_PATH"
if awk -F'|' -v cmd="$CHECK_STRING" '
  NF >= 2 && $1 ~ /^[0-9]+$/ {
    c = $2
    for (i = 3; i <= NF; i++) c = c "|" $i
    if (c == cmd) { found = 1; exit }
  }
  NF > 0 && $0 == cmd { found = 1; exit }
  END { exit !found }
' "$APPROVAL_FILE" 2>/dev/null; then
  # Remove ONE matching approval entry (one-time-use, first-match). Both
  # the project and global gates run per Bash call, so each call consumes
  # one entry. Multiple identical entries (one per gate) keep duplicates
  # so the second gate still finds a match. Match either new or legacy
  # format. Fixed 2026-04-22 after batch rm consumed both entries in one pass.
  awk -F'|' -v cmd="$CHECK_STRING" '
    !consumed && NF >= 2 && $1 ~ /^[0-9]+$/ {
      c = $2
      for (i = 3; i <= NF; i++) c = c "|" $i
      if (c == cmd) { consumed = 1; next }
      print; next
    }
    !consumed && $0 == cmd { consumed = 1; next }
    { print }
  ' "$APPROVAL_FILE" > "$APPROVAL_FILE.tmp" && mv "$APPROVAL_FILE.tmp" "$APPROVAL_FILE"
  chmod 0600 "$APPROVAL_FILE" 2>/dev/null || true
  echo "[$TIMESTAMP] APPROVED (pre-approved): $CHECK_STRING" >> "$LOG_FILE"
  emit_decision "allow" "Pre-approved (one-time use, consumed)"
  exit 0
fi

# === HELPER: block with approval instructions ===
block() {
  local REASON="$1"
  local CATEGORY="$2"
  local MSG="BLOCKED: $REASON. Ask the user for approval. If approved, write the exact command to {{project_path}}/data/approved.txt (one command per line) then retry."
  echo "$MSG" >&2
  echo "[$TIMESTAMP] BLOCKED ($CATEGORY): ${COMMAND}${FILE_PATH}" >> "$LOG_FILE"
  emit_decision "deny" "$MSG"
  exit 2
}

# === HELPER: hard block (not even user approval opens the gate) ===
hard_block() {
  local REASON="$1"
  local CATEGORY="$2"
  local MSG="HARD BLOCKED: $REASON. This cannot be approved through the hook. Run manually in Terminal if you genuinely need this."
  echo "$MSG" >&2
  echo "[$TIMESTAMP] HARD BLOCKED ($CATEGORY): $COMMAND" >> "$LOG_FILE"
  emit_decision "deny" "$MSG"
  exit 2
}

# === CATEGORY 1: ALWAYS BLOCKED (no approval possible) ===
# These are so catastrophic or history-destroying that even with approval,
# we don't allow them through the hook. Run them manually in Terminal if you must.

# Delete home / root filesystem
if echo "$COMMAND" | grep -qEi 'rm\s+-(rf|fr)\s+(/|~|\$HOME)\s*$'; then
  hard_block "This would delete your entire home directory or root filesystem" "catastrophic"
fi

# Disk formatting / partition ops
if echo "$COMMAND" | grep -qEi '(mkfs\.|dd\s+if=|fdisk|diskutil\s+erase)'; then
  hard_block "Disk formatting / partition operation" "disk"
fi

# Git history rewrites. These are almost never recoverable.
if echo "$COMMAND" | grep -qEi 'git\s+filter-(branch|repo)'; then
  hard_block "git filter-branch/filter-repo permanently rewrites history. Unrecoverable if pushed." "git-filter"
fi

if echo "$COMMAND" | grep -qEi '(git\s+update-ref\s+-d|git\s+reflog\s+expire|git\s+gc\s+.*--prune=now|git\s+gc\s+.*--aggressive)'; then
  hard_block "Permanent reflog / ref cleanup. Makes it impossible to recover lost commits." "git-reflog"
fi

# Reject `-c push.default=...` shell-form pre-commands. Known force-push bypass.
# Sets push.default for the single command, then a bare `git push` pushes current
# branch even if we'd otherwise expect an explicit refspec. Always hard-block.
if echo "$COMMAND" | grep -qEi 'git\s+-c\s+push\.default='; then
  hard_block "git -c push.default=... pre-command override is a known bypass for branch-target detection" "git-push-default-override"
fi

# Refspec-prefixed forced push: `git push origin +HEAD:main`, `git push remote +branch:branch`.
# The `+` in front of a refspec means "force this push" with no --force flag, which
# evades every flag-based check. Always hard-block. If you genuinely need this, run
# it manually in Terminal.
if echo "$COMMAND" | grep -qEi 'git\s+push\s+\S+\s+\+'; then
  hard_block "Refspec-prefixed forced push (+ before refspec). Same as --force, blocked unconditionally." "git-refspec-force"
fi

# Force push to protected branches: main, master, production, prod, release, develop.
# Any push with --force / -f / --force-with-lease targeting one of these branches
# is a hard block. This is what destroys shared history irrecoverably.
if echo "$COMMAND" | grep -qEi 'git\s+push(\s+[^-]\S*)*\s+(--force|-f|--force-with-lease)(\s|=|$)' || \
   echo "$COMMAND" | grep -qEi 'git\s+push\s+.*(--force|-f|--force-with-lease).*\s+(origin\s+)?(main|master|production|prod|release|develop)(\s|$|:)'; then
  # Hard-block if target branch is main/master/production/prod/release/develop
  if echo "$COMMAND" | grep -qEi '(origin\s+)?(main|master|production|prod|release|develop)(\s|$|:)'; then
    hard_block "Force push to protected branch (main/master/production/prod/release/develop). This destroys shared history. Never allowed via the hook." "git-force-push-protected"
  fi
  # Hard-block bare `git push -f` (no remote, no branch). This form pushes the
  # current branch to its upstream. If current branch is main, the named-branch
  # check above never sees "main" in the command and would otherwise miss this.
  # Hard-block any forced push that doesn't explicitly target a clearly
  # non-protected branch.
  if ! echo "$COMMAND" | grep -qEi 'git\s+push\s+\S+\s+[A-Za-z0-9._/+:-]+(\s|$)'; then
    hard_block "Force push without explicit branch target. Defaults to current branch which may be protected." "git-force-push-implicit"
  fi
fi

# === CATEGORY 2: BLOCKED UNTIL APPROVED ===

# --- File deletion ---
# Whitelist common CLI subcommands that use `rm` as a verb but are NOT filesystem
# deletes. Without this, `vercel env rm`, `gh secret rm`, `docker rm`, `docker
# container rm`, `docker image rm`, `docker volume rm`, `docker network rm`,
# `kubectl ... rm`, `npm rm`, `yarn remove`, `pnpm rm`, `bun remove`, `brew
# uninstall`, `git rm` all false-positive on the rm regex below. Patched
# 2026-04-30 after live false-positives.
if echo "$COMMAND" | grep -qE '\b(vercel\s+(env|domains|alias)\s+(rm|remove)|gh\s+(secret|variable|env|release|label|repo|ssh-key|gpg-key|auth\s+token)\s+(rm|remove|delete)|docker\s+(image|volume|network|container)?\s*rm|npm\s+rm|yarn\s+remove|pnpm\s+rm|bun\s+remove|brew\s+(uninstall|rm)|git\s+rm|kubectl\s+(secret|configmap)\s+rm)\b'; then
  echo "[$TIMESTAMP] WHITELISTED CLI rm subcommand: $COMMAND" >> "$LOG_FILE"
elif echo "$COMMAND" | grep -qE '(^|\s)rm\s+-[A-Za-z]*[rR][A-Za-z]*(\s|$)'; then
  block "Recursive file deletion detected" "rm-rf"
elif echo "$COMMAND" | grep -qE '(^|\s)rm\s+(-{1,2})?(--recursive|--force)'; then
  block "Long-flag recursive/forced file deletion (--recursive / --force)" "rm-longflag"
elif echo "$COMMAND" | grep -qE '(^|\s)rm\s'; then
  block "File deletion detected" "rm"
fi
# `/bin/rm` style invocation
if echo "$COMMAND" | grep -qE '(^|\s|;|&|\|)(/usr)?/bin/rm\s'; then
  block "File deletion via /bin/rm detected" "rm-path"
fi
# `find -delete` and `find -exec rm` are file deletion in disguise
if echo "$COMMAND" | grep -qE 'find\s.*-delete(\s|$)'; then
  block "find -delete recursively deletes files" "find-delete"
fi
if echo "$COMMAND" | grep -qE 'find\s.*-exec\s+rm\s'; then
  block "find -exec rm pipes deletion through find" "find-exec-rm"
fi
# rsync --delete can wipe a destination tree
if echo "$COMMAND" | grep -qE 'rsync\s.*--delete'; then
  block "rsync --delete removes files from destination not in source" "rsync-delete"
fi

# --- Database destructors ---
if echo "$COMMAND" | grep -qEi '(DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s+TABLE)'; then
  block "Destructive database operation (DROP/TRUNCATE)" "sql-drop"
fi

# DELETE without WHERE
if echo "$COMMAND" | grep -qEi 'DELETE\s+FROM\s+\w+\s*[;$]'; then
  block "DELETE FROM without WHERE clause. This deletes ALL rows." "sql-delete"
fi

# --- Git destructive operations ---
# Force push (any form, any branch that isn't main/master, those are hard-blocked above)
if echo "$COMMAND" | grep -qEi 'git\s+push(\s+\S+)*\s+(--force|-f)(\s|=|$)'; then
  block "Force push detected. If you actually need this, confirm the target branch isn't shared or critical." "git-force-push"
fi
if echo "$COMMAND" | grep -qEi 'git\s+push.*--force-with-lease'; then
  block "Force-push-with-lease detected. Safer than --force but still rewrites remote history." "git-force-lease"
fi

# Push with --mirror (rewrites everything on remote)
if echo "$COMMAND" | grep -qEi 'git\s+push\s+.*--mirror'; then
  block "git push --mirror can overwrite all remote refs" "git-mirror"
fi

# Push with --delete or :branch syntax (deletes remote branch)
if echo "$COMMAND" | grep -qEi 'git\s+push\s+.*(--delete|:[A-Za-z0-9._/-]+\s*$)'; then
  block "Deleting a remote branch via push" "git-push-delete"
fi

# Reset --hard (destroys uncommitted work AND can drop local commits)
if echo "$COMMAND" | grep -qEi 'git\s+reset\s+--hard'; then
  block "git reset --hard drops uncommitted work and can lose local commits" "git-reset-hard"
fi

# Branch force-delete
if echo "$COMMAND" | grep -qEi 'git\s+branch\s+(-D|--delete\s+--force|-[a-zA-Z]*D[a-zA-Z]*)\s'; then
  block "Force-deleting a branch (git branch -D)" "git-branch-force-delete"
fi

# Clean (removes untracked / ignored files)
if echo "$COMMAND" | grep -qEi 'git\s+clean\s+-[a-z]*f'; then
  block "git clean -f removes untracked files permanently" "git-clean"
fi

# Interactive rebase. Can rewrite history arbitrarily.
if echo "$COMMAND" | grep -qEi 'git\s+rebase\s+(-i|--interactive)'; then
  block "Interactive rebase can rewrite commits. Confirm the branch isn't shared." "git-rebase-i"
fi

# Rebase --onto (advanced, frequently destructive)
if echo "$COMMAND" | grep -qEi 'git\s+rebase\s+.*--onto'; then
  block "git rebase --onto rewrites history in non-obvious ways" "git-rebase-onto"
fi

# Amend rewrites the last commit. Dangerous if already pushed.
if echo "$COMMAND" | grep -qEi 'git\s+commit\s+.*--amend'; then
  block "git commit --amend rewrites the last commit. If already pushed, this requires force-push to remote." "git-amend"
fi

# Checkout with -- or restore that wipes working copy
if echo "$COMMAND" | grep -qEi 'git\s+checkout\s+--\s+\.(\s|$)'; then
  block "git checkout -- . wipes all uncommitted changes" "git-checkout-wipe"
fi
if echo "$COMMAND" | grep -qEi 'git\s+(restore|checkout)\s+\.(\s|$)'; then
  block "git restore . / git checkout . wipes all uncommitted changes" "git-restore-wipe"
fi

# Stash drop / clear
if echo "$COMMAND" | grep -qEi 'git\s+stash\s+(drop|clear)'; then
  block "git stash drop/clear permanently discards stashed work" "git-stash-drop"
fi

# Worktree remove --force
if echo "$COMMAND" | grep -qEi 'git\s+worktree\s+remove\s+.*(-f|--force)'; then
  block "git worktree remove --force discards local changes in the worktree" "git-worktree-force"
fi

# --- Sudo ---
if echo "$COMMAND" | grep -qE '^\s*sudo\s'; then
  block "sudo command detected" "sudo"
fi

# === CATEGORY 3: PROTECTED FILES (approval required to edit) ===
if [ -n "$FILE_PATH" ]; then
  if echo "$FILE_PATH" | grep -qEi '(\.env|\.env\.|id_rsa|id_ed25519|\.ssh/|\.gnupg/)'; then
    block "Edit to secrets/credentials file ($FILE_PATH)" "secrets"
  fi
fi

# All clear
emit_decision "allow"
exit 0
```

---


## Template: scripts/active-recall.sh

`Mode A of the {{orchestrator_lower}}-memory skill. Reads inbound text on stdin, dispatches scripts/active-recall-entities.sh to extract URLs / project names / persons / file paths, caps at 2 entities (latency budget 95ms x 2 = 190ms median), and emits a <memory> block with top-3 hits per entity from sqlite-vec via memory-search.sh. Two-layer cache at data/runtime/active-recall-cache.tsv with 3600s TTL: input-level (sha1 of full input, fast path) and per-entity (covers partial overlap). Carveout: any dot-prefixed dir under memory/ is invisible to memory-search.sh, so persona content never surfaces here. See xantham-system-v31 Section E6 for the full pipeline.`

```bash
#!/usr/bin/env bash
# Active recall orchestrator.
#
# Stdin: inbound text ({{messaging}} message, {{orchestrator_name}} task, etc.)
# Stdout: <memory> block with top relevant memories per entity, OR empty if no
#         entities (skip-list match in active-recall-entities.sh).
#
# Pipeline:
#   1. Pipe stdin to active-recall-entities.sh -> entities (one per line)
#   2. Cap at 2 entities (latency budget: 95ms x 2 = 190ms median)
#   3. For each: cache lookup -> sqlite-vec on miss -> top hits
#   4. Format as <memory> block with per-entity sections
#
# Cache:
#   - File: data/runtime/active-recall-cache.tsv
#   - Two layers, same TSV:
#     a) input-level cache (entity field = "__INPUT__:<sha1>"). Fast path,
#        skips entity extraction entirely on a repeat input.
#     b) per-entity cache (entity field = the literal entity). Covers partial
#        overlap when two different inputs share an entity.
#   - Format: <epoch_seconds>\t<entity_or_input_key>\t<base64_encoded_payload>
#   - TTL: 3600s (1 hour). Stale entries checked on-read, not pruned proactively.
#   - awk-based lookup for speed (no new dependencies).
#
# The dot-dir carveout invariant holds because memory-search uses sqlite-vec which
# inherits the dot-prune from embed-memories.py walk_markdown. Cached payloads
# come from sqlite-vec, so the carveout transitively holds.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

CACHE_FILE="data/runtime/active-recall-cache.tsv"
TTL=3600
NOW=$(date +%s)

INPUT=$(cat)

mkdir -p data/runtime
touch "$CACHE_FILE"

# Layer 1: input-level cache. Fast path. Skips entity extraction.
INPUT_HASH=$(printf '%s' "$INPUT" | shasum | awk '{print $1}')
INPUT_KEY="__INPUT__:${INPUT_HASH}"
cached_full=$(awk -F'\t' -v e="$INPUT_KEY" -v now="$NOW" -v ttl="$TTL" '
  $2 == e && (now - $1) < ttl { last = $3 }
  END { if (last != "") print last }
' "$CACHE_FILE")

if [ -n "$cached_full" ]; then
  echo "$cached_full" | base64 -d
  exit 0
fi

# Layer 2: cold path. Extract entities, search per-entity (with per-entity cache).
ENTITIES=$(echo "$INPUT" | bash scripts/active-recall-entities.sh | head -2)
[ -z "$ENTITIES" ] && exit 0

OUTPUT=""
OUTPUT+="<memory>"$'\n'
while IFS= read -r entity; do
  [ -n "$entity" ] || continue

  # Per-entity cache lookup: most-recent fresh entry wins.
  cached_b64=$(awk -F'\t' -v e="$entity" -v now="$NOW" -v ttl="$TTL" '
    $2 == e && (now - $1) < ttl { last = $3 }
    END { if (last != "") print last }
  ' "$CACHE_FILE")

  OUTPUT+="## Entity: $entity"$'\n'
  if [ -n "$cached_b64" ]; then
    payload=$(echo "$cached_b64" | base64 -d)
  else
    payload=$(bash scripts/memory-search.sh "$entity" 2>/dev/null | head -10 || true)
    payload_b64=$(printf '%s' "$payload" | base64 | tr -d '\n')
    printf '%s\t%s\t%s\n' "$NOW" "$entity" "$payload_b64" >> "$CACHE_FILE"
  fi
  OUTPUT+="$payload"$'\n'
  OUTPUT+=$'\n'
done <<< "$ENTITIES"
OUTPUT+="</memory>"

# Emit + record at input-level cache for fast path next time.
printf '%s\n' "$OUTPUT"
output_b64=$(printf '%s\n' "$OUTPUT" | base64 | tr -d '\n')
printf '%s\t%s\t%s\n' "$NOW" "$INPUT_KEY" "$output_b64" >> "$CACHE_FILE"
```

---


## Template: scripts/active-recall-entities.sh

`Entity extractor used by active-recall.sh. Reads inbound text on stdin, emits one entity per line for memory-search dispatch. Four entity types: (1) URL host (any http/https link), (2) project name (matched against docs/projects.md folder mapping including hyphenated prefix aliases), (3) named person (matched against the people block in {{user_name_lower}}'s profile), (4) file path (matches "like/this.ext" pattern). Skip-list of greetings + commands + one-word confirmations produces no entities. Output is deduped + sorted; caller caps to top-2.`

```bash
#!/usr/bin/env bash
# Read inbound text on stdin; emit entities one per line for memory-search dispatch.
# Entity types:
#   1. URL host (from any http/https link)
#   2. Project name (matched against docs/projects.md folder mapping, including
#      hyphenated prefix aliases. e.g. "wahb-worker" matches the folder
#      wahb-worker-minutes-cadence-repmapping)
#   3. Named person (matched against the people block in
#      memory/profile_{{user_name_lower}}.md)
#   4. File path (anything matching a `like/this.ext` pattern)
#
# Skip-list: greetings + commands + one-word confirmations produce no entities.
# This list MUST stay in sync with .claude/skills/{{orchestrator_lower}}-memory/SKILL.md.
#
# Output is deduped + line-per-entity + sorted. Caller caps to top-N.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

INPUT=$(cat)

# --- Skip-list ---------------------------------------------------------------
# Lowercase + trim whitespace for the skip check.
trim_lower=$(printf '%s' "$INPUT" | tr '[:upper:]' '[:lower:]' | awk '{$1=$1; print}')
case "$trim_lower" in
  hi|hey|gm|sup|yes|ok|go|sync|wrapup|healthcheck|help|team|projects|status|monitor|deploy|history|brain|notes)
    exit 0 ;;
esac

# --- Accumulator -------------------------------------------------------------
entities=$(mktemp)
trap 'rm -f "$entities"' EXIT

# --- 1. URL hosts + bare domains --------------------------------------------
# Schemed URLs: strip scheme + path/query/fragment, keep host only.
printf '%s\n' "$INPUT" \
  | grep -oE 'https?://[A-Za-z0-9.-]+(/[A-Za-z0-9._~:/?#@!$&'\''()*+,;=%-]*)?' 2>/dev/null \
  | sed -E 's|^https?://||; s|[/?#].*$||' \
  >> "$entities" || true

# Bare domains (no scheme): match <label>(.<label>)+ ending in a known TLD,
# preceded by start-of-string or a non-domain character. Common TLDs only,
# avoids matching "scripts/dream.sh" which is caught by the file-path branch.
printf '%s\n' "$INPUT" \
  | grep -oiE '(^|[^A-Za-z0-9.@/])([A-Za-z0-9-]+\.)+(com|co|co\.uk|uk|io|dev|ai|app|org|net|me|sh|xyz|tech|so)\b' 2>/dev/null \
  | sed -E 's|^[^A-Za-z0-9]+||' \
  | tr '[:upper:]' '[:lower:]' \
  >> "$entities" || true

# --- 2. File paths -----------------------------------------------------------
# A path is a token containing "/" with a 1-5 char extension. Strip URLs from
# the input first so they cannot bleed in as `//host.com` candidates.
input_no_urls=$(printf '%s' "$INPUT" \
  | sed -E 's|https?://[A-Za-z0-9./_~:?#@!$&'\''()*+,;=%-]+| |g')
printf '%s\n' "$input_no_urls" \
  | grep -oE '[A-Za-z0-9_./-]*/[A-Za-z0-9_.-]+\.[A-Za-z]{1,5}' 2>/dev/null \
  >> "$entities" || true

# --- 3. Project names --------------------------------------------------------
# Build a list of candidate aliases from docs/projects.md `Folder:` lines.
# Each folder yields:
#   - the folder basename (last `/` segment)
#   - hyphenated prefixes of that basename. e.g.
#     wahb-worker-minutes-cadence-repmapping -> wahb-worker, wahb-worker-minutes,
#     wahb-worker-minutes-cadence, wahb-worker-minutes-cadence-repmapping
# Match each alias case-insensitively at word boundaries against the input;
# emit the LONGEST matching alias for each folder so memory-search gets the
# most-specific token.
if [ -f docs/projects.md ]; then
  while IFS= read -r folder; do
    [ -n "$folder" ] || continue
    # Skip placeholder rows like "(Shopify-hosted, no local repo)"
    case "$folder" in
      "("*) continue ;;
    esac
    # basename = last path segment
    base=${folder##*/}
    [ -n "$base" ] || continue

    # Generate alias list: full base + each progressive hyphen-prefix.
    aliases=("$base")
    if [[ "$base" == *-* ]]; then
      IFS='-' read -ra parts <<<"$base"
      acc=""
      for p in "${parts[@]}"; do
        if [ -z "$acc" ]; then acc="$p"; else acc="$acc-$p"; fi
        # Skip 1-segment alias if it is too short / generic to be useful.
        if [ "$acc" != "$base" ] && [ ${#acc} -ge 4 ]; then
          aliases+=("$acc")
        fi
      done
    fi

    # Find the longest alias present in the input.
    best=""
    for alias in "${aliases[@]}"; do
      # Word-boundary, case-insensitive. Escape regex metacharacters in alias.
      # Use a Python-style approach via awk to avoid macOS sed bracket-class quirks.
      esc=$(printf '%s' "$alias" | awk '{
        out=""
        for (i=1; i<=length($0); i++) {
          c = substr($0, i, 1)
          if (index(".*^$/\\+?(){}[]|", c) > 0) { out = out "\\" c } else { out = out c }
        }
        print out
      }')
      if printf '%s' "$INPUT" | grep -qiE "(^|[^A-Za-z0-9])$esc([^A-Za-z0-9]|$)"; then
        if [ ${#alias} -gt ${#best} ]; then
          best="$alias"
        fi
      fi
    done
    [ -n "$best" ] && echo "$best" >> "$entities"
  done < <(grep -E "^Folder:" docs/projects.md | sed -E 's|^Folder:[[:space:]]*||')
fi

# --- 4. Named persons --------------------------------------------------------
# Customize the person list below to match the people in your Profile bucket.
# If profile_{{user_name_lower}}.md gains a structured `## People` section, swap
# this hardcoded list for parsing that section.
if [ -f memory/profile_{{user_name_lower}}.md ]; then
  for name in {{person_1}} {{person_2}} {{person_3}} {{person_4}} {{person_5}}; do
    [ -z "$name" ] && continue
    if printf '%s' "$INPUT" | grep -qE "(^|[^A-Za-z0-9])$name([^A-Za-z0-9]|$)"; then
      echo "$name" >> "$entities"
    fi
  done
fi

# --- Output: dedup + sort ----------------------------------------------------
sort -u "$entities" | grep -v '^$' || true
```

Note: the wizard substitutes `{{person_1}}` through `{{person_5}}` from the Profile bucket if it has a structured people block. If the profile has fewer than 5 named persons, leave the unused tokens empty and the loop will skip them. If the profile has more, extend the list manually after install.

---


## Template: scripts/dream.sh

`Mode B orchestrator of the {{orchestrator_lower}}-memory skill. Two run modes. Default scan mode walks memory/ and agent-memory/, flags near-duplicate pairs (word-overlap threshold), stale files (last-modified cutoff), and completion markers; writes a review-first proposal to data/dream-proposals/<date>.md. Full-cycle mode chains phases 1-4 (orient, gather, consolidate, prune+index) with cost cap enforcement between phase 3 and phase 4. Default cost cap $1.00; override via DREAM_COST_CAP_USD env var or --cost-cap flag. Default mode for full-cycle is dry-run; use --commit for the apply path. Phase 3 only hits the LLM when ANTHROPIC_API_KEY is present and apply mode is requested.`

```bash
#!/usr/bin/env bash
# {{orchestrator_name}} memory dream. Consolidation scan across markdown memory.
#
# Walks memory/*.md + agent-memory/**/*.md (skipping MEMORY.md index files),
# flags near-duplicate pairs + stale files, and writes a review-first proposal
# to data/dream-proposals/YYYYMMDD.md. Never auto-deletes; user reviews via
# "dream approve" or "dream reject" in a live session.
#
# Usage: bash scripts/dream.sh [mode] [opts]
#
# Modes:
#   (default)          Near-duplicate + stale + completion-marker scanner.
#                      Writes review-first proposal to data/dream-proposals/.
#   --full-cycle       Run phases 1-4 in sequence (orient -> gather ->
#                      consolidate -> prune+index). Writes per-phase artifacts
#                      to data/dream-runs/<turn-id>/. Enforces cost cap.
#
# Scan opts:
#   --dry-run          print candidates to stdout, do not write proposal file
#   --threshold N      similarity % to flag near-duplicates (default 55)
#   --stale-days N     file unchanged for N days flags as stale (default 90)
#
# Full-cycle opts:
#   --dry-run          (default) skip LLM API call, no commit, no push
#   --commit           run real LLM proposal + commit MEMORY.md regen + push
#   --turn-id ID       override run id (default: dream-YYYYMMDDTHHMMSS)
#   --cost-cap USD     abort if phase 3 reports cost > cap (default $1.00)
#
# Cost cap (full-cycle only): default $1/run. Phase 3 reports its own cost via
# `## Cost` section; orchestrator parses + aborts BEFORE phase 4 if exceeded.
# Override globally via DREAM_COST_CAP_USD env var.

set -euo pipefail

ORCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TODAY="$(date '+%Y-%m-%d')"
TODAY_COMPACT="$(date '+%Y%m%d')"

# Stale cutoff. macOS + GNU both accept this form via fallback.
STALE_DAYS=90
THRESHOLD=55
DRY_RUN=0
COMMIT=0
MODE="scan"
TURN_ID=""
COST_CAP_USD="${DREAM_COST_CAP_USD:-1.00}"

while [ $# -gt 0 ]; do
  case "$1" in
    --full-cycle) MODE="full-cycle"; shift ;;
    --scan) MODE="scan"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --commit) COMMIT=1; shift ;;
    --threshold) THRESHOLD="$2"; shift 2 ;;
    --stale-days) STALE_DAYS="$2"; shift 2 ;;
    --turn-id) TURN_ID="$2"; shift 2 ;;
    --cost-cap) COST_CAP_USD="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# Full-cycle defaults to dry-run unless --commit is explicit.
# Scan mode preserves existing semantic: --dry-run flag toggles DRY_RUN.
if [ "$MODE" = "full-cycle" ]; then
  if [ "$COMMIT" -eq 1 ]; then
    DRY_RUN=0
  else
    DRY_RUN=1
  fi
fi

# ===================================================================
# Full-cycle mode: orient -> gather -> consolidate -> prune+index
# ===================================================================
if [ "$MODE" = "full-cycle" ]; then
  TURN_ID="${TURN_ID:-dream-$(date +%Y%m%dT%H%M%S)}"
  RUN_DIR="$ORCH_DIR/data/dream-runs/$TURN_ID"
  mkdir -p "$RUN_DIR"

  if [ "$DRY_RUN" -eq 1 ]; then
    DRY_FLAG="--dry-run"
    MODE_LABEL="dry-run"
  else
    DRY_FLAG="--commit"
    MODE_LABEL="commit"
  fi

  echo "Dream cycle: $TURN_ID ($MODE_LABEL, cost cap \$$COST_CAP_USD)"
  echo "  Run dir: $RUN_DIR"
  echo

  # --- Phase 1: orient ---------------------------------------------
  echo "  Phase 1: orient..."
  if ! bash "$ORCH_DIR/scripts/dream/phase1-orient.sh" > "$RUN_DIR/orient.json" 2>"$RUN_DIR/phase1.stderr"; then
    echo "  ABORT: phase 1 failed (see $RUN_DIR/phase1.stderr)" >&2
    cat "$RUN_DIR/phase1.stderr" >&2
    exit 3
  fi

  # --- Phase 2: gather ---------------------------------------------
  echo "  Phase 2: gather..."
  if ! bash "$ORCH_DIR/scripts/dream/phase2-gather.sh" \
        < "$RUN_DIR/orient.json" \
        > "$RUN_DIR/signal.md" 2>"$RUN_DIR/phase2.stderr"; then
    echo "  ABORT: phase 2 failed (see $RUN_DIR/phase2.stderr)" >&2
    cat "$RUN_DIR/phase2.stderr" >&2
    exit 3
  fi

  # --- Phase 3: consolidate ----------------------------------------
  echo "  Phase 3: consolidate..."
  # Phase 3 mode: --apply only if we plan to commit AND a key is present.
  # Otherwise stay in --dry-run (stub) for cost safety.
  PHASE3_MODE_FLAG="--dry-run"
  if [ "$DRY_RUN" -eq 0 ] && [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    PHASE3_MODE_FLAG="--apply"
  fi
  if ! PHASE1_JSON="$(cat "$RUN_DIR/orient.json")" \
       PHASE2_MD="$(cat "$RUN_DIR/signal.md")" \
       bash "$ORCH_DIR/scripts/dream/phase3-consolidate.sh" \
            $PHASE3_MODE_FLAG --cost-cap "$COST_CAP_USD" \
            > "$RUN_DIR/proposal.md" 2>"$RUN_DIR/phase3.stderr"; then
    echo "  ABORT: phase 3 failed (see $RUN_DIR/phase3.stderr)" >&2
    cat "$RUN_DIR/phase3.stderr" >&2
    exit 3
  fi

  # --- Cost cap enforcement (parse phase 3 ## Cost section) --------
  # Phase 3 emits one of:
  #   "Estimated cost: $0.0000 USD ..."  (stub mode)
  #   "Actual cost: $0.0123 USD ..."     (real LLM call)
  COST="$(grep -oE '(Estimated|Actual) cost: \$[0-9]+\.[0-9]+' "$RUN_DIR/proposal.md" \
            | head -1 \
            | grep -oE '[0-9]+\.[0-9]+' || true)"
  COST="${COST:-0}"

  if python3 -c "import sys; sys.exit(0 if float('$COST') <= float('$COST_CAP_USD') else 1)"; then
    echo "  Phase 3 cost: \$$COST (under cap \$$COST_CAP_USD)"
  else
    echo "  ABORT: phase 3 cost \$$COST exceeds cap \$$COST_CAP_USD. Phase 4 not run." >&2
    exit 4
  fi

  # --- Phase 4: prune + index --------------------------------------
  echo "  Phase 4: prune+index..."
  if ! PHASE3_MD="$(cat "$RUN_DIR/proposal.md")" \
       TURN_ID="$TURN_ID" \
       bash "$ORCH_DIR/scripts/dream/phase4-prune.sh" $DRY_FLAG \
         > "$RUN_DIR/phase4.stdout" 2>"$RUN_DIR/phase4.stderr"; then
    echo "  ABORT: phase 4 failed (see $RUN_DIR/phase4.stderr)" >&2
    cat "$RUN_DIR/phase4.stderr" >&2
    exit 3
  fi
  cat "$RUN_DIR/phase4.stdout"

  echo
  echo "Dream cycle complete: $TURN_ID"
  echo "  Run dir: $RUN_DIR"
  echo "  Cost: \$$COST (cap \$$COST_CAP_USD)"
  echo "  Mode: $MODE_LABEL"
  exit 0
fi

# ===================================================================
# Default scan mode (existing behavior. Near-dupe + stale + markers)
# ===================================================================
PROPOSAL_DIR="$ORCH_DIR/data/dream-proposals"
mkdir -p "$PROPOSAL_DIR"
PROPOSAL_FILE="$PROPOSAL_DIR/${TODAY_COMPACT}.md"

# --- Collect files --------------------------------------
# Private dot-dir carveout: skip any dot-prefixed dir (memory/.<name>/)
# so persona-scoped content never participates in dream consolidation.
declare -a FILES
while IFS= read -r f; do
  FILES+=("$f")
done < <(find "$ORCH_DIR/memory" "$ORCH_DIR/agent-memory" \
  -type d -name '.*' -prune -o \
  -type f -name '*.md' \
  ! -name 'MEMORY.md' \
  -print 2>/dev/null | sort)

TOTAL_FILES="${#FILES[@]}"

# Build agent-dir counts
declare -a AGENT_DIRS
while IFS= read -r d; do
  [ -n "$d" ] && AGENT_DIRS+=("$d")
done < <(find "$ORCH_DIR/agent-memory" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

# --- Helper: body words (strip frontmatter, lowercase, unique, sorted) ---
body_words() {
  local f="$1"
  awk '/^---$/{c++; next} c>=2 || c==0 {print}' "$f" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9' '\n' \
    | awk 'length($0) >= 4' \
    | sort -u
}

# --- Similarity: word overlap % of file A ---
similarity() {
  local a="$1"
  local b="$2"
  local total_a
  total_a="$(wc -l < "$a" | tr -d ' ')"
  [ "$total_a" -eq 0 ] && { echo 0; return; }
  local common
  common="$(comm -12 "$a" "$b" 2>/dev/null | wc -l | tr -d ' ')"
  echo $(( common * 100 / total_a ))
}

# --- Determine bucket from file path ---
bucket_of() {
  local f="$1"
  local rel="${f#$ORCH_DIR/}"
  case "$rel" in
    memory/feedback_*) echo "feedback" ;;
    memory/project_*)  echo "project"  ;;
    memory/user_*)     echo "user"     ;;
    memory/note_*)     echo "note"     ;;
    memory/reference_*) echo "reference" ;;
    agent-memory/*)    echo "agent-memory" ;;
    memory/*)          echo "other"    ;;
    *)                 echo "other"    ;;
  esac
}

agent_of() {
  local f="$1"
  local rel="${f#$ORCH_DIR/}"
  case "$rel" in
    agent-memory/*) echo "$(echo "$rel" | awk -F/ '{print $2}')" ;;
    *) echo "{{orchestrator_lower}}" ;;
  esac
}

# --- Pre-compute word files ---
TMPDIR_WORK="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_WORK"' EXIT

for f in "${FILES[@]}"; do
  slug="$(echo "$f" | md5 -q 2>/dev/null || echo "$f" | md5sum | awk '{print $1}')"
  body_words "$f" > "$TMPDIR_WORK/$slug.words"
done

# --- Phase 1: Orient ----------------------------------
OUT="$(mktemp)"
{
  echo "MEMORY DREAM. $TODAY"
  echo ""
  echo "Scanned: $TOTAL_FILES markdown files ($(ls "$ORCH_DIR/memory"/*.md 2>/dev/null | grep -v MEMORY.md | wc -l | tr -d ' ') {{orchestrator_lower}} + $(( TOTAL_FILES - $(ls "$ORCH_DIR/memory"/*.md 2>/dev/null | grep -v MEMORY.md | wc -l | tr -d ' ') )) agent)"
  echo ""
  echo "Per-agent file counts:"
  for d in "${AGENT_DIRS[@]}"; do
    name="$(basename "$d")"
    cnt="$(find "$d" -maxdepth 1 -type f -name '*.md' ! -name 'MEMORY.md' 2>/dev/null | wc -l | tr -d ' ')"
    flag=""
    [ "$cnt" -ge 200 ] && flag="  <- NEEDS PRUNING (200+)"
    [ "$cnt" -eq 0 ] && flag="  <- UNDERUSED (0 files)"
    printf "  %-12s %4d%s\n" "$name" "$cnt" "$flag"
  done
  echo ""

  # --- Phase 3: Near-duplicate scan ----------------------
  echo "PROPOSED MERGES (near-duplicate pairs, threshold ${THRESHOLD}% word overlap)"
  echo ""
  MERGE_COUNT=0
  for (( i=0; i<TOTAL_FILES-1; i++ )); do
    for (( j=i+1; j<TOTAL_FILES; j++ )); do
      fa="${FILES[$i]}"
      fb="${FILES[$j]}"
      # Only compare within the same bucket + same agent. Cross-bucket matches are usually noise.
      bucket_a="$(bucket_of "$fa")"
      bucket_b="$(bucket_of "$fb")"
      [ "$bucket_a" != "$bucket_b" ] && continue
      agent_a="$(agent_of "$fa")"
      agent_b="$(agent_of "$fb")"
      [ "$agent_a" != "$agent_b" ] && continue
      slug_a="$(echo "$fa" | md5 -q 2>/dev/null || echo "$fa" | md5sum | awk '{print $1}')"
      slug_b="$(echo "$fb" | md5 -q 2>/dev/null || echo "$fb" | md5sum | awk '{print $1}')"
      sim="$(similarity "$TMPDIR_WORK/$slug_a.words" "$TMPDIR_WORK/$slug_b.words")"
      if [ "$sim" -ge "$THRESHOLD" ]; then
        MERGE_COUNT=$((MERGE_COUNT + 1))
        rel_a="${fa#$ORCH_DIR/}"
        rel_b="${fb#$ORCH_DIR/}"
        echo "- $rel_a"
        echo "  + $rel_b"
        echo "  ($bucket_a / $agent_a, ${sim}% word overlap)"
        echo ""
      fi
    done
  done
  if [ "$MERGE_COUNT" -eq 0 ]; then
    echo "  (no pairs above threshold)"
    echo ""
  fi

  # --- Phase 3b: Stale scan ------------------------------
  echo "PROPOSED STALE (files unchanged for $STALE_DAYS+ days)"
  echo ""
  STALE_COUNT=0
  STALE_CUTOFF=$(( $(date +%s) - STALE_DAYS*86400 ))
  for f in "${FILES[@]}"; do
    mtime="$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)"
    [ -z "$mtime" ] && continue
    if [ "$mtime" -lt "$STALE_CUTOFF" ]; then
      STALE_COUNT=$((STALE_COUNT + 1))
      rel="${f#$ORCH_DIR/}"
      days_old=$(( ($(date +%s) - mtime) / 86400 ))
      echo "- $rel  (${days_old} days since last change)"
    fi
  done
  if [ "$STALE_COUNT" -eq 0 ]; then
    echo "  (nothing unchanged for $STALE_DAYS+ days)"
    echo ""
  fi
  echo ""

  # --- Phase 3c: Completed-task markers ------------------
  echo "COMPLETED-TASK MARKERS (grep hints)"
  echo ""
  MARKER_COUNT=0
  for f in "${FILES[@]}"; do
    # Files whose body says "completed" / "no further action" / "shipped" / "done" early on.
    if head -20 "$f" | grep -qiE '(completed|no further action needed|shipped|done, delete)'; then
      MARKER_COUNT=$((MARKER_COUNT + 1))
      rel="${f#$ORCH_DIR/}"
      hint="$(head -20 "$f" | grep -iE '(completed|no further action needed|shipped|done, delete)' | head -1 | sed 's/^ *//' | head -c 100)"
      echo "- $rel"
      echo "  hint: $hint"
      echo ""
    fi
  done
  if [ "$MARKER_COUNT" -eq 0 ]; then
    echo "  (no obvious completion markers found)"
    echo ""
  fi
  echo ""

  # --- Phase 4: Summary ----------------------------------
  echo "---"
  echo "Totals: $MERGE_COUNT merge candidates + $STALE_COUNT stale + $MARKER_COUNT completion-markers."
  echo ""
  echo "All candidates are REVIEW-FIRST. Nothing will be touched without explicit"
  echo "\`dream approve\` (applies this proposal) or \`dream reject\` (discards it)."
  echo ""
  echo "Generated by scripts/dream.sh at $(date -u +%FT%TZ)."
} > "$OUT"

if [ "$DRY_RUN" -eq 1 ]; then
  cat "$OUT"
else
  mv "$OUT" "$PROPOSAL_FILE"
  echo "Wrote proposal: $PROPOSAL_FILE"
  echo ""
  echo "Summary:"
  tail -5 "$PROPOSAL_FILE"
fi
```

---


## Template: scripts/dream/phase1-orient.sh

`Phase 1 of dream consolidation. Reads memory/ tree state and emits a compact JSON state map for downstream phases. Counts memory files per semantic type (feedback / project / reference / note / user), episodic, agent-memory, sqlite-vec chunks, profile last_updated, recent reflections list, and corrections-promoted count. Output is one line of JSON via python3 for safe escaping. EXCLUDES dot-prefixed dirs under memory/ for the dot-dir carveout. Designed to pipe into phase2-gather.sh.`

```bash
#!/usr/bin/env bash
# Phase 1 of dream consolidation: orient.
#
# Reads current state of memory layer + emits JSON state map for downstream
# phases (gather, consolidate, prune+index).
#
# Output: JSON map on stdout. Designed to be piped to phase2-gather.sh or
# stored at data/dream-runs/<turn-id>/orient.json.
#
# Counts EXCLUDE memory/.<name>/ (dot-dir carveout). Uses find -prune dot-pattern.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Total memory files (recursive, dot-pruned per dot-dir carveout)
MEM_FILES=$(find memory -type d -name '.*' -prune -o -type f -name "*.md" -print 2>/dev/null | wc -l | tr -d ' ')

# Per-type counts. Semantic types live under memory/semantic/<type>/
count_dir() {
  local path="$1"
  if [ -d "$path" ]; then
    find "$path" -type d -name '.*' -prune -o -type f -name "*.md" -print 2>/dev/null | wc -l | tr -d ' '
  else
    echo 0
  fi
}

FEEDBACK=$(count_dir memory/semantic/feedback)
PROJECT=$(count_dir memory/semantic/project)
REFERENCE=$(count_dir memory/semantic/reference)
NOTE=$(count_dir memory/semantic/note)
USER=$(count_dir memory/semantic/user)
EPISODIC=$(count_dir memory/episodic)
AGENT=$(count_dir memory/agent-memory)

# Profile last_updated
PROFILE_UPD=$(grep "^last_updated:" memory/profile_{{user_name_lower}}.md 2>/dev/null | head -1 | awk '{print $2}')
PROFILE_UPD=${PROFILE_UPD:-unknown}

# Corrections promoted count (lines in jsonl)
if [ -f data/corrections-promoted.jsonl ]; then
  PROMOTED=$(wc -l < data/corrections-promoted.jsonl 2>/dev/null | tr -d ' ')
else
  PROMOTED=0
fi
PROMOTED=${PROMOTED:-0}

# Recent reflections (last 5 by mtime, basenames, comma-joined)
RECENT_REF=""
if [ -d data/reflections ]; then
  RECENT_REF=$(ls -t data/reflections/*.md 2>/dev/null | head -5 | xargs -I {} basename {} 2>/dev/null | tr '\n' ',' | sed 's/,$//')
fi

# sqlite-vec chunk count
CHUNKS=0
if [ -f data/{{orchestrator_lower}}-vec.db ]; then
  CHUNKS=$(sqlite3 data/{{orchestrator_lower}}-vec.db "SELECT COUNT(*) FROM chunks;" 2>/dev/null | tr -d ' ' || echo 0)
fi
CHUNKS=${CHUNKS:-0}

# Today's date for the run snapshot
TODAY=$(date '+%Y-%m-%d')

# Emit compact JSON (test greps for "key":"value" with no spacing)
python3 - "$TODAY" "$MEM_FILES" "$FEEDBACK" "$PROJECT" "$REFERENCE" "$NOTE" "$USER" "$EPISODIC" "$AGENT" "$PROFILE_UPD" "$PROMOTED" "$RECENT_REF" "$CHUNKS" <<'PYEOF'
import json
import sys

(_, today, mem_files, feedback, project, reference, note, user, episodic, agent,
 profile_upd, promoted, recent_ref, chunks) = sys.argv

out = {
    "phase": "orient",
    "run_date": today,
    "memory_files": int(mem_files),
    "memory_files_by_type": {
        "feedback": int(feedback),
        "project": int(project),
        "reference": int(reference),
        "note": int(note),
        "user": int(user),
        "episodic": int(episodic),
        "agent": int(agent),
    },
    "profile_last_updated": profile_upd,
    "corrections_promoted": int(promoted),
    "recent_reflections": recent_ref,
    "sqlite_vec_chunks": int(chunks),
}
print(json.dumps(out, separators=(",", ":")))
PYEOF
```

---


## Template: scripts/dream/phase2-gather.sh

`Phase 2 of dream consolidation. Reads phase 1 JSON from stdin, scans recent telegram (50 messages), corrections (data/corrections.jsonl, last 7 days), reflections (last 5 by mtime), audit highlights, and surfaces candidate patterns: repeated correction categories at >=3 hits, commit clusters at 5+ commits sharing a prefix, profile drift signal. Pure bash + awk, no LLM call, $0 cost. Emits structured markdown on stdout for phase 3 consumption.`

```bash
#!/usr/bin/env bash
# Phase 2 of dream consolidation: gather signal.
#
# Reads phase 1 JSON from stdin (state map).
# Scans recent telegram, corrections, reflections, audit for high-value patterns.
# Emits structured markdown report on stdout for phase 3 consumption.
#
# No LLM calls. Pure scan + summarize. Cost: $0.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Read phase 1 input (may be empty if invoked standalone)
PHASE1_INPUT=$(cat 2>/dev/null || echo '{}')

DATE=$(date '+%Y-%m-%d')
WINDOW_DAYS=7
CUTOFF=$(date -v-${WINDOW_DAYS}d '+%Y-%m-%d' 2>/dev/null || date --date="${WINDOW_DAYS} days ago" '+%Y-%m-%d')

cat <<HEADER
# Dream Phase 2: Gather Signal. $DATE

Scan window: last $WINDOW_DAYS days (from $CUTOFF). Collected from telegram tail, corrections, reflections, audit.

HEADER

# === Telegram tail (last 50 messages) ===
# Note: timestamp embedded in heading so a same-line awk range
# (start+end both match `^## `) still surfaces a `[YYYY-MM-DD]` marker.
TG_HEADER_TS="[$(date '+%Y-%m-%dT%H:%M:%S')]"
echo "## Telegram tail (window starts $TG_HEADER_TS)"
echo
echo '```'
if [ -x scripts/recent-telegram.sh ]; then
  bash scripts/recent-telegram.sh 50 2>/dev/null | tail -50 || echo "(no telegram traffic)"
else
  echo "(scripts/recent-telegram.sh missing)"
fi
echo '```'
echo

# === Recent corrections (categorize, count) ===
echo "## Recent corrections"
echo
if [ -f data/corrections.jsonl ]; then
  echo "Source: data/corrections.jsonl. Window: $CUTOFF onwards. Counts by category:"
  echo
  awk -F'"' -v cutoff="$CUTOFF" '
    /"ts":/ {
      ts = ""; cat = ""
      for (i = 1; i <= NF; i++) {
        if ($i == "ts") { ts = $(i+2) }
        if ($i == "category") { cat = $(i+2) }
      }
      if (substr(ts, 1, 10) >= cutoff && cat != "") print cat
    }
  ' data/corrections.jsonl 2>/dev/null \
    | sort | uniq -c | sort -rn | head -20 \
    | sed 's/^/  /'
  echo
  count_lines=$(awk -F'"' -v cutoff="$CUTOFF" '
    /"ts":/ {
      for (i = 1; i <= NF; i++) if ($i == "ts") { ts = $(i+2); break }
      if (substr(ts, 1, 10) >= cutoff) print
    }
  ' data/corrections.jsonl 2>/dev/null | wc -l | tr -d ' ')
  echo "Total corrections in window: $count_lines"
else
  echo "(no data/corrections.jsonl)"
fi
echo

# === Recent reflections (last 5 by mtime, summary) ===
echo "## Recent reflections"
echo
if ls data/reflections/*.md >/dev/null 2>&1; then
  ls -t data/reflections/*.md 2>/dev/null | head -5 | while IFS= read -r ref; do
    echo "### $(basename "$ref")"
    echo
    head -30 "$ref" 2>/dev/null
    echo
  done
else
  echo "(no reflections found in data/reflections/)"
fi

# === Audit highlights ===
echo "## Audit highlights"
echo
if [ -d data/audit ]; then
  latest_audit=$(ls -t data/audit/*.jsonl 2>/dev/null | head -1)
  if [ -n "$latest_audit" ]; then
    echo "Source: $(basename "$latest_audit"). Last 20 events:"
    echo '```'
    tail -20 "$latest_audit" 2>/dev/null
    echo '```'
  elif [ -f data/audit/audit.log ]; then
    echo "Source: data/audit/audit.log. Last 20 events:"
    echo '```'
    tail -20 data/audit/audit.log 2>/dev/null
    echo '```'
  else
    echo "(audit dir exists but no .jsonl/.log files)"
  fi
else
  echo "(no data/audit/ dir)"
fi
echo

# === Candidate patterns ===
echo "## Candidate patterns"
echo
echo "Heuristic surface. Phase 3 will distill these via LLM."
echo

# Repeated correction categories >= 3
if [ -f data/corrections.jsonl ]; then
  echo "### Repeated correction categories (>=3 hits in window)"
  hits=$(awk -F'"' -v cutoff="$CUTOFF" '
    /"ts":/ {
      ts = ""; cat = ""
      for (i = 1; i <= NF; i++) {
        if ($i == "ts") { ts = $(i+2) }
        if ($i == "category") { cat = $(i+2) }
      }
      if (substr(ts, 1, 10) >= cutoff && cat != "") print cat
    }
  ' data/corrections.jsonl 2>/dev/null \
    | sort | uniq -c \
    | awk '$1 >= 3 { print "- "$2": "$1" hits" }' \
    | sort -rn -k3)
  if [ -n "$hits" ]; then
    echo "$hits"
  else
    echo "- (none)"
  fi
  echo
fi

# Recent commit clusters (topics that got 5+ commits in window)
echo "### Recent commit clusters (5+ commits referencing same prefix)"
clusters=$(git log --since="$WINDOW_DAYS days ago" --pretty=format:'%s' 2>/dev/null \
  | awk -F'[: ]' '{print $1}' \
  | sort | uniq -c \
  | awk '$1 >= 5 { print "- "$2": "$1" commits" }' \
  | sort -rn -k3)
if [ -n "$clusters" ]; then
  echo "$clusters"
else
  echo "- (none)"
fi
echo

# Profile drift signal (if profile was edited in window)
echo "### Profile drift"
if [ -f memory/profile_{{user_name_lower}}.md ]; then
  PROFILE_AGE=$(git log -1 --format='%ar' memory/profile_{{user_name_lower}}.md 2>/dev/null || echo "unknown")
  echo "- profile_{{user_name_lower}}.md last modified: $PROFILE_AGE"
else
  echo "- profile_{{user_name_lower}}.md not found"
fi
echo

echo "---"
echo "End Phase 2 signal."
```

---


## Template: scripts/dream/phase3-consolidate.sh

`Phase 3 of dream consolidation. Reads PHASE1_JSON + PHASE2_MD env vars set by the orchestrator, builds an LLM prompt with hard rules embedded (carveouts: never propose changes to memory/.<name>/ or memory/profile_<user>.md), POSTs to api.anthropic.com/v1/messages with claude-haiku-4-5-20251001 by default, parses the response, post-hoc filters any line referencing the carveouts (defense-in-depth), reports actual cost. Modes: --dry-run (default, stub output unless DREAM_DRYRUN_USE_API=1) and --apply (real LLM call but does NOT auto-write, output gated through a separate apply-dream-proposal.sh reviewer). Cost cap refuses any input over 100K tokens.`

```bash
#!/usr/bin/env bash
# Phase 3 of dream consolidation: consolidate.
#
# Reads PHASE1_JSON + PHASE2_MD from env. Runs LLM-driven consolidation
# analysis. Proposes merges, drops, date-normalizations, cross-cutting
# promotions. Emits markdown proposal on stdout.
#
# Modes:
#   --dry-run (default): emit proposal, NO file writes. Skips API call
#                        unless DREAM_DRYRUN_USE_API=1 + ANTHROPIC_API_KEY
#                        present (otherwise emits stub).
#   --apply: run LLM call + emit proposal, BUT does NOT auto-write. apply
#            is gated through a separate apply-dream-proposal.sh reviewer.
#
# Hard rules:
#   - NEVER touches memory/.<name>/ (dot-dir carveout)
#   - NEVER touches memory/profile_<user>.md (Profile bucket; managed by
#     update-profile.sh)
#   - Cost cap: refuse if estimated input > 100K tokens
#   - Model default: claude-haiku-4-5-20251001 (cheap)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

MODE="dry-run"
MODEL="claude-haiku-4-5-20251001"
COST_CAP_USD="1.00"

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --model) MODEL="$2"; shift 2 ;;
    --cost-cap) COST_CAP_USD="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# Read phase 1 + phase 2 from env (the orchestrator pipes them in)
PHASE1=${PHASE1_JSON:-}
PHASE2=${PHASE2_MD:-}

if [ -z "$PHASE1" ] || [ -z "$PHASE2" ]; then
  echo "ERROR: PHASE1_JSON and PHASE2_MD env vars required" >&2
  exit 1
fi

DATE=$(date '+%Y-%m-%d')

# Map mode -> display label
if [ "$MODE" = "dry-run" ]; then
  MODE_LABEL="DRY-RUN"
else
  MODE_LABEL="APPLY (proposal only, no auto-write)"
fi

cat <<HEADER
# Dream Phase 3: Consolidate. $DATE

## Mode

$MODE_LABEL (model: $MODEL, cost cap: \$$COST_CAP_USD)

HEADER

# Estimate input size (rough: 4 chars per token).
INPUT_CHARS=$(printf '%s\n%s' "$PHASE1" "$PHASE2" | wc -c | tr -d ' ')
EST_TOKENS=$((INPUT_CHARS / 4))

if [ "$EST_TOKENS" -gt 100000 ]; then
  cat <<COSTCAP
## Cost cap

Aborted: estimated input ${EST_TOKENS} tokens exceeds 100K cap.
Reduce phase 2 output size or raise the cap explicitly.

Estimated cost: skipped (too expensive)
COSTCAP
  exit 0
fi

# Decide whether to hit the API
USE_API=false
if [ "$MODE" = "apply" ] && [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  USE_API=true
elif [ "$MODE" = "dry-run" ] && [ -n "${ANTHROPIC_API_KEY:-}" ] && [ "${DREAM_DRYRUN_USE_API:-0}" = "1" ]; then
  USE_API=true
fi

if [ "$USE_API" = "true" ]; then
  # Build the prompt. Hard rules embedded so the model self-enforces the
  # carveouts even if a reviewer forgets to grep.
  PROMPT_HEAD='You are {{orchestrator_name}}'"'"'s dream consolidator. You see a state snapshot (Phase 1 JSON) and a signal report (Phase 2 markdown). Propose conservative consolidation changes for memory files.

Output ONLY markdown with these sections (each can be empty if nothing applies):
## Proposed merges
- One per line: "MERGE memory/path/A.md INTO memory/path/B.md - reason"
## Proposed drops
- One per line: "DROP memory/path/X.md - reason"
## Proposed date-normalizations
- One per line: "NORMALIZE-DATE memory/path/X.md (line N): '"'"'yesterday'"'"' -> '"'"'YYYY-MM-DD'"'"'"
## Proposed cross-cutting promotions
- One per line: "PROMOTE-TO-PROCEDURAL memory/path/X.md - reason"

Hard rules (the reviewer will reject any output that violates these):
- NEVER propose changes to memory/.{{private_dir_name}}/ (gitignored dot-dir carveout)
- NEVER propose changes to memory/profile_{{user_name_lower}}.md (Profile bucket, managed by update-profile.sh)
- Be conservative: only propose changes you are confident about
- Cite specific evidence from the signal report or memory files
- If you have nothing to propose in a section, leave it empty (no placeholder text)

Phase 1 JSON state:'

  PROMPT_BODY="$PROMPT_HEAD
$PHASE1

Phase 2 signal report:
$PHASE2"

  # Build request payload via python3 to handle JSON escaping safely.
  PAYLOAD=$(PROMPT="$PROMPT_BODY" MODEL="$MODEL" python3 -c '
import json, os, sys
p = os.environ.get("PROMPT", "")
m = os.environ.get("MODEL", "")
print(json.dumps({
    "model": m,
    "max_tokens": 4096,
    "messages": [{"role": "user", "content": p}]
}))
')

  RESPONSE=$(curl -sS https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$PAYLOAD" 2>/dev/null || echo '{"error":{"message":"api_call_failed"}}')

  CONTENT=$(echo "$RESPONSE" | python3 -c '
import json, sys
try:
    r = json.load(sys.stdin)
    if "error" in r:
        msg = r["error"].get("message", str(r["error"])) if isinstance(r["error"], dict) else str(r["error"])
        print(f"(API error: {msg})")
        sys.exit(0)
    parts = []
    for c in r.get("content", []):
        if c.get("type") == "text":
            parts.append(c.get("text", ""))
    print("\n".join(parts))
except Exception as e:
    print(f"(API response parse failed: {e})")
' 2>/dev/null || echo "(API response parse failed)")

  # Post-hoc carveout enforcement: filter any line that mentions the
  # forbidden paths. This is the second line of defense (the prompt is
  # the first). If the model proposes anything in .<name>/ or profile_<user>.md
  # we drop the line + emit a warning at the bottom.
  FILTERED=$(echo "$CONTENT" | grep -v 'memory/\.{{private_dir_name}}/' | grep -v 'profile_{{user_name_lower}}\.md' || true)
  DROPPED=$(echo "$CONTENT" | grep -cE "memory/\\.{{private_dir_name}}/|profile_{{user_name_lower}}\\.md" || true)

  echo "$FILTERED"

  if [ "${DROPPED:-0}" -gt 0 ]; then
    echo
    echo "## Carveout enforcement"
    echo
    echo "Dropped $DROPPED proposal line(s) that referenced memory/.{{private_dir_name}}/ or profile_{{user_name_lower}}.md (out of scope for phase 3)."
  fi

  # Cost (rough estimate)
  USAGE=$(echo "$RESPONSE" | python3 -c '
import json, sys
try:
    r = json.load(sys.stdin)
    u = r.get("usage", {})
    ip = u.get("input_tokens", 0)
    op = u.get("output_tokens", 0)
    print(f"{ip} {op}")
except Exception:
    print("0 0")
' 2>/dev/null || echo "0 0")
  read -r INPUT_TOK OUTPUT_TOK <<< "$USAGE"
  # Haiku 4.5 pricing (approx): $0.80/M input, $4/M output
  COST=$(INPUT_TOK="$INPUT_TOK" OUTPUT_TOK="$OUTPUT_TOK" python3 -c '
import os
ip = int(os.environ.get("INPUT_TOK", 0) or 0)
op = int(os.environ.get("OUTPUT_TOK", 0) or 0)
print(f"{(ip * 0.80 + op * 4.00) / 1_000_000:.4f}")
')
  echo
  echo "## Cost"
  echo
  echo "Actual cost: \$$COST USD (input=$INPUT_TOK tokens, output=$OUTPUT_TOK tokens, model=$MODEL)"
else
  # Stub mode (no API key OR dry-run without DREAM_DRYRUN_USE_API=1)
  cat <<STUB
## Proposed merges

(stub: no LLM call in this mode. Set DREAM_DRYRUN_USE_API=1 with ANTHROPIC_API_KEY to invoke the real model, or use --apply for the apply path)

## Proposed drops

(stub)

## Proposed date-normalizations

(stub)

## Proposed cross-cutting promotions

(stub)

## Cost

Estimated cost: \$0.0000 USD (stub mode, no API call; estimated input ${EST_TOKENS} tokens at \$0.80/M would be ~\$$(printf '%.4f' "$(awk "BEGIN { printf \"%.4f\", ($EST_TOKENS * 0.80) / 1000000 }")") if a real call was made)
STUB
fi

# Apply mode footer: explicit reminder that this script does NOT auto-write.
if [ "$MODE" = "apply" ]; then
  echo
  echo "## Apply"
  echo
  echo "Apply mode emitted a real LLM proposal but does NOT auto-write."
  echo "Pipe this output to a reviewer + then use scripts/apply-dream-proposal.sh"
  echo "(separate task) to commit the approved changes one-by-one."
fi
```

Note: this template uses `{{private_dir_name}}` for the user-private dot-dir carveout token. If the install does not configure a private dot-dir, leave the value as the sentinel `noprivatedir` so the grep filters never match a real path. The wizard substitutes this from Q-block answers.

---


## Template: scripts/dream/phase4-prune.sh

`Phase 4 of dream consolidation. Regenerates memory/MEMORY.md as a flat-line index from the cognitive overlay (Profile + semantic types + episodic + agent-memory + procedural pointer), capped at 200 lines. Hard-strips any line referencing the dot-dir-carveout dot-dir before cap. Writes a per-run changes.md log to data/dream-runs/<TURN_ID>/ containing the phase 3 proposal verbatim for audit. Modes: --dry-run (default, no commit) and --commit (regen + commit + push, post-commit hook re-embeds via embed-memories.py).`

```bash
#!/usr/bin/env bash
# Phase 4 of dream consolidation: prune & index.
#
# Reads PHASE3_MD from env (phase 3's consolidation proposal markdown).
# Regenerates memory/MEMORY.md as a flat-line index, capped at 200 lines.
# Writes a per-run changes log at data/dream-runs/<TURN_ID>/changes.md.
#
# Modes:
#   --dry-run (default): regenerate MEMORY.md in working tree, write
#                        changes.md, but do NOT commit (caller decides)
#   --commit: regenerate + write + commit + push (post-commit hook re-embeds)
#
# Hard rules:
#   - MEMORY.md MUST exclude memory/.<name>/ (dot-dir carveout)
#   - MEMORY.md cap: 200 lines including the header
#   - changes.md MUST contain phase 3 proposal verbatim for audit trail
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

MODE="dry-run"
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) MODE="dry-run"; shift ;;
    --commit) MODE="commit"; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

TURN_ID=${TURN_ID:-"phase4-$(date +%Y%m%dT%H%M%S)"}
PHASE3=${PHASE3_MD:-"(no phase 3 proposal supplied)"}
DATE=$(date '+%Y-%m-%d')
RUN_DIR="data/dream-runs/$TURN_ID"

mkdir -p "$RUN_DIR"

# === Regenerate MEMORY.md from the cognitive overlay ===
TMP_MEM=$(mktemp)

cat > "$TMP_MEM" <<HEADER
<!-- Auto-generated by scripts/dream/phase4-prune.sh on $DATE.
     Hand-edits will be overwritten on the next dream run. Source of truth
     is the individual memory files under memory/{semantic,episodic,procedural,agent-memory}/.
     Cap: 200 lines. Excludes memory/.{{private_dir_name}}/ (dot-dir carveout). -->
# {{orchestrator_name}} Memory Index

HEADER

# Profile bucket
if [ -f memory/profile_{{user_name_lower}}.md ]; then
  desc=$(awk '/^description:/ {sub(/^description:[[:space:]]*/,""); print; exit}' memory/profile_{{user_name_lower}}.md | head -c 100)
  printf '## Profile\n\n- [profile_{{user_name_lower}}.md](profile_{{user_name_lower}}.md). %s\n\n' "${desc:-(profile bucket)}" >> "$TMP_MEM"
fi

# Semantic types. feedback / project / reference / note / user
for type in feedback project reference note user; do
  dir="memory/semantic/$type"
  [ -d "$dir" ] || continue
  count=$(find "$dir" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  [ "$count" -eq 0 ] && continue
  printf '## Semantic: %s (%d)\n\n' "$type" "$count" >> "$TMP_MEM"
  find "$dir" -type f -name "*.md" 2>/dev/null | sort | while IFS= read -r f; do
    case "$f" in *"/.{{private_dir_name}}/"*) continue ;; esac
    desc=$(awk '/^description:/ {sub(/^description:[[:space:]]*/,""); print; exit}' "$f" | head -c 80)
    name=$(basename "$f" .md)
    printf -- '- %s. %s\n' "$name" "${desc:-(no desc)}" >> "$TMP_MEM"
  done
  echo "" >> "$TMP_MEM"
done

# Episodic. Only the 10 most recent (sorted reverse by name; assumes date-prefix)
if [ -d memory/episodic ]; then
  count=$(find memory/episodic -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    printf '## Episodic (%d, showing 10 most recent)\n\n' "$count" >> "$TMP_MEM"
    find memory/episodic -type f -name "*.md" 2>/dev/null | sort -r | head -10 | while IFS= read -r f; do
      case "$f" in *"/.{{private_dir_name}}/"*) continue ;; esac
      name=$(basename "$f" .md)
      printf -- '- %s\n' "$name" >> "$TMP_MEM"
    done
    echo "" >> "$TMP_MEM"
  fi
fi

# Agent memory. count per agent
if [ -d memory/agent-memory ]; then
  count=$(find memory/agent-memory -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  printf '## Agent memory (%d)\n\n' "$count" >> "$TMP_MEM"
  for d in memory/agent-memory/*/; do
    [ -d "$d" ] || continue
    case "$d" in *"/.{{private_dir_name}}/"*) continue ;; esac
    agent=$(basename "$d")
    afiles=$(find "$d" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    printf -- '- %s (%d files)\n' "$agent" "$afiles" >> "$TMP_MEM"
  done
  echo "" >> "$TMP_MEM"
fi

# Procedural pointer
if [ -f memory/procedural/README.md ]; then
  echo "## Procedural" >> "$TMP_MEM"
  echo "" >> "$TMP_MEM"
  echo "- See \`memory/procedural/README.md\` (pointer to CLAUDE.md + .claude/skills/ + corrections + hooks)" >> "$TMP_MEM"
  echo "" >> "$TMP_MEM"
fi

# Defense-in-depth: strip any line referencing memory/.<name>/ before cap
grep -v "memory/\\.{{private_dir_name}}/\|memory/.{{private_dir_name}}/" "$TMP_MEM" > "$TMP_MEM.clean" && mv "$TMP_MEM.clean" "$TMP_MEM"

# Cap at 200 lines (truncate if over)
LINES=$(wc -l < "$TMP_MEM" | tr -d ' ')
if [ "$LINES" -gt 200 ]; then
  head -198 "$TMP_MEM" > "$TMP_MEM.capped"
  echo "" >> "$TMP_MEM.capped"
  echo "<!-- Truncated at 200 lines per Auto Dream convention. Full memory tree under memory/. -->" >> "$TMP_MEM.capped"
  mv "$TMP_MEM.capped" "$TMP_MEM"
fi

# Write to MEMORY.md
mv "$TMP_MEM" memory/MEMORY.md

FINAL_LINES=$(wc -l < memory/MEMORY.md | tr -d ' ')

# === Write the changes log ===
cat > "$RUN_DIR/changes.md" <<CHANGES
# Dream Run Changes. $TURN_ID

Run date: $DATE
Mode: $MODE

## MEMORY.md regen

Lines after regen: $FINAL_LINES (cap 200)

## Phase 3 proposal echo

$PHASE3

## Notes

This file is the per-run audit trail. Keep for at least 90 days.
CHANGES

echo "Phase 4 done."
echo "  MEMORY.md: $FINAL_LINES lines"
echo "  Changes log: $RUN_DIR/changes.md"

# Commit if --commit
if [ "$MODE" = "commit" ]; then
  git add memory/MEMORY.md "$RUN_DIR/changes.md"
  git commit -m "memory: dream cycle $TURN_ID (MEMORY.md regen + changes log)"
  git push origin main 2>/dev/null || true
fi
```

---


## Template: scripts/update-profile.sh

`Profile bucket update mechanism. Reads memory/profile_<user>.md and gathers signal from this session (telegram tail last 4h, completed/abandoned arcs from {{orchestrator_lower}}-state.json, new feedback memories committed in last 24h, explicit self-statements via simple regex). DRAFTS proposed updates to data/runtime/profile-update-pending.md. Does NOT auto-overwrite the Profile. The pending file is reviewed at the next session start by the orchestrator who applies, edits, or discards. Modes: default (write pending draft), --dry-run (print to stdout), --apply --yes (append pending under "Pending review" footer to profile, with backup). Wired into scripts/session-end-sync.sh after reflect.sh.`

```bash
#!/bin/bash
# update-profile.sh
#
# Profile bucket update mechanism.
#
# Reads the current memory/profile_<user>.md, gathers signal from this
# session (telegram tail, completed/abandoned arcs, new feedback memories
# committed since the last reflection), and DRAFTS proposed updates to
# data/runtime/profile-update-pending.md.
#
# It does NOT auto-overwrite the Profile. The pending file is reviewed
# at the next session start by the orchestrator, who applies, edits, or discards.
# This is intentional. Narrative judgment > regex pattern matching.
#
# Modes:
#   bash scripts/update-profile.sh            # write pending draft
#   bash scripts/update-profile.sh --dry-run  # print draft to stdout, do not write
#   bash scripts/update-profile.sh --apply    # apply pending draft to profile (requires --yes)
#
# Wired into scripts/session-end-sync.sh after reflect.sh.

set -euo pipefail

ORCH_DIR="{{project_path}}"
PROFILE="$ORCH_DIR/memory/profile_{{user_name_lower}}.md"
PENDING="$ORCH_DIR/data/runtime/profile-update-pending.md"
LOG_FILE="$ORCH_DIR/logs/profile-updates.log"

cd "$ORCH_DIR" || exit 0
mkdir -p "$(dirname "$PENDING")" "$(dirname "$LOG_FILE")"

DRY_RUN=0
APPLY=0
CONFIRM_YES=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --apply)   APPLY=1 ;;
    --yes)     CONFIRM_YES=1 ;;
    --help|-h)
      grep '^#' "$0" | head -25
      exit 0
      ;;
  esac
done

# Apply mode: copy pending draft into the Profile under a "Pending review" footer
# so the orchestrator can pick what to merge. Requires --yes to actually write.
if [ "$APPLY" -eq 1 ]; then
  if [ ! -f "$PENDING" ]; then
    echo "No pending draft at $PENDING. Nothing to apply."
    exit 0
  fi
  if [ "$CONFIRM_YES" -ne 1 ]; then
    echo "Refusing to apply without --yes. Run --dry-run first to inspect."
    exit 2
  fi
  ts=$(date -u +%FT%TZ)
  bak="${PROFILE}.bak.${ts//[:T-]/}"
  cp "$PROFILE" "$bak"
  printf '\n\n<!-- pending review at %s -->\n%s\n' "$ts" "$(cat "$PENDING")" >> "$PROFILE"
  echo "[$ts] applied pending draft to profile (backup at $bak)" >> "$LOG_FILE"
  echo "applied. backup: $bak"
  exit 0
fi

# Build draft. Stays small and read-only on the source memories.
ts=$(date -u +%FT%TZ)

# Section 1. telegram tail signal (this session-ish, last 4h)
since_iso=$(date -u -v-4H +%FT%TZ 2>/dev/null || date -u -d '4 hours ago' +%FT%TZ 2>/dev/null || date -u +%FT%TZ)
tail_file=$(mktemp)
trap 'rm -f "$tail_file"' EXIT
if [ -x "$ORCH_DIR/scripts/recent-telegram.sh" ]; then
  bash "$ORCH_DIR/scripts/recent-telegram.sh" 200 2>/dev/null | tail -80 > "$tail_file" || true
else
  echo "(recent-telegram.sh not found)" > "$tail_file"
fi

# Section 2. completed arcs since last session-end ({{orchestrator_lower}}-state.json)
state_file="$ORCH_DIR/data/runtime/{{orchestrator_lower}}-state.json"
arc_count="?"
if [ -f "$state_file" ] && command -v jq >/dev/null 2>&1; then
  arc_count=$(jq -r '.pending_arcs | length' "$state_file" 2>/dev/null || echo "?")
fi

# Section 3. new feedback memories committed in last 24h.
# Use git's :(glob) pathspec magic so ** matches across path separators.
# Files now live under memory/semantic/<type>/ post-cognitive-overlay-rollout.
# Top-level pathspecs kept alongside for the transition window where some
# memories may still exist at memory/<type>_*.md.
# Private dot-dir carveout enforced via :(exclude).
new_feedback=$(git -C "$ORCH_DIR" log --since='24 hours ago' --name-only --pretty=format: -- \
  ':(glob)memory/**/feedback_*.md' ':(glob)memory/**/user_*.md' ':(glob)memory/**/profile_*.md' \
  'memory/feedback_*.md' 'memory/user_*.md' 'memory/profile_*.md' \
  ':(exclude)memory/.{{private_dir_name}}/**' \
  2>/dev/null | sort -u | grep -v '^$' || true)

# Section 4. explicit self-statements heuristic (very simple regex; narrative judgment lives in the orchestrator)
self_lines=$(grep -E "(I'm|I am|I've|I want|I'm focused|I've decided|I'm not chasing|deciding|I prefer|I hate|I love)" "$tail_file" 2>/dev/null | head -10 || true)

# Build the draft
draft=$(cat <<EOF
# Profile update draft (proposed, not applied)

_Generated by \`scripts/update-profile.sh\` at ${ts}._
_The orchestrator reviews this on next session start. Apply, edit, or discard. Do not auto-merge._

## Why this exists

Profile (\`memory/profile_{{user_name_lower}}.md\`) is the mutable Karpathy three-bucket Profile file. This draft proposes updates the orchestrator should consider next session, based on signals from THIS session.

## Signal sources scanned

- Telegram tail (last 4h, ~80 messages): see embedded excerpt below
- Pending arcs in {{orchestrator_lower}}-state.json: ${arc_count} arcs
- New feedback / user / profile memory commits in last 24h:
\`\`\`
${new_feedback:-(none)}
\`\`\`

## Explicit self-statements detected (heuristic, low confidence)

These are lines from the telegram tail that pattern-match self-declarative phrasing. Orchestrator judgment required to decide if any update the Profile.

\`\`\`
${self_lines:-(none detected)}
\`\`\`

## Recommended review steps next session

1. Read the latest 10 reflections + this draft.
2. For each Profile section that may have moved (top-3 priorities, current obsessions, recent mood, recurring frustrations, project pipeline), ask: did this session change what is true?
3. Apply changes via Edit tool directly to memory/profile_{{user_name_lower}}.md. Bump \`last_updated\` field in frontmatter.
4. Commit with message \`profile: refresh per session-end signal <date>\`.
5. Move this pending file to \`data/runtime/profile-update-pending.md.applied.<ts>\` to mark reviewed (or delete it).

## Telegram tail excerpt (last 80 lines, redacted via redact-secrets.sh if available)

\`\`\`
$(cat "$tail_file" 2>/dev/null | head -80)
\`\`\`

## Project pipeline drift check

The orchestrator should verify the Tier 1 / Tier 2 / Tier 3 / Tier 4 ranking in profile_{{user_name_lower}}.md still matches reality. Triggers for re-rank:
- A Tier 2 project went live with paying customers (promote to Tier 1).
- A Tier 1 project is now blocked-on-external-only with no orchestrator action (demote).
- A Tier 4 project had >3 commits this week (consider promotion).
- A new project was registered (must be added).

## Anti-priority drift check

Verify the "things to NEVER do" list still applies. New items go in if {{user_name}} has said no to something twice. Old items that have been silently ignored for 90+ days may have been forgotten by everyone.
EOF
)

if [ "$DRY_RUN" -eq 1 ]; then
  printf '%s\n' "$draft"
  exit 0
fi

printf '%s\n' "$draft" > "$PENDING"
echo "[$ts] wrote profile-update-pending.md (telegram lines: $(wc -l < "$tail_file"))" >> "$LOG_FILE"
echo "wrote $PENDING ($(wc -c < "$PENDING") bytes)"
```

---


## Template: scripts/roll-episodic.sh

`Daily compilation pass. Rolls today's telegram tail (filtered to today's date) + latest reflection + commits into memory/episodic/<date>.md. Idempotent (re-run overwrites today's file with a fresh snapshot). Wired into scripts/session-end-sync.sh on session close. Manual: bash scripts/roll-episodic.sh [YYYY-MM-DD]. Frontmatter sets ttl_days=30 so episodic memory ages out automatically via check-memory-freshness.sh.`

```bash
#!/usr/bin/env bash
# Roll today's telegram tail + latest reflection + commits into memory/episodic/<date>.md.
# Idempotent: re-run overwrites today's file (fresh snapshot).
# Called by:
#  - Manual: bash scripts/roll-episodic.sh [YYYY-MM-DD]
#  - Stop hook: scripts/session-end-sync.sh runs this on session close.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DATE=${1:-$(date '+%Y-%m-%d')}
OUT="memory/episodic/$DATE.md"
mkdir -p memory/episodic

{
  echo "---"
  echo "name: episodic-$DATE"
  echo "description: Daily rolled telegram tail + reflection + commits for $DATE"
  echo "type: episodic"
  echo "last_verified: $DATE"
  echo "ttl_days: 30"
  echo "---"
  echo
  echo "# Episodic. $DATE"
  echo
  echo "## Telegram tail"
  echo
  echo '```'
  if [ -x scripts/recent-telegram.sh ]; then
    bash scripts/recent-telegram.sh 50 2>/dev/null | grep "^\[$DATE" || echo "(no telegram traffic today)"
  else
    echo "(scripts/recent-telegram.sh missing)"
  fi
  echo '```'
  echo
  echo "## Reflection"
  echo
  REF=$(ls -t "data/reflections/$DATE-"*.md 2>/dev/null | head -1)
  if [ -n "$REF" ] && [ -f "$REF" ]; then
    cat "$REF"
  else
    echo "(no reflection for $DATE)"
  fi
  echo
  echo "## Commits"
  echo
  echo '```'
  git log --since="$DATE 00:00" --until="$DATE 23:59" --oneline 2>/dev/null || echo "(no commits)"
  echo '```'
} > "$OUT"

echo "rolled: $OUT"
```

---


## Template: scripts/weekly-memory-compile.sh

`Weekly compilation pass. Runs Sundays via bash scripts/maintain.sh. For the past 7 days of episodic files, surfaces repeated patterns + new feedback candidates + cross-cutting decisions. Output goes to data/dream-proposals/weekly-<DATE>.md for human review. Pure-bash signal scan, no LLM call, $0 cost. Heuristics flag: 3+ new feedback rules in window, correction categories at >=3 hits, 5+ episodic files indicating heavy session activity.`

```bash
#!/usr/bin/env bash
# Weekly memory compile. For the past 7 days of episodic files, surface
# repeated patterns + new feedback candidates + cross-cutting decisions.
# Output goes to data/dream-proposals/weekly-<DATE>.md for human review.
#
# Pure scan (no LLM call). Cost: $0.
#
# Triggered by maintain.sh on Sundays.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

DATE=$(date '+%Y-%m-%d')
WINDOW_DAYS=7
CUTOFF=$(date -v-${WINDOW_DAYS}d '+%Y-%m-%d' 2>/dev/null || date --date="${WINDOW_DAYS} days ago" '+%Y-%m-%d')
CUTOFF_EPOCH=$(date -v-${WINDOW_DAYS}d +%s 2>/dev/null || date --date="${WINDOW_DAYS} days ago" +%s)

mkdir -p data/dream-proposals
OUT="data/dream-proposals/weekly-$DATE.md"

{
  echo "# Weekly Memory Digest. $DATE"
  echo
  echo "Past 7 days of {{orchestrator_name}} activity, scanned for repeated patterns + new feedback candidates + cross-cutting decisions. Pure-bash signal scan, no LLM."
  echo
  echo "## Window"
  echo
  echo "- Scan window: \`$CUTOFF\` to \`$DATE\` (last 7 days)"
  echo "- Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo

  # ----------------------------------------------------------------
  # Episodic files in window
  # ----------------------------------------------------------------
  echo "## Episodic files in window"
  echo
  EPI_FILES_IN_WINDOW=""
  if [ -d memory/episodic ]; then
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      base=$(basename "$f" .md)
      # Filename is YYYY-MM-DD; compare lexicographically against CUTOFF
      if [[ "$base" > "$CUTOFF" || "$base" = "$CUTOFF" ]]; then
        EPI_FILES_IN_WINDOW="${EPI_FILES_IN_WINDOW}${base}"$'\n'
      fi
    done < <(find memory/episodic -maxdepth 1 -type f -name "*.md" 2>/dev/null | sort)
  fi
  EPI_COUNT=$(printf '%s' "$EPI_FILES_IN_WINDOW" | grep -c . || true)
  echo "Found **$EPI_COUNT** episodic file(s) in window:"
  echo
  echo '```'
  if [ "$EPI_COUNT" -eq 0 ]; then
    echo "(none. episodic memory may not have rolled yet this week)"
  else
    printf '%s' "$EPI_FILES_IN_WINDOW"
  fi
  echo '```'
  echo

  # ----------------------------------------------------------------
  # Repeated patterns
  # ----------------------------------------------------------------
  echo "## Repeated patterns"
  echo
  echo "### Corrections by category (window: last 7 days)"
  echo
  CORR_OUT=""
  if [ -f data/corrections.jsonl ]; then
    CORR_OUT=$(awk -v cutoff="$CUTOFF" '
      {
        # Extract ts (ISO date) and category from each JSON line
        match($0, /"ts":"[^"]+"/)
        ts = substr($0, RSTART+6, RLENGTH-7)
        ts_date = substr(ts, 1, 10)
        if (ts_date < cutoff) next
        match($0, /"category":"[^"]+"/)
        if (RLENGTH > 0) {
          cat = substr($0, RSTART+12, RLENGTH-13)
          print cat
        }
      }
    ' data/corrections.jsonl 2>/dev/null | sort | uniq -c | sort -rn | head -10 | sed 's/^/- /')
  fi
  if [ -z "$CORR_OUT" ]; then
    echo "- (no corrections logged in window)"
  else
    echo "$CORR_OUT"
  fi
  echo

  echo "### Commit-message prefixes (window: last 7 days)"
  echo
  COMMIT_OUT=$(git log --since="${WINDOW_DAYS} days ago" --pretty=format:'%s' 2>/dev/null \
    | awk -F':' '{print $1}' \
    | awk '{print $1}' \
    | sort | uniq -c | sort -rn | head -10 \
    | sed 's/^/- /')
  if [ -z "$COMMIT_OUT" ]; then
    echo "- (no commits in window)"
  else
    echo "$COMMIT_OUT"
  fi
  echo

  # ----------------------------------------------------------------
  # New feedback candidates
  # ----------------------------------------------------------------
  echo "## New feedback candidates"
  echo
  echo "Feedback memories created in last $WINDOW_DAYS days:"
  echo
  found=0
  found_lines=""
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    f_epoch=$(stat -f %B "$f" 2>/dev/null || stat -c %W "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)
    if [ -n "$f_epoch" ] && [ "$f_epoch" -ge "$CUTOFF_EPOCH" ]; then
      desc=$(awk '/^description:/ {sub(/^description:[[:space:]]*/,""); print; exit}' "$f" 2>/dev/null | cut -c1-120)
      found_lines="${found_lines}- \`$(basename "$f" .md)\`. ${desc:-(no desc)}"$'\n'
      found=$((found + 1))
    fi
  done < <(find memory/semantic/feedback memory -maxdepth 3 -type f -name "feedback_*.md" 2>/dev/null | sort -u)
  if [ "$found" -eq 0 ]; then
    echo "- (none in window)"
  else
    printf '%s' "$found_lines"
  fi
  echo

  # ----------------------------------------------------------------
  # Cross-cutting candidates
  # ----------------------------------------------------------------
  echo "## Cross-cutting candidates"
  echo
  echo "Heuristic surface. Review whether any of these should promote to procedural / cross-cutting reference memory:"
  echo
  HAS_SIGNAL=0
  if [ "$found" -ge 3 ]; then
    echo "- **$found new feedback rules** established this week. Consider whether any are cross-cutting (apply across multiple projects) and should promote to \`memory/procedural/\`."
    HAS_SIGNAL=1
  fi
  if [ -f data/corrections.jsonl ]; then
    cat_count=$(awk -v cutoff="$CUTOFF" '
      {
        match($0, /"ts":"[^"]+"/)
        ts = substr($0, RSTART+6, RLENGTH-7)
        ts_date = substr(ts, 1, 10)
        if (ts_date < cutoff) next
        match($0, /"category":"[^"]+"/)
        if (RLENGTH > 0) {
          cat = substr($0, RSTART+12, RLENGTH-13)
          print cat
        }
      }
    ' data/corrections.jsonl 2>/dev/null | sort | uniq -c | awk '$1 >= 3' | wc -l | tr -d ' ')
    if [ "$cat_count" -ge 1 ]; then
      echo "- **$cat_count correction categor(ies)** hit >=3 in window. Run \`bash scripts/promote-correction.sh <category>\` per category."
      HAS_SIGNAL=1
    fi
  fi
  if [ "$EPI_COUNT" -ge 5 ]; then
    echo "- **$EPI_COUNT episodic files** in window. Heavy session activity. Consider a manual scan for emerging themes the heuristics miss."
    HAS_SIGNAL=1
  fi
  if [ "$HAS_SIGNAL" -eq 0 ]; then
    echo "- (no cross-cutting signals detected this week. Quiet week or insufficient activity)"
  fi
  echo

  # ----------------------------------------------------------------
  # Footer
  # ----------------------------------------------------------------
  echo "---"
  echo
  echo "End weekly digest. Review and apply via \`dream apply\` on actionable items, or move this file to \`data/dream-proposals/applied/\` once reviewed. Reject by moving to \`rejected/\`."
} > "$OUT"

LINES=$(wc -l < "$OUT" | tr -d ' ')
SIZE=$(wc -c < "$OUT" | tr -d ' ')
echo "Weekly digest written: $OUT ($LINES lines, $SIZE bytes)"
```

---


## Template: scripts/monthly-memory-retrospective.sh

`Monthly compilation pass. Runs first Sunday of each month via bash scripts/maintain.sh. Runs scripts/dream.sh --full-cycle and writes a retrospective covering memory size growth (per-type breakdown, 30-day commit activity), token spend (sums all proposal.md cost lines in data/dream-runs/), recall stats (active-recall-cache.tsv entries + unique entities), memory freshness (delegates to check-memory-freshness.sh). Modes: --dry-run (default, dream cycle in dry-run) and --commit (real LLM call + commit + push).`

```bash
#!/usr/bin/env bash
# Monthly memory retrospective. Runs the full dream --full-cycle + writes a
# retrospective covering memory size over time, token spend, hit rate, stale
# rate. Triggered by maintain.sh on the first Sunday of each month.
#
# Modes:
#   --dry-run (default): runs dream --full-cycle in dry-run, writes retrospective
#   --commit: runs dream --full-cycle in apply mode (real LLM call), writes retro
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

MODE="dry-run"
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) MODE="dry-run"; shift ;;
    --commit) MODE="commit"; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

TURN_ID=${TURN_ID:-"monthly-$(date +%Y%m%dT%H%M%S)"}
DATE=$(date '+%Y-%m-%d')
RUN_DIR="data/dream-runs/$TURN_ID"

mkdir -p "$RUN_DIR"

# Step 1: Run the full dream cycle
echo "Running dream --full-cycle for monthly retrospective..."
DREAM_FLAG="--dry-run"
[ "$MODE" = "commit" ] && DREAM_FLAG=""

bash scripts/dream.sh --full-cycle $DREAM_FLAG --turn-id "$TURN_ID" 2>&1 | sed 's/^/[dream] /' || true

# Step 2: Build the retrospective
RETRO="$RUN_DIR/retrospective.md"
{
  echo "# Monthly Memory Retrospective. $DATE"
  echo
  echo "Run ID: \`$TURN_ID\`"
  echo "Mode: $MODE"
  echo
  echo "## Memory size growth"
  echo
  # Total memory files now (basename match catches files in semantic/<type>/ too)
  CURRENT=$(find memory -type d -name '.*' -prune -o -type f -name "*.md" -print 2>/dev/null | wc -l | tr -d ' ')
  echo "- Current total: **$CURRENT** memory files"
  echo
  echo "Per-type breakdown:"
  for type in feedback project reference note user; do
    count=$(find memory/semantic/$type -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    [ "$count" -gt 0 ] && echo "- semantic/$type: $count"
  done
  EPI=$(find memory/episodic -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  AGENT=$(find memory/agent-memory -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  [ "$EPI" -gt 0 ] && echo "- episodic: $EPI"
  [ "$AGENT" -gt 0 ] && echo "- agent-memory: $AGENT"
  echo
  echo "30-day commit activity for memory/:"
  echo '```'
  git log --since="30 days ago" --pretty=format:'%h %ad %s' --date=short -- memory/ 2>/dev/null | head -20 || echo "(no commits)"
  echo
  echo '```'
  echo

  echo "## Token spend"
  echo
  echo "Cost summary for dream cycles in last 30 days:"
  echo
  # Scan data/dream-runs/ for cost lines in proposal.md files
  TOTAL_RUNS=0
  TOTAL_COST_CENTS=0
  if [ -d data/dream-runs ]; then
    while IFS= read -r prop; do
      [ -f "$prop" ] || continue
      cost=$(grep -oE 'cost: \$[0-9]+\.[0-9]+' "$prop" 2>/dev/null | head -1 | sed 's/cost: \$//')
      [ -z "$cost" ] && cost="0.0000"
      TOTAL_RUNS=$((TOTAL_RUNS + 1))
      cents=$(python3 -c "print(int(float('$cost') * 10000))" 2>/dev/null || echo 0)
      TOTAL_COST_CENTS=$((TOTAL_COST_CENTS + cents))
    done < <(find data/dream-runs -mtime -30 -name "proposal.md" -type f 2>/dev/null)
  fi
  TOTAL_USD=$(python3 -c "print(f'{$TOTAL_COST_CENTS / 10000:.4f}')" 2>/dev/null || echo "0.0000")
  echo "- Dream runs in last 30 days: $TOTAL_RUNS"
  echo "- Total cost: \$$TOTAL_USD"
  echo "- Avg per run: \$$(python3 -c "print(f'{$TOTAL_COST_CENTS / 10000 / max($TOTAL_RUNS, 1):.4f}')" 2>/dev/null || echo "0.0000")"
  echo

  echo "## Recall stats (hit rate)"
  echo
  echo "Active recall cache stats from \`data/runtime/active-recall-cache.tsv\`:"
  if [ -f data/runtime/active-recall-cache.tsv ]; then
    LINES=$(wc -l < data/runtime/active-recall-cache.tsv | tr -d ' ')
    echo "- Cache entries: $LINES"
    UNIQUE_ENTITIES=$(awk -F'\t' '{print $2}' data/runtime/active-recall-cache.tsv 2>/dev/null | sort -u | wc -l | tr -d ' ')
    echo "- Unique entities cached: $UNIQUE_ENTITIES"
  else
    echo "- (cache not yet populated)"
  fi
  echo

  echo "## Memory freshness (stale rate)"
  echo
  if [ -x scripts/check-memory-freshness.sh ]; then
    bash scripts/check-memory-freshness.sh 2>&1 | tail -5 | sed 's/^/    /' || echo "(freshness check failed)"
  else
    echo "(check-memory-freshness.sh not executable)"
  fi
  echo

  echo "## This run's dream cycle"
  echo
  echo "Artifacts in \`$RUN_DIR/\`:"
  ls -la "$RUN_DIR" 2>/dev/null | tail -n +2 | awk '{print "- " $NF " (" $5 " bytes)"}' || echo "(no artifacts)"
  echo

  echo "---"
  echo "End monthly retrospective."
} > "$RETRO"

echo "Monthly retrospective: $RETRO"

# Commit if --commit
if [ "$MODE" = "commit" ]; then
  git add memory/MEMORY.md "$RUN_DIR/"
  git commit -m "memory: monthly retrospective $TURN_ID"
  git push origin main 2>/dev/null || true
fi
```

---


## Template: scripts/auth-fallback.sh

`Auth-mode flipper between Max OAuth and a separately-billed Anthropic API key. Caps any Anthropic OAuth suspension outage from 30 days to minutes. Commands: status (current mode + redacted key + /v1/messages reachability), use-api-key (flip to API key after pre-flight probe), use-oauth (flip back, clears env override), test-key <KEY> (test a candidate key without activating it). API key stored at $HOME/.config/claude/api-key (mode 0600, NEVER in git). Active mode marker at $HOME/.config/claude/auth-mode. Env file at $HOME/.config/claude/auth-env.sh. See docs/auth-failover-runbook.md for full provisioning + cost watch runbook.`

```bash
#!/usr/bin/env bash
# auth-fallback.sh. flip Claude Code between Max OAuth and Anthropic API key auth.
#
# The #1 mitigation against an Anthropic OAuth suspension (e.g. Persona
# age-verification 30-day hold). Without this, a single classifier hit takes
# the orchestrator fully dark for up to 30 days. With this, max outage drops
# to a few minutes. The time it takes to flip auth modes and verify.
#
# AUTH MODES
#   - oauth      : Max subscription OAuth (default). `claude auth status` shows
#                  authMethod=claude.ai, billing flat via Max plan.
#   - api-key    : Anthropic API key. env var ANTHROPIC_API_KEY honoured by
#                  Claude Code; per-token billing via console.anthropic.com.
#
# STORAGE
#   API key lives at ~/.config/claude/api-key (mode 0600, NEVER in git).
#   Active mode marker at ~/.config/claude/auth-mode (oauth|api-key).
#
# COMMANDS
#   status [--quiet]      Print current mode, redacted key, /v1/messages reachability
#   use-api-key           Flip to API key (key must already exist at the path above)
#   use-oauth             Flip back to OAuth (clears env override; keychain stays)
#   test-key <KEY>        Test a candidate key without activating it
#
# All commands are idempotent and return 0 on success / non-zero on failure.

set -uo pipefail

CONFIG_DIR="$HOME/.config/claude"
KEY_FILE="$CONFIG_DIR/api-key"
MODE_FILE="$CONFIG_DIR/auth-mode"
SHELL_PROFILE="$CONFIG_DIR/auth-env.sh"

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR" 2>/dev/null || true

cmd="${1:-status}"
shift || true

quiet=0
for arg in "$@"; do
  [[ "$arg" == "--quiet" ]] && quiet=1
done

log() { [[ $quiet -eq 1 ]] || echo "$@"; }
err() { echo "$@" >&2; }

redact_key() {
  local k="$1"
  local len=${#k}
  if [[ $len -lt 12 ]]; then
    echo "<too-short-redacted>"
  else
    echo "${k:0:7}...${k: -4}"
  fi
}

read_active_mode() {
  if [[ -f "$MODE_FILE" ]]; then
    cat "$MODE_FILE"
  elif [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    echo "api-key"
  else
    echo "oauth"
  fi
}

# Hit /v1/messages with a 1-token Haiku probe. Returns 0/1, sets http_code.
probe_messages() {
  local key="$1"
  local mode="$2"
  http_code=0
  err_body=""
  if [[ "$mode" == "api-key" ]]; then
    if [[ -z "$key" ]]; then
      err_body="no-api-key-loaded"
      return 1
    fi
    local resp
    resp="$(curl -s -o /tmp/auth-fallback-probe.$$ -w '%{http_code}' \
      -X POST https://api.anthropic.com/v1/messages \
      -H "content-type: application/json" \
      -H "anthropic-version: 2023-06-01" \
      -H "x-api-key: $key" \
      --max-time 10 \
      -d '{"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}' 2>/dev/null)" || resp="000"
    http_code="$resp"
    if [[ "$resp" == "200" ]]; then
      rm -f /tmp/auth-fallback-probe.$$
      return 0
    fi
    err_body="$(head -c 300 /tmp/auth-fallback-probe.$$ 2>/dev/null || true)"
    rm -f /tmp/auth-fallback-probe.$$
    return 1
  else
    # OAuth mode. defer to `claude auth status` since the OAuth token is not
    # exposed to us as an env var; the daemon manages it via keychain.
    local out
    out="$(claude auth status --json 2>/dev/null || echo '{}')"
    if echo "$out" | grep -q '"loggedIn"[[:space:]]*:[[:space:]]*true'; then
      http_code="200"
      return 0
    fi
    err_body="$out"
    http_code="401"
    return 1
  fi
}

case "$cmd" in
  status)
    mode="$(read_active_mode)"
    log "Auth mode: $mode"
    api_key=""
    if [[ -f "$KEY_FILE" ]]; then
      api_key="$(tr -d '\n' < "$KEY_FILE")"
      log "API key (provisioned): $(redact_key "$api_key") at $KEY_FILE"
    else
      log "API key (provisioned): <none>. see docs/auth-failover-runbook.md to provision"
    fi

    # OAuth status (always informational)
    oauth_out="$(claude auth status --json 2>/dev/null || echo '{}')"
    if echo "$oauth_out" | grep -q '"loggedIn"[[:space:]]*:[[:space:]]*true'; then
      sub="$(echo "$oauth_out" | grep -oE '"subscriptionType"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
      log "OAuth: logged-in (subscription=$sub)"
    else
      log "OAuth: not logged in"
    fi

    # Reachability probe under ACTIVE mode
    if probe_messages "$api_key" "$mode"; then
      log "Reachability: OK (mode=$mode, http=$http_code)"
      exit 0
    else
      err "Reachability: FAIL (mode=$mode, http=$http_code)"
      [[ -n "$err_body" ]] && err "  body: $err_body"
      exit 1
    fi
    ;;

  test-key)
    candidate="${1:-}"
    if [[ -z "$candidate" ]]; then
      err "Usage: $0 test-key <KEY>"
      exit 2
    fi
    if [[ ! "$candidate" =~ ^sk-ant- ]]; then
      err "Warning: key does not start with sk-ant- (still testing)"
    fi
    if probe_messages "$candidate" "api-key"; then
      log "Test: PASS (http=$http_code). key is valid, /v1/messages reachable"
      exit 0
    else
      err "Test: FAIL (http=$http_code)"
      [[ -n "$err_body" ]] && err "  body: $err_body"
      case "$http_code" in
        401) err "  -> 401: key is invalid or revoked" ;;
        403) err "  -> 403: key valid but org/account suspended" ;;
        429) err "  -> 429: rate-limited (transient)" ;;
        000) err "  -> network unreachable (transient)" ;;
      esac
      exit 1
    fi
    ;;

  use-api-key)
    if [[ ! -f "$KEY_FILE" ]]; then
      err "FAIL: $KEY_FILE not found"
      err "Provision a key first. see docs/auth-failover-runbook.md"
      exit 2
    fi
    perms="$(stat -f %A "$KEY_FILE" 2>/dev/null || stat -c %a "$KEY_FILE" 2>/dev/null || echo '?')"
    if [[ "$perms" != "600" ]]; then
      err "Tightening perms on $KEY_FILE (was $perms)"
      chmod 600 "$KEY_FILE"
    fi
    api_key="$(tr -d '\n' < "$KEY_FILE")"
    if [[ -z "$api_key" ]]; then
      err "FAIL: $KEY_FILE is empty"
      exit 2
    fi

    # Probe before flipping
    log "Pre-flight: probing /v1/messages with candidate key..."
    if ! probe_messages "$api_key" "api-key"; then
      err "FAIL: pre-flight probe failed (http=$http_code). refusing to flip"
      [[ -n "$err_body" ]] && err "  body: $err_body"
      exit 1
    fi
    log "Pre-flight: OK"

    # Write env snippet that the user sources to apply
    cat > "$SHELL_PROFILE" <<EOF
# auto-generated by scripts/auth-fallback.sh. flip to api-key mode
export ANTHROPIC_API_KEY="$api_key"
EOF
    chmod 600 "$SHELL_PROFILE"
    echo "api-key" > "$MODE_FILE"

    log "Mode flipped: api-key"
    log "ANTHROPIC_API_KEY written to $SHELL_PROFILE (mode 0600)"
    log ""
    log "TO ACTIVATE in this shell now:"
    log "  source $SHELL_PROFILE"
    log ""
    log "TO ACTIVATE in all future {{orchestrator_name}} sessions:"
    log "  Add this to {{shell_profile}} (one-time):"
    log "    [ -f $SHELL_PROFILE ] && [ \"\$(cat $MODE_FILE 2>/dev/null)\" = api-key ] && source $SHELL_PROFILE"
    log ""
    log "TO VERIFY:"
    log "  bash $0 status"
    exit 0
    ;;

  use-oauth)
    echo "oauth" > "$MODE_FILE"
    # Blank out the env file so a stale source-line does not keep the override alive.
    cat > "$SHELL_PROFILE" <<EOF
# auto-generated by scripts/auth-fallback.sh. oauth mode (no env override)
# Mode is oauth; ANTHROPIC_API_KEY intentionally NOT exported.
unset ANTHROPIC_API_KEY 2>/dev/null
EOF
    chmod 600 "$SHELL_PROFILE"
    log "Mode flipped: oauth"
    log "Env override cleared. Claude Code will use the keychain OAuth token."
    log ""
    log "TO ACTIVATE in this shell now:"
    log "  unset ANTHROPIC_API_KEY"
    log ""
    log "TO VERIFY:"
    log "  bash $0 status"
    exit 0
    ;;

  *)
    err "Usage: $0 {status|use-api-key|use-oauth|test-key <KEY>} [--quiet]"
    exit 2
    ;;
esac
```

---


## Template: scripts/check-auth-status.sh

`4th SLO canary. Pings Anthropic /v1/messages with a 1-token Haiku call using the active auth mode (OAuth via `claude auth status --json` proxy, or API key via direct curl). Logs result to data/slo-canaries.jsonl. After 3 consecutive failures writes data/runtime/auth-degraded.flag with diagnostic JSON and fires `auth canary degraded` via scripts/telegram-signal.sh so the next session greeting picks it up. Streak counter at data/runtime/auth-canary-streak. Mac launchd / Windows Task Scheduler runs every 5 min. Exits 0 even on probe failure so cron does not go red on transient blips. Alerting is via the streak + flag mechanism.`

```bash
#!/usr/bin/env bash
# check-auth-status.sh. auth canary for early OAuth-suspension detection.
#
# Pings Anthropic /v1/messages with a 1-token Haiku call using the active auth
# mode (OAuth vs API key) and logs the result to data/slo-canaries.jsonl.
# After 3 consecutive failures, writes data/runtime/auth-degraded.flag and
# fires a disguised-phrase Telegram signal so the next session sees it.
#
# Wired alongside the other SLO canaries. runs every 5 min. Manual run:
#   bash scripts/check-auth-status.sh
#
# Built as part of the API-key fallback infrastructure.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$REPO_ROOT/data/slo-canaries.jsonl"
RUNTIME_DIR="$REPO_ROOT/data/runtime"
DEGRADED_FLAG="$RUNTIME_DIR/auth-degraded.flag"
STREAK_FILE="$RUNTIME_DIR/auth-canary-streak"

mkdir -p "$(dirname "$LOG_FILE")" "$RUNTIME_DIR"
touch "$LOG_FILE"

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Determine mode + key
MODE_FILE="$HOME/.config/claude/auth-mode"
KEY_FILE="$HOME/.config/claude/api-key"

if [[ -f "$MODE_FILE" ]]; then
  mode="$(cat "$MODE_FILE")"
elif [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
  mode="api-key"
else
  mode="oauth"
fi

http_code="000"
ok=false
exit_code=0
error=""

if [[ "$mode" == "api-key" ]]; then
  if [[ -f "$KEY_FILE" ]]; then
    key="$(tr -d '\n' < "$KEY_FILE")"
  else
    key="${ANTHROPIC_API_KEY:-}"
  fi

  if [[ -z "$key" ]]; then
    error="no-key-loaded"
    exit_code=2
  else
    resp_file="$(mktemp)"
    http_code="$(curl -s -o "$resp_file" -w '%{http_code}' \
      -X POST https://api.anthropic.com/v1/messages \
      -H "content-type: application/json" \
      -H "anthropic-version: 2023-06-01" \
      -H "x-api-key: $key" \
      --max-time 10 \
      -d '{"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}' 2>/dev/null)" || http_code="000"
    if [[ "$http_code" == "200" ]]; then
      ok=true
    else
      ok=false
      exit_code=1
      body="$(head -c 200 "$resp_file" 2>/dev/null | tr '\n' ' ' | sed 's/"/\\"/g')"
      case "$http_code" in
        401) error="http_401_creds_bad: $body" ;;
        403) error="http_403_suspension: $body" ;;
        429) error="http_429_rate_limit: $body" ;;
        000) error="network_unreachable" ;;
        *)   error="http_${http_code}: $body" ;;
      esac
    fi
    rm -f "$resp_file"
  fi
else
  # OAuth mode. `claude auth status` is the proxy. It checks keychain creds +
  # whether the daemon thinks the org is alive.
  out="$(claude auth status --json 2>/dev/null || echo '{}')"
  if echo "$out" | grep -q '"loggedIn"[[:space:]]*:[[:space:]]*true'; then
    ok=true
    http_code="200"
  else
    ok=false
    exit_code=1
    error="oauth_logged_out: $(echo "$out" | tr '\n' ' ' | head -c 200 | sed 's/"/\\"/g')"
    http_code="401"
  fi
fi

# Manage consecutive-failure streak
if [[ "$ok" == "true" ]]; then
  echo 0 > "$STREAK_FILE"
  # Clear degraded flag on first recovery
  if [[ -f "$DEGRADED_FLAG" ]]; then
    rm -f "$DEGRADED_FLAG"
  fi
else
  prev=0
  [[ -f "$STREAK_FILE" ]] && prev="$(cat "$STREAK_FILE")"
  [[ "$prev" =~ ^[0-9]+$ ]] || prev=0
  streak=$((prev + 1))
  echo "$streak" > "$STREAK_FILE"

  if [[ "$streak" -ge 3 && ! -f "$DEGRADED_FLAG" ]]; then
    cause="unknown"
    case "$http_code" in
      401) cause="creds_bad_http_401" ;;
      403) cause="suspension_http_403" ;;
      429) cause="rate_limit_http_429" ;;
      000) cause="network_unreachable" ;;
    esac
    cat > "$DEGRADED_FLAG" <<EOF
{"ts":"$ts","mode":"$mode","streak":$streak,"http":"$http_code","cause":"$cause","error":"$error"}
EOF

    # Fire disguised-phrase signal so next session greeting picks it up.
    if [[ -x "$REPO_ROOT/scripts/telegram-signal.sh" ]]; then
      bash "$REPO_ROOT/scripts/telegram-signal.sh" "auth canary degraded" >/dev/null 2>&1 || true
    fi
  fi
fi

# Append JSONL line
jsonl_line=$(cat <<EOF
{"name":"auth-status","ts":"$ts","ok":$ok,"mode":"$mode","exit":$exit_code,"http":"$http_code","error":"$(echo "$error" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n')"}
EOF
)
echo "$jsonl_line" >> "$LOG_FILE"

# Exit 0 even on probe failure so cron does not go red on transient blips.
# alerting is via the streak + flag mechanism.
exit 0
```

---


## Template: scripts/export-blueprint.sh

`Sanitiser that strips a personal blueprint down to the public template shape. Reads blueprints/{{orchestrator_lower}}-system-v31.md by default (or --src <path>), runs sed substitutions for: real email -> {{user_email}}, full name + bare first-name -> {{user_name}}, real notebook ID -> {{brain_notebook_id}}, real Telegram chat ID -> {{telegram_chat_id}}, actual home dir -> {{home_dir}}, company name -> {{company_name}}. Prints to stdout by default or writes to --out <path>. Use this if you ever update the personal blueprint and want to re-export the public version.`

```bash
#!/bin/bash
# export-blueprint.sh. sanitise the personal blueprint for public sharing.
#
# Input:  blueprints/{{orchestrator_lower}}-system-v31.md (your personal copy with real IDs,
#         names, tokens, etc)
# Output: prints a sanitised version to stdout, OR writes to a file if you
#         pass --out <path>.
#
# Sanitisation rules:
#   - Real email + name -> {{user_email}} / {{user_name}}
#   - Real notebook ID -> {{brain_notebook_id}}
#   - Real Telegram chat ID -> {{telegram_chat_id}}
#   - Actual home dir -> {{home_dir}}
#   - Company name -> {{company_name}}
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$SCRIPT_DIR/blueprints/{{orchestrator_lower}}-system-v31.md"
OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT="$2"; shift 2 ;;
    --src) SRC="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [ ! -f "$SRC" ]; then
  echo "source blueprint not found: $SRC" >&2
  exit 1
fi

sanitise() {
  sed \
    -e 's/{{user_email_literal}}/{{user_email}}/g' \
    -e 's/{{user_name_literal}}/{{user_name}}/g' \
    -e 's/\b{{user_first_name_literal}}\b/{{user_name}}/g' \
    -e 's/{{notebook_id_literal}}/{{brain_notebook_id}}/g' \
    -e 's/{{telegram_chat_id_literal}}/{{telegram_chat_id}}/g' \
    -e 's|{{home_dir_literal}}|{{home_dir}}|g' \
    -e 's/{{company_name_literal}}/{{company_name}}/g'
}

if [ -n "$OUT" ]; then
  sanitise < "$SRC" > "$OUT"
  echo "wrote sanitised blueprint to $OUT"
else
  sanitise < "$SRC"
fi
```

Note: this template ships with placeholder `*_literal` tokens because the wizard cannot ship a sanitiser containing the user's actual values. After install, the user edits this file once to replace each `{{<thing>_literal}}` with their real value (their email address, their full name, their first name word-boundary form, etc), and after that every blueprint export round-trips correctly. The wizard prints a one-line reminder pointing here in the install summary.

---


## Template: scripts/install-launchd-wrappers.sh

`MAC ONLY. Builds AppleScript .app wrappers under ~/Applications/ that let launchd invoke the orchestrator's canary daemons WITHOUT granting Full Disk Access to /bin/bash itself. Pattern: macOS TCC blocks launchd-spawned bash from executing scripts under ~/Documents/. .plist files cannot receive FDA. .app bundles can. So we wrap each daemon (canaries, proactive trigger, morning digest, corrections review, signal fire) in a tiny AppleScript .app and grant FDA only to those bundles. After running this script, two MANUAL steps remain (user only): grant FDA to the built .apps via System Settings UI, and swap the new plists into ~/Library/LaunchAgents. Linux + Windows users SKIP THIS SCRIPT ENTIRELY. Linux uses systemd timers + cron; Windows uses Task Scheduler. Source AppleScripts live at scripts/launchd-wrappers/*.applescript.`

```bash
#!/usr/bin/env bash
# install-launchd-wrappers.sh
#
# MAC ONLY. Builds the AppleScript .app wrappers that let launchd invoke the
# orchestrator's canary + proactive-trigger daemons WITHOUT granting Full
# Disk Access to /bin/bash itself.
#
# Linux + Windows users skip this script entirely. Linux uses systemd timers
# or cron; Windows uses Task Scheduler.
#
# Output location:
#   ~/Applications/{{orchestrator_name}}-Canaries.app
#   ~/Applications/{{orchestrator_name}}-ProactiveTrigger.app
#   ~/Applications/{{orchestrator_name}}-MorningDigest.app
#   ~/Applications/{{orchestrator_name}}-CorrectionsReview.app
#   ~/Applications/{{orchestrator_name}}-SignalFire.app
#
# Source AppleScripts (committed to the repo):
#   scripts/launchd-wrappers/canaries-wrapper.applescript
#   scripts/launchd-wrappers/proactive-trigger-wrapper.applescript
#   scripts/launchd-wrappers/morning-digest-wrapper.applescript
#   scripts/launchd-wrappers/corrections-review-wrapper.applescript
#   scripts/launchd-wrappers/signal-fire-wrapper.applescript
#
# Why ~/Applications/ and not /Applications/:
#   ~/Applications/ is unprivileged. no sudo needed, no codesign re-trust
#   when the bundle is rebuilt. Same precedent as Chrome's user-scope apps.
#
# After this script runs, two MANUAL steps remain ({{user_name}} only):
#   1. Grant Full Disk Access to BOTH built .apps (System Settings UI)
#   2. Swap the new plists in (scripts/launchd-wrappers/new-*.plist) and reload
#
# See docs/launchd-wrapper-setup.md for the exact UI walkthrough.
#
# Idempotent. re-running rebuilds both .apps in place.

set -euo pipefail

# Refuse to run on non-Mac.
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "install-launchd-wrappers.sh is Mac-only. Skipping on $(uname -s)." >&2
  exit 0
fi

REPO_ROOT="{{project_path}}"
SRC_DIR="$REPO_ROOT/scripts/launchd-wrappers"
APPS_DIR="$HOME/Applications"

CANARIES_APP="$APPS_DIR/{{orchestrator_name}}-Canaries.app"
PROACTIVE_APP="$APPS_DIR/{{orchestrator_name}}-ProactiveTrigger.app"
MORNING_DIGEST_APP="$APPS_DIR/{{orchestrator_name}}-MorningDigest.app"
CORRECTIONS_REVIEW_APP="$APPS_DIR/{{orchestrator_name}}-CorrectionsReview.app"
SIGNAL_FIRE_APP="$APPS_DIR/{{orchestrator_name}}-SignalFire.app"

mkdir -p "$APPS_DIR"

build_app() {
  local applescript="$1"
  local app_path="$2"
  local label="$3"

  if [ ! -f "$applescript" ]; then
    echo "error: source AppleScript not found: $applescript" >&2
    return 1
  fi

  # If already built, remove first. osacompile will not overwrite a bundle.
  if [ -d "$app_path" ]; then
    echo "  removing existing $app_path"
    rm -rf "$app_path"
  fi

  echo "  compiling $label -> $app_path"
  /usr/bin/osacompile -o "$app_path" "$applescript"

  # Ad-hoc codesign so macOS does not quarantine-block the bundle on first
  # launch. The "-" identity is the local ad-hoc signer. Fine for personal
  # tooling, would NOT be fine for distribution.
  echo "  ad-hoc signing $label"
  /usr/bin/codesign --deep --force --sign - "$app_path"

  # Verify the applet exists at the expected internal path. If this fails,
  # osacompile silently produced a broken bundle (rare but seen).
  if [ ! -x "$app_path/Contents/MacOS/applet" ]; then
    echo "error: $app_path/Contents/MacOS/applet missing or not executable" >&2
    return 1
  fi

  echo "  ok $label built. applet=$app_path/Contents/MacOS/applet"
}

echo "Building launchd-wrapper .apps..."
echo

echo "[1/5] {{orchestrator_name}}-Canaries"
build_app "$SRC_DIR/canaries-wrapper.applescript" "$CANARIES_APP" "{{orchestrator_name}}-Canaries"
echo

echo "[2/5] {{orchestrator_name}}-ProactiveTrigger"
build_app "$SRC_DIR/proactive-trigger-wrapper.applescript" "$PROACTIVE_APP" "{{orchestrator_name}}-ProactiveTrigger"
echo

echo "[3/5] {{orchestrator_name}}-MorningDigest"
build_app "$SRC_DIR/morning-digest-wrapper.applescript" "$MORNING_DIGEST_APP" "{{orchestrator_name}}-MorningDigest"
echo

echo "[4/5] {{orchestrator_name}}-CorrectionsReview"
build_app "$SRC_DIR/corrections-review-wrapper.applescript" "$CORRECTIONS_REVIEW_APP" "{{orchestrator_name}}-CorrectionsReview"
echo

echo "[5/5] {{orchestrator_name}}-SignalFire"
build_app "$SRC_DIR/signal-fire-wrapper.applescript" "$SIGNAL_FIRE_APP" "{{orchestrator_name}}-SignalFire"
echo

echo "Verifying codesign..."
/usr/bin/codesign -dvv "$CANARIES_APP" 2>&1 | head -5 || true
echo
/usr/bin/codesign -dvv "$PROACTIVE_APP" 2>&1 | head -5 || true
echo
/usr/bin/codesign -dvv "$MORNING_DIGEST_APP" 2>&1 | head -5 || true
echo
/usr/bin/codesign -dvv "$CORRECTIONS_REVIEW_APP" 2>&1 | head -5 || true
echo
/usr/bin/codesign -dvv "$SIGNAL_FIRE_APP" 2>&1 | head -5 || true
echo

cat <<NEXT_STEPS
================================================================
Build complete. Manual steps remain ({{user_name}}, NOT the orchestrator):

1) GRANT FULL DISK ACCESS to ALL five built .apps:
     System Settings -> Privacy & Security -> Full Disk Access
     Click "+" and add each of:
       ~/Applications/{{orchestrator_name}}-Canaries.app
       ~/Applications/{{orchestrator_name}}-ProactiveTrigger.app
       ~/Applications/{{orchestrator_name}}-MorningDigest.app
       ~/Applications/{{orchestrator_name}}-CorrectionsReview.app
       ~/Applications/{{orchestrator_name}}-SignalFire.app
     Toggle ALL switches ON.

2) SWAP IN THE NEW PLISTS and reload launchd:
     # Canaries + proactive (existing):
     cp scripts/launchd-wrappers/new-com.{{orchestrator_lower}}.canaries.plist \\
        ~/Library/LaunchAgents/com.{{orchestrator_lower}}.canaries.plist
     cp scripts/launchd-wrappers/new-com.{{orchestrator_lower}}.proactive-trigger.plist \\
        ~/Library/LaunchAgents/com.{{orchestrator_lower}}.proactive-trigger.plist
     bash scripts/canaries-daemon.sh reload
     bash scripts/proactive-daemon.sh reload

     # Morning digest + corrections review (new):
     cp scripts/launchd-wrappers/new-com.{{orchestrator_lower}}.morning-digest.plist \\
        ~/Library/LaunchAgents/com.{{orchestrator_lower}}.morning-digest.plist
     cp scripts/launchd-wrappers/new-com.{{orchestrator_lower}}.corrections-review.plist \\
        ~/Library/LaunchAgents/com.{{orchestrator_lower}}.corrections-review.plist
     launchctl bootstrap gui/\$(id -u) \\
        ~/Library/LaunchAgents/com.{{orchestrator_lower}}.morning-digest.plist
     launchctl bootstrap gui/\$(id -u) \\
        ~/Library/LaunchAgents/com.{{orchestrator_lower}}.corrections-review.plist

     # (Signal-fire system removed in v31. See system blueprint section
     # "Removed in v31" for the rationale. Do not reintroduce any
     # signal-schedule.sh / signal-fire-* scripts without an explicit
     # reactivation decision.)

3) VERIFY:
     # Canaries within 5 min:
     launchctl print gui/\$(id -u)/com.{{orchestrator_lower}}.canaries | grep 'last exit'
     # Morning-digest fires at 08:07 local; to test immediately:
     launchctl kickstart -k gui/\$(id -u)/com.{{orchestrator_lower}}.morning-digest
     launchctl print gui/\$(id -u)/com.{{orchestrator_lower}}.morning-digest | grep 'last exit'
     # Same for corrections-review (fires Mondays at 08:37 local):
     launchctl kickstart -k gui/\$(id -u)/com.{{orchestrator_lower}}.corrections-review
     # Exit code 0 = FDA granted correctly. 126 = FDA not applied yet.

Full walkthrough: docs/launchd-wrapper-setup.md
================================================================
NEXT_STEPS
```

Note: this template uses NEXT_STEPS heredoc UNQUOTED so the `\$(id -u)` interpolation deferral works correctly. Backslashes added throughout to defer shell expansion until the heredoc emits its contents to stdout. Linux + Windows users skip the entire script. their canary scheduling lives in systemd timers / Task Scheduler respectively (see the auth-failover Task Scheduler XML and the systemd timer template earlier in this file).

---


## Template: scripts/regenerate-setup-checklist.sh

`Tiny stub helper. Used when a new extension is installed or a component is upgraded that needs verification, to re-write SETUP-CHECKLIST.md based on the current state of .{{orchestrator_lower}}-blueprint-version. Body is fully inlined in the landing wizard at xantham-system-v31.md (Generation Order Step 17 area, "for when new components arrive" section). No separate body needed here. The wizard reads that section, writes the file at install time, and the install summary points the user back here if they want to extend it. If you want to swap the stub for a richer regeneration script later, the entry point pattern is: parse .{{orchestrator_lower}}-blueprint-version, list installed components, emit one checklist item per component into a new SETUP-CHECKLIST.md.`

```bash
#!/usr/bin/env bash
# regenerate-setup-checklist.sh. re-write SETUP-CHECKLIST.md based on
# the current state of .{{orchestrator_lower}}-blueprint-version. Used when a new
# extension is installed or a component is upgraded that needs verification.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Regenerating SETUP-CHECKLIST.md based on installed components..."
echo "Open a fresh Claude Code session at $REPO_ROOT and run:"
echo ""
echo "  Read .{{orchestrator_lower}}-blueprint-version. Regenerate SETUP-CHECKLIST.md per"
echo "  the Post-install verification section of the public blueprint,"
echo "  including a checklist item for every component currently installed."
```
