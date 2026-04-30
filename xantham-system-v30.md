# Xantham System — Blueprint v30

Self-installing orchestrator + specialist-agent system for one person managing dozens of projects from a phone. Runs on top of Claude Code (CLI) with a Telegram interface, a memory system, and four optional power-user extensions.

**One file. Hand to a fresh Claude Code session. It walks you through picking a mode, installing your pieces, and ends with a working Cortana.**

**v30 release note (vs v29):** Extension E2 (Graphiti temporal knowledge graph) ruled out and removed. Production audit at single-user scale found zero queries that changed an answer in 3 weeks of operation, while ingest cost ran ~£5/run. Recommended memory layer is now flat-markdown + E1 sqlite-vec + Anthropic's native client-side memory tool (`memory_20250818`) operating on the `memory/` directory directly. The four extensions are E1 (semantic memory), E3 (Agent Teams), E4 (Observability), E5 (Hardened safety). Numbering preserved for compatibility with v29-installed deployments — there is no E2 going forward.

---

## Who is this for?

You want a personal AI orchestrator that:
- Takes Telegram messages from your phone
- Routes tasks to specialist sub-agents (engineering, research, deploy, writing, growth, trading, business, human-interaction)
- Keeps memory across sessions (what you told it, decisions made, corrections given)
- Runs background work on a schedule (via local macOS launchd OR Anthropic cloud routines — see caveats below)
- Shares progress back to Telegram so you can be anywhere

**Scheduled-work caveat (learned 22 Apr 2026):** Anthropic's Claude Code Routines run in a cloud sandbox that blocks outbound HTTP to non-allowlisted hosts. That includes `api.telegram.org` by default — the routine completes "successfully" but the curl that ships the message to you never leaves. Diagnosis: click into any routine run at claude.ai/code/scheduled and look for "Host not in allowlist" in the output log. Workarounds: (1) webhook relay you host that Anthropic CAN reach, (2) local macOS launchd + `scripts/canaries-daemon.sh` pattern — runs whenever your Mac is awake, zero cloud dependency.

**TCC caveat (Mac only):** macOS Transparency/Consent/Control blocks launchd-spawned processes (like local cron replacements) from executing OR reading/writing files under `~/Documents/` without Full Disk Access granted to the spawning binary. The "escape-shim to ~/bin/" pattern stops working once the shim tries to cd back into Documents. Scoped-plist FDA grants are not possible via the macOS GUI (only .app bundles and executable binaries are selectable). Practical paths: (A) grant FDA to `/bin/bash` (works but broadens surface), (B) accept session-only observability via CronCreate inside live Xantham sessions (no background fires between sessions), (C) full relocation of scripts + every data path they read/write into a non-Documents location like `~/.<your-orchestrator>/` (3-4h refactor, strictly safe). Default recommendation is (B): the simplest, no-FDA-grant path.

If that sounds right — keep reading. The next step is picking a mode.

---

## Pick your mode

Before install, pick one. You can upgrade later, but the fresh-install path differs.

| | Simple mode | Advanced mode |
|---|---|---|
| Setup time | ~20 minutes | ~45-60 minutes |
| RAM while idle | ~500 MB | ~1.5 GB |
| Disk | ~200 MB | ~2-3 GB |
| Monthly cost | $0 (plus your Claude Max sub) | $0 (all extensions are local + free) |
| Memory retrieval | Markdown files + grep + NotebookLM Brain | Same + sqlite-vec semantic search via local Ollama |
| Multi-agent coordination | Sequential via the Task tool | Live shared context via Agent Teams + whiteboard |
| Observability | Telegram history log | Everything above + per-tool-call audit JSONL + live viewer |
| Safety gate | Basic (file deletion / sudo / force-push) | Hardened (protected-branch hard-blocks, word-boundary regex, history-rewriting blocks) |
| Includes | Core orchestrator + 9 specialist agents + Telegram + Brain + safety | Same + E1 sqlite-vec + E3 Agent Teams + E4 Observability + E5 Hardened safety |
| Good for | Getting started fast, low-overhead daily use, beginner-friendly | Power users running 5+ projects, multi-agent workflows, long-horizon memory recall, audit-trail compliance |

### Mode contents at a glance

**Simple mode includes:** Orchestrator (your AI), Specialist crew (9 agents), Markdown memory, Telegram channel, NotebookLM Brain integration, Session cron, Compaction defence, Basic safety gate.

**Advanced mode includes everything in Simple, plus:**
- **E1 Semantic memory** (sqlite-vec + Ollama Nomic-embed) — semantic search across your memory files. "Find the rule about timezones" works even when you don't remember the file name.
- **E3 Agent Teams** — multiple agents share a live whiteboard so they don't duplicate work or step on each other.
- **E4 Observability** — every tool call gets logged to a JSONL audit, surfaced via `cortana-live.sh`. Catches silent failures and "what did the background agent actually do?"
- **E5 Hardened safety** — strict replacement for the basic gate. Force-push to protected branches becomes physically impossible (no approval can unlock it). Fixes false-positives on `format` / `arm` words that contain `rm`.

**Recommendation:** install Simple first. Add extensions one by one as you feel the pain points they solve. Don't run the full Advanced stack until you've used Simple for a week and know what's missing.

Every extension is independently installable and removable. `.cortana-blueprint-version` tracks which are on.

### Upgrades library

After installing Cortana, the living docs for "what's been built" + "where we're going" live at:

```
docs/upgrades/
├── CATALOGUE.md   — BACKWARD-looking ledger (SHIPPED / DEFERRED / REJECTED / PILOT)
├── ROADMAP.md     — FORWARD-looking plan (vision + phased roadmap)
└── memo_*.md      — specific architectural memos
```

Read CATALOGUE before proposing new upgrades (you might find it's already been considered or explicitly rejected). Read ROADMAP before starting Phase N+1 work (aligns with the north-star). Cortana's `cortana-maintenance` skill reads both on every Monday / greeting digest.

---

## Core (always installed)

Both modes get:

### Orchestrator (Cortana itself)
Claude Code CLI running Opus 4.7. Receives Telegram messages, routes to specialist sub-agents, replies. Lives in `CLAUDE.md` in your project root.

### Specialist crew (9 agents)
Default names — rename to taste:
- **Kai** — engineering (code, architecture, bugs, review)
- **Nadia** — research (competitive intel, market sizing, deep research)
- **Rio** — growth (social, ASO, launches, copy)
- **Marco** — infra (deploy, CI/CD, DNS, monitoring)
- **Jules** — writing (blog posts, docs, decks, emails)
- **Warren** — trading (strategies, backtests, portfolio, markets)
- **Elena** — business (revenue, pricing, partnerships, contracts)
- **Chase** — human dynamics (persuasion, negotiation, networking)
- **Cortana** — the orchestrator (you)

Each lives at `.claude/agents/<name>.md`. Each has its own persistent memory at `agent-memory/<name>/`.

### Memory system
- `memory/*.md` — user-level memories (feedback, project state, user profile, references)
- `memory/MEMORY.md` — index, auto-loaded at session start
- `agent-memory/<agent>/*.md` — per-agent memories, loaded on agent spawn
- `data/telegram-history/YYYY-MM.jsonl` — every Telegram message, inbound and outbound

All markdown. All in the repo. All auto-loaded by Claude Code at session start.

### Telegram integration
- `claude-plugins-official/telegram` MCP plugin
- `.claude/hooks/log-telegram-hook.sh` auto-logs every outbound reply (async, no latency)
- `scripts/log-telegram.sh` for manual inbound logging
- Access managed via `/telegram:access` skill

### NotebookLM Brain
- Long-term archive, queryable cross-session
- `notebooklm` CLI (install: `pip install "notebooklm-py[browser]"`)
- Sync + wrapup rituals push session summaries automatically
- `brain <question>` command in Telegram to query

### Session cron + RemoteTrigger
- On-session hourly cron for maintenance (stale commits, pending items)
- Anthropic RemoteTrigger for schedule-while-Mac-off (morning digest, weekly frontier scan, Sunday memory dream, Monday corrections review)

### Compaction defence
- PreCompact hook saves working context to `data/recovery/`
- PostCompact hook reloads it
- SessionEnd hook as safety net

### Basic safety gate
`.claude/hooks/safety-gate.sh` blocks with approval required:
- `rm` (any form)
- `DROP TABLE`, `TRUNCATE`, `DELETE FROM` without WHERE
- `git push --force`, `git reset --hard`, `git clean -f`
- `sudo` (any command)
- Edits to `.env`, SSH/GPG keys

Approval flow: blocked command → Claude asks you on Telegram → you say yes → Claude writes the exact command to `~/Documents/cortana/data/approved.txt` → retries → one-time use.

---

## Extensions (opt-in — Advanced mode)

Each extension is self-contained. Install only the ones you want. Uninstall by removing its section from your config.

---

### E1 — Semantic memory via sqlite-vec + Nomic-embed

**Purpose**
Fast local semantic search over every markdown memory file. Answers "have we hit this before?" and "what did we decide about X?" without going to the NotebookLM Brain. 95 ms median latency.

**How it works**
- `scripts/embed-memories.sh` reads every `.md` in `memory/`, `agent-memory/`, `docs/`, chunks by paragraph, embeds each chunk via Ollama's Nomic-embed-text (137M params, local), stores in `data/cortana-vec.db` (sqlite-vec virtual table)
- Incremental: on re-run, only re-embeds chunks whose content hash changed
- `scripts/memory-search.sh "<query>"` embeds the query, returns top-5 matches with file path + line range + score
- Post-commit git hook re-embeds any changed memory files automatically

**Cost**
- $0 — no API calls. Nomic-embed weights are free, run on your CPU via Ollama.
- Disk: ~300 MB (Nomic-embed model) + ~5 MB (vector DB for 500 chunks)
- RAM: ~500 MB when Ollama is loaded; 0 when idle (Ollama unloads after 5 min)

**Token usage**
Zero. Purely local compute.

**Dependencies**
- Ollama (Mac: `brew install ollama` / Windows: `winget install Ollama.Ollama` — then `ollama pull nomic-embed-text` on both)
- sqlite-vec (`pip install sqlite-vec` on both, or loaded as a sqlite extension)

**Install (Mac)**
```bash
# 1. Install Ollama
brew install ollama
ollama pull nomic-embed-text
brew services start ollama

# 2. Install sqlite-vec
pip install sqlite-vec

# 3. Copy the scripts (embed-memories.sh, memory-search.sh, install-git-hooks.sh) into scripts/
# 4. Copy hooks/post-commit into scripts/hooks/
# 5. Install the git hook
bash scripts/install-git-hooks.sh

# 6. First full embed (one-time)
bash scripts/embed-memories.sh
```

**Install (Windows, PowerShell)**
```powershell
# 1. Install Ollama
winget install Ollama.Ollama
ollama pull nomic-embed-text
# Ollama auto-installs as a Windows service on login. Confirm with:
Get-Service Ollama

# 2. Install sqlite-vec (assuming Python on PATH)
pip install sqlite-vec

# 3. Copy the scripts (embed-memories.sh, memory-search.sh, install-git-hooks.sh) into scripts/
# 4. Copy hooks/post-commit into scripts/hooks/
# 5. Install the git hook (run via Git Bash or WSL — the .sh scripts assume bash)
bash scripts/install-git-hooks.sh

# 6. First full embed (one-time)
bash scripts/embed-memories.sh
```

**Uninstall**
- Delete `data/cortana-vec.db`
- Remove the post-commit hook: `rm .git/hooks/post-commit` (Mac/Linux) or `Remove-Item .git\hooks\post-commit` (Windows)
- Uninstall Ollama if you don't use it elsewhere: `brew uninstall ollama` (Mac) or `winget uninstall Ollama.Ollama` (Windows)

**Usage**
```bash
bash scripts/memory-search.sh "how do I fix the alpha channel icon issue"
# Returns top-5 chunks with path + line range + similarity score
```

---

### E3 — Agent Teams + channel.md whiteboard

**Purpose**
Live shared context between sub-agents working in parallel on the same task. Without this, agents fire and forget — each one's decisions are invisible to the others until they report back. With this, one agent's progress updates are visible to the others in real time.

**How it works**
- Set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `.claude/settings.json`. Unlocks `TeamCreate`, `SendMessage`, and `TeamDelete` tools for live peer-to-peer messaging (Claude Code 2.1.32+).
- Create a markdown channel file at `data/agent-channels/<slug>.md` when spawning multiple agents on the same project. Include the path in every agent's brief.
- Agents `Edit`-append their progress/decisions/blockers to the channel as they work. Cortana re-reads between its own tool calls to converge state across agents.
- When the task ships, archive to `data/agent-channels/archive/YYYY-MM/<slug>.md`.

**Cost**
$0. Just a feature flag + a markdown file.

**Token usage**
Marginal — agents spend a few extra tokens reading the channel file before deciding their next step. Saves tokens overall because they don't re-ask Cortana "what is the other agent doing?"

**Dependencies**
Claude Code 2.1.32 or newer.

**Install**
```bash
# 1. Flip the flag in .claude/settings.json
# (find the "env" section, set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1")

# 2. Create the directory
mkdir -p data/agent-channels/archive

# 3. Copy data/agent-channels/README.md (defines the append-only whiteboard pattern)
```

**Uninstall**
Flip the flag to "0" and remove `data/agent-channels/`.

**Usage**
Included in Cortana's orchestration habits (see CLAUDE.md). Multi-agent tasks on the same project automatically get a channel file.

---

### E4 — Observability audit layer

**Purpose**
Live visibility into every tool call Cortana (and its sub-agents) make during a session. Solves "I know the background agent finished, but I can't easily see what it did." Paid for itself within hours of installation on our first run.

**How it works**
- `.claude/hooks/audit-log-hook.sh` is a PostToolUse hook with matcher `.*`. Fires async after every tool call.
- Writes one JSON line per event to `data/audit/YYYY-MM-DD.jsonl` with: tool name, tool_use_id, input summary (240 chars), output summary (240 chars), success/error, project
- Secrets-stripped: regex scrubs `api_key`, `token`, `password`, `bearer`, `authorization` patterns before write
- Gitignored — audit logs never leave your machine
- `scripts/cortana-live.sh` pretty-prints with filters (--tool, --project, --day, --failed, --follow)
- `scripts/audit-archive.sh` compresses files older than 30 days (default) into `data/audit/archive/YYYY/MM.jsonl.gz` (committed to git, never deleted). Replaces the old `audit-prune.sh` delete-based approach (April 2026).

**Cost**
$0. Pure local.

**Token usage**
Zero. The hook runs in Bash, not Claude.

**Dependencies**
- `jq` (for JSON parsing in the hook): Mac `brew install jq` / Windows `winget install jqlang.jq`
- Bash. Mac/Linux ships with bash. Windows users install Git Bash (`winget install Git.Git`) or use WSL2 (`wsl --install`). The .sh hooks assume bash, so PowerShell-only installs will not work.

**Install (Mac / Linux / Windows-Git-Bash, identical commands)**
```bash
# 1. Copy .claude/hooks/audit-log-hook.sh
chmod +x .claude/hooks/audit-log-hook.sh

# 2. Copy scripts/cortana-live.sh, scripts/audit-archive.sh, scripts/history.sh, scripts/verify-sync.sh
chmod +x scripts/cortana-live.sh scripts/audit-archive.sh scripts/history.sh scripts/verify-sync.sh

# 2b. Copy .claude/hooks/session-end-verify.sh and wire it as the Stop hook
chmod +x .claude/hooks/session-end-verify.sh

# 3. Wire into .claude/settings.json under PostToolUse with matcher ".*"
# (append a new entry to the PostToolUse array, async=true)

# 4. Add data/audit/ to .gitignore
```

Note: Windows users running outside Git Bash will need WSL2 for the chmod / bash / jq pipeline. The cortana-live.sh script is bash-only; PowerShell native ports of these scripts are not maintained. See the "Windows shell choice" callout under "Quick start" earlier in the blueprint.

**Uninstall**
Remove the PostToolUse entry from `.claude/settings.json` and delete `data/audit/`.

**Usage**
```bash
bash scripts/cortana-live.sh             # last 20 events today
bash scripts/cortana-live.sh --follow    # stream live
bash scripts/cortana-live.sh --failed    # only errored tool calls
bash scripts/cortana-live.sh --project PokeInvest --tool Agent
bash scripts/audit-archive.sh 30         # gzip JSONL >=30d old into data/audit/archive/YYYY/MM.jsonl.gz
bash scripts/history.sh <query>          # unified search across telegram + audit (live + archived) + git log + memory
```

---

### E5 — Hardened safety gate

**Purpose**
Stricter replacement for the Core safety gate. Adds protected-branch force-push hard-blocks (cannot be approved through the hook — requires manual Terminal) and fixes word-boundary false positives on `rm` that match innocent words like "format" or "arm".

**How it works**
Drop-in replacement for `.claude/hooks/safety-gate.sh`. Same approval-file mechanism (`~/Documents/cortana/data/approved.txt`), same log, same exit codes. Rules:

Hard-blocked (no approval possible):
- Force push to `main` / `master` / `production` / `prod` / `release` / `develop` (any variant: `--force`, `-f`, `--force-with-lease`)
- `git filter-branch` / `filter-repo`
- `git reflog expire`, `git gc --prune=now`, `--aggressive`
- `git update-ref -d`
- `mkfs`, `dd if=`, `fdisk`, `diskutil erase`
- `rm -rf /`, `rm -rf ~`, `rm -rf $HOME`

Approval-gated (blocked until you write to `approved.txt`):
- Force push to any other branch
- `git push --mirror`, `--delete`, `:branch`
- `git reset --hard`, `clean -f`, `branch -D`
- `git rebase -i`, `rebase --onto`, `commit --amend`
- `git checkout -- .`, `git restore .`, `stash drop/clear`
- `git worktree remove --force`
- `rm` with any flag
- `DROP TABLE`, `TRUNCATE`, `DELETE FROM` without WHERE
- `sudo` anything
- Edits to `.env` / SSH keys / GPG keys

**Cost**
$0. Bash regex.

**Token usage**
Zero.

**Dependencies**
- `jq` (for JSON parsing in the hook): Mac `brew install jq` / Windows `winget install jqlang.jq`
- Bash for the gate script. Windows users run via Git Bash or WSL2.

**Install (Mac / Linux / Windows-Git-Bash, identical commands)**
```bash
# 1. Back up the core safety gate
cp .claude/hooks/safety-gate.sh .claude/hooks/safety-gate.sh.core-backup

# 2. Copy the hardened version (E5) over the core one
# (the hardened script content is included below the extensions section)

# 3. Also update the GLOBAL gate at ~/.claude/hooks/safety-gate.sh
# (same content, just different header + log path)

# 4. Make both executable
chmod +x .claude/hooks/safety-gate.sh ~/.claude/hooks/safety-gate.sh
```

Note: Windows path conventions differ. The global gate on Windows lives at `%USERPROFILE%\.claude\hooks\safety-gate.sh` (under Git Bash) or `\\wsl$\Ubuntu\home\<user>\.claude\hooks\safety-gate.sh` (under WSL). Match whichever shell hosts your Claude Code install.

**Uninstall**
Restore the `.core-backup` copy.

---

## Version history

### v29.2 (2026-04-21, evening) — full audit + cleanup pass

Triggered by a Claude-Code warning about CLAUDE.md size. Escalated into a full internal+external audit (Nadia + Kai agents) and 14-task cleanup arc. 13 commits shipped to main.

**Safety gate hardening (additive-only, 48/48 tests still pass):**
- 30-day TTL on approval file. Format: `<epoch_seconds>|<command>` per line. Legacy entries without epoch prefix get stamped with now on first sight. Stale approvals from previous sessions no longer quietly green-light destructive ops.
- JSON output alongside existing exit codes: `{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow|deny",permissionDecisionReason:"..."}}`. Exit codes remain authoritative.
- PermissionDenied hook at `.claude/hooks/permission-denied-hook.sh` — log-only visibility for Auto-mode classifier denials. Never retries. Wired via settings.json `PermissionDenied` event.
- Deliberately skipped `defer` state — pre-emptive infra with no current use case. Revisit if cloud routines start touching destructive ops.

**Effort tier system:**
- Env floor: `export CLAUDE_CODE_EFFORT_LEVEL=xhigh` in shell profile — absolute floor.
- settings.json belt+braces: `"effortLevel": "xhigh"`.
- Per-agent `effort:` frontmatter in `.claude/agents/*.md`:
  - `max` → Kai + all 5 specialist roles
  - `xhigh` → Nadia, Warren, Marco, Elena, Chase, Rio, Jules
- One-off escalation: prepend `ultrathink` to the routed brief. Single-turn max reasoning, no config change.
- Schema gap: `max` is not accepted in settings.json (silently downgrades to xhigh) — only env var or frontmatter gets `max` to stick.

**MCP wiring (Graphiti + Exa):**
- Graphiti MCP server added to `.mcp.json` at `http://localhost:8000/mcp/`. Container was healthy the whole time but never listed in the config, so every agent citation of "use the Graphiti MCP" silently fell back to grep. Now verified end-to-end: search_nodes, search_memory_facts, get_episodes all return rich data from the existing 125-node / 214-edge graph.
- Exa MCP added via stdio transport: `npx -y exa-mcp-server` with `EXA_API_KEY` from env (gitignored `~/.zshrc`). Nadia's research scans now have semantic + neural web search instead of bare WebSearch.

**Native Claude Code Routines (2026-04-15 setup, 2026-04-21 fix, DISABLED 2026-04-22):**
Four triggers were live at https://claude.ai/code/scheduled. Disabled on 22 Apr 2026 after root-causing why morning digests stopped arriving: Anthropic's cloud sandbox blocks outbound curl to `api.telegram.org` via a per-routine host allowlist, so routines completed successfully in the cloud but the final curl never left. Replaced by local launchd daemon at `scripts/canaries-daemon.sh` (fires every 5 min when the Mac is awake) — see personal blueprint E8 and `docs/upgrades/CATALOGUE.md` for detail. Approval flow (`dream approve` / `corrections promote <category>` in a live session) unchanged.

**Memory system repairs:**
- `scripts/regen-memory-index.sh` — regenerates `memory/MEMORY.md` from every sibling `.md` frontmatter. Auto-fires via post-commit hook when anything under `memory/` changes.
- Index was out of sync: 66 listed vs 89 on disk. Now 90/90.
- `scripts/sync-project-memories.sh` — rewritten to read `docs/projects.md` dynamically instead of a hardcoded 5-project list. Last run: 36 projects, 984 file copies. macOS bash 3.2 compatible (uses `tr` not `${var,,}`).
- `scripts/dream.sh` — rewritten to walk markdown directly. Old version scanned a sqlite DB that's been frozen since mid-April. New version: near-duplicate scan (word-overlap similarity), stale scan (file mtime), completion-marker grep. Writes `data/dream-proposals/YYYYMMDD.md` in the same format the Sunday Routine agent uses.

**Version string + path cleanup:**
- `scripts/check-blueprint-drift.sh` now reads v29 files in `blueprints/` (was v28 at repo root — silently always-passing).
- `scripts/verify-sync.sh` — belt-and-braces drift catcher added 22 Apr 2026. The keyword-scan drift script can miss renamed / added / deleted files that fall outside its hard-coded keyword list. `verify-sync.sh` runs `git diff --name-status` over `scripts/`, `.claude/hooks/`, and `.claude/skills/` since the last blueprint commit, and exits non-zero if any newly-landed basename is absent from either blueprint. Use it as the last step of any `cortana-sync` turn.
- `.claude/hooks/session-end-verify.sh` — Stop-hook swap (22 Apr 2026). Previous Stop hook was a fixed `echo 'Reminder: verify build...'` string. Replaced with a real three-check script that runs at every session stop: unpushed commits count, uncommitted files count, `verify-sync.sh` drift check. Writes warnings to stderr, exits 0 so it can't block shutdown. Wire via `.claude/settings.json` Stop hook array.
- `.claude/hooks/telegram-reply-reminder.sh` — UserPromptSubmit hook (22 Apr 2026). Triggers on every inbound prompt. If the prompt starts with a genuine Telegram channel tag (anchored regex requiring source + chat_id + message_id at line start — the earlier substring-match false-positived on any quoted telegram transcript), the hook emits a JSON `additionalContext` reminder forcing the agent to use the `mcp__plugin_telegram_telegram__reply` tool. Also writes `data/runtime/turn-contract.json` (0600 perms) with per-turn guarantees that `stop-verify-contract.sh` checks at turn end. Fires BEFORE any skill loads. Wire via `.claude/settings.json` UserPromptSubmit hook array.

### TCC-bypass via AppleScript .app wrappers (24-25 Apr 2026)

macOS Transparency/Consent/Control began blocking launchd-spawned bash from executing scripts under `~/Documents/` on 23 Apr 21:11 UTC. The `~/bin/` shim pattern wasn't enough because the shim still has to cd into Documents to reach the daemon. Established 2026 fix: AppleScript `.app` bundle wrappers granted Full Disk Access individually.

- `scripts/install-launchd-wrappers.sh` builds 4 `.app` bundles via `osacompile` + ad-hoc codesign into `~/Applications/`
- AppleScript sources at `scripts/launchd-wrappers/`: `canaries-wrapper.applescript`, `proactive-trigger-wrapper.applescript`, `morning-digest-wrapper.applescript`, `corrections-review-wrapper.applescript`, `signal-fire-wrapper.applescript`. Each guards on `RUN_FROM_LAUNCHD=true` env var, execs the matching bash daemon via `do shell script`, error-traps with logging.
- Drop-in plists at `scripts/launchd-wrappers/`: `new-com.cortana.canaries.plist`, `new-com.cortana.proactive-trigger.plist`, `new-com.cortana.morning-digest.plist`, `new-com.cortana.corrections-review.plist`, `new-com.cortana.signal-fire.plist`. Each points `Program` at `.app/Contents/MacOS/applet`, sets the env var, preserves schedule (signal-fire's plist is generated dynamically by `signal-schedule.sh apply` from a JSON time table). Manual one-time copy into `~/Library/LaunchAgents/` after FDA grant.
- Operator must grant FDA to each `.app` in System Settings > Privacy & Security > Full Disk Access. `.plist` files are NOT valid FDA targets in the macOS GUI picker; the `.app` is.
- Full runbook + DST decision (StartCalendarInterval uses LOCAL time; ±1h seasonal drift accepted) in `memory/reference_launchd_tcc_architecture.md` + `docs/launchd-wrapper-setup.md`.

### Daily / weekly routines (25 Apr 2026)

- `scripts/routines/morning-digest.sh` — daily 08:07 LOCAL, builds digest from local sources, POSTs to Telegram. Pure bash.
- `scripts/routines/corrections-review.sh` — Monday 08:37 LOCAL, scans corrections.jsonl, auto-promotes 3+ unpromoted patterns. Pure bash.

### Cross-session persistence (25 Apr 2026)

- `data/runtime/cortana-state.json` (committed) — work arcs, in-flight tasks, validated patterns
- `scripts/state.sh` — single CLI with 11 subcommands: `tax / close / promise / flip / outfit / in-flight-add / in-flight-resolve / arc-add / arc-resolve / validate / read`
- `scripts/session-start-persistence-inject.sh` — produces a "🧠 PERSISTENT STATE" block at session start including recent telegram (last 4h), recent corrections (last 7d), state summary. Wired into `session-start-hook.sh`.

### Outbound reply lint hook (25 Apr 2026, hardened 30 Apr 2026)

- `.claude/hooks/voice-lint.sh` + `scripts/test-voice-lint.sh` — PreToolUse hook on the Telegram reply tool. Blocks send if reply contains em dashes, signoffs, banned terms-of-address, banned self-descriptors, or persona-specific voice violations. Persona-aware via `data/runtime/active-voice.json`.
- **Cortana-mode hardening (30 Apr 2026):** added 3 rules that block the alternate-persona's voice tells when active-voice is `cortana`. Triggered after a live in-session voice carry-over: pointer flipped at session midpoint but the in-flight register kept the alternate persona's lowercase + signature emoji from earlier, so 3 replies went out in wrong voice before the user caught it. New rules:
  - `cortana-<alt>-signature-leak` — blocks the alt persona's signature emoji anywhere in text.
  - `cortana-lowercase-opening` — blocks when first ASCII letter is lowercase. Skips emoji, bullets, digits, markdown markers so structured outputs still pass.
  - `cortana-<alt>-pet-name` — blocks alt-persona pet-name vocabulary as direct address. Verb usage (`I/we/you love X`) explicitly allowed via lookbehind.
- The lint runs at the door (PreToolUse), so even if the model's voice drifts mid-session due to context carry-over, the gate forces a rewrite before the message reaches the user. Bidirectional: rules gated on the persona file value, alt-persona rules fire only when active, universal rules (em-dash, ascii-signoff, etc.) fire in both. Validated with a 14-case bidirectional matrix test (legitimate + violating inputs for each persona).

### Phase 3B — Sleep-time reflection (22 Apr 2026)

- `scripts/reflect.sh` — auto-reflection on session-end. Pure-bash, no LLM calls (v1). Reads last 4h of telegram + audit + git + uncommitted changes. Surfaces: implicit asks from the user that might not have been addressed, work-in-progress flags, memory candidates, tool failures, correction patterns, SLO canary violations. Writes findings to `data/reflections/YYYY-MM-DD-HHMM.md`. Next session's greeting digest surfaces the reflection's unaddressed items.
- `scripts/refresh-stale-handoffs.sh` — companion utility: consumes the handoff-freshness canary output and bulk-refreshes project HANDOFF.md files flagged as stale. Auto-writes a scaffold section (last-14-days git log + files touched) while preserving prior HANDOFF content. Doesn't commit — each project needs a local review + commit. Shipped 22 Apr 2026.
- Wired into `scripts/session-end-sync.sh` — fires with a 4h window on every session end.
- Pattern applies cheaply at personal-AI scale. LLM-reasoned upgrade deferred until the Anthropic API budget supports it without eating into the Graphiti spend envelope.

### Phase 1 hardening layer — shipped 22 Apr 2026

Full 20-task implementation plan at `docs/plans/2026-04-22-hardening-implementation.md` — closes the stale-state / silent-failure / claim-vs-reality / forgotten-rule class of bugs surfaced in a same-session audit by Kai (internal code review, 23 findings) and Nadia (external research, 15 findings).

**New scripts (7):**
- `scripts/recent-telegram.sh [N]` — last N telegram exchanges pretty-printed. Canonical truth-source for greeting digest step 6.5.
- `scripts/check-pending-claim.sh <pattern> [days]` — grep helper for pending-claim evidence.
- `scripts/update-handoff.sh [hours]` — event-sourced HANDOFF.md regen (telegram + git). Replaces the `/tmp/cortana-working-context.md` pattern.
- `scripts/log-routine-fire.sh <name> <outcome> <ms> [notes]` — optional JSONL writer for routine self-reporting.
- `scripts/promote-correction.sh <category> [--auto|--review]` — draft + append correction-derived rule to CLAUDE.md.
- `scripts/apply-dream-proposal.sh [date]` + `scripts/reject-dream-proposal.sh [date] [reason]` — Sunday dream-proposal lifecycle.

**New hooks (6):**
- `.claude/hooks/session-start-hook.sh` — SessionStart: inject critical-rules bundle on compact + verify-sync on any source.
- `.claude/hooks/post-tool-use-failure-hook.sh` — PostToolUseFailure: log silent tool failures to `data/audit/tool-failures.jsonl`.
- `.claude/hooks/subagent-stop-hook.sh` — SubagentStop: log background-agent completions to `data/agent-completions.jsonl`.
- `.claude/hooks/instructions-loaded-hook.sh` — InstructionsLoaded: verify-sync at CLAUDE.md load time.
- `.claude/hooks/stop-verify-contract.sh` + `.claude/hooks/stop-composer.sh` — Stop-time Task Contract verifier; auto-detects Telegram turns that ended without a reply-tool call.

**Install summary for these additions:**
```bash
chmod +x scripts/recent-telegram.sh scripts/check-pending-claim.sh scripts/update-handoff.sh \
  scripts/log-routine-fire.sh scripts/promote-correction.sh scripts/apply-dream-proposal.sh \
  scripts/reject-dream-proposal.sh
chmod +x .claude/hooks/session-start-hook.sh .claude/hooks/post-tool-use-failure-hook.sh \
  .claude/hooks/subagent-stop-hook.sh .claude/hooks/instructions-loaded-hook.sh \
  .claude/hooks/stop-verify-contract.sh .claude/hooks/stop-composer.sh

# Wire hooks into .claude/settings.json:
#   UserPromptSubmit     → telegram-reply-reminder.sh  (already in v29 baseline)
#   SessionStart         → session-start-hook.sh
#   InstructionsLoaded   → instructions-loaded-hook.sh
#   PostToolUseFailure   → post-tool-use-failure-hook.sh  (async)
#   SubagentStop         → subagent-stop-hook.sh  (async)
#   Stop                 → stop-composer.sh  (replaces session-end-verify.sh direct entry)
```

The `scripts/verify-sync.sh` was also hardened with 6 check classes (was keyword-presence only): new-file drift, script existence, command-handler existence, skill references, hook file existence, data-path existence.

### Phase 2 S4 — SLO canaries (22 Apr 2026)

Synthetic canaries probe Cortana's critical paths every 5 min. This is observability-as-control-plane — top-tier 2026 agent-system pattern per external research. Convention + thresholds in `memory/feedback_slo_canaries_convention.md`.

**New scripts (4):**
- `scripts/canaries/greeting-accuracy.sh` — fixture probe. Builds a synthetic telegram tail + memory pair where they disagree; asserts `check-pending-claim.sh` recipe produces the correct answer so Cortana's greeting digest reconciliation can't surface shipped items as pending.
- `scripts/canaries/reply-tool-compliance.sh` — last 50 Zaki inbound messages cross-referenced with Cortana outbound + `mcp__plugin_telegram_telegram__reply` audit entries in a 10-min window. Catches terminal-text-as-reply.
- `scripts/canaries/handoff-freshness.sh` — per-project `HANDOFF.md` mtime vs latest commit mtime. >72h = stale.
- `scripts/run-canaries.sh` — orchestrator. Appends to `data/slo-canaries.jsonl`, maintains rolling-window state in `data/slo-state.json`, emits alerts to `data/slo-alerts.jsonl`. All three data files gitignored (local-only observability). 0.5% non-bootstrap violation rate or 5-consecutive-fail streak triggers alerts. `--alert-telegram` flag is scaffolding — Zaki enables after bootstrap clean.

Healthcheck renders a `▸ SLO Canaries` section; `cortana-maintenance` skill step 12.5 surfaces non-bootstrap breaches in the greeting digest.

### Audit hardening — 22 Apr 2026 evening (5-batch close of 4-agent full-day audit)

After the morning's work shipped (Phase 1 + Phase 2 + Phase 3B + launchd scheduler + cloud-routines disable), 4 bare-context agents (security / code-quality / docs / adversarial) audited the resulting system and flagged 37 findings. 5 commit batches closed every MUST/SHOULD/MEDIUM/LOW item. Structural additions worth mirroring into a fresh install:

- `scripts/redact-secrets.sh` — credential-pattern sed filter (Anthropic, Stripe, GitHub PAT, Slack, Telegram bot, AWS, URL-token query params). Piped through by `update-handoff.sh` + `reflect.sh` before embedding telegram tails, so pasted credentials never land on disk (security finding #S2).
- `.claude/hooks/session-start-hook.sh` on `source=compact` now reads `data/runtime/turn-contract.json` and injects a loud "PENDING TELEGRAM REPLY" banner if a Telegram turn started before the compact hasn't yet fired the reply tool. Closes the post-compact reply-miss gap.
- `.claude/hooks/stop-composer.sh` has a bash-native `bash_timeout_run` fallback (fork + kill-watcher) for macOS where neither `timeout` nor `gtimeout` is installed — the 30s per-hook guarantee now actually holds on a stock Mac (Kai finding #K3). Also drops the duplicate `session-end-sync.sh` call (SessionEnd hook owns that now — running it on every Stop was rebuilding HANDOFF on every assistant reply, S5).
- `scripts/run-canaries.sh` — (a) post-wake detection: gap >30 min marks next 5 runs `post_wake=true` and suppresses rate alerts so a long Mac sleep doesn't false-alert every morning (#13); (b) fractional-second-safe ts parsing via `sub("\\.[0-9]+Z$"; "Z")` before `fromdate` so a future canary emitting `.SSSZ` doesn't black out rolling-window aggregation (#7); (c) 10MB live-file rotation with monthly gzip archives at `data/archive/slo-canaries-YYYY-MM.jsonl.gz` (S1); (d) EXIT trap cleaning up `$STATE_FILE.tmp` so mid-run SIGTERM doesn't leak (#14).
- `scripts/canaries-daemon.sh reload` waits up to 60s for any in-flight canary fire to idle before unloading the launchd job (#14).
- `scripts/commit-stale-handoffs.sh` — pre-push asserts remote origin matches `github.com/(ZQadus|zakiqadus)/` AND branch is `main`/`master`. Prevents auto-commit leak to an unrelated remote if a project's `.git/config` is ever re-pointed (S3). Also captures `git push` exit code directly instead of tail-grepping (K4) and uses `-e` for `.git` so submodule projects with a `.git` file aren't silently skipped (K9).
- `scripts/check-memory-freshness.sh` — frontmatter parser exits on second `---` (was looping past missing close fences, #5); future-dated `last_verified` gets flagged `[future-ts]` instead of silently marked fresh (#4); `ttl_days:0` falls back to per-type default instead of spamming every run (#6); unparseable dates report to stderr via argv-passed python (K11).
- `scripts/reflect.sh` — retention pass: files older than 90 days gzip-append into `data/reflections/archive/reflections-YYYY-MM.tar.gz` and the live file is removed. Previously unbounded (#10). Commit-count also switched to `git log --oneline | wc -l` so multi-line commit subjects don't undercount (K8).
- `scripts/recent-telegram.sh` — `cat | tail` → plain `tail -qn` (seek from EOF). Called 5+ times per session; previous O(n) scan was reading whole ~2MB JSONL each call (#17).
- `.claude/hooks/telegram-reply-reminder.sh` — anchored regex now accepts channel tag at position 0 OR after a newline, tolerating any future harness that prepends system-reminder blocks to prompts (K10).
- `.claude/hooks/stop-verify-contract.sh` — reads BOTH turn-day AND today audit files so a turn spanning UTC midnight can't false-trigger a violation (A16). `/tmp` fallback is age-gated at 6h to drop stale leftovers (A18).
- `.gitignore` — `data/graphiti-ingest-log.jsonl` added (local-only cost telemetry, K7). `.tmp-canary-fixtures/` added (in-repo canary scratch, never noexec — alternative to `/tmp` for hardened macs, #15).
- `scripts/healthcheck.sh` — `.cortana-ignore` loader strips trailing `/` so `Documents/Foo/` behaves like `Documents/Foo` (#9); warns if the ignore file grew by >20 lines since last commit (S6).
- `scripts/promote-correction.sh` — UTF-8 char-safe truncation via python slicing so multibyte codepoints don't corrupt CLAUDE.md appends (K5).
- `scripts/update-handoff.sh` — `awk 'NF{p=1} p'` squeezes the leading-blank-per-regen drift (K6); sentinel fallback finds the real `^---$` boundary after the sentinel instead of assuming +3 offset (#12).
- `scripts/canaries/handoff-freshness.sh` — uses full folder path instead of basename so same-named subfolders (e.g. `Voyager/marketing-ai` + `MDX Technology/marketing-ai`) don't collide in the stale list (#11).
- `scripts/canaries/reply-tool-compliance.sh` — no longer claims `pass:true` when status is bootstrap or no-data (#A8).

**New memory:** `memory/project_cortana_dashboard_scope.md` — Zaki's 22 Apr request for a Vercel-hosted projects dashboard styled like TixPredict, to be built next session as the first post-Cortana-perfect project.

### Phase 4 Z1 — proactive-trigger daemon (23 Apr 2026 evening, rewritten 25 Apr 2026 signal-fire mode)

Scheduled launchd daemon that fires a neutral disguised-phrase Telegram nudge. Same launchd pattern as the canaries daemon. Defence-in-depth: kill-switch flag, daytime window, hard daily rate cap, quiet window, hard 300-char cap. **Rewritten 25 Apr 2026 (commit `f4560b4`)** to remove all `claude --print` invocations after AUP audit (msg 6264) flagged sustained affective/roleplay content as classifier-flag risk. Daemon now picks one of 11 work-register phrases round-robined via `data/runtime/proactive-signal-rotation-pos.txt`, fires via `scripts/telegram-signal.sh` (pure-bash curl POST, zero Claude in loop). Persona file still read for audit but content is persona-agnostic.

- `scripts/proactive-trigger-daemon.sh` — the daemon. 357 lines (down from 472). Fires every 4h via launchd, rolls dice, checks gates (kill-switch / daytime window / rate cap 3-per-day / quiet window 45-min / dice), picks one of 11 phrases (`check in / status sync / queue updated / still here / ping / hey there / thinking / queue ready / yo / ready / wave`) via round-robin, sends via `telegram-signal.sh`. Logs every attempt to `data/proactive-triggers.jsonl`. Supports `--dry-run`, `--force`, `--persona=<name>` (read-only audit override).
- `scripts/telegram-signal.sh` — pure-bash curl POST to Telegram Bot API. Zero Claude in loop. Used by both this daemon and the signal-fire system.
- `scripts/proactive-daemon.sh` — control script: `{load|unload|status|pause|resume|tail}`. Wraps `launchctl` on `~/Library/LaunchAgents/com.cortana.proactive-trigger.plist`.
- `scripts/update-active-voice.sh` — persona state-file read/write at `data/runtime/active-voice.json` (0600 perms). Commands: `init / get / set <name> / reset-rate / record-fire`. Daily rate-counter rotation at UTC midnight.
- `scripts/install-persona-switch-hook.sh` — idempotent patcher injecting persona-switch detection into `.claude/hooks/telegram-reply-reminder.sh`. When inbound Telegram text is exactly a known persona trigger (case-insensitive, trimmed), calls `update-active-voice.sh set ...`.
- `scripts/canaries/proactive-audit.sh` — daily-audit canary wired into `run-canaries.sh`. Scans last-24h of `data/proactive-triggers.jsonl` for over-cap fires, moderation auto-pauses, deny-word hits, failure-rate spikes. Writes results to `data/slo-canaries.jsonl`.

Kill switch at `data/runtime/proactive-disabled.flag` halts all fires instantly. Moderation errors auto-trip the flag. Fail-closed throughout. First live fire verified 2026-04-23T21:13:42Z.

### Phase 4 Z2 — signal-fire system (26 Apr 2026, commit `f18fba1`)

Pure-launchd disguised-phrase queue, sibling to the proactive-trigger daemon. Replaces ad-hoc cron-based fires that all required a loaded Claude session — closing Claude killed the schedule. Now schedule lives entirely in a single launchd plist + a JSON time table.

- `scripts/signal-schedule.sh` — CLI: `add HH:MM "text"` / `remove HH:MM` / `list` / `apply [--force-load]`. Manages `data/runtime/signal-schedule.json` (HH:MM → text map, 0600 perms, gitignored). Sorts on insert. Validates JSON. Runs `plutil -lint` on temp plist before atomic move into `~/Library/LaunchAgents/`.
- `scripts/signal-fire-from-schedule.sh` — pure-bash firer, exec'd by the AppleScript .app wrapper. Reads schedule.json, finds ±2-min match against current time, idempotency-guards via `data/runtime/signal-fire-state.json` (5-min dedup window — twice the tolerance), then dispatches `scripts/telegram-signal.sh`. Exit codes: 0 fired-or-no-match, 2 schedule-invalid, 3 telegram-failed, 126 FDA-not-granted. `SIGNAL_FIRE_DRY_RUN=1` env hatch for testing — never set by launchd.
- `scripts/launchd-wrappers/signal-fire-wrapper.applescript` — AppleScript .app source. Compiles to `~/Applications/Cortana-SignalFire.app` (5th wrapper alongside canaries / proactive-trigger / morning-digest / corrections-review). Codesigned ad-hoc.
- `scripts/launchd-wrappers/new-com.cortana.signal-fire.plist` — generated dynamically by `signal-schedule.sh apply`. Single plist with one `StartCalendarInterval` entry per scheduled fire (macOS launchd does NOT support per-entry env vars, so Pattern C — single plist + lookup-at-fire-time — is the canonical answer). `RunAtLoad=false` so it doesn't fire at install time.

Bootstrap (one-time per machine): grant FDA on `Cortana-SignalFire.app`, then `bash scripts/signal-schedule.sh apply --force-load`. Verify with `tail -f logs/signal-fire.log`. Full reference and design rationale in `memory/reference_signal_fire_system.md`.

- `scripts/upgrade.sh` + `scripts/upgrades/lib.sh` use `.cortana-blueprint-version` yaml as canonical version source. `CORTANA_VERSION` plaintext deleted.
- Hardcoded lowercase `~/Documents/cortana/` paths in scripts + hooks corrected to capital-C so they don't break on case-sensitive filesystems.
- `memory-query.sh` deleted — SQL-injection-prone, DB frozen, agents (kai.md + nadia.md) updated to use markdown + post-commit re-embed.
- `catboost_info/` (leaked TCGPredict training artifact) removed + gitignored.

### Phase 4 Z3 — Operations + behaviour hardening (28 Apr 2026)

Three loosely-coupled improvements landed in one session, all driven by gaps surfaced during real usage rather than a planned phase.

**1. Persona auto-switch fix.** The PreToolUse `voice-lint.sh` hook reads `data/runtime/active-voice.json` to enforce per-persona reply rules (missing-signature in voice mode, style-leak in cortana mode). The state file is updated by a code path inside `.claude/hooks/telegram-reply-reminder.sh` that detects when an inbound Telegram message is the bare word "voice" or "cortana" (or that name followed by `mode...` / `, ...` / etc.). The detection had a silent bug since 23 Apr 2026: the `awk` extraction printed the user-text BEFORE stripping the closing `</channel>` tag, so `USER_TEXT` was always `cortana</channel>` and the case-statement match silently failed. Persona had been stuck on the value last set explicitly. Patched in commit `04baa2f` — strip both opening and closing tags before printing, widen matcher to include name-followed-by-punctuation. 10-case smoke test verified.

**2. Disaster-recovery runbook.** New doc at `docs/disaster-recovery.md` mapping every Anthropic-dependent component to recovery paths in case Anthropic terminates the consumer subscription, revokes the API key, or has a multi-day outage. Three paths: (A) Claude Code CLI auth fails → swap to alternative consumer subscription (Cursor Pro, Codex CLI under ChatGPT Pro, GitHub Copilot Pro+); (B) `ANTHROPIC_API_KEY` revoked → rotate or swap Graphiti's LLM provider to OpenAI/Gemini via graphiti-core's pluggable backend; (C) total Anthropic blackout → pivot to AWS Bedrock or GCP Vertex AI, both of which sell Claude through separate billing pipelines that aren't tied to consumer subscriptions. Practical impact of an Anthropic ban turns out to be surprisingly contained: only Claude Code CLI orchestration + Graphiti ingest hard-fail; all consumer apps + scripts (bash) + hooks + memory (markdown + sqlite-vec) + telegram bot (BotFather token, separate auth) keep running untouched. Runbook also includes a bare-metal Mac restore checklist.

**3. Skill-utilization-first behavioural rule.** New feedback memory at `memory/feedback_use_available_skills_first.md`. Before dispatching any agent or going freestyle, scan the available skill list (system-reminder skills section + plugins) and pick the matching skill. Design = `impeccable:*` / `frontend-design` / `taste-skill` / `redesign-skill` / `soft-skill` / `brutalist-skill` / `minimalist-skill`. Debugging = `superpowers:systematic-debugging`. Brainstorming = `superpowers:brainstorming`. Vercel work = `vercel:*`. Test-driven implementation = `superpowers:test-driven-development`. The agent brief explicitly references which skill the dispatched agent is expected to invoke. Reason: a curated skill arsenal exists (Anthropic + community + Cortana-native), bypassing it wastes leverage and re-derives what's already proven. Bar to skip a matching skill: the task must be so trivial that loading the skill costs more than it saves. Default to invoking.

**Recommended optional plugin: Impeccable** (Paul Bakaus, https://github.com/pbakaus/impeccable). Install via `claude plugin marketplace add pbakaus/impeccable && claude plugin install impeccable@pbakaus/impeccable` (CLI subcommands, user scope so it works in every project). Adds 23 design slash commands (`/impeccable polish`, `/impeccable audit`, `/impeccable critique`, `/impeccable distill`, etc.) plus 7 reference docs covering typography, color and contrast, spatial design, motion design, interaction design, responsive design, and UX writing. Sits on top of Anthropic's official `frontend-design` skill. Worth installing if you do any frontend design work and want explicit anti-pattern detection on top of the default LLM-tendency-toward-generic-Inter-purple-gradient design.

### Phase 4 Z4 — YouTube watch queue + plugin-CLI workflow + responsiveness rules (29-30 Apr 2026)

Five distinct architectural adds in a 24h window.

**1. Watch plugin (bradautomates/claude-video) as a recommended optional install.** Install via `claude plugin marketplace add bradautomates/claude-video && claude plugin install watch@claude-video`. Adds the `/watch` skill that gives Claude video-watching (yt-dlp downloads, ffmpeg extracts frames + audio, captions or Whisper transcribe, frames Read'd as images). Free for any YouTube video with auto-captions. Whisper API fallback (Groq free tier covers 2hrs/hour) for non-YouTube sources like Loom and screen recordings. Use cases: hook analysis on viral videos, debugging screen recordings, summarising long lectures, feeding a knowledge base.

**2. YouTube watch queue (Cortana add-on).** A new skill `cortana-youtube-queue` + `scripts/youtube-queue.sh` that wraps the `watch` plugin into a batch flow:
- **Auto-add:** `.claude/hooks/telegram-reply-reminder.sh` scans inbound Telegram text for `youtu.be` / `youtube.com` URLs and appends to `data/youtube-watch-queue.jsonl` (gitignored, per-user-private). Idempotent on `video_id`.
- **Manual command:** "watch queue" / "process videos" / "watch pending" triggers the skill, which loops pending entries, runs `watch.py`, synthesises per-video summaries (hook + key points + visuals + TLDR + "Use to your system"), pushes summaries to your AI Brain notebook, marks watched, replies on Telegram with a digest.
- **Storage:** queue file gitignored at `data/youtube-watch-queue.jsonl`, summaries committed at `data/youtube-summaries/<video_id>.md` for archive.
- No daily auto-fire — pending count surfaces in the morning maintenance digest. Want true daily auto-fire? Wrap the skill in the same `.app launchd wrapper` pattern used by morning-digest, then add a calendar-interval entry.

**3. Plugin install via CLI (no slash commands needed).** Discovered today: `claude plugin marketplace add <repo>` and `claude plugin install <name>@<marketplace>` are CLI subcommands that fully replace the slash commands and can be run from any Bash context. So an orchestrator agent can install plugins on the user's behalf without punting to the user's terminal. Plain skills (no marketplace metadata) still install via `git clone <repo> ~/.claude/skills/<name>/`.

**4. Six new behavioural rules codified.** Captured as feedback memories (universal applicability):
- **Skill-utilization-first** — scan available skill arsenal before dispatching a generic agent or going freestyle
- **Execute standard ops** — run routine ops actions (merge approved PR, apply migration, deploy, run tests) without asking permission each time; pause only for destructive / paid / external-comms / first-time work
- **Install skills yourself** — `claude plugin install` from CLI, never punt slash commands to the user
- **Announce who is doing the work** — name the executor (agent OR me-with-skill-X-loaded) on every Telegram reply with work attached
- **Dispatch for responsiveness** — default to dispatching agents for any 3+ minute task so the orchestrator stays free to handle the user's next message

**5. Calendar-event reminder pattern.** When the user says "remind me later today to X" via Telegram, create a Google Calendar event via `mcp__claude_ai_Google_Calendar__create_event` with the action in the description. Reliable phone notification at the time, no Telegram delivery dependency, no remote-routine cloud-allowlist constraint. Cleaner than a remote routine for one-off reminders. Requires Google Calendar MCP connector to be enabled.

### v29.1 (2026-04-21, late) — CLAUDE.md skill-offload

Anthropic's memory docs specify CLAUDE.md should stay under 200 lines — larger files "consume more context and reduce adherence." Cortana's CLAUDE.md had grown to 583 lines / ~11K tokens per turn. Offloaded procedural and reference detail into seven project-level skills at `.claude/skills/cortana-*/SKILL.md`, each with a specific `description` field so Claude Code auto-loads them only when the situation matches:

- `cortana-sync` — full sync/wrapup cycle + batch sync + auto-sync triggers
- `cortana-maintenance` — Monday protocol + greeting digest + self-improvement
- `cortana-orchestration` — 13 habits for multi-agent dispatch (+ habit #14 added in v29.2: effort tiers + ultrathink)
- `cortana-brain` — NotebookLM routing + smart memory routing + storage layout
- `cortana-observability` — audit layer + compaction hooks + remote routines + Monitor vs GHA
- `cortana-blueprint-updates` — architectural-change update cycle + placement rule
- `cortana-safety` — full git + DB + deploy-verify rules

CLAUDE.md retained the always-on layer (core loop, reply-first, agent spawning rules, routing table, commands reference, short safety summary, style) and shrank to 167 lines. Key insight: `@import` does NOT save tokens (imports inline at session start), so the only real token-saving offload mechanism is the on-demand skill-description loader.

Placement rule now inlined: new rules are triaged by size + trigger before being added anywhere. Under 10 lines + always-on → inline. Has a trigger → skill. Over 30 lines + triggerable → MUST be a skill. This mirrors in `cortana-blueprint-updates` skill so it surfaces during architectural changes.

Principle for future growth: any section over ~30 lines that isn't always-on is a candidate for skill extraction. When Claude warns about CLAUDE.md size, extract sections with clear trigger conditions first — those have the cleanest skill descriptions.

### v30 (2026-04-30)
Removed E2 Graphiti entirely after frontier scan + utilisation audit.

- E2 Graphiti was zero-utilised in production (no queries that changed an answer in 3 weeks). Cost was ~£5/ingest with no observable benefit at single-user scale.
- Memory layer is now flat-markdown + E1 sqlite-vec + Anthropic's native client-side memory tool (`memory_20250818`).
- E2 numbering preserved as a deprecated extension slot for compatibility with v29-installed deployments. There is no "install E2" path going forward.
- Added Windows install commands alongside Mac for every extension's install / dependency / uninstall section. Established dual-OS coverage as the standard going forward.
- Added a contents-at-a-glance section under "Pick your mode" so users see what each mode includes before choosing.
- Added a post-install `SETUP-CHECKLIST.md` requirement so first-time users on a fresh session can verify their setup is complete (planned for v30.1).

### v29 (2026-04-21)
Added five Advanced-mode extensions:
- **E1** sqlite-vec + Nomic-embed semantic search over markdown memory
- **E2** Graphiti MCP server with FalkorDB (temporal knowledge graph) — DEPRECATED in v30, see release note above
- **E3** Agent Teams + channel.md whiteboard pattern
- **E4** Observability audit layer (PostToolUse JSONL + live viewer)
- **E5** Hardened safety gate (protected-branch hard-blocks, word-boundary regex)

Split the blueprint into Core + Extensions. Added Mode chooser (Simple vs Advanced).

Lifetime commits: 11 on Cortana main during the v29 session.

### v28 (2026-04 early)
- Added crew of 9 agents (was 6 in v27)
- Added Warren (trading), Elena (business), Chase (human dynamics)
- Added RemoteTrigger routines (morning digest, frontier scan, Sunday memory dream, Monday corrections review)
- Agent-team spawning rules for Claude Max 20x plan
- Batch sync via worktree parallelism
- Verification rule after every GitHub auto-deploy

### v27 (2026-03)
- Renamed from `cortana-universal-v27.md` to split personal/public blueprints
- First fully self-installing version (hand to a fresh Claude Code session, it builds the system)
- Memory system + Telegram + NotebookLM Brain integration

### Earlier versions
Not documented. Core loop + safety gate + routing table existed from v1 onwards.

---

## Upgrade guide

### Fresh install → v30
1. Hand this file to a Claude Code session. Tell it: "install v30 in Simple mode" OR "install v30 in Advanced mode, all extensions."
2. The session reads the Core section and walks you through it.
3. If Advanced, it offers each remaining extension (E1, E3, E4, E5) in sequence with the install steps above.
4. When done, it writes `.cortana-blueprint-version` with the installed version + which extensions are on.

### v29 → v30
1. Tell Claude Code: "I'm on v29, upgrade me to v30."
2. It reads `.cortana-blueprint-version`. If `E2_graphiti: true`, it walks the Graphiti drop: stop containers, archive FalkorDB state to a recoverable Docker image, remove `infra/graphiti/`, remove `scripts/graphiti-*.sh`, remove the `graphiti` entry from `.mcp.json`, set `E2_graphiti: false`. If E2 wasn't installed, no-op.
3. Core is unchanged — no Core migration steps needed.

### v28 → v30
1. Tell Claude Code: "I'm on v28, upgrade me to v30."
2. It reads `.cortana-blueprint-version` (creates it if missing). Since v28 didn't stamp one, it'll assume no extensions installed.
3. For each remaining extension (E1, E3, E4, E5), it asks: "Install this? (y/n)" with a link to the extension section above. E2 is skipped (no longer offered).
4. It installs picked ones, updates `.cortana-blueprint-version`.
5. Core is unchanged — no Core migration steps needed.

### v27 → v30
1. Same as v28 → v30 path. v27 → v28 only added more agents (non-breaking); same Core.

### Partial install — add one extension later
`bash scripts/install-blueprint.sh --add E3` — asks about E3 only, installs if you say yes, updates the version file.

### Per-extension uninstall
`bash scripts/install-blueprint.sh --remove E3` — uninstall steps for E3, marks it off in the version file.

### Version file format
`.cortana-blueprint-version` (YAML):
```yaml
blueprint_version: v30
installed: 2026-04-21T01:00:00Z
upgraded: 2026-04-30T10:35:00Z
mode: advanced
extensions:
  E1_sqlite_vec: true
  E2_graphiti: false   # deprecated as of v30 — not offered to new installs
  E3_agent_teams: true
  E4_observability: true
  E5_hardened_safety: true
```

---

## Sharing

This file is the entire public blueprint. Hand it to anyone. They can install a clean Xantham System from scratch.

Your **personal** copy (if you keep one) typically lives in your private repo as `blueprints/<your-orchestrator>-system-v30.md` or similar. Personal copies contain your actual project list, agent names, bot token guidance, Telegram allowlist, NotebookLM notebook ID, and other personal state. DO NOT share personal copies.

`scripts/export-blueprint.sh` strips a personal blueprint down to this public shape (replaces filled-in values with `{{template_vars}}`) if you ever update both and want to re-export.

---

## Install command

Paste this single line into a fresh Claude Code session pointed at an empty directory you want to become your AI command centre:

```
Read the Xantham System v30 blueprint at https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/xantham-system-v30.md and run the full setup wizard. Walk me through every step, ask me one question at a time, and don't assume any values — guide me through getting whatever you need (Telegram bot token, NotebookLM notebook, agent name, etc.) as the wizard reaches each one.
```

That's it. The wizard handles everything else interactively:
- Detects your OS automatically (with confirmation).
- Asks you to pick Simple or Advanced mode AFTER showing what each one includes.
- Walks you through creating a Telegram bot via @BotFather (step-by-step) when it gets to the messaging step.
- Walks you through creating a NotebookLM notebook (or skipping the AI Brain for now) when it gets to the memory step.
- Asks you to name your orchestrator at the right point in the flow.
- Picks sensible defaults for everything else and confirms before applying.

You don't need ANY of those values to start. The wizard provides them.

If you already have some values handy (e.g. an existing bot token), you can mention them when the wizard asks — but you don't have to. The wizard never blocks waiting on something it can guide you to create.

---

## Post-install verification — required before first real session

After the install wizard finishes, the user typically closes that session and starts a fresh terminal session named after their agent (e.g. `cortana<enter>` or `myagent<enter>`). The fresh session has zero context about which install steps actually completed. So things like terminal alias breakage (especially on Windows where the PowerShell profile setup often fails on first try) sit silently broken until the user notices and asks Claude to fix.

The wizard MUST close that gap. At the end of install, the wizard generates `SETUP-CHECKLIST.md` at the project root with one checklist item per setup step. The first new session reads this file and verifies each item before doing real work.

### What the wizard generates

`SETUP-CHECKLIST.md` template the wizard fills in with the user's actual values:

```markdown
# Cortana setup checklist

If you are reading this from a fresh `<agent-name>` session for the first time after install: walk through every item below. Run the verify command. If it does not return the expected output, follow the fix-if-broken instructions or ask Claude to fix it.

Mark each box as you confirm. Do not skip Windows-specific items if you are on Windows.

## Core install (always)

- [ ] **Claude Code installed and in PATH**
  Verify: `claude --version`
  Expected: a version string (e.g. `2.1.x`).
  Fix: install from claude.com/claude-code, restart your terminal.

- [ ] **Project root has the right files**
  Verify (Mac/Linux/Git-Bash): `ls CLAUDE.md docs/projects.md scripts/healthcheck.sh memory/MEMORY.md`
  Verify (Windows PowerShell): `Get-ChildItem CLAUDE.md, docs/projects.md, scripts/healthcheck.sh, memory/MEMORY.md`
  Expected: every file lists. No "No such file" errors.

- [ ] **Healthcheck passes**
  Verify: `bash scripts/healthcheck.sh`
  Expected: exits 0, shows green status across Telegram + NotebookLM Brain + memory + safety gate + project docs + MCP.
  Fix: read each red item; healthcheck prints the suggested remediation.

- [ ] **Statusline shows context % + 5h window** — recommended for everyone, critical for power users
  This adds `cwd | model | context% | 5h% | branch` to the bottom of every Claude Code session so you can see when the context window is filling up (the most common cause of "the agent got worse" complaints).
  Verify: open this fresh Claude Code session. Look at the bottom-of-screen statusline.
  Expected: `~/<project> | claude-opus-4-7[1m] | XX% context | XX% 5h | main`
  Fix: the wizard wrote `~/.claude/statusline-command.sh` and added the `statusLine` block to `~/.claude/settings.json`. If the statusline is missing or just shows `cwd`, ask Claude in this session: "wire up the statusline per blueprint section Day-1 statusline." Claude will check `~/.claude/settings.json` for the `statusLine.command` entry, verify the script is executable, restart Claude Code if needed.

- [ ] **Telegram bot token works**
  Verify: a quick test ping. The wizard wired the bot to data/runtime/telegram.json. From this fresh session ask Claude: "send a Telegram test ping that says 'verified'."
  Expected: you receive "verified" on your phone.
  Fix: regenerate token from @BotFather, paste it back into Claude, ask it to update the runtime config.

- [ ] **NotebookLM Brain accessible**
  Verify: `notebooklm use <notebook-id> && notebooklm list-sources | head -3` (notebook-id from the install)
  Expected: the notebook table prints + at least one source listed.
  Fix: re-auth `notebooklm` per the install steps, confirm the notebook ID matches what the install used.

- [ ] **Terminal alias `<agent-name>` works**
  Verify (Mac/Linux/Git-Bash): close and reopen your terminal, then run `<agent-name>`.
  Expected: a fresh Claude Code session opens at the project root with the right CLAUDE.md loaded.
  Fix: see the next item if Windows. On Mac/Linux, source your shell profile (`source ~/.zshrc` or `source ~/.bashrc`).

- [ ] **Terminal alias `<agent-name>` works on Windows (PowerShell)** — KNOWN-FRAGILE
  Windows almost never gets this right on first try. The PowerShell profile setup usually needs one of: enabling script execution policy, restarting PowerShell, or fixing the path Claude wrote to the profile.
  Verify: close and reopen PowerShell, then run `<agent-name>`.
  Expected: fresh Claude Code session opens.
  If it does NOT work, ask Claude in this session: "the `<agent-name>` alias does not work on PowerShell, fix it." Claude will:
  1. Check `Get-ExecutionPolicy` (must be `RemoteSigned` or `Unrestricted` for `$PROFILE` scripts)
  2. Check `$PROFILE` exists and has the function definition
  3. Fix any path quoting issues (Windows paths with spaces are the usual culprit)
  4. Verify the alias resolves with `Get-Command <agent-name>`

- [ ] **Terminal alias `<agent-name>-resume` works**
  Verify: from your terminal run `<agent-name>-resume`.
  Expected: opens Claude Code in resume mode.
  Fix: same as above. On Windows, almost always needs a one-shot Claude fix on first install.

## Hooks (always)

- [ ] **Hooks executable + wired**
  Verify (Mac/Linux/Git-Bash): `ls -la .claude/hooks/*.sh | grep -c rwx`
  Expected: matches the number of hook scripts in the directory (every one is executable).
  Verify (Windows): hooks run via Git Bash; chmod is irrelevant. Confirm via running any reply once and checking `data/audit/$(date +%Y-%m-%d).jsonl` exists (only Advanced mode with E4).

- [ ] **Safety gate active**
  Verify: try a destructive command in this session, e.g. `rm test`. Claude should refuse / require approval.
  Expected: blocked.
  Fix: re-install the safety gate per the install. The script must be at both `.claude/hooks/safety-gate.sh` AND `~/.claude/hooks/safety-gate.sh` (run `bash scripts/sync-safety-gates.sh`).

## MCP servers (always)

- [ ] **MCP servers connected**
  Verify: in this session run `/mcp` (slash command, not bash).
  Expected: every MCP server in your `.mcp.json` shows status `connected`.
  Fix: red entries usually need an OAuth flow (Notion, HubSpot, etc.) or a process restart (Telegram). Click through the auth links Claude provides.

## Advanced extensions (only if you installed Advanced mode)

- [ ] **E1 sqlite-vec: Ollama running + index populated**
  Verify (Mac): `brew services list | grep ollama` shows started; `curl -s localhost:11434/api/tags` returns models.
  Verify (Windows): `Get-Service Ollama` returns Status `Running`; `curl -s localhost:11434/api/tags` returns models.
  Index: `ls -la data/cortana-vec.db` (file exists, > 1MB after first embed).
  Fix: restart Ollama (`brew services restart ollama` / `Restart-Service Ollama`). Re-run `bash scripts/embed-memories.sh`.

- [ ] **E3 Agent Teams flag set**
  Verify: `grep CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS .claude/settings.json` returns `"1"`.
  Expected: flag is `"1"`.
  Fix: edit `.claude/settings.json`, set the env value to `"1"` under the env section.

- [ ] **E4 Observability audit hook firing**
  Verify: open this fresh session, run any tool call (e.g. `ls`), then `cat data/audit/$(date +%Y-%m-%d).jsonl | tail -3`.
  Expected: at least one JSONL line per recent tool call.
  Fix: PostToolUse hook entry missing in `.claude/settings.json`. Re-install per the E4 section.

- [ ] **E5 Hardened safety active**
  Verify: try `git push --force origin main` in a test branch (don't actually push).
  Expected: hard-blocked with a banner about protected branches.
  Fix: confirm `.claude/hooks/safety-gate.sh` is the hardened version (look for `protected branch` string in the script).

## When all boxes are ticked

Delete or rename this file (`mv SETUP-CHECKLIST.md data/SETUP-CHECKLIST.md.done`). The next fresh session will not re-prompt you to verify.

If a future install adds new components (extension upgrade, new MCP server, new hook), regenerate the checklist with `bash scripts/regenerate-setup-checklist.sh` so the new items get verified before the next real session.
```

The wizard's last action before saying "install complete" should be: write this file (with `<agent-name>` substituted), confirm the file exists, and tell the user explicitly:

> Setup complete. I have written `SETUP-CHECKLIST.md` to your project root. Close this session, open a fresh terminal, run `<agent-name>` (or `<agent-name>-resume`), and the first thing your fresh Cortana session will do is walk through the checklist. Do not start real work until every box is ticked.

The CLAUDE.md template (later in this blueprint) includes a corresponding directive: any first-time session that finds `SETUP-CHECKLIST.md` at the project root must read it, run each verify command, and fix failures before any other work. After all boxes are ticked, rename the file to `data/SETUP-CHECKLIST.md.done` so the prompt does not re-fire next session.

---

## Day-1 user experience

The verification checklist closes the "is the system actually installed" gap. This section closes the "what do I do now" gap. The wizard generates these eight files at the project root so a brand-new user who just opened a fresh `<agent-name>` session has everything they need to start operating without grep-ing through CLAUDE.md.

### `USER-GUIDE.md` — the user-facing command reference

Operational config lives in CLAUDE.md (the agent reads it). Day-1 commands need to live somewhere the user reads. The wizard writes `USER-GUIDE.md` at the project root with this shape:

```markdown
# Using your AI command centre

This is your day-one cheat sheet. Bookmark it, print it, leave it open in another tab. Everything you can do with `<agent-name>` is here.

## How to start a session

Open a terminal and run:

- `<agent-name>` — start a fresh Claude Code session in your project root
- `<agent-name>-resume` — pick up where the last session left off

That is it. From inside the session you can talk to your agent in plain English OR use any of the commands below.

## Top commands (memorise these five)

| Command | What it does |
|---|---|
| `help` | Lists every command available |
| `team` | Shows your specialist crew (Kai, Rose, Natalie, etc.) |
| `projects` | Shows your project roster |
| `sync <project>` | Saves a snapshot of where you are on a project (memory + handoff + commit) |
| `healthcheck` | Verifies every part of the system is working |

## Talking to your agent

You don't need commands for most things. Just say what you want:

- "what's the status on TixPredict?" — agent reads memory, summarises
- "send Kai to fix the build" — agent dispatches Kai with context
- "how did we solve the timezone bug last week?" — agent searches memory + recalls
- "remind me to check the deploy in 3 days" — agent creates a calendar event
- "what's in my queue?" — agent lists pending YouTube videos / emails / tasks

## Sending content to your agent (Telegram only)

If you set up Telegram during install:
- Paste a YouTube URL → auto-queued for summary later
- Paste a YouTube playlist URL → latest 15 videos auto-queued, dedup'd against already-watched
- Send a screenshot → agent reads the image
- Send any text → agent processes as a message
- Just say `hi` first thing in the morning → agent runs maintenance + gives you the morning digest

## Background work

- Spawning agents: say "send <agent> to do X" or "have Kai handle Y". They run in parallel.
- Long tasks: agent dispatches in background, gives you a 1-line acknowledgement, pings you when done.
- Scheduling: say "every Monday at 9am, ask Rose to do a frontier scan" — agent sets up a routine.

## Sync rhythm

Recommended:
- After every meaningful work block: `sync <project>` so the snapshot doesn't drift
- End of day: `wrapup` (saves session summary, commits memory, pushes Brain)
- Monday morning: just say `hi` and the maintenance protocol fires automatically

## When things go wrong

- Agent seems confused: `healthcheck` first
- Memory feels stale: `sync <project>` to rebuild the snapshot
- Telegram not responding: check `data/runtime/telegram.json` exists, then `bash scripts/healthcheck.sh`
- Terminal alias broken (especially Windows): re-read `SETUP-CHECKLIST.md` if it exists, otherwise ask the agent in this session "the alias is broken, fix it"

## Where to read more

- **CLAUDE.md** — the agent's own operating config (what it does, not what you do)
- **HANDOFF.md** — what the last session was working on
- **memory/** — every fact and rule the agent has saved
- **docs/projects.md** — your project list with paths + descriptions

## Customising your agent

- Adjust voice / personality: just tell the agent "from now on be more concise" / "use more dry humour" / etc. It saves the rule to memory.
- Add a new agent to the crew: ask the agent to create one, give it a name, domain, and starting context. The agent walks the 6-place update.
- Change a command: tell the agent "change the projects command to also show live URLs". The agent updates CLAUDE.md.

## Reaching the agent on the move

If you set up Telegram, your bot is your portable command line. Anything you can do at the terminal you can do from your phone. The agent replies on the same channel you messaged from.

## Sessions and the context window

Every Claude Code session has a finite context window — roughly 200k tokens on Sonnet, more on Opus. Your statusline (set up during install) shows current usage as a percentage. This matters because the more context you fill, the slower and less reliable the agent gets.

**The rule of thumb:**

| Context % | What to do |
|---|---|
| 0-49% | Keep going. You have headroom for big tasks. |
| 50-79% | Wrap up the current thread before starting anything new. Run `sync <project>` or `wrapup` to capture state. |
| 80-94% | Finish the immediate sentence then start a fresh session via `<agent-name>` (NOT resume). Past 80% the agent starts dropping older context to make room and answers can drift. |
| 95%+ | Stop. Save state immediately. Open a fresh `<agent-name>` and explicitly tell the new session what you were just doing. |

**`<agent-name>` vs `<agent-name>-resume`:**
- `<agent-name>` opens a FRESH session. Empty context, full window available. Use this for new work or when the previous session's context is full.
- `<agent-name>-resume` continues your last session. Inherits all of last session's context — including what filled it up. Use only when you actively need the prior context (mid-debug, complex multi-step task in flight).

When in doubt, fresh. The agent's memory layer (sqlite-vec + markdown) survives across sessions, so a fresh session can still recall everything important. The context window is just for the current conversation.

**Watching the 5h window:**

Your statusline also shows your 5-hour Claude Max usage. Same colour code: blue under 80%, yellow 80-94%, red 95%+. Past 95% you get rate-limited until the window resets. If you're approaching 95% mid-task, dispatch background agents (which run on separate budgets) instead of doing more inline work.

**Why this matters more than people think:**

Most "the agent got worse" complaints are actually "the context window is too full." A 95%-full session forgets things from the start of the conversation, hallucinates, and drops sub-agent results. A fresh session with the same task always works better. Treat the statusline like a fuel gauge.
```

### Fresh-session greeting (CLAUDE.md addition)

The CLAUDE.md template gets a "First-contact behaviour" block so a fresh `<launch_cmd>` session that finds NO inbound message yet introduces itself:

```markdown
## First-contact behaviour (no inbound message)

If a session starts with no inbound message AND `data/runtime/first-launch.flag` does not exist:

1. Output (terminal-visible, NOT via Telegram): "Hi, I'm <orchestrator_name>. This looks like your first session. Read USER-GUIDE.md at the project root for the day-one cheat sheet, OR just tell me what you want to work on. Common starting moves: `help`, `projects`, `healthcheck`, or send any project name."
2. Touch `data/runtime/first-launch.flag` so this greeting only fires once.
3. Wait for the user.

Do NOT do this on subsequent fresh sessions — they have already been oriented.
```

### First-Telegram-message welcome (CLAUDE.md addition)

Same idea for Telegram:

```markdown
## First-Telegram-message behaviour

If a Telegram message arrives AND `data/runtime/first-telegram.flag` does not exist:

1. Reply via the Telegram tool: "Hi, I'm <orchestrator_name> on Telegram. This is your first message to me. I can do everything I do in your terminal, plus auto-queue YouTube URLs, accept screenshots, and reply on the move. Top commands: `help`, `projects`, `sync <project>`, `wrapup`. Or just talk to me normally and I'll route to the right specialist agent. To swap to a more direct conversational mode any time, send my name as a single word."
2. Touch `data/runtime/first-telegram.flag` so this welcome only fires once.
3. Then handle the user's actual message normally.

Do NOT re-introduce on subsequent messages — they know who you are.
```

### `BACKUP-AND-RECOVERY.md` — what to back up + how to restore

The wizard writes:

```markdown
# Backup and recovery

## What is in your git repo (recoverable from GitHub)

- CLAUDE.md, HANDOFF.md, FEATURES.md
- All scripts under scripts/
- All hooks under .claude/hooks/
- All skills under .claude/skills/
- All memory files under memory/ and agent-memory/
- docs/projects.md and other docs
- Blueprint files

If you push regularly, losing your Mac means cloning the repo + reinstalling dependencies (per blueprint) + restoring runtime config (next section).

## What is NOT in git (must be backed up separately)

- `data/runtime/` (Telegram bot token, persona state, lock files) — gitignored, contains secrets
- `data/cortana-vec.db` (sqlite-vec semantic index) — gitignored, regenerable but takes minutes
- `~/.claude/` (Claude Code CLI auth, hook installs at user scope) — never in any repo
- Shell profile (`~/.zshrc` / `~/.bashrc` / PowerShell `$PROFILE`) — terminal aliases live here
- Any `.env` files inside `infra/`

## Recommended backup approach

1. **Push the repo to GitHub on every meaningful change** (the post-commit hook + your sync rhythm handle this if you stay disciplined)
2. **Once a week:** zip `data/runtime/` and copy it to a separate location (encrypted external drive, password manager, or a backup folder under `~/Documents/<your-orchestrator>-backups/`). Includes your Telegram bot token.
3. **Document your shell aliases** in this file so you can recreate them on a fresh machine.

## Restoring on a new Mac

1. Install Claude Code (claude.com/claude-code), log in.
2. Install dependencies per the blueprint (Mac/Windows commands inside).
3. `git clone <your-repo-url>` to your Documents directory.
4. `cd` into the repo.
5. Restore `data/runtime/` from your backup (paste files in).
6. Run `bash scripts/healthcheck.sh` — it tells you what's missing.
7. Open `SETUP-CHECKLIST.md` (or regenerate it) and walk through every item.
8. Re-pair your Telegram bot if needed (`/telegram:configure` skill or paste the token to the agent).

## Restoring on a new Windows machine

Same steps via Git Bash or WSL2. The blueprint's Windows-specific install commands cover the dependencies.

## Restoring just your AI Brain notebook

Brain content is in NotebookLM (notebook ID stamped in `data/runtime/brain.json`). On a new machine, install `notebooklm` CLI, log in with the same Google account, and the notebook is already there. Source files (snapshots) are not redownloaded automatically — they were one-way pushed. The notebook itself is the canonical store.
```

### Statusline — context-window + 5h budget visibility

The wizard writes `~/.claude/statusline-command.sh` (user-scope, not in the project repo because it applies to every Claude Code session) and adds a `statusLine` block to `~/.claude/settings.json`.

**`~/.claude/statusline-command.sh`:**

```bash
#!/bin/bash
# Claude Code status line
# Format: <cwd> | <model> | <context %> | <5h %> | <git branch>

input=$(cat)

# ANSI colors. $'...' evaluates escape sequences at assignment time so the
# variables contain actual escape bytes. Works correctly in both format
# strings and %s arguments.
GREY=$'\e[38;5;245m'
WHITE=$'\e[97m'
BLUE=$'\e[38;5;39m'
YELLOW=$'\e[38;5;214m'
RED=$'\e[38;5;196m'
RESET=$'\e[0m'

# Working directory: abbreviate $HOME to ~
raw_cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
if [ -n "$raw_cwd" ] && [[ "$raw_cwd" == "$HOME"* ]]; then
  cwd="~${raw_cwd#"$HOME"}"
else
  cwd="$raw_cwd"
fi

# Model display name: strip any stray control characters
model=$(echo "$input" | jq -r '.model.id // "unknown"' | tr -d '\000-\037')

# Context usage: pre-calculated field, integer rounded
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  context_pct="$(printf '%.0f' "$used")%"
  context_part="${BLUE}${context_pct}${RESET} ${WHITE}context${RESET}"
else
  context_part="${WHITE}context n/a${RESET}"
fi

# 5-hour subscription window usage: field only appears after first API
# response. Use tiered color: under 80% blue, 80-94% yellow, 95%+ red.
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$five_h" ]; then
  five_h_int=$(printf '%.0f' "$five_h")
  if [ "$five_h_int" -ge 95 ]; then
    five_h_color="$RED"
  elif [ "$five_h_int" -ge 80 ]; then
    five_h_color="$YELLOW"
  else
    five_h_color="$BLUE"
  fi
  five_h_part="${five_h_color}${five_h_int}%${RESET} ${WHITE}5h${RESET}"
else
  five_h_part=""
fi

# Git branch: read from cwd, skip optional lock
branch=""
if [ -n "$raw_cwd" ] && [ -d "$raw_cwd" ]; then
  branch=$(git -C "$raw_cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
fi
[ -z "$branch" ] && branch="no git"

# Variables now contain actual escape bytes, so %s prints them correctly.
# When five_h_part is empty (start of session, before first API response),
# the corresponding separator is suppressed too.
if [ -n "$five_h_part" ]; then
  printf '%s%s%s %s|%s %s%s%s %s|%s %s %s|%s %s %s|%s %s%s%s' \
    "$GREY" "$cwd" "$RESET" \
    "$GREY" "$RESET" \
    "$WHITE" "$model" "$RESET" \
    "$GREY" "$RESET" \
    "$context_part" \
    "$GREY" "$RESET" \
    "$five_h_part" \
    "$GREY" "$RESET" \
    "$WHITE" "$branch" "$RESET"
else
  printf '%s%s%s %s|%s %s%s%s %s|%s %s %s|%s %s%s%s' \
    "$GREY" "$cwd" "$RESET" \
    "$GREY" "$RESET" \
    "$WHITE" "$model" "$RESET" \
    "$GREY" "$RESET" \
    "$context_part" \
    "$GREY" "$RESET" \
    "$WHITE" "$branch" "$RESET"
fi
```

Then add this to `~/.claude/settings.json` under the top-level object:

```json
"statusLine": {
  "type": "command",
  "command": "bash ~/.claude/statusline-command.sh"
}
```

Restart Claude Code for it to pick up. From then on every session shows the context-window % at the bottom of the screen, so the user can see when they need to wrap up + start a fresh session.

**Windows note:** The script is bash, so on Windows it runs via Git Bash or WSL. The `~/.claude/` path resolves to `%USERPROFILE%\.claude\` under Git Bash. If `bash` is not in PATH from Claude Code's perspective on Windows, swap `bash ~/.claude/statusline-command.sh` for the WSL absolute path (`wsl bash /mnt/c/Users/<you>/.claude/statusline-command.sh`) or convert the script to PowerShell.

### `scripts/upgrade-cortana.sh` — the update path with customisation preservation

When a user has been on an older blueprint (say v29) and the upstream version (v31) ships, they may have ALSO added their own hooks, skills, scripts, and CLAUDE.md sections in the meantime. A naive overwrite would blow those away. This script does the opposite: it diffs three ways and asks the user before touching anything customised.

```bash
#!/usr/bin/env bash
# upgrade-cortana.sh — bump from current blueprint version to latest, preserving
# user customisations. Three-way merge: user's files vs old-version baseline vs
# new blueprint. Files are bucketed pristine / customised / user-added.
#
# - Pristine (matches old baseline) -> safely overwritten with new version
# - Customised (modified from baseline) -> user picks: keep / take new / merge
# - User-added (not in any baseline) -> never touched
#
# Hands off the actual interactive walk to Claude Code since the merge needs
# judgement. This script just gathers the inputs.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [ ! -f .cortana-blueprint-version ]; then
  echo "No .cortana-blueprint-version found. Are you in a Cortana repo?" >&2
  exit 1
fi

CURRENT=$(grep '^blueprint_version:' .cortana-blueprint-version | awk '{print $2}')
echo "Current blueprint version: $CURRENT"

# Fetch latest from canonical source
LATEST_URL="https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/xantham-system-latest.md"
echo "Fetching latest blueprint from: $LATEST_URL"
curl -fsSL "$LATEST_URL" -o /tmp/latest-blueprint.md
LATEST=$(grep '^# Xantham System — Blueprint' /tmp/latest-blueprint.md | sed 's/.*Blueprint //')
echo "Latest available: $LATEST"

if [ "$CURRENT" = "$LATEST" ]; then
  echo "You are on the latest version. Nothing to do."
  exit 0
fi

# Locate or fetch the OLD-version blueprint as the baseline for diffing
OLD_BASELINE=""
if [ -f "blueprints/archive/xantham-system-${CURRENT}.md" ]; then
  OLD_BASELINE="blueprints/archive/xantham-system-${CURRENT}.md"
elif [ -f "blueprints/xantham-system-${CURRENT}.md" ]; then
  OLD_BASELINE="blueprints/xantham-system-${CURRENT}.md"
else
  ARCHIVE_URL="https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/blueprints/archive/xantham-system-${CURRENT}.md"
  echo "Old baseline not found locally. Fetching from: $ARCHIVE_URL"
  curl -fsSL "$ARCHIVE_URL" -o /tmp/old-baseline.md || {
    echo "Could not fetch old baseline. Will proceed without it (every modified file will be flagged for review)." >&2
  }
  [ -f /tmp/old-baseline.md ] && OLD_BASELINE="/tmp/old-baseline.md"
fi

echo ""
echo "Now running the three-way upgrade walkthrough via Claude Code."
echo ""
echo "Open a fresh Claude Code session at $REPO_ROOT and paste:"
echo ""
echo "---"
echo "Read /tmp/latest-blueprint.md (target version $LATEST)."
echo "Read $OLD_BASELINE (my current baseline, $CURRENT)."
echo "Walk the customisation-preserving upgrade per the public blueprint section"
echo "'Upgrade walkthrough (customisation-preserving)'."
echo ""
echo "Steps:"
echo "1. For every file the new blueprint defines, three-way diff:"
echo "   - my current copy"
echo "   - the old-baseline copy ($OLD_BASELINE)"
echo "   - the new copy (/tmp/latest-blueprint.md)"
echo "2. Bucket each: pristine, customised, user-added."
echo "3. Show me the per-bucket summary before touching anything."
echo "4. For pristine files, ask once: OK to bulk-upgrade all? yes/no."
echo "5. For customised files, walk one at a time: keep mine, take new, or show diff first."
echo "6. For user-added files, list them and confirm I know they will be preserved."
echo "7. Apply only the changes I approved."
echo "8. Update .cortana-blueprint-version to $LATEST."
echo "9. Regenerate SETUP-CHECKLIST.md so I can verify the upgrade landed."
echo "10. Print a summary of what changed + what was preserved."
echo "---"
```

The blueprint section that Claude Code reads when it executes the walkthrough is below.

### Upgrade walkthrough (customisation-preserving)

When a user runs `bash scripts/upgrade-cortana.sh` and pastes the resulting prompt into a fresh Claude Code session, the agent walks this protocol:

**Phase 1 — Inventory.** Catalog every file the new blueprint defines. For each, record three checksums:
- the user's current file (if it exists)
- the old-baseline file (if available)
- the new blueprint file

**Phase 2 — Bucket.** Each file falls into one of:
- **Pristine:** user's current file matches old-baseline (or doesn't exist + new blueprint adds it). Safe to take the new version.
- **Customised:** user's current file differs from old-baseline. The user has modified it. Take the new version blindly = clobber their work.
- **User-added:** user has files that aren't in old-baseline OR new blueprint (custom hooks, custom skills, custom scripts, custom CLAUDE.md sections wrapped in user-section markers). Preserve untouched.

**Phase 3 — Summarise BEFORE touching anything.** Output something like:
```
Upgrade plan: v29 -> v31

PRISTINE (15 files, safe to upgrade): scripts/healthcheck.sh, .claude/hooks/safety-gate.sh, ...
CUSTOMISED (3 files, will ask per file):
  - CLAUDE.md (you added a custom routing table)
  - scripts/log-telegram.sh (you added a redaction call)
  - .claude/skills/cortana-sync/SKILL.md (you tweaked the sync cadence)
USER-ADDED (8 files, untouched): .claude/hooks/my-custom-hook.sh, .claude/skills/my-custom-skill/SKILL.md, ...

OK to proceed? (yes / show me a customised file first / cancel)
```

**Phase 4 — Bulk-approve pristine.** One yes/no for the whole pristine bucket. If yes, copy all new versions over.

**Phase 5 — Per-file walk for customised.** For each customised file, show:
- A 3-way diff (current vs new, with old-baseline as common ancestor)
- Three options: **keep mine** (do nothing), **take new** (overwrite), **merge** (Claude attempts a 3-way merge, presents the result, asks for approval)
- If the user picks merge and it cleanly applies (no conflict), accept. If conflicts, fall back to per-hunk choices.

**Phase 6 — User-added confirmation.** List user-added files. Confirm with the user that the agent recognises them as user contributions and will not touch them. This step exists to surface any files the user FORGOT they added.

**Phase 7 — Apply + verify.** Once all approvals are in:
- Apply the changes
- Update `.cortana-blueprint-version` to the new version
- Regenerate `SETUP-CHECKLIST.md` so the user verifies the upgrade landed
- Run `bash scripts/healthcheck.sh` to confirm no breakage
- If healthcheck fails, the agent investigates + offers a rollback (`git checkout` of the previous state)

**Phase 8 — Summary.** Output:
```
Upgrade complete: v29 -> v31

Upgraded (15 files): healthcheck.sh, safety-gate.sh, ... (full list)
Took new (1 customised file): scripts/log-telegram.sh
Kept yours (1 customised file): CLAUDE.md
Merged (1 customised file): .claude/skills/cortana-sync/SKILL.md
Preserved untouched (8 user-added files): my-custom-hook.sh, my-custom-skill/SKILL.md, ... (full list)
New since v29: USER-GUIDE.md, SETUP-CHECKLIST.md, FIRST-WEEK.md, ... (full list of new components)

Run SETUP-CHECKLIST.md to verify the upgrade landed cleanly.
```

**Why this matters:** users who've been operating for months will have evolved their setup. A naive upgrade that overwrites everything is hostile to that investment. This protocol lets users adopt new upstream features (auto-digest improvements, new hooks, new skills) while preserving every personal addition they've made.

### `BLUEPRINT-MARKERS.md` — convention for user-added sections inside blueprint files

Some users will modify CLAUDE.md or other shared files in-place (rather than adding new files). To preserve their additions across upgrades, the upgrade walkthrough recognises sections wrapped in marker comments:

```markdown
<!-- USER-CUSTOM-SECTION:start name="my-custom-routing" -->
... my custom rules go here ...
<!-- USER-CUSTOM-SECTION:end -->
```

When the upgrade overwrites a customised file, it preserves any USER-CUSTOM-SECTION blocks at the same logical location in the new file. If the new blueprint version has restructured the file, the agent prompts the user to manually re-place the preserved blocks.

Recommended: tell users to wrap their custom CLAUDE.md additions in these markers BEFORE upgrading. The pre-upgrade prompt should include:

> "Have you customised CLAUDE.md or other blueprint-shipped files? If yes, wrap your custom sections in USER-CUSTOM-SECTION markers before continuing the upgrade. Any unmarked customisations will trigger the per-file walk."

### `FIRST-WEEK.md` — daily-ops guide

The wizard writes:

```markdown
# Your first week with <agent-name>

Day 1: just play. Run `help`, `projects`, `team`. Send a casual message on Telegram. Watch the agent respond. Do not over-plan.

Day 2-3: pick one real project. Add it via `register a new project called X`. Use `sync X` after each work block. Notice how the agent picks up context faster on day 3 than day 1 — that is memory working.

Day 4: try a complex task. "Send Kai to refactor the auth flow in X." Watch the agent dispatch, work in background, and come back with results. This is the multi-agent pattern.

Day 5: make a correction. When the agent gets something wrong, just tell it "no, do it like this." It saves the correction to memory and won't make the same mistake again.

Day 6: trigger maintenance. Just say `hi` Monday morning. The agent runs healthcheck, surfaces stale items, suggests next priorities.

Day 7: review. Type `wrapup` at end of day. Agent commits memory, pushes the Brain snapshot, and writes a HANDOFF for next week.

If you have done all seven, you are operating at full capability.
```

### `PITFALLS.md` — common things not to do

The wizard writes:

```markdown
# Common pitfalls (read this once, save yourself days)

## Do not commit secrets to memory files

The agent saves to `memory/` automatically and the post-commit hook embeds them. If you tell the agent "my API key is sk-xxx", that string ends up in git history. Use `data/runtime/*` files for secrets (gitignored, 0600 perms).

## Do not edit CLAUDE.md by hand without backing up first

`cp CLAUDE.md CLAUDE.md.bak.$(date +%s)` first. Bad edits to CLAUDE.md break the agent's operating loop. The agent itself can edit CLAUDE.md safely (it knows the structure); you doing it raw is risky.

## Do not skip the SETUP-CHECKLIST first session

Every box matters. The Windows alias quirk is the most common silently-broken item. Half-installed systems waste hours of debugging weeks later.

## Do not delete `data/runtime/`

That directory has your Telegram bot token, persona state, and lock files. Losing it forces you to re-pair everything. Back it up weekly per BACKUP-AND-RECOVERY.md.

## Do not run `git push --force` on main

The hardened safety gate (E5) blocks this hard, but if you somehow get past it: stop, pull, resolve, re-push. Force-push to main destroys shared history. Same on production / develop / release.

## Do not reinstall Cortana over an existing install without backing up

Re-running the wizard on a populated repo can overwrite CLAUDE.md / settings / memory. Always backup the entire repo first: `git branch backup/$(date +%s) && git push origin backup/$(date +%s)`.

## Do not run multiple `<agent-name>` aliases pointing at different repos

Confusion. Each agent name should map to one project. Use `<agent-name>` for Cortana, a different name for any other personal AI you build.

## Do not assume the AI Brain is canonical

The Brain (NotebookLM) is a search-and-summary layer on top of memory snapshots. The CANONICAL store is `memory/*.md`. If they disagree, trust memory files.
```

### `MEMORY-HYGIENE.md` — what to commit, what to gitignore

The wizard writes:

```markdown
# Memory hygiene

The agent saves memory automatically. You usually don't need to think about it. This doc is for the corner cases.

## What auto-commits

- Anything the agent saves to `memory/<type>_<topic>.md` via its core loop step 6
- Anything the agent saves to `agent-memory/<agent-name>/<file>.md`
- The auto-regenerated `memory/MEMORY.md` index (post-commit hook)
- `data/cortana-vec.db` SHA / chunk count tracking (NOT the .db itself; that's gitignored)

## What is gitignored (locally only)

- `data/cortana-vec.db` (regenerable from `bash scripts/embed-memories.sh`)
- `data/runtime/*` (secrets, persona state, lock files)
- `data/audit/*.jsonl` (you can archive these via `bash scripts/audit-archive.sh 30` to push older ones into git)
- `data/youtube-watch-queue.jsonl` and `data/youtube-playlists.jsonl` (local ops state)
- `infra/*/.env` (API keys)

## When to manually save a memory

If the agent missed something important, tell it: "save this to memory: <fact>." It writes a file, commits, and the post-commit hook re-embeds. You should rarely need to do this — the core loop handles it.

## When to clean up memory

Memories accumulate. Once a quarter:
- Run `bash scripts/check-memory-freshness.sh` to surface stale entries (past their TTL)
- Walk through and either re-verify (set `last_verified` to today) or delete (`rm memory/<file>.md`)
- Delete invalidates the post-commit hook auto-removes the chunk from sqlite-vec
```

### `scripts/regenerate-setup-checklist.sh` — for when new components arrive

The wizard writes a stub:

```bash
#!/usr/bin/env bash
# regenerate-setup-checklist.sh — re-write SETUP-CHECKLIST.md based on
# the current state of .cortana-blueprint-version. Used when a new
# extension is installed or a component is upgraded that needs verification.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Regenerating SETUP-CHECKLIST.md based on installed components..."
echo "Open a fresh Claude Code session at $REPO_ROOT and run:"
echo ""
echo "  Read .cortana-blueprint-version. Regenerate SETUP-CHECKLIST.md per"
echo "  the Post-install verification section of the public blueprint,"
echo "  including a checklist item for every component currently installed."
```

### Wizard's final action sequence

After install, the wizard's last step is to write all of these files:

**Project root:**
1. `SETUP-CHECKLIST.md` (verification)
2. `USER-GUIDE.md` (day-1 cheat sheet, includes session management + context window guidance)
3. `BACKUP-AND-RECOVERY.md` (restore docs)
4. `FIRST-WEEK.md` (daily-ops guide)
5. `PITFALLS.md` (anti-patterns)
6. `MEMORY-HYGIENE.md` (memory rules)
7. `scripts/upgrade-cortana.sh` (future bump path)
8. `scripts/regenerate-setup-checklist.sh` (regen helper)

**User scope (one-time, applies to every Claude Code session on this machine):**
9. `~/.claude/statusline-command.sh` (the bash script that renders the statusline)
10. `~/.claude/settings.json` updated to add the `statusLine` block pointing at that script

Plus update the CLAUDE.md template with the First-contact + First-Telegram-message + SETUP-CHECKLIST first-session-check blocks (already shown).

Then the wizard tells the user:

> Setup complete. Six files written to your project root + two scripts under scripts/ + the statusline at ~/.claude/. SETUP-CHECKLIST.md is the one to read first. USER-GUIDE.md is your day-1 cheat sheet (includes when to start a fresh session vs resume, what the context % means). BACKUP-AND-RECOVERY.md tells you what to back up. FIRST-WEEK.md is your week-1 ops guide. PITFALLS.md is what NOT to do. MEMORY-HYGIENE.md is the memory rules. Close this session, run `<agent-name>` from your terminal, and the first session will walk SETUP-CHECKLIST.md before any real work. You'll see the new statusline at the bottom showing your context window — watch it as you work, especially past 50%.

---

# Full reference — Core install wizard, templates, patterns, troubleshooting

The sections above cover the v29-v30 additions (mode chooser, extensions, versioning, OS coverage).
What follows is the complete Core install guide inherited from v28: the 15-question setup wizard,
every template file (CLAUDE.md, settings.json, agents, scripts, hooks), advanced patterns,
and the full troubleshooting catalogue. Skip to any section from the headings; nothing in here
is required if you've already installed Core via Simple mode — these are the full templates
the wizard uses under the hood.

## Prerequisites

Before starting the wizard, ensure the following are installed. The wizard should check for these and help install any that are missing.

**All platforms:**
- **Claude Code** -- the CLI (`claude` command must work)
- **Node.js** (v18+) -- for scripts and tools
- **Git** -- for version control and GitHub integration
- **jq** -- for JSON processing in scripts
- **SQLite** -- for the memory database
  - Mac: `brew install sqlite3` (usually pre-installed)
  - Windows: `winget install SQLite.SQLite`
  - Linux: `sudo apt install sqlite3`
- **bun** -- required for the Telegram plugin and some Claude Code plugins
  - Mac/Linux: `curl -fsSL https://bun.sh/install | bash`
  - Windows: `powershell -c "irm bun.sh/install.ps1 | iex"`

**Optional:**
- **gh** (GitHub CLI) -- for automatic repo creation (`brew install gh` / `winget install GitHub.cli`)
- **notebooklm** -- for the AI Brain feature (installed during setup if selected)

## Instructions for Claude Code

Read this entire section carefully before asking the first question. You are about to run an interactive setup wizard that builds a multi-agent AI command centre.

### How to run the wizard

1. Read this full document first. Understand all four parts before you start asking questions.
2. Ask the questions below **one at a time**. Wait for the user's answer before moving to the next question.
3. Store each answer as a variable using the `{{placeholder}}` names specified. You will need every one of them when generating files from the templates in Part 3.
4. Some questions have branching logic -- only ask them if the conditions are met.
5. After all questions are answered, generate every file listed in the "Generation Order" section using the templates in Part 3. Substitute all `{{placeholders}}` with the user's answers.
6. Run the post-setup validation checks.
7. Print the setup summary.

### Variable reference

These are the variables you will collect. Every template in Part 3 references them by these exact names.

| Variable | Type | Set by question |
|---|---|---|
| `{{orchestrator_name}}` | string | Q1 |
| `{{orchestrator_name_lower}}` | string (lowercase of above) | Derived from Q1 |
| `{{os}}` | mac / windows / linux | Q2 |
| `{{purpose}}` | personal / work / both | Q3 |
| `{{work_type}}` | software-dev / data-science / general-office / custom | Q4 (conditional) |
| `{{plan}}` | max-20x / max-5x / pro | Q5 |
| `{{messaging}}` | telegram / terminal | Q6 |
| `{{telegram_token}}` | string | Q6 (conditional, if telegram) |
| `{{agent_preset}}` | solo-dev / full-team / dev-team / custom | Q7 |
| `{{agents}}` | list of {role, name} | Q7 |
| `{{security}}` | standard / enterprise | Q8 |
| `{{library}}` | yes / no | Q9 |
| `{{brain}}` | yes / no | Q10 |
| `{{personality}}` | string (free text) | Q11 |
| `{{launch_cmd}}` | string | Q12 |
| `{{mcp_servers}}` | list of strings | Q13 |
| `{{plugins}}` | list of strings | Q14 |
| `{{first_project}}` | {name, path, description, stack} or null | Q15 |
| `{{project_path}}` | string (absolute path to the orchestrator project directory) | Derived from current working directory |
| `{{shell_profile}}` | file path (.zshrc, .bashrc, etc.) | Derived from Q2 |
| `{{package_manager}}` | brew / apt / winget | Derived from Q2 |

### Derived values

After collecting answers, compute these before generating files:

- `{{orchestrator_name_lower}}` = lowercase version of `{{orchestrator_name}}`, spaces replaced with hyphens
- `{{shell_profile}}` = `~/.zshrc` on Mac, `~/.bashrc` on Linux, PowerShell profile on Windows
- `{{package_manager}}` = `brew` on Mac, `apt` on Linux, `winget` on Windows
- `{{project_path}}` = the absolute path of the current working directory (where the user is running Claude Code)
- `{{db_name}}` = `{{orchestrator_name_lower}}.db`
- `{{agent_count}}` = length of `{{agents}}` list + 1 (the orchestrator)
- For each agent in `{{agents}}`: `{{agent_<role>_name}}` = the name the user chose for that role

---

## The Questions

### Q1: Name your orchestrator

Ask:
> What would you like to name your orchestrator? This is your AI assistant's identity -- the name it uses when talking to you, the name in the database, the name in every config file. Pick something you want to see every day.
>
> Examples: Cortana, Jarvis, Friday, Atlas, Nova, Sage, or anything you like.

**Valid answers:** Any string. No restrictions.
**Default:** None -- this must be chosen.
**Affects:** Every file in the system. The orchestrator name appears in CLAUDE.md, the database filename, shell launch commands, agent configs, help text, team text, and all scripts. This is the single most important variable.

---

### Q2: Operating system

Ask:
> What operating system are you on?
>
> 1. **Mac** -- macOS with Homebrew
> 2. **Windows** -- Windows with PowerShell (no WSL needed)
> 3. **Linux** -- Ubuntu, Debian, Fedora, Arch, or similar

**Valid answers:** Mac, Windows, Linux (or 1, 2, 3)
**Default:** None.
**Affects:** Shell profile path, package manager commands, file paths in scripts, date command syntax, shell function format (bash/zsh vs PowerShell).

**After they answer:** Confirm the derived values:
- Mac: shell profile = `~/.zshrc`, package manager = `brew`
- Windows: shell profile = PowerShell `$PROFILE`, package manager = `winget`, scripts run natively in PowerShell (no WSL needed). Install SQLite via `winget install SQLite.SQLite` or `choco install sqlite`
- Linux: shell profile = `~/.bashrc`, package manager = `apt`

---

### Q3: Purpose

Ask:
> What will you use this system for?
>
> 1. **Personal projects** -- side projects, learning, personal productivity
> 2. **Work** -- professional software development, business operations
> 3. **Both** -- personal and work use
>
> This affects security defaults and which agent presets I'll suggest.

**Valid answers:** Personal, Work, Both (or 1, 2, 3)
**Default:** None.
**Affects:** Security tier default (Enterprise when Work/Both), agent preset suggestions, whether audit logging is recommended.

---

### Q4: Work type (conditional)

**Only ask if Q3 = Work or Both.**

Ask:
> What kind of work?
>
> 1. **Software Development** -- building apps, APIs, services, full-stack development
> 2. **Data Science** -- ML models, data pipelines, analysis, notebooks
> 3. **General Office** -- documents, email, scheduling, project management
> 4. **Custom** -- I'll describe it
>
> If Custom, tell me what you do and I'll suggest the right agent lineup.

**Valid answers:** Software Development, Data Science, General Office, Custom (or 1, 2, 3, 4)
**Default:** None.
**Affects:** Agent preset recommendations. Software Dev gets the Dev Team preset suggestion. Data Science gets a research-heavy preset. General Office gets a writing/productivity-heavy preset.

If they pick Custom, ask them to describe their work in a sentence. Use that description to recommend agents from the available roles.

---

### Q5: Claude plan

Ask:
> What Claude plan are you on?
>
> 1. **Max 20x** -- highest tier. Enables aggressive parallel agent spawning (4-6 concurrent), background task dispatch, and the reply-first pattern where you get an instant acknowledgment while agents work in the background.
> 2. **Max 5x** -- mid tier. Enables moderate parallel spawning (2-3 concurrent), background dispatch for longer tasks.
> 3. **Pro** -- base tier. Agents run sequentially. Still fully functional, just one thing at a time.
>
> Not sure? Start with whatever plan you're on. The system works on all tiers -- the plan just determines how many agents can work simultaneously.

**Valid answers:** Max 20x, Max 5x, Pro (or 1, 2, 3)
**Default:** None.
**Affects:** Agent spawning rules in CLAUDE.md, context management strategy (when to warn about context usage), recommended maximum agent count, batch sync strategy (parallel vs sequential).

**Plan-specific limits to communicate:**

| Feature | Max 20x | Max 5x | Pro |
|---|---|---|---|
| Parallel agents | 4-6 concurrent | 2-3 concurrent | Sequential |
| Background spawning | Aggressive | Moderate | Minimal |
| Recommended max agents | 8+ | 5-6 | 3-4 |
| Context warning threshold | 85% | 75% | 60% |
| Batch sync | Parallel (worktrees) | Sequential | Sequential |

If they're on Pro and later select more agents than recommended, warn them but don't block it.

---

### Q6: Messaging

Ask:
> Do you want Telegram integration? This lets you control everything from your phone -- send a message on Telegram and your AI responds. Your laptop runs Claude Code in a terminal window and you talk to it remotely.
>
> 1. **Yes** -- set up Telegram (I'll walk you through creating the bot)
> 2. **No** -- terminal only (you'll interact directly in the Claude Code terminal)
>
> You can always add Telegram later. It takes about 2 minutes.

**Valid answers:** Yes, No (or 1, 2)
**Default:** No.
**Affects:** Whether the Telegram plugin is installed, whether log-telegram.sh and the telegram logging hook are generated, whether the core loop includes Telegram logging steps, whether .mcp.json is generated, and the launch command format.

**If Yes -- run the BotFather walkthrough:**

Tell the user:
> Let's create your Telegram bot. Follow these steps:
>
> **Step 1:** Open Telegram on your phone or desktop. Search for **@BotFather** and start a chat with it. BotFather is Telegram's official bot for creating bots.
>
> **Step 2:** Send `/newbot` to BotFather.
>
> **Step 3:** BotFather will ask for a display name. This is what people see in Telegram. You can use your orchestrator's name: **{{orchestrator_name}}**
>
> **Step 4:** BotFather will ask for a username. This must end in `bot`. Try: **{{orchestrator_name_lower}}_bot** or **{{orchestrator_name_lower}}bot**
>
> **Step 5:** BotFather will give you an API token. It looks like this: `7123456789:AAHxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`. Copy it.
>
> **Step 6:** Paste the token here and I'll configure everything.

After they paste the token, store it as `{{telegram_token}}`.

Then tell them:
> I'll install the Telegram plugin during setup. After setup, you'll be able to send your bot a message and get a response.
>
> **Important:** The first time you message the bot, you'll need to approve the pairing in your Claude Code terminal. This is a one-time security step.

---

### Q7: Agent team

This is a multi-step question. First, show the preset based on their earlier answers.

**Determine which preset to suggest:**
- If Q3 = Personal and (Q4 not asked or Q4 != Software Development): suggest **Solo Dev**
- If Q3 = Personal and they seem like a power user (mentioned multiple domains): suggest **Full Team**
- If Q3 = Work and Q4 = Software Development: suggest **Dev Team**
- If Q3 = Both: suggest **Full Team**
- Otherwise: suggest **Solo Dev** with a note about other options

**Present the suggested preset first, then show all options:**

Ask:
> Time to build your team. Based on what you told me, I'd suggest the **[suggested preset]** lineup. Here are all the options:
>
> **Solo Dev** (3 agents) -- lean and fast
> - Orchestrator (that's {{orchestrator_name}})
> - Engineer -- code, architecture, debugging, reviews
> - Researcher -- analysis, market research, tech evaluation
>
> **Full Team** (8 agents) -- covers everything
> - Orchestrator
> - Engineer -- code, architecture, debugging
> - Researcher -- analysis, market research, intel
> - Marketing -- growth, social media, ASO, launches
> - DevOps -- deploy, CI/CD, infra, monitoring
> - Writer -- blog posts, docs, emails, presentations
> - Business -- revenue, pricing, partnerships, contracts
> - Trading -- strategies, backtesting, portfolio, markets
>
> **Dev Team** (9 agents) -- built for software shops
> - Orchestrator
> - Lead Engineer -- architecture, system design, code reviews
> - Frontend Engineer -- UI/UX, React/Vue/Angular, CSS, accessibility
> - Backend Engineer -- APIs, databases, auth, server logic
> - DevOps Engineer -- CI/CD, deployment, monitoring, Docker, cloud
> - QA Engineer -- test writing, test planning, edge cases, regression
> - Security Engineer -- vulnerability scanning, code audit, OWASP
> - Technical Writer -- API docs, README, architecture docs
> - Researcher -- tech evaluation, library comparison, best practices
>
> **Custom** -- pick and choose from any of the roles above, or define your own
>
> Which preset? Or say "custom" to build your own lineup.

**After they pick a preset (or custom):**

If they picked a preset, confirm the roster and ask:
> Want to add, remove, or change any roles before we name them?

If they said custom, ask:
> Which roles do you want? Pick from this list or describe new ones:
> - Engineer, Researcher, Marketing, DevOps, Writer, Business, Trading
> - Lead Engineer, Frontend Engineer, Backend Engineer, QA Engineer, Security Engineer, Technical Writer
> - Or describe a custom role and I'll add it.

**After the roster is finalized, name each agent:**

For each agent role in the final roster, ask:
> Name your **[Role]** agent:

Give a suggestion for each one based on the role. Examples:
- Engineer: "Kai, Atlas, Forge, or anything you like"
- Researcher: "Nadia, Scout, Sage, Aria"
- Marketing: "Rio, Harper, Blaze, Zara"
- DevOps: "Marco, Bolt, Flux, Sigma"
- Writer: "Jules, Pen, Quinn, Muse"
- Business: "Elena, Sterling, Blake, Morgan"
- Trading: "Warren, Quant, Ledger, Apex"
- Lead Engineer: "Kai, Chief, Principal, Arch"
- Frontend: "Pixel, React, Vue, Canvas"
- Backend: "Core, Node, Rust, Stack"
- QA: "Test, Guard, Proof, Check"
- Security: "Shield, Vault, Sentinel, Cipher"
- Technical Writer: "Docs, Scribe, Jules, Ink"

You can ask them to name multiple agents at once to save time:
> Let's name your agents. Give me names for each role (or hit enter for the suggestion):
> - Engineer (suggestion: Kai):
> - Researcher (suggestion: Nadia):
> [etc.]

Store the complete roster as `{{agents}}` -- a list of `{role, name}` pairs.

---

### Q8: Security level

Ask:
> Security level?
>
> 1. **Standard** -- a safety gate that blocks destructive commands (rm -rf, DROP TABLE, force push), permission allowlist for common safe commands, database backups on maintenance. Good for personal projects.
>
> 2. **Enterprise** -- everything in Standard, plus: full audit log of every tool call, stricter deny list (no curl to external URLs or package installs without approval), sensitive file detection (.env, credentials, keys), git signed commits enforced, file access scoped to the project directory. Pick this for work or if you want maximum protection.
>
> [Default: {{Enterprise if purpose=Work or Both, Standard otherwise}}]

**Valid answers:** Standard, Enterprise (or 1, 2)
**Default:** Enterprise if Q3 = Work or Both, Standard if Q3 = Personal.
**Affects:** Which safety gate hook variant is generated, whether the audit log hook is created, permission allowlist strictness in settings.json, whether sensitive file detection is active.

---

### Q9: Knowledge library

Ask:
> Do you want a knowledge library? This is a folder where your agents write and reference handbooks -- structured documents on topics they research or learn about. Over time it becomes a personal wiki that your agents draw from.
>
> For example, an engineer agent might write a handbook on "Authentication Patterns in Next.js" after building a login system. A research agent might write one on "Competitive Landscape for [Your Product]" after doing market analysis. The library grows organically as you use the system.
>
> 1. **Yes** -- create the library structure
> 2. **No** -- skip it (you can add one later)

**Valid answers:** Yes, No (or 1, 2)
**Default:** No.
**Affects:** Whether the Library folder scaffold is generated, whether CLAUDE.md includes library integration instructions, whether agent configs reference the library.

---

### Q10: NotebookLM Brain

Ask:
> Do you want a NotebookLM Brain? This connects your system to a Google NotebookLM notebook that stores session summaries and project snapshots. It gives your AI long-term memory that you can query across sessions -- "what did we decide about the database schema?" or "when did we fix that auth bug?"
>
> Requirements: a Google account and the `notebooklm` CLI tool installed.
>
> 1. **Yes** -- set up Brain integration (I'll guide you through creating the notebook)
> 2. **No** -- skip it (local memory only, which still works great)
>
> Note: the Brain is optional. The SQLite memory system handles session-to-session context on its own. The Brain adds cross-session search across project summaries and decisions.

**Valid answers:** Yes, No (or 1, 2)
**Default:** No.
**Affects:** Whether Brain integration sections appear in CLAUDE.md, whether the wrapup flow pushes to NotebookLM, whether the `brain` command is registered, whether smart memory routing includes Brain queries.

**If Yes:**

Tell the user:
> After setup, you'll need to:
> 1. Install the NotebookLM CLI: follow instructions at the project repo
> 2. Run `notebooklm login` to authenticate with your Google account
> 3. Run `notebooklm create "{{orchestrator_name}} Brain"` to create your notebook
> 4. Copy the notebook ID and I'll add it to your config
>
> We'll handle this as a post-setup step. I'll remind you.

---

### Q11: Personality

Ask:
> Describe your orchestrator's personality. How should {{orchestrator_name}} talk to you? This seeds the initial voice -- it'll evolve naturally over time as you use the system.
>
> Some examples:
> - "Direct and efficient. No fluff. Have opinions."
> - "Formal and thorough. Explain reasoning. Be precise."
> - "Casual and witty. Use humor. Keep it light."
> - "Warm but professional. Encouraging. Patient."
> - "Blunt. Challenge my assumptions. Push back when I'm wrong."
>
> Or describe it in your own words.

**Valid answers:** Any string.
**Default:** "Direct and efficient. No fluff. Have opinions." (if they just hit enter)
**Affects:** The personality section in CLAUDE.md, the orchestrator's initial voice, how agents communicate.

---

### Q12: Launch command

Ask:
> What terminal command do you want to use to start your system? This generates four shell functions:
>
> - `<command>` -- start with Telegram (if enabled)
> - `<command>-terminal` -- start in terminal-only mode
> - `<command>-resume` -- resume the last session with Telegram
> - `<command>-resume-terminal` -- resume in terminal mode
>
> All commands include `--dangerously-skip-permissions` so your system runs without constant permission prompts. Your safety gate hook handles security instead.
>
> If Telegram is disabled, the first two are identical and the `-terminal` variants are omitted.
>
> Examples: `cortana`, `jarvis`, `ai`, `cmd`, `assistant`, or whatever you want to type.

**Valid answers:** Any string (no spaces, lowercase recommended).
**Default:** Lowercase version of orchestrator name (e.g., "Cortana" -> "cortana").
**Affects:** Shell profile functions that get added to your shell config.

---

### Q13: MCP servers

Ask:
> Which MCP servers would you like to connect? These give your agents access to external services. Pick the ones relevant to your work -- you can always add more later.
>
> Available now:
>
> 1. **Chrome** -- browser automation, web scraping, form filling, screenshot capture
> 2. **Neon** -- serverless Postgres database, branching, SQL execution, schema management
> 3. **Gmail** -- read and draft emails, search inbox, manage labels
> 4. **Google Calendar** -- view schedule, create events, find free time
> 5. **Notion** -- read and write pages, search docs, manage databases
> 6. **Vercel** -- deploy, check build logs, get deploy URLs, manage domains
> 7. **Supabase** -- database, auth, storage, edge functions (backend-as-a-service)
> 8. **HubSpot** -- CRM, contacts, deals, companies, pipelines
> 9. **Computer Use** -- control your desktop, click buttons, type text, take screenshots
>
> Enter the numbers of the ones you want (e.g., "1, 3, 4") or "none" to skip. Everything you skip is still available to add later.

**Valid answers:** Comma-separated numbers, "none", or "all".
**Default:** None.
**Affects:** .mcp.json configuration, which MCP tools are referenced in CLAUDE.md agent capabilities, whether specific MCP setup instructions are included.

After they pick, confirm the selection and note which ones are available later:
> Selected: [list]. The others (Chrome, Neon, Gmail, etc.) are available any time -- just say "add [server] MCP" in a session and I'll configure it.

---

### Q14: Plugins and skills

Ask:
> Which plugins and skills do you want to install? These extend what your agents can do.
>
> **Plugins** (always-on capabilities):
> - **superpowers** -- planning workflows, systematic debugging, code review, TDD, parallel task dispatch. **Recommended for everyone.**
>
> **Skills** (on-demand capabilities, activated when needed):
> - **document-skills** -- create and edit PDFs, Word docs, Excel spreadsheets, PowerPoint presentations
> - **frontend-design** -- premium UI/UX generation with design system support
> - **example-skills** -- reference implementations for common patterns
>
> I'd recommend at least **superpowers**. The others depend on your use case:
> - Building apps with UIs? Add **frontend-design**.
> - Working with office documents? Add **document-skills**.
> - Learning Claude Code patterns? Add **example-skills**.
>
> Enter the names you want (e.g., "superpowers, document-skills") or "all" or "none".

**Valid answers:** Comma-separated names, "all", "none".
**Default:** superpowers.
**Affects:** Plugin installation commands run during setup, skill references in CLAUDE.md.

---

### Q15: First project

Ask:
> Let's register your first project. This creates the project docs structure (CLAUDE.md, HANDOFF.md, FEATURES.md) and optionally a git repo and GitHub remote.
>
> If you already have a project folder you want to manage, we'll register it. If not, we can skip this and register projects later.
>
> 1. **Register a project** -- I'll ask for details
> 2. **Skip** -- I'll register projects later
>
> What would you like to do?

**If they choose to register:**

Ask these in sequence:
> - **Project name:** (e.g., "MyApp", "DataPipeline", "CompanySite")
> - **Folder path:** (absolute path, or "create" to make a new folder)
> - **One-line description:** (what does this project do?)
> - **Tech stack:** (e.g., "Next.js, TypeScript, Postgres", "Python, FastAPI, Redis")

Store as `{{first_project}}` with all four fields.

**Valid answers for "Register or Skip":** Register, Skip (or 1, 2)
**Default:** Skip.
**Affects:** Whether register-project.sh runs during setup, whether a project entry appears in docs/projects.md.

---


## Q16-Q20: Power-user extensions (Advanced mode only)

**Skip this block if Q8 Security / Q5 plan setup defaulted to Simple mode.** If the user picked Advanced mode, walk through each extension, explain what it does, the cost / time / tradeoffs, and ask whether to install now or later.

For each extension below, use the full "explain before asking" pattern — show the user **what it is**, **how it works**, **what it costs**, **what it requires**, and **who benefits** before taking a yes/no.

---

### Q16: E1 — Semantic memory (sqlite-vec + Nomic-embed)

Ask:
> Your memory system is a pile of markdown files. To find "have we hit this before?" you'd grep for exact strings — which fails on paraphrases, misses synonyms, and misses context. Semantic memory solves that.
>
> **What you get:** a local vector-search index over every memory file. Query it like: `bash scripts/memory-search.sh "alpha channel icon issue"` — it returns the top 5 matching memory chunks with file paths + similarity scores. 95 ms median latency.
>
> **How it works:** Ollama runs Nomic-embed-text (a 137M-parameter embedding model) locally on your Mac. Every memory chunk gets embedded into a 768-dimensional vector, stored in a tiny sqlite-vec database. Search queries get embedded the same way and nearest-neighbour matched.
>
> **What it costs:**
> - **Money:** £0. No API calls. Weights are free, compute is local.
> - **Disk:** ~300 MB (Nomic-embed model) + ~5 MB (vector DB for a typical 500-chunk corpus).
> - **RAM:** ~500 MB when Ollama is active, 0 when idle (Ollama auto-unloads after 5 min).
> - **Install time:** ~10 minutes.
>
> **Pain it solves:** "I know we decided something about X, but I can't remember exactly what I called it in the memory file." Grep can't help you there; this can.
>
> 1. **Install now** — I'll walk you through Ollama + sqlite-vec + the first embed
> 2. **Skip** — add later with `bash scripts/install-blueprint.sh --add E1`

**Valid answers:** Install, Skip (or 1, 2)
**Default:** Install (if Advanced mode — sqlite-vec is the single biggest daily-use improvement over base Core).
**Affects:** Whether Ollama is installed, whether `data/cortana-vec.db` exists, whether the post-commit embed hook is live, whether `bash scripts/memory-search.sh` is usable.

---

### Q17: SKIPPED in v30

> E2 (Graphiti temporal knowledge graph) was an opt-in extension in v29 that has been ruled out in v30 after a utilisation audit found it produced zero queries that changed an answer at single-user scale. Q17 is preserved as a numbered placeholder so the wizard's step counts match across v29 and v30; the wizard skips this step automatically. If you genuinely have a multi-user / temporal-reasoning use case, install Mem0 (Apache 2.0) or Letta directly outside this blueprint — do not try to revive E2.

---

### Q18: E3 — Agent Teams + channel.md whiteboard

Ask:
> When two agents work on the same project in parallel, each one's decisions are invisible to the other until both report back. Agent Teams + the channel.md pattern fix that — agents share a live markdown whiteboard and can send peer-to-peer messages.
>
> **What you get:**
> - `TeamCreate`, `SendMessage`, `TeamDelete` tools for live agent-to-agent messaging (Claude Code 2.1.32+)
> - A `data/agent-channels/<task>.md` shared whiteboard where every agent Edit-appends progress, decisions, blockers. The orchestrator re-reads between its own tool calls to resolve cross-agent state.
>
> **How it works:** A single env flag (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) unlocks the team primitives. The whiteboard pattern is append-only markdown. When the task ships, archive the channel to `data/agent-channels/archive/YYYY-MM/`.
>
> **What it costs:** £0. Just a feature flag and a directory.
>
> **Install time:** ~5 minutes.
>
> **Pain it solves:** "I sent Kai to build the API and Marco to deploy it. Marco needs Kai's schema decisions but they don't know about each other." With Teams, they share context live.
>
> **Experimental:** this is an experimental Claude Code feature. Worth trying. If it's unstable, turn the flag off and the whiteboard still works as a plain-file pattern.
>
> 1. **Install now** — flip the flag + create the directory
> 2. **Skip** — default sequential agent spawning, no shared context

**Valid answers:** Install, Skip (or 1, 2)
**Default:** Install (low cost, high ceiling).
**Affects:** `.claude/settings.json` env block, `data/agent-channels/` directory creation, whether CLAUDE.md mentions the channel.md pattern in orchestration habits.

---

### Q19: E4 — Observability audit layer

Ask:
> Every tool call your agents make can be logged to a local audit file, so when a background agent runs for 10 minutes you can read what it actually did without tailing a transcript.
>
> **What you get:**
> - A PostToolUse hook that writes one JSON line per tool call to `data/audit/YYYY-MM-DD.jsonl` (async, non-blocking)
> - `bash scripts/cortana-live.sh --follow` — a pretty-printed live viewer with filters (by tool, project, day, failed-only)
> - `bash scripts/audit-archive.sh` — retention (gzip-archives logs >=30 days old into `data/audit/archive/YYYY/MM.jsonl.gz`, committed to git so the forensic trail is permanent)
> - `bash scripts/history.sh <query>` — unified search across Telegram conversation history, audit log (live + archived), git commit log, and memory markdown
>
> **How it works:** a Bash hook under `.claude/hooks/audit-log-hook.sh` receives the tool payload on stdin after each tool call, extracts name / input / output / success, strips secret patterns, appends to today's JSONL file.
>
> **What it costs:** £0. Pure local Bash.
>
> **Privacy:** audit logs are gitignored (never leave your machine). Regex scrubs common secret shapes (api_key, token, password, bearer, authorization) before write. Input and output summaries capped at 240 chars.
>
> **Install time:** ~5 minutes.
>
> **Pain it solves:** "Kai said he committed the fix but I can't see what he did." Now you can — live tail shows every bash, every edit, every Agent spawn in real time.
>
> 1. **Install now** — copy the hook + scripts, wire into settings.json
> 2. **Skip** — no per-tool-call audit trail

**Valid answers:** Install, Skip (or 1, 2)
**Default:** Install (paid for itself within hours of install during our own v29 dogfooding).
**Affects:** `.claude/hooks/audit-log-hook.sh` creation, PostToolUse hook entry in settings.json, `data/audit/` gitignore entry.

---

### Q20: E5 — Hardened safety gate

Ask:
> The Core safety gate (installed by default) blocks `rm`, `DROP TABLE`, `git push --force`, `sudo`, etc. The Hardened gate adds:
>
> - **Hard-blocks on force-push to `main`/`master`/`production`/`prod`/`release`/`develop`** — cannot be approved through the hook even with your confirmation. Requires manual Terminal if you really need it.
> - **Hard-blocks on history-rewriting ops:** `git filter-branch`, `filter-repo`, `reflog expire`, `gc --prune=now`, `update-ref -d`.
> - **Word-boundary regex on `rm`** — fixes false-positives where the Core gate blocks harmless commands like `echo "format..."` because "format" contains "rm" substring.
> - **More comprehensive git coverage:** blocks `rebase -i`, `--onto`, `commit --amend`, `checkout -- .`, `restore .`, `stash drop`, `stash clear`, `worktree remove --force`, `branch -D`.
>
> **What you get:** protection against the force-push-instead-of-commit class of incident that destroys shared git history. Specifically this blueprint was hardened after Cortana once force-pushed by mistake and overwrote commits.
>
> **What it costs:** £0. Same Bash hook, tighter rules. Zero token usage.
>
> **Install time:** ~5 minutes.
>
> **Test suite:** 48 cases in `/tmp/safety_test.sh` (regex false-positives + every destructive git op). Validated on install.
>
> 1. **Install now** — replaces the Core safety gate with the hardened version (backup is kept at `.claude/hooks/safety-gate.sh.core-backup`)
> 2. **Skip** — keep the Core gate

**Valid answers:** Install, Skip (or 1, 2)
**Default:** Install in Advanced mode (the Core gate will not catch a determined mistake — hardened is what you want for any real repo).
**Affects:** `.claude/hooks/safety-gate.sh` overwrite (with backup), same for the global gate at `~/.claude/hooks/safety-gate.sh`.

---

After Q16-Q20, echo back the extension choices and update `.cortana-blueprint-version` accordingly:

```yaml
blueprint_version: v30
installed: <now>
mode: <simple|advanced>
extensions:
  E1_sqlite_vec: <true|false>
  E2_graphiti: false   # deprecated as of v30 — never set to true on a fresh install
  E3_agent_teams: <true|false>
  E4_observability: <true|false>
  E5_hardened_safety: <true|false>
```

---

## Generation Order

After all questions are answered, generate files in this order. Each file comes from a template in Part 3.

1. **Create directory structure:**
   ```
   {{project_path}}/
   ├── .claude/
   │   ├── settings.json
   │   ├── hooks/
   │   │   ├── safety-gate.sh
   │   │   ├── log-telegram-hook.sh      (only if messaging=telegram)
   │   │   └── audit-log-hook.sh         (only if security=enterprise)
   │   └── agents/
   │       └── <agent-name>.md           (one per selected agent)
   ├── scripts/
   │   ├── maintain.sh
   │   ├── healthcheck.sh
   │   ├── load-context.sh
   │   ├── commit-watcher.sh
   │   ├── log-correction.sh
   │   ├── history.sh
   │   ├── register-project.sh
   │   ├── check-blueprint-drift.sh
   │   ├── sync-project-memories.sh
   │   ├── pre-compaction-sync.sh
   │   ├── post-compaction-reload.sh
   │   ├── session-end-sync.sh
   │   ├── log-telegram.sh              (only if messaging=telegram)
   │   └── batch-sync.sh
   ├── data/
   │   ├── help-text.md
   │   ├── team-text.md
   │   └── telegram-history/            (only if messaging=telegram)
   ├── docs/
   │   └── projects.md
   ├── Library/                         (only if library=yes)
   │   └── CLAUDE.md
   └── CLAUDE.md
   ```

2. **Create the SQLite database:** run `setup-db.sh` which creates `data/{{db_name}}` with the full schema (memories table with FTS5, corrections table, patterns table).

3. **Generate CLAUDE.md** from the master template. This is the largest file -- it defines the orchestrator's identity, core loop, routing table, commands, agent spawning rules, safety rules, and everything else.

4. **Generate .claude/settings.json** from the appropriate security tier template.

5. **Generate hook scripts** and make them executable (`chmod +x`).

6. **Generate all scripts/** and make them executable.

7. **Generate agent configs** in `.claude/agents/` -- one per selected agent.

8. **Create agent + orchestrator memory directories INSIDE the repo**, then symlink Claude Code's expected paths to them. Canonical files live in the repo so `git commit` backs them up and cloud routines see them:
    ```bash
    mkdir -p {{project_root}}/memory
    mkdir -p {{project_root}}/agent-memory/<agent-name-lower>  # for each agent
    PROJECT_SLUG=$(echo "{{project_root}}" | sed 's|/|-|g; s|^-||')
    mkdir -p ~/.claude/projects/$PROJECT_SLUG
    ln -s {{project_root}}/memory ~/.claude/projects/$PROJECT_SLUG/memory
    ln -s {{project_root}}/agent-memory ~/.claude/agent-memory
    ```
    Also generate `scripts/restore-memory-symlinks.sh` so a fresh clone on a new Mac can rebuild the symlinks in one command. The orchestrator repo MUST stay private -- memory files contain personal and project context.

9. **Generate .mcp.json** if Telegram or any MCP servers were selected.

10. **Add shell launch functions** to the user's shell profile.

11. **Generate data/help-text.md and data/team-text.md** from the agent roster.

12. **Generate docs/projects.md** template.

13. **Generate Library scaffold** if library=yes.

14. **Install Telegram plugin** if messaging=telegram:
    ```
    claude plugin add telegram@claude-plugins-official
    ```
    Then configure with the token.

15. **Install selected plugins** (superpowers, document-skills, etc.):
    ```
    claude plugin add <plugin-name>
    ```

16. **Register first project** if one was provided -- run register-project.sh with the project details.

17. **Run post-setup validation.**

---

## Post-Setup Validation

After generating everything, run these checks and report results:

### 1. File verification
Check that every generated file exists and is non-empty. List any missing files.

### 2. Database verification
Run `sqlite3 data/{{db_name}} "SELECT count(*) FROM memories;"` -- should return 0 (empty but valid).

### 3. Script permissions
Verify all scripts in `scripts/` and `.claude/hooks/` are executable.

### 4. Shell functions
Source the shell profile and verify the launch commands are defined:
```bash
source {{shell_profile}} && type {{launch_cmd}}
```

### 5. Telegram connection (if enabled)
Send a test message to verify the bot is responding:
> Tell the user: "Open Telegram and send any message to your bot. I'll wait for it to come through."
> When the message arrives, confirm: "Telegram is connected. You can control {{orchestrator_name}} from your phone."

### 6. Plugin verification
For each installed plugin, verify it loaded:
```bash
claude plugin list
```

### 7. Healthcheck
Run the generated `scripts/healthcheck.sh` and display results.

### Print setup summary

After all checks pass, print:

```
Setup complete.

{{orchestrator_name}} is ready.

System:
- OS: {{os}}
- Plan: {{plan}}
- Security: {{security}}
- Messaging: {{messaging}}

Team ({{agent_count}} agents):
- {{orchestrator_name}} (Orchestrator)
- [for each agent: {{name}} ({{role}})]

Integrations:
- Telegram: [connected / not configured]
- MCP servers: [list or "none"]
- Plugins: [list or "none"]
- Library: [enabled / disabled]
- Brain: [enabled / disabled]

Launch commands:
- {{launch_cmd}}                  Start {{orchestrator_name}}
- {{launch_cmd}}-terminal         Start in terminal mode
- {{launch_cmd}}-resume           Resume last session
- {{launch_cmd}}-resume-terminal  Resume in terminal mode

First steps:
1. Run `{{launch_cmd}}` to start your first session
2. Say "hey" -- {{orchestrator_name}} will run maintenance and greet you
3. Try "help" to see all commands
4. [If Telegram enabled:] Message your bot from Telegram to test remote control
5. [If Brain enabled:] Run `notebooklm login` then `notebooklm create "{{orchestrator_name}} Brain"` to set up long-term memory
```

---

--- END OF PART 1: SETUP WIZARD ---

Part 2: Architecture Reference begins below.

---

# Part 2: Architecture Reference

This section documents how the system works after setup. Claude reads it to understand what it built. You read it to understand what you're running. Everything below applies regardless of which agents you chose, which plan you're on, or whether you use Telegram or terminal.

---

## 1. Architecture Overview

The entire system is one Claude Code session reading one CLAUDE.md file. That's it.

When Claude Code starts, it reads the CLAUDE.md in the current working directory. That file tells it who it is (your orchestrator), what agents it has (personas with distinct roles and expertise), how to process messages (the core loop), what safety rules to follow, and what commands to respond to. The agents are not separate processes, containers, or API endpoints. They are personas within the same session. When your orchestrator routes a message to the engineer agent, Claude shifts into the engineer's role, expertise, and voice. The context window is shared. The model is the same. The difference is in the instructions.

This simplicity is deliberate. There are no microservices to deploy, no inter-process communication to debug, no orchestration layer to maintain. One CLAUDE.md, a few bash scripts, a SQLite database, and optionally a Telegram bot. The system runs on your laptop. When the laptop is on and Claude Code is running, the system is live. When you close it, it stops.

State persists across sessions through three mechanisms: the SQLite database (operational memory -- research findings, project context, decisions), Claude Code's built-in memory system (behavioural learning -- how you want things done, what mistakes to avoid), and project documentation files (HANDOFF.md for session continuity, FEATURES.md for product documentation). When a new session starts, Claude reads the CLAUDE.md, loads its memory files, and picks up where the last session left off.

For parallel work, Claude Code spawns sub-agents. On Max 20x, you can have 4-6 agents working simultaneously in background threads, each with their own context window. On Max 5x, 2-3 concurrent agents. On Pro, agents run sequentially. The orchestrator always stays responsive -- it acknowledges your message immediately, dispatches agents in the background, and sends results when they finish. You never stare at silence wondering if something is happening.

The architecture scales by adding agents and scripts, not by adding infrastructure. A three-agent setup and a twelve-agent setup run on the same laptop, the same way. The CLAUDE.md just has more routing rules.

---

## 2. The Agent System

### Roles and routing

Every agent has a role (what they do), signal words (what triggers routing to them), and a personality (how they communicate). The orchestrator reads your message, matches it against the routing table, and delegates to the right agent.

The routing table in CLAUDE.md looks like this:

```markdown
## Routing table
| Signal | Agent |
|---|---|
| Research, analysis, market sizing | @{{researcher_name}} |
| Code, bugs, architecture, review | @{{engineer_name}} |
| Deploy, CI/CD, infra, monitoring | @{{devops_name}} |
```

Signal matching is intent-based, not keyword-based. "Can you look into what competitors charge?" routes to the researcher even though it doesn't contain the word "research." Claude understands context.

Multi-domain requests get split. "Research competitors then write a comparison blog post" becomes two subtasks: the researcher gathers data, then the writer turns it into content. The orchestrator coordinates the handoff.

If the orchestrator can't determine intent, it asks. It does not guess.

### Agent configuration files

Each agent has a config file at `.claude/agents/<agent-name-lower>.md`. This file defines:

```markdown
# {{agent_name}} -- {{role}}

## Role
One paragraph describing what this agent does.

## Personality
How they communicate. Tone, style, quirks.

## Capabilities
- Bullet list of what they can do

## Routing signals
When to route messages to this agent.

## Constraints
What they should not do. Boundaries with other agents.
```

The orchestrator references these configs when routing. Agents reference them when they need to understand their own scope.

### Adding a new agent

Adding an agent after setup requires updates in six places:

1. **CLAUDE.md** -- add to routing table, update agent count
2. **`.claude/agents/<name>.md`** -- create the config file
3. **`{{project_root}}/agent-memory/<name>/MEMORY.md`** -- create the memory directory and index inside the repo (Claude Code reads it via the `~/.claude/agent-memory/<name>/` symlink)
4. **`data/help-text.md`** -- add to the command list
5. **`data/team-text.md`** -- add to the team roster display
6. **`docs/projects.md`** -- no change needed, but the agent count in descriptions should match

Never leave a partial update. If the routing table references an agent that has no config file, or the team roster lists an agent not in the routing table, things break in confusing ways.

### Removing an agent

Reverse the process: remove from all six places. Delete the config file and memory directory. Any memories saved by that agent in the SQLite database can stay (they are historical context) or be pruned manually.

### Agent memory persistence

Each agent has a persistent memory directory at `{{project_root}}/agent-memory/<name>/` (canonical, inside the orchestrator repo). Claude Code accesses it via the `~/.claude/agent-memory/<name>/` symlink. Inside it:

- **MEMORY.md** -- an index file loaded into every conversation. One-line pointers to individual memory files. Keep it under 200 lines.
- **Individual memory files** -- markdown files with frontmatter containing the actual memory content.

This is separate from the SQLite database. Agent memory files store behavioural learning: patterns discovered, approaches that worked, domain-specific knowledge accumulated over time. The SQLite database stores operational memory: project context, research findings, task tracking.

When an engineer agent discovers a tricky framework pattern, it saves to its memory directory. When a researcher agent completes an analysis, the findings go to SQLite. The distinction matters because memory files load automatically every session (costing tokens) while SQLite is queried on demand (costing nothing until accessed).

---

## 3. Core Loop

The core loop is the sequence your orchestrator follows for every incoming message. There are two variants depending on whether Telegram is enabled.

### Telegram variant (7 steps)

```
1. Receive message from user via Telegram
2. Log it: bash scripts/log-telegram.sh "user" "<message>" "<project>" <has_image>
3. Check memory (conditional -- skip for simple confirmations, commands, or 
   when context is already loaded)
4. Route to the right agent with a context packet
5. Send reply, then log it: bash scripts/log-telegram.sh "{{orchestrator_name_lower}}" "<reply>" "<project>" false
6. Save important context as a new markdown file in memory/ (post-commit hook auto-embeds into sqlite-vec)
7. If user corrected you, log it: bash scripts/log-correction.sh "<category>" "<description>"
```

Step 2 and 5 can batch together -- log both inbound and outbound after replying if speed matters more than log ordering.

Step 3 has an optimisation: skip the memory check for messages that don't need context. "Yes", "do it", "ok", commands like "help" or "status" -- these don't benefit from a database query. This saves a round trip on 60%+ of messages.

Step 4 includes a context packet: what the user wants, which project, what's been tried, any constraints. Don't just change tone -- give the agent everything it needs to work independently without asking follow-up questions.

Step 7 only triggers when the user explicitly corrects the orchestrator's behaviour. These corrections accumulate in `data/corrections.jsonl` and drive the self-improvement system (see section 8).

### Terminal variant (5 steps)

Without Telegram, the loop is simpler:

```
1. Receive message directly in the Claude Code terminal
2. Check memory (conditional)
3. Route to the right agent with a context packet
4. Respond directly in the terminal
5. Save important context to memory
```

No logging steps because terminal conversations are already captured by Claude Code's session history. No correction logging because corrections happen inline.

### The reply-first rule

On Max 20x and Max 5x plans, the orchestrator always replies immediately. If the task requires agent work that will take more than a few seconds, the orchestrator acknowledges first ("On it, routing to {{engineer_name}}"), dispatches the agent in the background with `run_in_background: true`, and stays available for more messages.

When the background agent finishes, the orchestrator sends a new message with results. New messages trigger push notifications on Telegram. Edits don't. This matters -- if you're away from your laptop, the ping on your phone tells you work is done.

On Pro plans, the reply-first rule is optional because agents run sequentially anyway.

---

## 4. Memory System

The memory system is markdown-first with a vector-search index built on top.

### Markdown memory files (source of truth)

The real files live in the orchestrator repo at `{{project_root}}/memory/` (cross-agent memory) and `{{project_root}}/agent-memory/<name>/` (per-agent memory). `~/.claude/projects/<project-path-slug>/memory` and `~/.claude/agent-memory/<name>/` are symlinks that point at them. This keeps memory inside the repo for backup and cloud-routine access while Claude Code finds them at the paths it expects. On a fresh install, run `bash scripts/restore-memory-symlinks.sh` after cloning.

Each memory directory contains a `MEMORY.md` index file (loaded into every conversation, one-line pointers only, target under 200 lines) and individual memory files with frontmatter.

**Memory types:**

- **user** -- who the user is, preferences, knowledge level, how they work
- **feedback** -- corrections and confirmations. "Don't do X" and "yes, that approach was right"
- **project** -- ongoing work context, deadlines, motivations behind decisions
- **reference** -- pointers to external resources (dashboards, docs, issue trackers)
- **note** -- ephemeral notes and todos

Each file has frontmatter with `name`, `description`, `type`, and optionally `last_verified` + `ttl_days` for freshness tracking. Stale memories are surfaced by `scripts/check-memory-freshness.sh`.

### Vector search on top (sqlite-vec)

A sibling sqlite-vec database at `data/vector-memory.db` indexes every markdown memory into dense embeddings (Nomic-embed via Ollama). The post-commit hook re-embeds changed files automatically — agents never write to the DB directly. Search via `bash scripts/memory-search.sh "<query>"`.

**Why markdown + vector instead of operational SQLite:**
- Markdown is diffable, git-tracked, survives DB corruption.
- Vector search returns semantic matches across all memory without FTS5 quoting gotchas.
- No parallel write path means no drift between "markdown reality" and "DB reality".

### How agents save memories

Agents save by writing a new `memory/<type>_<topic>.md` file (or updating an existing one) and committing. The post-commit hook takes care of embedding. Agents never run a `save` command — the filesystem is the API.

### Maintenance

The maintenance script (`scripts/maintain.sh`) runs on Monday sessions:
1. Check-memory-freshness sweep — flag any file past its `last_verified + ttl_days`.
2. Report MEMORY.md index sizes and warn if any index is over 200 lines.
3. Trigger the SLO canary probes (if enabled).

High-importance memories persist indefinitely. No auto-deletion — memory pruning is an explicit human decision.

---

## 5. Safety Layer

The safety system uses multiple independent layers. Any single layer can fail -- a regex might miss an edge case, the AI might not follow instructions perfectly, a backup might be corrupted. But all layers failing simultaneously is extremely unlikely. The redundancy is the point.

### Layer 1: Permission allowlist (settings.json)

The `permissions.allow` array in `.claude/settings.json` whitelists commands that can run without prompting. Read-only commands (`ls`, `cat`, `grep`), build tools (`node`, `npm`, `python`), version control (`git`), and file editing (`Write`, `Edit`, `Read`) are pre-approved.

The `permissions.deny` array hard-blocks catastrophic commands that should never run through Claude Code: filesystem formatting (`mkfs`), raw disk writes (`dd`), partition editing (`fdisk`), mass process termination (`killall`), system shutdown/reboot.

Commands not in either list trigger a permission dialog in Claude Code.

### Layer 2: PreToolUse safety gate hook

Every Bash command and every file Write/Edit passes through `.claude/hooks/safety-gate.sh` before execution. The hook receives the command as JSON on stdin and either allows it (exit 0) or blocks it (exit 2).

**Three categories:**

**Category 1: Hard blocks (no approval possible)**
- `rm -rf /` or `rm -rf ~` or `rm -rf $HOME`
- `mkfs`, `dd if=`, `fdisk`, `diskutil erase`
- `git filter-branch` / `git filter-repo` — unrecoverable history rewrites
- `git reflog expire`, `git gc --prune=now`, `git gc --aggressive` — orphans commits permanently
- `git update-ref -d` — deletes refs
- **Force push to protected branches** (`main` / `master` / `production` / `prod` / `release` / `develop`) — any form of `--force`, `-f`, or `--force-with-lease`

These are catastrophic or destroy shared history. Even if you say "yes, do it," the hook refuses. Run them manually in a real terminal if you genuinely need them.

**Category 2: Soft blocks (user approval required)**
- `rm` with any flags or targets (word-boundary checked so "form", "arm" etc. don't false-positive)
- `DROP TABLE`, `DROP DATABASE`, `DROP SCHEMA`, `TRUNCATE TABLE`
- `DELETE FROM` without a WHERE clause
- Git destructive ops on non-protected branches:
  - Force push: `git push --force`, `-f`, `--force-with-lease`
  - `git push --mirror`, `git push --delete`, `git push origin :branch`
  - `git reset --hard`, `git clean -f` / `-fd`
  - `git branch -D`
  - `git rebase -i`, `git rebase --onto`
  - `git commit --amend`
  - `git checkout -- .`, `git restore .`
  - `git stash drop`, `git stash clear`
  - `git worktree remove --force`
- `sudo` commands

When blocked, the hook tells the orchestrator why. The orchestrator asks you (via Telegram or terminal). If you approve, the orchestrator writes the exact command to `data/approved.txt`. On retry, the hook sees the pre-approval, allows it through, and removes it. One-time use only.

**Category 3: Protected files (approval required to edit)**
- `.env` files
- SSH keys (`id_rsa`, `id_ed25519`)
- `.ssh/` and `.gnupg/` directories

Every block and approval is logged to `logs/safety-gate.log` with timestamps for audit.

### Layer 3: CLAUDE.md safety rules

The CLAUDE.md contains explicit safety rules that every agent inherits: never execute destructive operations without confirmation, always state what you're about to do before doing it, always back up before data-altering operations, use transactions for multi-step database changes, never force push to main, never DELETE without WHERE.

These rules overlap intentionally with the safety gate. The AI follows safe practices before the hook even needs to fire. The hook catches the cases where instructions alone aren't enough.

### Layer 4: Automatic backups

The maintenance script creates timestamped backups of the database every run. The 10 most recent are retained. The CLAUDE.md rules also mandate backups before any data-altering operation on any project database.

### Standard vs Enterprise tiers

**Standard** (default for personal use):
- Safety gate on Bash + Write/Edit
- Permission allowlist for common safe commands
- Database backups on maintenance
- Conversation history logging

**Enterprise** (default for work use):
- Everything in Standard, plus:
- Full audit log of every tool call (timestamped, tool name, args, result summary) via a separate `audit-log-hook.sh`
- Stricter deny list: no `curl` to external URLs without approval, no `pip install`/`npm install` without approval
- Sensitive file detection: blocks writes to `.env`, credentials, keys, tokens unless explicitly approved
- Git signed commits enforced
- File access scoped to project directory (no home directory browsing)
- Session timeout warnings
- Audit log tamper detection via checksums

Enterprise adds overhead. Every tool call gets logged, every external request needs approval. This is appropriate for work environments where an audit trail matters and accidental data exposure is a compliance risk. For personal projects, Standard is sufficient.

---

## 6. Conversation History

Every message (inbound from the user, outbound from the orchestrator) gets logged to `data/telegram-history/YYYY-MM.jsonl`. One file per month. Each line is a JSON object:

```json
{"ts": "2026-04-13T14:30:00Z", "sender": "user", "text": "deploy my-app", "project": "my-app", "has_image": false}
{"ts": "2026-04-13T14:30:05Z", "sender": "{{orchestrator_name_lower}}", "text": "On it, routing to {{devops_name}}...", "project": "my-app", "has_image": false}
```

### Logging

**Telegram variant:** The core loop logs after receiving (step 2) and after replying (step 5) using `scripts/log-telegram.sh`.

**Terminal variant:** Terminal conversations are captured by Claude Code's session history. No separate logging needed, but you can add it if you want searchable JSONL history.

### Searching

`scripts/history.sh "<query>" [--from YYYY-MM-DD] [--to YYYY-MM-DD]` searches across all monthly Telegram history files, audit logs (live + archived), git log, and memory markdown in one pass. The `history <query>` command wraps this.

### Loading context on session start

When a new session starts, the orchestrator loads the most recent 200 messages from the current month's history file:

```bash
tail -200 data/telegram-history/$(date -u +%Y-%m).jsonl | jq -r '"[\(.ts)] \(.sender): \(.text[0:120])"'
```

This gives immediate context on what was discussed recently without burning tokens on the full history. Combined with HANDOFF.md (which captures where each project left off), the orchestrator can pick up mid-conversation.

### Sync to Brain

During wrapup or sync operations, the current month's history file gets pushed to the NotebookLM Brain (if enabled). This makes conversation history queryable across sessions via semantic search.

---

## 7. Maintenance Protocol

Maintenance runs automatically under two conditions: every Monday, or when the user's first message is a greeting (hey, morning, yo, sup, good morning).

### The 8-step protocol

1. **Backup the database.** Copy `data/{{db_name}}` to `data/backups/` with a timestamp. Keep the 10 most recent backups, delete older ones.

2. **Prune expired memories.** Delete any memory past its `expires_at` date.

3. **Prune low-importance old memories.** Delete memories with importance 3 or below that are older than 90 days.

4. **Report memory stats.** Per-agent counts, average importance, last memory date. Flag any agent with 200+ memories (suggest pruning) or 0 memories (flag as underused).

5. **Check for pending improvements.** Read any memory files that contain pending action items or improvement suggestions from previous sessions.

6. **Load recent conversation history.** Run `scripts/load-context.sh` to load the last 200 messages and HANDOFF.md for any project the user mentions.

7. **Check for stale commits.** Run `scripts/commit-watcher.sh` to look for uncommitted changes older than 30 minutes across active projects.

8. **Send a greeting digest.** Compile everything into a concise message:
   - Health status (1 line)
   - Open threads from last session
   - Suggested priorities: "Here's what I'd work on today" based on HANDOFF.md priorities
   - Stale commits warning (if any)
   - Memory warnings (if any agent is over 200 or at 0)

Then answer the user's actual message.

The digest ensures nothing gets buried between sessions. Pending items surface automatically when relevant.

### The healthcheck command

`scripts/healthcheck.sh` runs a comprehensive system check:
- Telegram plugin connectivity (if enabled)
- NotebookLM Brain auth (if enabled)
- SQLite database integrity
- Safety gate hook executable and functional
- All scripts executable
- Project docs coverage (CLAUDE.md, HANDOFF.md, FEATURES.md for every registered project)
- MCP server configuration

Run it anytime with the `healthcheck` command, or it runs as part of maintenance.

---

## 8. Self-Improvement

The system tracks its own mistakes and improves over time through two mechanisms.

### Corrections log

When the user corrects the orchestrator's behaviour, step 7 of the core loop logs it:

```bash
bash scripts/log-correction.sh "<category>" "<description>"
```

This appends to `data/corrections.jsonl`:

```json
{"ts": "2026-04-13T14:30:00Z", "category": "signoff", "description": "Signed off with orchestrator name again"}
```

**Categories:** signoff, em-dash, ai-tell, forgot-docs, wrong-project, missed-command, wrong-agent, other.

### Rule promotion

Every Monday (as part of maintenance), the orchestrator reviews corrections.jsonl. If any category hits 3 or more occurrences, it gets promoted from a soft memory to a hardcoded rule in CLAUDE.md. This makes the most common mistakes impossible to repeat.

The promotion is explicit: "Promoted 'no signoff' to a hard rule because it happened 4 times." Only patterns get promoted -- the same mistake repeated -- not one-off situational corrections.

### Pattern detection

After 10+ sessions, the orchestrator starts tracking recurring behaviours in `data/patterns.jsonl`:

```json
{"pattern": "always checks forward test first on PokeInvest", "project": "PokeInvest", "count": 7, "first_seen": "2026-03-01", "last_seen": "2026-04-13"}
```

After 5 or more occurrences, the orchestrator suggests making the pattern automatic: "I've noticed you always check forward test results first when working on this project. Want me to do that automatically when you mention it?"

The orchestrator never auto-acts on a detected pattern. It suggests. The user confirms. Only then does the pattern become a workflow rule.

---

## 9. Personality Evolution

The orchestrator and each agent start with a personality seed -- the traits you defined during setup. That seed is the starting point, not the ceiling.

### How personality compounds

Every session generates feedback. Some of it is explicit ("don't be so formal"), some implicit (the user engages more with certain response styles, ignores others). The orchestrator saves observations about what worked to feedback memory files. Over time, these observations stack. The voice becomes more natural, more tailored to how you actually communicate.

This is not a static template. It's a living document that grows like memory does.

### Agent voice persistence

Each agent develops their own voice too. The engineer might become more terse over time because the user prefers concise code explanations. The researcher might become more structured because the user keeps asking for tables and comparisons. These observations get saved to each agent's memory directory (`~/.claude/agent-memory/<name>/`).

### The rules

1. Personality always evolves forward. It never resets to defaults between sessions.
2. Observations are saved after sessions, not during (to avoid mid-conversation drift).
3. The user can explicitly override any personality trait at any time ("be more formal from now on").
4. Personality memories are stored as feedback-type memory files, not in the SQLite database, because they need to load automatically every session.

The goal is that after a month of use, the system feels like it knows you. After three months, it feels like a colleague who understands your working style. This happens organically through the feedback memory system -- no explicit personality programming required beyond the initial seed.

---

## 10. Context Management

Claude Code has a context window that fills up during long sessions. Managing it well is the difference between a system that works for 20 minutes and one that works for hours.

### Plan-specific strategies

| | Max 20x | Max 5x | Pro |
|---|---|---|---|
| Warning threshold | 85% | 75% | 60% |
| Agent spawning | Aggressive (4-6 concurrent) | Moderate (2-3) | Sequential |
| Background dispatch | Always for tasks > 5 seconds | For tasks > 30 seconds | Minimal |
| Idle-time usage | Proactive -- suggest next priority, run maintenance | Moderate -- check for pending items | Conservative -- wait for instructions |
| Batch sync | Parallel via worktree agents | Sequential | Sequential |

On Max 20x, the system maximises every token. If agents are running in the background and no new task is pending, the orchestrator proactively suggests the next priority from HANDOFF.md. Idle tokens are wasted tokens.

On Pro, the system is conservative. One thing at a time. No proactive suggestions unless asked. Context is precious.

### Compaction defence

Claude Code compacts context at ~85% usage (on Max 20x; lower thresholds on other plans). Without protection, everything since the last explicit save gets lost. Three lifecycle hooks prevent this:

**PreCompact** (`scripts/pre-compaction-sync.sh`): Fires before compaction. Saves the current working context to `data/recovery/`. Keeps the last 5 snapshots.

**PostCompact** (`scripts/post-compaction-reload.sh`): Fires after compaction. Reads the saved checkpoint and recent Telegram history back into context. Re-reads HANDOFF.md for the active project.

**SessionEnd** (`scripts/session-end-sync.sh`): Safety net on exit. Saves final working context for the next session to pick up. Ensures nothing is lost even if compaction doesn't fire.

### Checkpoint format

The orchestrator writes to `/tmp/{{orchestrator_name_lower}}-working-context.md` on every milestone:

```markdown
# Working Context Checkpoint
Updated: 2026-04-13T14:30:00Z
Project: my-app
Task: implementing user authentication
Status: middleware complete, testing login flow
Key decisions:
- Using JWT with httpOnly cookies, not localStorage
- Session expiry set to 7 days
Unsaved context:
- Found a race condition in the refresh token flow, fix in progress
```

**When to checkpoint:** After finishing a subtask. Before switching projects. After a key decision. When context usage feels high. This is what the PreCompact hook grabs. No checkpoint means nothing to recover.

---

## 11. Pre-Compaction Sync

When context usage approaches the warning threshold, the orchestrator runs a sync before recommending a fresh session. This is critical for continuity.

### The sequence

1. **Alert the user.** "Context at 85%. Syncing projects before recommending a fresh session."

2. **Auto-sync all projects touched this session.** Update HANDOFF.md for each project with where you stopped and what's next.

3. **Save pending memories.** Any context gathered this session that hasn't been saved to SQLite or memory files yet.

4. **Push to Brain** (if enabled). Session summary and updated project snapshots.

5. **Tell the user.** "All synced. Start a new session to get a fresh context window."

The orchestrator never lets compaction wipe unsaved work. The sync must happen before context is lost. If you've been coding for an hour and context hits 85%, the orchestrator interrupts to save state. This feels annoying in the moment but prevents the far worse outcome of losing your entire session context and having to explain everything again.

On lower-tier plans with smaller context windows, this happens sooner and more frequently. On Max 20x with aggressive background agents, it happens less often but the sync is larger when it does.

---

## 12. Sync System

The sync system keeps project documentation current across sessions. It operates at two levels: individual project docs and the overall system state.

### Project documentation files

Every registered project has three standard files:

- **CLAUDE.md** -- technical reference. Stack, architecture, scripts, environment variables, build commands. Claude reads this when working on the project.
- **HANDOFF.md** -- session continuity. What was done, where it stopped, what's next. The first thing read when resuming work on a project.
- **FEATURES.md** -- product documentation. Every feature, how it works, how to use it, limitations. The source of truth for what the product does.

### Auto-sync triggers

The system automatically syncs project docs under four conditions:

1. **Session end.** When the user says bye, done, goodnight, or the conversation goes quiet after a work block: update HANDOFF.md for all projects touched.

2. **After milestones.** Shipped a feature, fixed a significant bug, deployed: sync that project's HANDOFF.md immediately.

3. **Context switch.** Switching from one project to another: sync the outgoing project's HANDOFF.md before starting the new one. This ensures continuity even if the new project fills up context and the old project's state gets compacted away.

4. **On greeting.** When the user starts a new session, run maintenance and check HANDOFF.md for any project mentioned in the first message.

### Manual sync and wrapup

The user can trigger a full sync manually:

- `sync <project>` -- full sync cycle for a single project (CLAUDE.md + HANDOFF.md + FEATURES.md + memories + Brain push)
- `sync all` or `batch sync` -- full sync for every registered project
- `wrapup` -- end-of-session comprehensive sync: all projects touched, session summary, memories saved, conversation history pushed to Brain

### Batch sync with worktrees

On Max 20x, `sync all` uses parallel worktree agents for speed. One agent per project, all running simultaneously. While project agents update docs, the orchestrator handles system-level tasks (memories, session summary, Brain push, drift check). This turns a 10-minute serial sync into about 1 minute.

On Max 5x and Pro, batch sync runs sequentially. Still the same operations, just one project at a time.

### Project registration

When creating a new project:

```bash
bash scripts/register-project.sh "<folder_path>" "<description>" "<stack>"
```

This creates CLAUDE.md, HANDOFF.md, and FEATURES.md if missing, adds the project to `docs/projects.md`, inits a git repo if needed, and creates a private GitHub repo. The healthcheck flags any project folders without proper registration.

---

## 13. Commands

The system responds to two types of commands: system commands and smart shortcuts.

### System commands

These work in both Telegram and terminal mode.

| Command | What it does |
|---|---|
| `help` | Reads `data/help-text.md` and displays the full command list |
| `team` | Reads `data/team-text.md` and displays the agent roster with roles and descriptions |
| `projects` | Lists all registered projects with status, stack, and one-line descriptions |
| `healthcheck` | Runs `scripts/healthcheck.sh` -- checks all integrations, database, hooks, docs coverage |
| `security` | Reads `docs/security-status.md` and reports security posture across all projects |
| `history <query>` | Searches conversation history across all monthly log files |
| `brain <question>` | Queries the NotebookLM Brain (if enabled) for cross-session recall |
| `maintain` | Manually triggers the full maintenance protocol |
| `memory <query>` | Searches memories across all agents in SQLite |
| `wrapup` | End-of-session sync: update all docs, save memories, push to Brain |

### Smart shortcuts

Quick commands for common multi-step workflows. These require a project name.

| Command | What it does |
|---|---|
| `ship <project>` | Git add + commit + push. Asks for a commit message if the changes don't make it obvious. |
| `review <project>` | Runs tests + spawns a code review agent on recent changes. Reports findings. |
| `status <project>` | Reads that project's HANDOFF.md and summarises where you left off. |
| `sync <project>` | Full sync cycle for that project (all 3 docs + memories + Brain). |
| `nuke <project>` | Git stash + git clean. Requires explicit confirmation before executing. |

### Direct agent routing

You can skip the routing table and send directly to a specific agent:

```
@{{engineer_name}} fix the login bug in the auth middleware
@{{researcher_name}} what's the market size for fitness apps in the UK
```

The `@` prefix bypasses intent detection and routes immediately to the named agent.

---

## 14. Knowledge Library

The library is an optional module -- a structured folder where agents write and reference handbooks on topics they research or learn about. Over time it becomes a personal wiki that agents draw from.

### Structure

```
Library/
├── CLAUDE.md                    (rules for library usage)
├── software-engineering/
│   ├── authentication-patterns.md
│   └── database-optimization.md
├── market-research/
│   ├── fitness-app-landscape.md
│   └── saas-pricing-models.md
└── domain-knowledge/
    └── negotiation-frameworks.md
```

Topics are organised by domain, not by agent. Multiple agents can contribute to the same topic. The library's CLAUDE.md defines rules: citation requirements, confidence tagging, structure standards.

### Agent linking

Agents are configured to read from and write to the library through their config files:

- A researcher agent might write new handbook entries after completing an analysis
- An engineer agent might reference the authentication patterns handbook when building a login system
- A business agent might read the pricing models handbook before recommending a pricing strategy

The linking is declarative, specified in each agent's `.claude/agents/<name>.md` config file.

### How handbooks grow

Handbooks start sparse and fill in over time. The first entry on "Authentication Patterns" might be three paragraphs based on one project. After five projects that involve auth, it's a comprehensive reference. The library compounds like memory does -- every session adds a little more.

Agents are instructed to update existing handbooks rather than creating duplicates. If a handbook exists on a topic, the agent adds to it. If no handbook exists, the agent creates one.

### When to enable it

Enable the library if you expect to work across many projects in similar domains. The upfront cost is near zero (just a folder structure). The long-term payoff is agents that get better at their domain with every project.

Skip it if you're working on a single project or your work doesn't involve recurring domain knowledge.

---

## 15. NotebookLM Brain

The Brain is an optional integration that connects your system to Google NotebookLM. It stores session summaries and project snapshots in a searchable notebook that persists indefinitely. Unlike file-based memory (which loads into context and costs tokens), the Brain is queried on demand via API at near-zero cost.

### Why it matters

Claude has amnesia. Every session starts fresh, minus whatever it reads from files. Reading lots of files burns tokens. The Brain solves this by storing everything in NotebookLM's RAG system. One query retrieves exactly what you need from months of history.

Two memory layers working together:
- **Local files (primary):** CLAUDE.md, HANDOFF.md, memory files. Fast, always available. Used for active work.
- **NotebookLM Brain (secondary):** Session summaries and project snapshots. Queryable semantically. Used for cross-project questions and historical recall.

### Smart memory routing

The orchestrator automatically decides which source to check. The decision tree:

**Use local files only (fast, free, always available):**
- Active coding or building tasks -- CLAUDE.md + HANDOFF.md already loaded
- "What's next?" / "Where were we?" -- HANDOFF.md
- Current session context -- conversation history
- Specific file or code questions -- read the code directly

**Query the Brain (slower, richer, cross-session):**
- Cross-project questions: "status across all projects", "which project uses Neon?"
- Historical recall: "what did we decide about...", "when did we fix..."
- Questions about projects not currently in context
- Pattern questions: "what bugs keep coming up?"
- Any message starting with "brain" explicitly

**Use both local + Brain (when uncertain or high stakes):**
- Local memory has a partial answer -- check Brain for more
- Contradictions between local context and expectations -- verify with Brain
- Strategy or planning questions that benefit from full history
- When the user says "think about this carefully" or "check everything"

Default: start with local. If the answer feels incomplete or spans multiple projects and sessions, also query the Brain. Never let a Brain auth failure block a response -- always fall back to local files.

### The brain command

```
brain what did we decide about the database schema for my-app?
```

This explicitly queries the Brain and returns the answer. Useful for historical questions that local files can't answer.

### Sync to Brain

The Brain gets fed from two sources:
1. **Sync operations** -- project snapshots pushed during `sync <project>` or `sync all`
2. **Wrapup** -- session summaries pushed during `wrapup`

Conversation history files also get pushed during sync so the Brain can search through past conversations.

If NotebookLM auth fails at any point, the system skips silently and relies on local files. The Brain is a supplement, not a dependency. Everything works without it.

---

--- END OF PART 2: ARCHITECTURE REFERENCE ---

Part 3: Code Templates begins below.


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
4. The Windows terminal alias items (`{{orchestrator_name}}` and `{{orchestrator_name}}-resume`) are KNOWN-FRAGILE on PowerShell first install. If those are not working, fix them BEFORE moving on — they are how the user starts every future session.
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
6. After every interaction, save important context as a new markdown file in `memory/<type>_<topic>.md` (types: feedback / project / user / reference / note). Commit it — the post-commit hook auto-embeds into sqlite-vec and auto-regenerates `memory/MEMORY.md`.
7. If user corrected you, log it: `bash scripts/log-correction.sh "<category>" "<description>"`
<!-- ELSE -->
1. Receive message from user in terminal
2. Check if relevant memories exist -- skip for simple confirmations, commands, or when you already have context
3. Route to the right agent (see routing table). Pass a context packet: what the user wants, what project, what's been tried, constraints.
4. Respond directly in terminal. NO "-- {{orchestrator_name}}" signoff. NO em dashes. NO AI tells. Be concise.
5. After every interaction, save important context as a new markdown file in `memory/<type>_<topic>.md` (types: feedback / project / user / reference / note). Commit it — the post-commit hook auto-embeds into sqlite-vec.
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

**Default path:** `git commit` + `git push` (no `--force`). If remote has diverged, stop and ask — never "fix" it by force-pushing. Use `git pull --rebase` or `git merge`.

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
- Force push to `main` / `master` / `production` / `prod` / `release` / `develop` — any form
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
Write to `/tmp/{{orchestrator_name_lower}}-working-context.md` on every milestone:
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
            "command": "echo 'Reminder: verify build, test changes{{IF_TELEGRAM}}, reply on Telegram{{ENDIF}}'"
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
APPROVAL_FILE="{{project_path}}/data/approved.txt"

mkdir -p "$LOG_DIR"
touch "$APPROVAL_FILE"

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
  hard_block "Permanent reflog / ref cleanup — makes lost commits unrecoverable" "git-reflog"
fi

# Force push to protected branches
if echo "$COMMAND" | grep -qEi 'git\s+push(\s+[^-]\S*)*\s+(--force|-f|--force-with-lease)(\s|=|$)' || \
   echo "$COMMAND" | grep -qEi 'git\s+push\s+.*(--force|-f|--force-with-lease).*\s+(origin\s+)?(main|master|production|prod|release|develop)(\s|$|:)'; then
  if echo "$COMMAND" | grep -qEi '(origin\s+)?(main|master|production|prod|release|develop)(\s|$|:)'; then
    hard_block "Force push to protected branch — destroys shared history" "git-force-push-protected"
  fi
fi

# ================= CATEGORY 2: BLOCKED UNTIL APPROVED =================
# File deletion (word-boundary safe so "form ", "arm " etc. don't false-trigger)
if echo "$COMMAND" | grep -qE '(^|\s)rm\s+-(r|f|rf|fr|Rf|fR)'; then
  block "Recursive or forced file deletion detected" "rm-rf"
fi
if echo "$COMMAND" | grep -qE '(^|\s)rm\s'; then
  block "File deletion detected" "rm"
fi
if echo "$COMMAND" | grep -qE '(^|\s|;|&|\|)(/usr)?/bin/rm\s'; then
  block "File deletion via /bin/rm detected" "rm-path"
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

## Template: scripts/maintain.sh

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

echo "=== $passed/$total checks passed ==="
```

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

Unified history search across four sources in one pass: Telegram JSONL history, audit logs (live `data/audit/*.jsonl` and archived `data/audit/archive/YYYY/MM.jsonl.gz`), `git log`, and memory markdown. Supports `--from YYYY-MM-DD` / `--to YYYY-MM-DD` date range filters. Ships as `scripts/history.sh` in the reference implementation — copy that file verbatim. The `history <query>` command wraps it.

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

# Create GitHub repo
if command -v gh &>/dev/null; then
    REMOTE_URL=$(cd "$FOLDER_PATH" && git remote get-url origin 2>/dev/null || echo "")
    if [[ -z "$REMOTE_URL" ]]; then
        if (cd "$FOLDER_PATH" && gh repo create "$PROJECT_NAME" --private --source=. --push 2>/dev/null); then
            echo "  GitHub repo created (private)"
        fi
    fi
fi

echo "=== Done ==="
```

---

## Template: scripts/pre-compaction-sync.sh

```bash
#!/bin/bash
PROJECT_DIR="{{project_path}}"
RECOVERY_DIR="$PROJECT_DIR/data/recovery"
WORKING_CTX="/tmp/{{orchestrator_name_lower}}-working-context.md"
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

## Template: scripts/session-end-sync.sh

```bash
#!/bin/bash
PROJECT_DIR="{{project_path}}"
RECOVERY_DIR="$PROJECT_DIR/data/recovery"
WORKING_CTX="/tmp/{{orchestrator_name_lower}}-working-context.md"
LOG_FILE="$PROJECT_DIR/logs/session-lifecycle.log"
TIMESTAMP=$(date -u +%Y%m%d_%H%M%S)

mkdir -p "$RECOVERY_DIR" "$(dirname "$LOG_FILE")"

if [ -f "$WORKING_CTX" ]; then
  cp "$WORKING_CTX" "$RECOVERY_DIR/session-end-$TIMESTAMP.md"
  echo "[$(date -u +%H:%M:%S)] Session ended. Working context saved." >> "$LOG_FILE"
else
  echo "[$(date -u +%H:%M:%S)] Session ended. No working context to save." >> "$LOG_FILE"
fi

ls -t "$RECOVERY_DIR"/session-end-*.md 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null
```

---

## Template: scripts/log-telegram.sh

<!-- Only generate if messaging=telegram -->

```bash
#!/usr/bin/env bash
set -euo pipefail

SENDER="${1:?Usage: log-telegram.sh <sender> <text> [project] [has_image]}"
TEXT="${2:?Usage: log-telegram.sh <sender> <text> [project] [has_image]}"
PROJECT="${3:-}"
HAS_IMAGE="${4:-false}"

HISTORY_DIR="{{project_path}}/data/telegram-history"
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
For cross-agent visibility, save important decisions as new markdown files in `memory/` (cross-project) or `agent-memory/<name>/` (your own) and commit — the post-commit hook auto-embeds into sqlite-vec so other agents find them via `bash scripts/memory-search.sh "<query>"`.
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

Add these to `{{shell_profile}}`:

```bash
# {{orchestrator_name}} -- Xantham System
# --dangerously-skip-permissions lets the system run without constant approval prompts.
# Safety is handled by the hooks in .claude/settings.json instead.
<!-- IF messaging=telegram -->
{{launch_cmd}}() {
  claude --dangerously-skip-permissions --project "{{project_path}}" --plugin telegram
}
{{launch_cmd}}-terminal() {
  claude --dangerously-skip-permissions --project "{{project_path}}"
}
{{launch_cmd}}-resume() {
  claude --resume --dangerously-skip-permissions --project "{{project_path}}" --plugin telegram
}
{{launch_cmd}}-resume-terminal() {
  claude --resume --dangerously-skip-permissions --project "{{project_path}}"
}
<!-- ELSE -->
{{launch_cmd}}() {
  claude --dangerously-skip-permissions --project "{{project_path}}"
}
{{launch_cmd}}-resume() {
  claude --resume --dangerously-skip-permissions --project "{{project_path}}"
}
<!-- ENDIF -->
```

### For Windows (PowerShell)

Add these to the PowerShell profile (`$PROFILE`):

```powershell
# {{orchestrator_name}} -- Xantham System
# --dangerously-skip-permissions lets the system run without constant approval prompts.
# Safety is handled by the hooks in .claude/settings.json instead.
<!-- IF messaging=telegram -->
function {{launch_cmd}} {
  claude --dangerously-skip-permissions --project "{{project_path}}" --plugin telegram
}
function {{launch_cmd}}-terminal {
  claude --dangerously-skip-permissions --project "{{project_path}}"
}
function {{launch_cmd}}-resume {
  claude --resume --dangerously-skip-permissions --project "{{project_path}}" --plugin telegram
}
function {{launch_cmd}}-resume-terminal {
  claude --resume --dangerously-skip-permissions --project "{{project_path}}"
}
<!-- ELSE -->
function {{launch_cmd}} {
  claude --dangerously-skip-permissions --project "{{project_path}}"
}
function {{launch_cmd}}-resume {
  claude --resume --dangerously-skip-permissions --project "{{project_path}}"
}
<!-- ENDIF -->
```

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

--- END OF PART 3: CODE TEMPLATES ---

Part 4: Advanced Patterns & Troubleshooting begins below.
# Part 4: Advanced Patterns & Troubleshooting

This section covers power-user patterns for getting the most out of your system, plus solutions for every common issue you will hit.

---

## Section A: Advanced Patterns

### A1. Parallel agent spawning

Your Claude plan determines how aggressively you can run agents in parallel. More parallelism means faster results but burns through your context window quicker.

**Max 20x -- aggressive parallelism**

Spawn 4-6 agents concurrently. Background dispatch is the default. The reply-first pattern means {{orchestrator_name}} always acknowledges your message immediately, then dispatches agents in the background and sends new messages as they finish.

Rules:
- Simple task (one domain): 1 agent, foreground or background depending on expected speed
- Medium task (build a feature): 2-3 agents in parallel (e.g., builder + tester + reviewer)
- Complex task (multi-project, research + build): 4-6 agents, all background, report as each finishes
- Always pass the project's HANDOFF.md + CLAUDE.md content to agents so they have full context
- Agents can spawn their own subagents (max depth 2)
- Multi-domain routing: if a task touches multiple agents (e.g., "research X then build Y"), spawn both simultaneously with clear scope boundaries

Example -- "Research the best auth library for our stack, then implement it":
1. {{orchestrator_name}} replies: "On it. Sending {{agent_researcher_name}} to evaluate options and {{agent_engineer_name}} to prep the integration scaffolding."
2. Research agent runs in background evaluating libraries
3. Engineer agent runs in background setting up auth module structure
4. Research agent finishes first -- {{orchestrator_name}} sends results to you AND to the engineer agent
5. Engineer agent incorporates the recommendation and finishes implementation

**Max 5x -- moderate parallelism**

Spawn 2-3 agents concurrently. Background dispatch for longer tasks, foreground for quick ones.

Rules:
- Simple task: 1 agent, foreground
- Medium task: 2 agents in parallel (builder + reviewer)
- Complex task: 2-3 agents, background for the slow ones
- Be more conservative with context -- you have less room to work with

Example -- "Fix the login bug and update the docs":
1. {{orchestrator_name}} replies: "Sending {{agent_engineer_name}} on the bug, I'll handle the docs after."
2. Engineer agent runs in background on the bug
3. {{orchestrator_name}} updates docs in foreground (or spawns a second agent if the docs update is substantial)
4. Engineer finishes -- {{orchestrator_name}} sends the fix summary

**Pro -- sequential execution**

One agent at a time. No background dispatch. Each task completes before the next starts.

Rules:
- Route to one agent, wait for completion, then route the next task
- Keep tasks focused and small to avoid context bloat
- Prioritise the most important task first since you have limited room

Example -- "Research auth libraries then implement the best one":
1. {{orchestrator_name}} routes to research agent, waits for results
2. Research agent returns recommendation
3. {{orchestrator_name}} routes to engineer agent with the recommendation
4. Engineer implements it

**Agent watchdog (Max 5x and 20x only)**

Monitor background agents for timeouts. Default thresholds:

| Agent type | Warning | Alert |
|---|---|---|
| Research agents | 5 min | 10 min |
| Code agents | 10 min | 15 min |
| Infrastructure/sync agents | 3 min | 5 min |

At the warning threshold, send a status update: "{{agent_name}} still working on [task] (X min). Will alert if it takes much longer."

At the alert threshold: "{{agent_name}} has been running for X min on [task]. Something might be stuck. Want me to check on it?"

Never auto-kill agents. Just keep the user informed.

---

### A2. Git worktree isolation

When spawning agents for multi-project or multi-file work, use `isolation: "worktree"` to give each agent its own git checkout. This prevents merge conflicts when multiple agents edit files in the same repository.

**When to use worktrees:**
- Batch sync across multiple projects (each agent syncs one project)
- Independent feature branches (agent A builds feature X, agent B builds feature Y)
- Any time two agents might touch overlapping files
- Large refactors where you want an isolated sandbox

**When NOT to use worktrees:**
- Changes that depend on each other (agent B needs agent A's output)
- Single-file edits where there is no conflict risk
- Quick tasks where the overhead of creating a worktree is not worth it

**How it works:**
1. Claude Code creates a temporary git worktree (a separate checkout of the same repo)
2. The agent runs entirely within that worktree
3. When the agent finishes, changes are merged back or committed from the worktree
4. The worktree is cleaned up

This is particularly powerful for batch sync (see A5) where you can spawn one agent per project, each in its own worktree, and sync everything in parallel.

---

### A3. Monitor vs GitHub Actions vs CronCreate

Three tools for recurring or background work. Each has a specific use case. Pick the wrong one and you either miss events or waste resources.

**Monitor (event-driven, session-only)**

Use when you need real-time reaction to external events during an active session.

- Spawns a background script as an event stream
- {{orchestrator_name}} only wakes up when the script emits a stdout line
- Dies when the session exits
- Replaces polling loops inside the agent

Good for:
- Live site health monitoring while debugging a deploy
- Watching deploy status during a dev session
- Tailing a long-running training job's progress
- Database row changes during interactive work

Bad for:
- Anything that must run when the machine is off or asleep
- Time-driven schedules ("run at 6am daily")

Important: the Monitor subprocess runs in `/bin/zsh`, not bash. No word-splitting on `$VAR`. Test your monitor scripts in zsh before deploying.

Important: do NOT use Monitor for Telegram message receiving. The Telegram plugin already uses long-polling `getUpdates`, which is event-driven at the HTTP layer and holds exactly one consumer per token. Wrapping it in Monitor would conflict with the single-consumer rule.

**GitHub Actions (time-driven, always-on)**

Use when the task MUST run even when your machine is off.

- Runs on GitHub's infrastructure on a cron schedule
- Failures get logged regardless of session state
- Cannot interact with {{orchestrator_name}} directly (but can write status to a DB)

Good for:
- Daily price sync, nightly backups, weekly model retrains
- Monthly snapshots, scheduled security scans
- Any task with "run at X time" semantics

Bad for:
- Real-time reaction to events
- Tasks that need interactive user input

**CronCreate (schedule-driven, session-only)**

Use when you need periodic tasks during an active session but don't need to watch for events.

- Runs on a fixed interval (e.g., every hour)
- Lighter than Monitor because it fires on schedule, not on external input
- Dies when the session exits

Good for:
- Hourly healthcheck digest
- Periodic memory pruning
- Auto-commit watcher (check for stale uncommitted changes every 30 min)
- Any "check this periodically while I'm working" pattern

**The hybrid pattern (best of all three)**

For maximum coverage, combine them:

1. GitHub Actions runs the work nightly and writes status to a DB table (`deploy_status`, `sync_status`, etc.)
2. When {{orchestrator_name}} starts a session, a Monitor tails that DB table
3. Any failure from the nightly run surfaces instantly on session start
4. Any failure during the active session surfaces in real time
5. Between sessions, nothing is lost -- the DB is the source of truth

This gives you: always-on execution (GitHub Actions) + real-time alerting during sessions (Monitor) + periodic housekeeping (CronCreate).

---

### A4. Compaction defence

Claude Code compacts context at approximately 85% usage. When compaction fires, everything since the last explicit save is at risk. The compaction defence system uses three lifecycle hooks to prevent data loss.

**The three hooks**

| Hook | Trigger | Script | Purpose |
|---|---|---|---|
| PreCompact | Before context compaction | `scripts/pre-compaction-sync.sh` | Saves working context to `data/recovery/` |
| PostCompact | After context compaction | `scripts/post-compaction-reload.sh` | Reloads checkpoint + recent history into context |
| SessionEnd | When session exits | `scripts/session-end-sync.sh` | Safety net -- saves final context for next session |

These are configured in `.claude/settings.json` under the `hooks` section.

**How checkpoints work**

The PreCompact hook grabs whatever is in `/tmp/{{orchestrator_name_lower}}-working-context.md` and copies it to `data/recovery/`. It keeps the last 5 snapshots so you can recover from any recent compaction.

The PostCompact hook reads the saved checkpoint back into context and also loads recent conversation history from the Telegram/terminal log. It re-reads the active project's HANDOFF.md so the session can continue without losing track of where it was.

**Checkpoint format**

Write to `/tmp/{{orchestrator_name_lower}}-working-context.md` regularly:

```
# Working Context Checkpoint
Updated: <ISO timestamp>
Project: <active project>
Task: <what we're working on>
Status: <where we are>
Key decisions:
- <decision 1>
- <decision 2>
Unsaved context:
- <anything not yet in HANDOFF.md or memory>
```

**When to checkpoint:**
- After finishing a subtask
- Before switching projects
- After a key decision
- When context usage feels high (ask {{orchestrator_name}} -- it can estimate)
- Before any risky operation

No checkpoint = nothing to recover. Make it a habit.

**Plan-specific context thresholds**

| Plan | Warning threshold | Recommended action |
|---|---|---|
| Max 20x | 85% | Checkpoint, consider wrapping up |
| Max 5x | 75% | Checkpoint, start planning session end |
| Pro | 60% | Checkpoint, wrap current task, start fresh |

---

### A5. Batch sync with worktrees

When you have multiple projects to sync, doing them one at a time is slow. Batch sync spawns one agent per project, each in its own git worktree, and syncs everything in parallel.

**How it works:**

1. {{orchestrator_name}} reads `docs/projects.md` and identifies all projects with a folder and HANDOFF.md
2. Spawns one agent per project with `isolation: "worktree"`
3. Each agent independently updates that project's CLAUDE.md, HANDOFF.md, and FEATURES.md
4. While agents run in parallel, {{orchestrator_name}} handles its own sync tasks (memories, session summary, Brain push if configured, drift check)
5. All agents complete, changes are committed

This turns a 10-minute serial sync into roughly 1 minute.

**When to use:**
- `sync all` or `batch sync` commands (syncing every project)
- End-of-session wrapup when multiple projects were touched
- Weekly maintenance sync

**When NOT to use:**
- Single project sync (`sync <project>`) -- just run it normally, worktree overhead is not worth it
- When only one or two projects were touched -- the parallel setup cost exceeds the time saved

---

### A6. Adding new agents post-setup

After your initial setup, you may want to add new agents as your needs evolve. There are 6 places that need updating. Miss any one and the agent either will not be routed to, will not have memory, or will not show up in help output.

**Update checklist:**

1. **CLAUDE.md routing table** -- add the new agent with signal words that trigger routing
2. **CLAUDE.md agent count** -- update "crew of N" to N+1
3. **`.claude/agents/<name>.md`** -- create the agent config file with role, personality, capabilities, and instructions
4. **`{{project_root}}/agent-memory/<name>/MEMORY.md`** -- create the memory directory and index file in the repo (Claude Code finds it via the `~/.claude/agent-memory/<name>/` symlink)
5. **`data/help-text.md`** -- add the agent to the help command output
6. **`data/team-text.md`** -- add the agent to the team roster display

Do all 6 in one pass. Never leave a partial update.

---

### A7. Upgrading your plan

When you move from Pro to Max 5x, or from Max 5x to Max 20x, the system can take advantage of more parallelism and context. Here is what to change.

**Pro to Max 5x:**
- Update agent spawning rules in CLAUDE.md: change from sequential to 2-3 concurrent agents
- Enable background dispatch for longer tasks
- Update context warning threshold from 60% to 75%
- Enable the agent watchdog
- Consider adding more agents (Pro recommends 3-4, Max 5x supports 5-6 comfortably)

**Max 5x to Max 20x:**
- Update agent spawning rules in CLAUDE.md: change from 2-3 to 4-6 concurrent agents
- Enable aggressive background dispatch (reply-first pattern becomes the default)
- Update context warning threshold from 75% to 85%
- Enable batch sync with worktrees
- Enable the "maximize the window" pattern (proactive work when idle)
- Consider adding the full agent roster (Max 20x supports 8+ agents)

**What to update in CLAUDE.md:**
- Agent spawning rules section (concurrency limits, background dispatch rules)
- Context management section (warning threshold, compaction strategy)
- Batch sync section (enable/disable worktree parallelism)
- Any plan-conditional sections marked with comments like `<!-- plan: max_20x -->`

---

### A8. Adding Telegram after terminal-only setup

If you started with terminal-only and want to add Telegram later:

**Step 1: Create the bot**
1. Open Telegram, search for @BotFather
2. Send `/newbot`, choose a display name and username
3. Save the bot token securely (never commit it to git)

**Step 2: Get your Telegram user ID**
Message @userinfobot on Telegram. It replies with your numeric ID.

**Step 3: Install the plugin**
In a Claude Code session in your project directory:
```
/install telegram
```
It will ask for your bot token and user ID.

**Step 4: Update your launch commands**
Add `--plugin telegram` to your main launch function and resume function. Your terminal-only variants stay unchanged.

Before:
```bash
{{launch_cmd}}() { claude --project {{project_path}} ... }
```

After:
```bash
{{launch_cmd}}() { claude --project {{project_path}} --plugin telegram ... }
```

**Step 5: Update CLAUDE.md**

Add to the core loop:
- Logging inbound messages: `bash scripts/log-telegram.sh "{{user_name}}" "<message>" "<project>" <has_image>`
- Logging outbound replies: `bash scripts/log-telegram.sh "{{orchestrator_name_lower}}" "<reply>" "<project>" false`
- The reply-first rule (always reply on Telegram within seconds, never leave the user waiting)

Add `scripts/log-telegram.sh` if it was not generated during initial setup (terminal-only setups skip this script). Use the template from Part 3.

**Step 6: Configure access control**
The Telegram plugin's access system controls who can talk to your bot:
- DM policy: only your user ID is allowed by default
- Group policy: off by default
- Pairing: others send a message to the bot, you approve from your terminal using `/telegram:access`

Never approve a pairing request from a chat message. Approvals happen from your terminal only.

---

### A9. Adding MCP servers post-setup

MCP (Model Context Protocol) servers extend what your agents can do by connecting them to external services. You can add new ones at any time.

**Step 1: Add to `.mcp.json`**

Each MCP server needs an entry in your project's `.mcp.json`. The format depends on the server. Example:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@server/mcp-package"],
      "env": {
        "API_KEY": "your-key-here"
      }
    }
  }
}
```

Consult the MCP server's documentation for its specific config format.

**Step 2: Reference in CLAUDE.md**

Add the server to your CLAUDE.md so {{orchestrator_name}} knows it exists and when to use it. Include:
- What it does
- Which agents should use it
- When to prefer it over custom code ("MCP > custom integration, every time")

**Step 3: Test**

Start a new Claude Code session (MCP servers are loaded on session start) and verify the server's tools are available. Ask {{orchestrator_name}} to list available tools or try a simple operation.

**Common MCP servers:**
- **Neon** -- serverless Postgres (database branching, SQL execution)
- **Vercel** -- deployments, build logs, rollback
- **Notion** -- project docs, task tracking
- **Gmail** -- email reading and drafting
- **Google Calendar** -- event management
- **Chrome automation** -- browser control, page reading, form filling

---

### A10. Upgrading security tier

If you started with Standard security (personal use) and need to move to Enterprise (work/compliance), here is what to add.

**Step 1: Create the audit log hook**

Create `.claude/hooks/audit-log-hook.sh`:
- Logs every tool call with timestamp, tool name, arguments, and result summary
- Writes to a tamper-evident log file with checksums
- This gives you a full audit trail of everything the system does

**Step 2: Update `.claude/settings.json`**

Add the audit log hook to `PreToolUse` alongside the safety gate:
```json
{
  "matcher": "Bash|Write|Edit|Read",
  "hooks": [
    {
      "type": "command",
      "command": ".claude/hooks/audit-log-hook.sh"
    }
  ]
}
```

Expand the deny list:
```json
"deny": [
  "Bash(curl:*)",
  "Bash(wget:*)",
  "Bash(pip install:*)",
  "Bash(npm install:*)"
]
```

This blocks external network requests and package installation without explicit approval.

**Step 3: Add sensitive file detection**

Update the safety gate to block writes to additional file patterns:
- `.env*`, `credentials*`, `*.key`, `*.pem`, `*.p12`
- Any file containing "secret", "token", or "password" in its name
- Files outside the project directory (no home directory browsing)

**Step 4: Enable git signed commits**

Add to CLAUDE.md safety rules: all commits must be signed. Configure with:
```bash
git config commit.gpgsign true
```

**Step 5: Add session timeout warnings**

Add to CLAUDE.md: warn when a session has been active for more than 4 hours without a sync. Long sessions increase the risk of unsaved context.

---

## Section B: Troubleshooting

### B1. Telegram bot not responding

**Symptom:** You send a message to your bot on Telegram and get no reply.

**Cause 1: Claude Code is not running.**
The bot only works when Claude Code is active in your terminal. If you closed the terminal, your Mac went to sleep, or the session ended, the bot is offline.
Fix: Start a new session with your launch command. Use `caffeinate -i` to prevent sleep during long sessions:
```bash
caffeinate -i {{launch_cmd}}
```

**Cause 2: Bot token is wrong or expired.**
Fix: Check your Telegram plugin config. The token should match what BotFather gave you. If in doubt, create a new bot with BotFather and reinstall the plugin.

**Cause 3: Plugin not installed or not started.**
Fix: In a Claude Code session, run `/install telegram`. If already installed, check that your launch command includes `--plugin telegram`.

**Cause 4: Pairing not approved.**
If you are messaging from a new account or device, the plugin's access control may be blocking you.
Fix: Check the plugin's access configuration. Run `/telegram:access` from your terminal to review and approve pairings.

**Cause 5: Another session is consuming messages.**
Telegram's `getUpdates` API is single-consumer. If another Claude Code session has the same bot token, it will steal messages.
Fix: Close all other Claude Code sessions using the same bot token. Only one session per token.

---

### B2. "SQLite database is locked"

**Symptom:** Memory queries or saves fail with "database is locked" errors.

**Cause:** Another process has the SQLite database file open. This usually happens when two Claude Code sessions are running against the same project directory, or when an orphaned process from a crashed session still holds a lock.

**Fix:**
1. Close other Claude Code sessions that use the same database
2. Check for orphaned processes:
   ```bash
   lsof {{project_path}}/data/{{orchestrator_name_lower}}.db
   ```
3. If you find orphaned processes, note their PID and terminate them:
   ```bash
   kill <PID>
   ```
4. If the database is corrupted (rare), restore from the latest backup in `data/backups/`

**Prevention:** The maintenance script creates timestamped backups of the database. If you run maintenance regularly, you always have a recent backup.

---

### B3. Safety gate blocking legitimate commands

**Symptom:** The safety gate blocks a command you actually want to run. You see "BLOCKED: ..." in the output.

**Cause:** The safety gate uses pattern matching. Some legitimate commands match destructive patterns. For example, a `grep` command that contains the string "DROP TABLE" in its search pattern would trigger the SQL destructor check.

**Fix -- pre-approve the command:**
1. {{orchestrator_name}} tells you what was blocked and asks for approval
2. You confirm (on Telegram or terminal)
3. {{orchestrator_name}} writes the exact command to `data/approved.txt`
4. {{orchestrator_name}} retries the command
5. The safety gate sees the pre-approval, allows it, and removes the approval (one-time use)

**Fix -- adjust patterns:**
If a specific pattern causes repeated false positives, edit `.claude/hooks/safety-gate.sh` and make the regex more specific. For example, if `rm` commands in a build script keep getting blocked, you can add a path-specific exception. Be careful not to weaken the gate for genuinely dangerous commands.

**Note:** Category 1 blocks (catastrophic operations like `rm -rf /`) cannot be pre-approved. These must be run manually in your terminal if you truly need them.

---

### B4. Context running out mid-task

**Symptom:** {{orchestrator_name}} warns about high context usage, or starts behaving oddly (forgetting earlier instructions, repeating itself, losing track of the current task).

**Cause:** The context window is filling up. This happens faster with large codebases, long conversations, or multiple agent dispatches in a single session.

**Fix -- immediate:**
1. Write a checkpoint (see A4 for format)
2. Run `sync <project>` or `wrapup` to save all state
3. Start a fresh session -- your launch command or resume command will reload context from HANDOFF.md and checkpoints

**Fix -- preventive:**
- Checkpoint after every milestone
- Use `wrapup` when switching between large tasks
- On Pro plans, keep tasks small and focused
- On Max plans, monitor context usage and sync at the warning threshold

**Plan-specific advice:**

| Plan | Context window | Strategy |
|---|---|---|
| Pro | Smallest | One task per session. Sync often. Keep agent count low. |
| Max 5x | Medium | 2-3 tasks per session. Sync at 75%. |
| Max 20x | Largest | Full session of work. Sync at 85%. Compaction defence handles the rest. |

---

### B5. Agent not responding / stuck

**Symptom:** A background agent has been running for a long time with no output.

**Cause:** The agent may be stuck in a loop, waiting for user input it cannot get (since it is running in the background), or processing a very large file/codebase.

**Fix:**
1. Check the watchdog timeout thresholds (see A1). If you have not set these up yet, add them to your CLAUDE.md.
2. For a stuck agent in the current session: you cannot directly kill a background agent, but you can start a new task. The stuck agent will eventually time out or complete.
3. If the pattern repeats: the task may be too large for a single agent. Break it into smaller subtasks.

**Prevention:**
- Pass clear, scoped instructions to agents (not "fix everything", but "fix the login bug in auth.js")
- Set watchdog thresholds in CLAUDE.md so you get warnings before agents time out
- For very long tasks (model training, large migrations), use Monitor to stream progress instead of background agents

---

### B6. Memory search returning nothing

**Symptom:** `bash scripts/memory-search.sh "query"` returns no results even though you know memories exist.

**Cause 1: Query matched no semantic neighbours.**
Vector search ranks by cosine similarity. If your query is very specific (a unique project name, a typo, an acronym), there may be no embedding close enough. Rephrase using plain-English keywords.

**Cause 2: Post-commit hook did not re-embed.**
Every memory write goes through git, and the post-commit hook re-embeds changed markdown files into `data/vector-memory.db`. If the hook failed silently (missing dependency, Ollama not running), new memories never land in the index.
Fix: verify the hook:
```bash
cat .git/hooks/post-commit
ls -la data/vector-memory.db
```
If the DB is missing or stale, run the embedder manually:
```bash
bash scripts/embed-memories.sh
```

**Cause 3: Ollama/Nomic-embed not running.**
The embedding model lives locally. If Ollama is not serving it, embedding quietly fails.
Fix:
```bash
ollama list | grep nomic-embed-text
ollama serve &
```

**Cause 4: Memory file not committed yet.**
The post-commit hook only fires on commit. Uncommitted markdown files are invisible to vector search.
Fix: `git add memory/<file>.md && git commit -m "memory: ..."`.

---

### B7. Shell functions not loading

**Symptom:** Your launch command (e.g., `{{launch_cmd}}`) is not found after you added it to your shell profile.

**Cause 1: Did not source the profile.**
Fix: Run `source ~/.zshrc` (or `source ~/.bashrc` depending on your shell). New functions are not available until the profile is reloaded or a new terminal window is opened.

**Cause 2: Wrong profile file.**
macOS uses zsh by default (`~/.zshrc`). Linux varies -- could be `~/.bashrc` or `~/.zshrc`. Check which shell you are running:
```bash
echo $SHELL
```
Then make sure your functions are in the right file.

**Cause 3: Syntax error in the function.**
A syntax error anywhere in your profile file can prevent ALL functions from loading. Fix: check for errors:
```bash
zsh -n ~/.zshrc
```
or
```bash
bash -n ~/.bashrc
```
This runs a syntax check without executing the file.

**Cause 4: `claude install` overwrote your config.**
The `claude install` command can delete custom aliases and rewrite shell config. If your launch functions disappeared after a Claude Code update, re-add them. Consider using shell functions (not aliases) as they are more resilient to this.

---

### B8. Windows specific issues

**Symptom:** Various issues when running on Windows with PowerShell.

**Note:** This system runs natively on Windows with PowerShell. WSL2 is NOT required.

**SQLite not found:**
Install SQLite for Windows:
```powershell
winget install SQLite.SQLite
```
Or with Chocolatey: `choco install sqlite`. After installing, restart your terminal so the PATH updates.

**Line endings (CRLF vs LF):**
Windows editors may save files with CRLF line endings. Hook scripts with CRLF may fail.
Prevention: configure git to handle line endings:
```powershell
git config core.autocrlf true
```

**Script execution policy:**
PowerShell may block scripts by default. If you get "execution of scripts is disabled" errors:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Path separators:**
Use forward slashes or escaped backslashes in paths. Claude Code handles both, but be consistent in your CLAUDE.md.

**PowerShell profile location:**
Your launch functions go in `$PROFILE`. To find the file path:
```powershell
echo $PROFILE
```
If the file does not exist, create it: `New-Item -Path $PROFILE -Type File -Force`

---

### B9. NotebookLM auth failures

**Symptom:** Commands like `notebooklm ask "question"` fail with authentication errors, or `notebooklm source add` silently fails.

**Cause 1: Token expired.**
NotebookLM tokens expire periodically.
Fix: Re-authenticate:
```bash
notebooklm login
```
Follow the prompts to re-authorize.

**Cause 2: CLI not installed or not in PATH.**
Fix: Check that the `notebooklm` CLI is installed and accessible:
```bash
which notebooklm
```
If not found, check if it is installed in a non-standard location (e.g., `~/bin/`) and add that to your PATH:
```bash
export PATH="$HOME/bin:$PATH"
```
Add this to your shell profile so it persists.

**Cause 3: Wrong notebook ID.**
If you created a new notebook or the ID changed, update the notebook ID in your CLAUDE.md.
Fix: List your notebooks to find the correct ID:
```bash
notebooklm list
```

**Important:** NotebookLM is optional. If auth fails during a sync or wrapup, the system should skip silently and rely on local files. Local files (HANDOFF.md, CLAUDE.md, FEATURES.md) are always the primary source of truth. The Brain is a secondary, queryable layer on top.

---

### B10. Permission denied on scripts

**Symptom:** Running a script fails with "Permission denied".

**Cause:** The script file is not marked as executable.

**Fix:**
```bash
chmod +x scripts/*.sh .claude/hooks/*.sh
```

This marks all `.sh` files in both directories as executable. Run this once after initial setup, and again if you add new scripts.

If you are on WSL and the files are on a Windows mount, see B8 for the file permissions workaround.

---

### B11. Hooks not firing

**Symptom:** The safety gate does not block dangerous commands, or the compaction defence hooks do not save checkpoints.

**Cause 1: Wrong path in `settings.json`.**
Hook paths in `settings.json` are relative to the project directory. If your project moved or the path is wrong, hooks silently fail.
Fix: Verify the paths. Open `.claude/settings.json` and check that every hook path points to an existing, executable file:
```bash
ls -la .claude/hooks/safety-gate.sh
ls -la scripts/pre-compaction-sync.sh
ls -la scripts/post-compaction-reload.sh
ls -la scripts/session-end-sync.sh
```

**Cause 2: Script not executable.**
Fix: `chmod +x` on the script (see B10).

**Cause 3: `settings.json` syntax error.**
A malformed JSON file causes Claude Code to ignore the entire settings file, including all hooks.
Fix: Validate the JSON:
```bash
jq . .claude/settings.json
```
If `jq` reports an error, fix the syntax. Common culprits: trailing commas, missing quotes, unescaped characters.

**Cause 4: Hook script has a runtime error.**
The script runs but crashes before it can do its job. Check for missing dependencies (like `jq` not being installed) or wrong variable references.
Fix: Run the hook script manually with test input to see the error:
```bash
echo '{"tool_input":{"command":"test"}}' | bash .claude/hooks/safety-gate.sh
echo $?
```
Exit code 0 means it allowed the command. Exit code 2 means it blocked. Any other output or error tells you what went wrong.

---

### B12. Agent memory not persisting

**Symptom:** Agents forget things between sessions. Memories saved in one session are not available in the next.

**Cause 1: MEMORY.md not created.**
Each agent needs a memory directory and index file at `{{project_root}}/agent-memory/<name>/MEMORY.md` (inside the orchestrator repo). Claude Code reads it via the `~/.claude/agent-memory/<name>/` symlink. If either side is missing, the agent has nowhere to save.
Fix: create the directory in the repo, then confirm the symlink exists:
```bash
mkdir -p {{project_root}}/agent-memory/<agent-name>
touch {{project_root}}/agent-memory/<agent-name>/MEMORY.md
# If ~/.claude/agent-memory is not already a symlink, run:
bash {{project_root}}/scripts/restore-memory-symlinks.sh
```

**Cause 2: Wrong path.**
The agent config (`.claude/agents/<name>.md`) must reference the correct memory path. Check that the path matches the actual directory.

**Cause 3: Memory file not committed.**
Markdown memory files only become searchable via vector search once the post-commit hook has re-embedded them. If the agent writes a file but never commits, other agents cannot find it with `memory-search.sh`.
Fix: Ensure the agent's instructions include "write the file, then commit it" as a single unit.

**Cause 4: Agent config missing memory protocol.**
The agent's `.claude/agents/<name>.md` file should include instructions about when and how to save memories.
Fix: Add a memory section to the agent config that specifies what categories of information to save (user / feedback / project / reference / note) and the file naming convention (`memory/<type>_<topic>.md`).

--- END OF PART 4: ADVANCED PATTERNS & TROUBLESHOOTING ---

--- END OF BLUEPRINT ---

# Appendix — Script Files

Every code block below has its destination path in the first line. Save each to that path, then `chmod +x` shell scripts.

## E1 — sqlite-vec + Nomic-embed

### `scripts/embed-memories.sh`

```bash
#!/usr/bin/env bash
# Thin wrapper over scripts/embed-memories.py so the rest of Cortana can call it
# like any other shell script. Forwards args, picks the working Python 3.13.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Order matters: we need a Python whose sqlite3 was built with loadable extensions.
# uv's distribution (~/.local/bin/python3.13) ticks that box; the python.org one
# at /usr/local/bin/python3 does NOT.
for cand in "${CORTANA_PY:-}" "$HOME/.local/bin/python3.13" /opt/homebrew/bin/python3.14; do
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
for cand in "${CORTANA_PY:-}" "$HOME/.local/bin/python3.13" /opt/homebrew/bin/python3.14; do
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
# with the repo. Idempotent — safe to run multiple times. Never overwrites
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
    # Already a symlink — refresh it.
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
# this is cheap — only changed chunks are re-embedded.
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
# If it fails, we log it — never block the commit.
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

## E4 — Observability

### `.claude/hooks/audit-log-hook.sh`

```bash
#!/bin/bash
# PostToolUse hook: append a minimal event record for every tool call to
# data/audit/YYYY-MM-DD.jsonl so we can replay what happened in a session.
#
# Wired in .claude/settings.json under PostToolUse. async=true so it never
# blocks tool execution.
#
# Gitignored — audit logs live on disk only, not in git.
set -euo pipefail

INPUT=$(cat)

# If input is malformed, exit quietly — never break tool flow
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

### `scripts/cortana-live.sh`

```bash
#!/bin/bash
# cortana-live — pretty-print the Cortana audit JSONL
#
# Usage:
#   cortana-live                       # last 20 events from today
#   cortana-live --follow              # tail -F today, stream live
#   cortana-live --last 50             # last 50 events
#   cortana-live --tool Bash           # only Bash events
#   cortana-live --project PokeInvest  # only events in a project
#   cortana-live --day 2026-04-20      # events from a specific day
#   cortana-live --failed              # only errored tool calls
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
    local_ts=$(date -u -j -f "%Y-%m-%dT%H:%M:%S.000Z" "$ts" "+%H:%M:%S" 2>/dev/null || echo "$ts")
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
# audit-archive — gzip audit JSONL files older than N days into the archive dir.
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
  echo "(dry run — no files moved)"
  exit 0
fi

echo "audit-archive: archived=$archived skipped=$skipped (threshold: $DAYS days)"
```

## E5 — Hardened safety gate

### `.claude/hooks/safety-gate.sh`

```bash
#!/bin/bash
# CORTANA SAFETY GATE
# Blocks destructive commands and prompts Zaki for approval via Telegram.
# Exit 0 = allow. Exit 2 = block (message sent to Claude via stderr).
#
# APPROVAL FLOW:
# 1. Hook blocks a dangerous command
# 2. Claude sees the block reason and asks Zaki on Telegram
# 3. Zaki says "yes" / "approved"
# 4. Claude writes the command to ~/Documents/cortana/data/approved.txt
# 5. Claude retries the command
# 6. Hook sees it's pre-approved, allows it, removes the approval

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // empty')

# Nothing to inspect
if [ -z "$COMMAND" ] && [ -z "$FILE_PATH" ]; then
  exit 0
fi

TIMESTAMP=$(date -Iseconds)
LOG_FILE="$HOME/Documents/cortana/logs/safety-gate.log"
APPROVAL_FILE="$HOME/Documents/cortana/data/approved.txt"

# Ensure approval file exists
touch "$APPROVAL_FILE"

# === CHECK FOR PRE-APPROVAL ===
# If Zaki already approved this exact command, let it through and clear it
CHECK_STRING="$COMMAND$FILE_PATH"
if grep -qFx "$CHECK_STRING" "$APPROVAL_FILE" 2>/dev/null; then
  # Remove the approval (one-time use)
  grep -vFx "$CHECK_STRING" "$APPROVAL_FILE" > "$APPROVAL_FILE.tmp" && mv "$APPROVAL_FILE.tmp" "$APPROVAL_FILE"
  echo "[$TIMESTAMP] APPROVED (pre-approved by Zaki): $CHECK_STRING" >> "$LOG_FILE"
  exit 0
fi

# === HELPER: block with approval instructions ===
block() {
  local REASON="$1"
  local CATEGORY="$2"
  echo "BLOCKED: $REASON. Ask Zaki for approval on Telegram. If he approves, write the exact command to ~/Documents/cortana/data/approved.txt (one command per line) then retry." >&2
  echo "[$TIMESTAMP] BLOCKED ($CATEGORY): ${COMMAND}${FILE_PATH}" >> "$LOG_FILE"
  exit 2
}

# === HELPER: hard block (not even Zaki-approval opens the gate) ===
hard_block() {
  local REASON="$1"
  local CATEGORY="$2"
  echo "HARD BLOCKED: $REASON. This cannot be approved through the hook. Run manually in Terminal if you genuinely need this." >&2
  echo "[$TIMESTAMP] HARD BLOCKED ($CATEGORY): $COMMAND" >> "$LOG_FILE"
  exit 2
}

# === CATEGORY 1: ALWAYS BLOCKED (no approval possible) ===
# These are so catastrophic or history-destroying that even with approval,
# we don't allow them through the hook. Zaki must run them manually in Terminal.

# Delete home / root filesystem
if echo "$COMMAND" | grep -qEi 'rm\s+-(rf|fr)\s+(/|~|\$HOME)\s*$'; then
  hard_block "This would delete your entire home directory or root filesystem" "catastrophic"
fi

# Disk formatting / partition ops
if echo "$COMMAND" | grep -qEi '(mkfs\.|dd\s+if=|fdisk|diskutil\s+erase)'; then
  hard_block "Disk formatting / partition operation" "disk"
fi

# Git history rewrites — these are almost never recoverable
if echo "$COMMAND" | grep -qEi 'git\s+filter-(branch|repo)'; then
  hard_block "git filter-branch/filter-repo permanently rewrites history — unrecoverable if pushed" "git-filter"
fi

if echo "$COMMAND" | grep -qEi '(git\s+update-ref\s+-d|git\s+reflog\s+expire|git\s+gc\s+.*--prune=now|git\s+gc\s+.*--aggressive)'; then
  hard_block "Permanent reflog / ref cleanup — makes it impossible to recover lost commits" "git-reflog"
fi

# Force push to protected branches: main, master, production, prod, release, develop
# Any push with --force / -f / --force-with-lease targeting one of these branches
# is a hard block. This is what destroys shared history irrecoverably.
if echo "$COMMAND" | grep -qEi 'git\s+push(\s+[^-]\S*)*\s+(--force|-f|--force-with-lease)(\s|=|$)' || \
   echo "$COMMAND" | grep -qEi 'git\s+push\s+.*(--force|-f|--force-with-lease).*\s+(origin\s+)?(main|master|production|prod|release|develop)(\s|$|:)'; then
  # Only hard-block if the target branch is main/master/production/prod/release/develop OR unspecified (defaults to current branch which might be main)
  if echo "$COMMAND" | grep -qEi '(origin\s+)?(main|master|production|prod|release|develop)(\s|$|:)'; then
    hard_block "Force push to protected branch (main/master/production/prod/release/develop) — this destroys shared history. Never allowed via the hook." "git-force-push-protected"
  fi
fi

# === CATEGORY 2: BLOCKED UNTIL ZAKI APPROVES ===

# --- File deletion ---
# Only match `rm` as a standalone command (not inside words like "form", "arm", "term").
# `(^|\s)` ensures rm is at start of command or after whitespace.
if echo "$COMMAND" | grep -qE '(^|\s)rm\s+-(r|f|rf|fr|Rf|fR)'; then
  block "Recursive or forced file deletion detected" "rm-rf"
fi
if echo "$COMMAND" | grep -qE '(^|\s)rm\s'; then
  block "File deletion detected" "rm"
fi
# `/bin/rm` style invocation
if echo "$COMMAND" | grep -qE '(^|\s|;|&|\|)(/usr)?/bin/rm\s'; then
  block "File deletion via /bin/rm detected" "rm-path"
fi

# --- Database destructors ---
if echo "$COMMAND" | grep -qEi '(DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s+TABLE)'; then
  block "Destructive database operation (DROP/TRUNCATE)" "sql-drop"
fi

# DELETE without WHERE
if echo "$COMMAND" | grep -qEi 'DELETE\s+FROM\s+\w+\s*[;$]'; then
  block "DELETE FROM without WHERE clause — this deletes ALL rows" "sql-delete"
fi

# --- Git destructive operations ---
# Force push (any form, any branch that isn't main/master — those are hard-blocked above)
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

# Interactive rebase — can rewrite history arbitrarily
if echo "$COMMAND" | grep -qEi 'git\s+rebase\s+(-i|--interactive)'; then
  block "Interactive rebase can rewrite commits. Confirm the branch isn't shared." "git-rebase-i"
fi

# Rebase --onto (advanced, frequently destructive)
if echo "$COMMAND" | grep -qEi 'git\s+rebase\s+.*--onto'; then
  block "git rebase --onto rewrites history in non-obvious ways" "git-rebase-onto"
fi

# Amend — rewrites the last commit, dangerous if already pushed
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
exit 0
```
