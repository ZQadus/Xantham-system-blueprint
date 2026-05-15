---
architectural_role: trunk
---

# Xantham System - Blueprint v31

You hand this file to a fresh Claude Code session. It walks you through picking a mode, generating the install scripts, and finishes with a working personal orchestrator on your phone. **Time to first reply: about an hour from `git clone` to your phone vibrating with output (30-45 minutes if Node 18 / Git / jq / sqlite3 / bun are already installed, closer to 90 minutes from a fresh laptop where the wizard installs prereqs first).**

The orchestrator takes Telegram messages from your phone, routes tasks to a crew of specialist sub-agents (engineering, research, growth strategy, platform-tactical social media, deploy, writing, trading, business, human-interaction), keeps memory across sessions, and runs background work on a schedule. Replies come back to Telegram so you can be anywhere.

Built and run by one person managing 8+ active projects since April 2026. Every habit, hook, and skill in this blueprint earned its place after a real bug, a real correction, or a real session-end review. The system itself is generic; you bring your own agent names, project list, and Telegram bot.

---

## What you need before starting

| Required | Why |
|---|---|
| **Claude.ai Max subscription** | The orchestrator runs on Claude Code which uses your Claude.ai sub. Max tier gives the rate-limit headroom needed for daily intensive use. |
| **Telegram account** | The phone-side interface. Free. |
| **A Mac or Windows laptop** | Mac and Windows are the supported install paths with side-by-side commands. Linux should work, untested. |
| **45 to 90 minutes of focused install time** | The install is interactive. The 75 to 120 min total above includes Telegram bot setup + first message round-trip after install completes. |
| **Optional: separately-billed Anthropic API key** | Two uses. (1) The auth-failover canary that flips to a paid API key if your Max OAuth ever suspends. (2) The optional `dream` memory consolidation pass which costs about $1 per run on weekly cadence (~$4/month). |

Background scheduled tasks have a few Mac-specific quirks documented in the Troubleshooting section. They do not block daily use.

---

## Pick your mode

> **Recommendation: install Simple first.** Add extensions one by one as you feel the pain points they solve. Do not run the full Advanced stack until you have used Simple for a week and know what is missing.

Before install, pick one. You can upgrade later, but the fresh-install path differs.

| | Simple mode | Advanced mode |
|---|---|---|
| Setup time | ~20 minutes | ~45-60 minutes |
| RAM while idle | ~500 MB | ~1.5 GB |
| Disk | ~200 MB | ~2-3 GB |
| **Monthly cost** | **$0 ongoing** (your Claude Max sub covers the orchestrator) | **$0 ongoing for the local stack.** ~$4/month if you also enable the optional `dream` consolidation pass (~$1 per weekly run on Anthropic API) |
| Memory retrieval | Markdown files + grep + NotebookLM Brain | Same + sqlite-vec semantic search via local Ollama |
| Multi-agent coordination | Sequential via the Task tool | Live shared context via Agent Teams + whiteboard |
| Observability | Telegram history log | Everything above + per-tool-call audit JSONL + live viewer |
| Safety gate | Basic (file deletion / sudo / force-push) | Hardened (protected-branch hard-blocks, word-boundary regex, history-rewriting blocks) |
| Includes | Core orchestrator + 9 specialist agents + Telegram + Brain + safety | Same + E1 sqlite-vec + E3 Agent Teams + E4 Observability + E5 Hardened safety |
| Good for | Getting started fast, low-overhead daily use, beginner-friendly | Power users running 5+ projects, multi-agent workflows, long-horizon memory recall, audit-trail compliance |

### Mode contents at a glance

**Simple mode includes:** Orchestrator (your AI), Specialist crew (9 specialists), Markdown memory, Telegram channel, NotebookLM Brain integration, Session cron, Compaction defence, Basic safety gate.

**Advanced mode includes everything in Simple, plus:**
- **E1 Semantic memory** (sqlite-vec + Ollama Nomic-embed) - semantic search across your memory files. "Find the rule about timezones" works even when you don't remember the file name.
- **E3 Agent Teams** - multiple agents share a live whiteboard so they don't duplicate work or step on each other.
- **E4 Observability** - every tool call gets logged to a JSONL audit, surfaced via `{{orchestrator_lower}}-live.sh`. Catches silent failures and "what did the background agent actually do?"
- **E5 Hardened safety** - strict replacement for the basic gate. Force-push to protected branches becomes physically impossible (no approval can unlock it). Fixes false-positives on `format` / `arm` words that contain `rm`.

Every extension is independently installable and removable. `.{{orchestrator_lower}}-blueprint-version` tracks which are on.

### Upgrades library

After installing your orchestrator, the living docs for "what's been built" + "where we're going" live at:

```
docs/upgrades/
├── CATALOGUE.md   - BACKWARD-looking ledger (SHIPPED / DEFERRED / REJECTED / PILOT)
├── ROADMAP.md     - FORWARD-looking plan (vision + phased roadmap)
└── memo_*.md      - specific architectural memos
```

Read CATALOGUE before proposing new upgrades (you might find it's already been considered or explicitly rejected). Read ROADMAP before starting Phase N+1 work (aligns with the north-star). The `{{orchestrator_lower}}-maintenance` skill reads both on every Monday / greeting digest. (A skill is a bundle of instructions Claude loads on-demand when the situation matches.)

---

## Core (always installed)

Both modes get:

### Orchestrator (your AI itself)
Claude Code CLI running Opus 4.7. Receives Telegram messages, routes to specialist sub-agents, replies. Lives in `CLAUDE.md` in your project root.

### Specialist crew (9 specialists)
Default names - rename to taste. Total team is 9 specialists + 1 orchestrator = 10 agents:
- **Kai** - engineering (code, architecture, bugs, review)
- **Rose** - research (competitive intel, market sizing, deep research)
- **Natalie** - growth (ASO, launches, paid + organic strategy, brand positioning)
- **Maya** - social (platform-tactical content for TikTok / IG / X / YouTube / Reddit, algorithm play, viral hooks, creator economy, community management)
- **Marco** - infra (deploy, CI/CD, DNS, monitoring)
- **Isabella** - writing (blog posts, docs, decks, emails)
- **Warren** - trading (strategies, backtests, portfolio, markets)
- **Elena** - business (revenue, pricing, partnerships, contracts)
- **Chase** - human dynamics (persuasion, negotiation, networking)
- **{{orchestrator_name}}** - the orchestrator (you)

Each lives at `.claude/agents/<name>.md`. Each has its own persistent memory at `agent-memory/<name>/`.

### Operating principles

The orchestrator runs under a small set of cross-project rules. They apply to every dispatch, every architectural change, every new project.

**Built to scale, never break existing clients.** Every architectural change preserves current user behaviour AND is designed for 100x current load from day one. If a change would silently alter how an already-shipped product works, it does not ship. Back-compat first, scale-aware second. Zero silent breaking changes, ever.

**Reply first, log after.** When a Telegram message arrives, the reply tool fires before any logging or memory work. Every pre-reply Bash call adds a second or two of user-visible latency, and the user is staring at their phone.

**Verify before claiming done.** "Pushed" is not "deployed." After any push to a hosting platform, verify the deploy actually landed before reporting success. Same for migrations, same for credential rotations.

**Plan before code on multi-file changes.** Anything that touches three or more files, adds a new feature, or introduces a new dependency gets a written plan before code. Cheaper to redirect on a paragraph than on 200 lines.

These four show up again in the orchestration skill, the safety skill, and several feedback memories. They are the floor, not advice.

### Memory system
- `memory/MEMORY.md` - index, auto-loaded at session start (capped at 200 lines per Anthropic Auto Dream convention)
- `memory/profile_<user>.md` - mutable narrative for the user (the Profile bucket; see sub-section below)
- `memory/episodic/<YYYY-MM-DD>.md` - daily-rolled telegram tail + reflection + commits (cognitive-overlay episodic bucket; flat structure, one file per day)
- `memory/semantic/<type>/*.md` - durable atomic facts split by type prefix: `feedback/`, `project/`, `reference/`, `note/`, `user/` subdirs (cognitive-overlay semantic bucket)
- `memory/procedural/README.md` - pointer to CLAUDE.md + `.claude/skills/` + corrections-promoted ledger (cognitive-overlay procedural bucket; "how the orchestrator behaves" is in the operating layer, not files)
- `agent-memory/<agent>/*.md` - per-agent memories, loaded on agent spawn (one MEMORY.md index plus topic files per specialist)
- `data/telegram-history/YYYY-MM.jsonl` - every Telegram message, inbound and outbound

All markdown. All in the repo. All auto-loaded by Claude Code at session start.

The cognitive-overlay structure (episodic / semantic / procedural) is the CALA (a 2024 cognitive-architecture paper covering long-term agent memory) / MIRIX (an open-source agent memory framework that ships these three buckets) pattern, layered on top of Karpathy's three-bucket Memory + Knowledge + Profile model (Andrej Karpathy's late-2025 informal taxonomy of agent memory, from his X / Substack posts, not a formal paper). Episodic is "what happened today." Semantic is "durable atomic facts." Procedural is "how the orchestrator behaves" (lives in skills + CLAUDE.md, not in files). Every memory iterator (search, embed, freshness check, dream consolidation, blueprint export) recurses subdirs AND dot-prunes (`-not -path "*/.*"`), so any dot-dir carveouts stay invisible at search time, at index time, and at export time.

#### Profile bucket

The Profile bucket is the third leg of the Karpathy three-bucket pattern: Memory (the Index, auto-loaded), Knowledge (semantic + episodic + procedural files), Profile (mutable narrative about the user).

There is exactly one profile file per user: `memory/profile_<user>.md`. Read at session start. Updated mid-session on explicit signals ("call me Sam", "I'm now working on X full-time"). Drafted at session end by `scripts/update-profile.sh` based on observed changes during the session. Lifecycle is `update_frequency: per-session` and `ttl_days: 7` in the frontmatter so it stays fresh.

In v31, the Profile bucket is user-side only. The 9 specialist agents have `agent-memory/<name>/MEMORY.md` indexes plus topic files, no per-agent profile narrative. Per-agent profiles are a v32+ candidate, not v31.

Update flow on session end:

```bash
# Mac, Linux, Windows Git Bash, Windows WSL2
bash scripts/update-profile.sh
# Reads recent telegram + reflections + corrections, drafts a diff against
# the existing profile_<user>.md, writes the diff for the orchestrator to
# review and apply. Pure bash, no OS-specific paths.
```

Mid-session updates are inline edits when the user states something profile-shaped: a new role, a new constraint, a new preference. Don't update on every minor signal, only when the change matters cross-session.

Carveout: any dot-prefixed subdirectory under `memory/.<name>/` (e.g. `memory/.private/`) is gitignored AND dot-pruned by every iterator. Files the user keeps in such a private subdirectory never surface in public exports, never feed the semantic index, never appear in MEMORY.md.

### Telegram integration
- `claude-plugins-official/telegram` MCP plugin (a plugin is a bundle of skills + commands installed through the Claude Code app; an MCP server is a pre-built connector that lets your agents talk to outside services like Telegram, Gmail, your database, Vercel, and so on)
- `.claude/hooks/log-telegram-hook.sh` auto-logs every outbound reply (async, no latency). A hook is a small script that runs automatically before or after the agent does certain actions; the safety gate is also a hook.
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

**Approval flow in plain English.** If your agent tries one of those destructive commands, the safety gate pauses and pings you on Telegram. The message shows the exact command and asks something like: "Approve `rm old-file.txt`?" Reply `yes` to allow it. Reply anything else to refuse. If you happen to be at your laptop, you can also reply directly in the terminal, same effect. The approval is one-time only. The same command next session pauses again. The agent writes your `yes` to `{{project_path}}/data/approved.txt` so it can re-read it on the retry, then deletes the entry.

---

## Extensions (opt-in - Advanced mode)

Each extension is self-contained. Install only the ones you want. Uninstall by removing its section from your config.

---

### E1 - Semantic memory via sqlite-vec + Nomic-embed

**Purpose**
Fast local semantic search over every markdown memory file. Answers "have we hit this before?" and "what did we decide about X?" without going to the NotebookLM Brain. 95 ms median latency.

**How it works**
- `scripts/embed-memories.sh` reads every `.md` in `memory/`, `agent-memory/`, `docs/`, chunks by paragraph, embeds each chunk via Ollama's Nomic-embed-text (137M params, local), stores in `data/vector-memory.db` (sqlite-vec virtual table)
- Incremental: on re-run, only re-embeds chunks whose content hash changed
- `scripts/memory-search.sh "<query>"` embeds the query, returns top-5 matches with file path + line range + score
- Post-commit git hook re-embeds any changed memory files automatically

**Cost**
- $0 - no API calls. Nomic-embed weights are free, run on your CPU via Ollama.
- Disk: ~300 MB (Nomic-embed model) + ~10-15 MB (vector DB for 1200 chunks; a mature setup runs 1000-1500 chunks across memory + agent-memory + docs)
- RAM: ~500 MB when Ollama is loaded; 0 when idle (Ollama unloads after 5 min)

**Token usage**
Zero. Purely local compute.

**Dependencies**
- Ollama (Mac: `brew install ollama` / Windows: `winget install Ollama.Ollama` - then `ollama pull nomic-embed-text` on both)
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
# 5. Install the git hook (run via Git Bash or WSL - the .sh scripts assume bash)
bash scripts/install-git-hooks.sh

# 6. First full embed (one-time)
bash scripts/embed-memories.sh
```

**Uninstall**

Run this dependency check FIRST. E6 (Amazing Memory) active recall calls into the sqlite-vec index installed by E1. Removing E1 while E6 is on silently breaks active-recall lookups (Mode A returns empty; the orchestrator stops surfacing relevant memory before each non-trivial reply).

```bash
# Mac / Linux / Windows-Git-Bash, identical commands
VERSION_FILE=".{{orchestrator_lower}}-blueprint-version"
if [ -f "$VERSION_FILE" ] && grep -q "E6_amazing_memory: true" "$VERSION_FILE"; then
  echo "WARN: E6 (Amazing Memory) is installed and depends on E1's sqlite-vec index."
  echo "      Uninstalling E1 will silently break E6 active recall."
  echo ""
  echo "      Recommended: uninstall E6 first (see E6 Uninstall block above)."
  echo "      To proceed anyway, re-run with --force-anyway:"
  echo "        bash scripts/install-blueprint.sh --remove E1 --force-anyway"
  exit 1
fi
```

Once the dependency check passes (or you opted in via `--force-anyway`):
- Delete `data/vector-memory.db`
- Remove the post-commit hook: `rm .git/hooks/post-commit` (Mac/Linux) or `Remove-Item .git\hooks\post-commit` (Windows)
- Uninstall Ollama if you don't use it elsewhere: `brew uninstall ollama` (Mac) or `winget uninstall Ollama.Ollama` (Windows)

**Usage**
```bash
bash scripts/memory-search.sh "how do I fix the alpha channel icon issue"
# Returns top-5 chunks with path + line range + similarity score
```

**Verify**
```bash
# Mac / Linux / Windows-Git-Bash. Each line exercises the actual capability.

# 1. Ollama is up and serving Nomic-embed
ollama list | grep -q nomic-embed-text && echo "OK: nomic-embed model present"

# 2. sqlite-vec extension loads in the project's Python interpreter
python3 -c "import sqlite_vec; print('OK: sqlite-vec import works')"

# 3. The vector index file exists and has chunks (real embed must have run)
[ -s data/vector-memory.db ] && echo "OK: data/vector-memory.db non-empty"

# 4. Round-trip a known query through the search and confirm we get hits.
#    Seed memory: write a one-off file, embed it, search for it.
mkdir -p memory && cat > memory/note_e1_verify_seed.md <<'SEED'
---
name: e1 verify seed
description: ephemeral seed for E1 install verify
type: note
---
The verification phrase is "lavender artichoke calibration".
SEED
git add memory/note_e1_verify_seed.md && git commit -m "chore(verify): E1 seed" >/dev/null
bash scripts/embed-memories.sh >/dev/null 2>&1
bash scripts/memory-search.sh "lavender artichoke calibration" \
  | grep -q "note_e1_verify_seed" \
  && echo "OK: E1 semantic search round-trip works"

# 5. Cleanup the seed memory
git rm memory/note_e1_verify_seed.md >/dev/null
git commit -m "chore(verify): drop E1 seed" >/dev/null

echo "OK: E1 installed"
```

---

### E3 - Agent Teams + channel.md whiteboard

**Purpose**
Live shared context between sub-agents working in parallel on the same task. Without this, agents fire and forget - each one's decisions are invisible to the others until they report back. With this, one agent's progress updates are visible to the others in real time.

**How it works**
- Set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `.claude/settings.json`. Enables `TeamCreate`, `SendMessage`, and `TeamDelete` tools for live peer-to-peer messaging (Claude Code 2.1.32+).
- Create a markdown channel file at `data/agent-channels/<slug>.md` when spawning multiple agents on the same project. Include the path in every agent's brief.
- Agents `Edit`-append their progress/decisions/blockers to the channel as they work. The orchestrator re-reads between its own tool calls to converge state across agents.
- When the task ships, archive to `data/agent-channels/archive/YYYY-MM/<slug>.md`.

**Cost**
$0. Just a feature flag + a markdown file.

**Token usage**
Marginal - agents spend a few extra tokens reading the channel file before deciding their next step. Saves tokens overall because they don't re-ask the orchestrator "what is the other agent doing?"

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
Included in the orchestrator's orchestration habits (see CLAUDE.md). Multi-agent tasks on the same project automatically get a channel file.

**Verify**
```bash
# Mac / Linux / Windows-Git-Bash. Each line exercises the actual capability.

# 1. Feature flag is on in settings (the env block is what unlocks the tools)
jq -e '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS == "1"' .claude/settings.json >/dev/null \
  && echo "OK: agent-teams flag enabled"

# 2. Whiteboard directory exists and is writable
mkdir -p data/agent-channels && touch data/agent-channels/.write-probe && rm data/agent-channels/.write-probe \
  && echo "OK: data/agent-channels/ writable"

# 3. Round-trip an append: create a test channel, append a line, read it back
TESTCH="data/agent-channels/_install-verify.md"
echo "# install verify channel" > "$TESTCH"
echo "- agent-a: started" >> "$TESTCH"
echo "- agent-b: ack agent-a, starting lane 2" >> "$TESTCH"
[ "$(wc -l < "$TESTCH")" -eq 3 ] && echo "OK: append-only whiteboard pattern works"
rm "$TESTCH"

echo "OK: E3 installed"
```

---

### E4 - Observability audit layer

**Purpose**
Live visibility into every tool call your orchestrator (and its sub-agents) make during a session. Solves "I know the background agent finished, but I can't easily see what it did." Paid for itself within hours of installation on our first run.

**How it works**
- `.claude/hooks/audit-log-hook.sh` is a PostToolUse hook with matcher `.*`. Fires async after every tool call.
- Writes one JSON line per event to `data/audit/YYYY-MM-DD.jsonl` with: tool name, tool_use_id, input summary (240 chars), output summary (240 chars), success/error, project
- Secrets-stripped: regex scrubs `api_key`, `token`, `password`, `bearer`, `authorization` patterns before write
- Gitignored - audit logs never leave your machine
- `scripts/{{orchestrator_lower}}-live.sh` pretty-prints with filters (--tool, --project, --day, --failed, --follow)
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

# 2. Copy scripts/{{orchestrator_lower}}-live.sh, scripts/audit-archive.sh, scripts/history.sh, scripts/verify-sync.sh
chmod +x scripts/{{orchestrator_lower}}-live.sh scripts/audit-archive.sh scripts/history.sh scripts/verify-sync.sh

# 2b. Copy .claude/hooks/session-end-verify.sh and wire it as the Stop hook
chmod +x .claude/hooks/session-end-verify.sh

# 3. Wire into .claude/settings.json under PostToolUse with matcher ".*"
# (append a new entry to the PostToolUse array, async=true)

# 4. Add data/audit/ to .gitignore
```

Note: Windows users running outside Git Bash will need WSL2 for the chmod / bash / jq pipeline. The {{orchestrator_lower}}-live.sh script is bash-only; PowerShell native ports of these scripts are not maintained. See the "Windows shell choice" callout under "Quick start" earlier in the blueprint.

**Uninstall**
Remove the PostToolUse entry from `.claude/settings.json` and delete `data/audit/`.

**Usage**
```bash
bash scripts/{{orchestrator_lower}}-live.sh             # last 20 events today
bash scripts/{{orchestrator_lower}}-live.sh --follow    # stream live
bash scripts/{{orchestrator_lower}}-live.sh --failed    # only errored tool calls
bash scripts/{{orchestrator_lower}}-live.sh --project MyProject --tool Agent
bash scripts/audit-archive.sh 30         # gzip JSONL >=30d old into data/audit/archive/YYYY/MM.jsonl.gz
bash scripts/history.sh <query>          # unified search across telegram + audit (live + archived) + git log + memory
```

**Verify**
```bash
# Mac / Linux / Windows-Git-Bash. Each line exercises the actual capability.

# 1. Hook is wired in PostToolUse with matcher ".*"
jq -e '.hooks.PostToolUse[] | select(.matcher == ".*") | .hooks[] | select(.command | contains("audit-log-hook.sh"))' \
  .claude/settings.json >/dev/null \
  && echo "OK: audit-log-hook wired in settings"

# 2. Hook is executable
[ -x .claude/hooks/audit-log-hook.sh ] && echo "OK: audit-log-hook executable"

# 3. data/audit/ is gitignored (a real hit on the index would otherwise commit secrets)
grep -q "^data/audit/" .gitignore && echo "OK: data/audit/ gitignored"

# 4. Hook actually writes to the audit log when fired. Trigger it directly with
#    a synthetic JSON payload (mimics what Claude Code passes via stdin).
TODAY=$(date +%Y-%m-%d)
PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"echo install-verify"},"tool_output":"install-verify","success":true}'
echo "$PAYLOAD" | bash .claude/hooks/audit-log-hook.sh >/dev/null 2>&1
[ -s "data/audit/${TODAY}.jsonl" ] \
  && grep -q "install-verify" "data/audit/${TODAY}.jsonl" \
  && echo "OK: audit-log-hook writes JSONL events"

# 5. The pretty-print viewer reads what the hook wrote
bash scripts/{{orchestrator_lower}}-live.sh --day "$TODAY" 2>/dev/null | head -1 | grep -q . \
  && echo "OK: live.sh reads back audit events"

echo "OK: E4 installed"
```

---

### E5 - Hardened safety gate

**Purpose**
Stricter replacement for the Core safety gate. Adds protected-branch force-push hard-blocks (cannot be approved through the hook - requires manual Terminal) and fixes word-boundary false positives on `rm` that match innocent words like "format" or "arm".

**How it works**
Drop-in replacement for `.claude/hooks/safety-gate.sh`. Same approval-file mechanism (`{{project_path}}/data/approved.txt`), same log, same exit codes. Rules:

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

The wizard generates the hardened gate body straight into `.claude/hooks/safety-gate.sh` during Step 11 from the `## E5 - Hardened safety gate` template in `blueprints/xantham-templates-v31.md` (262 lines). It includes hard-blocks for force-push to protected branches, git filter-branch, reflog expire, refspec-prefixed force pushes (`+HEAD:main`), `push.default` overrides, and a CLI-rm whitelist (`vercel env rm`, `gh secret rm`, `docker rm`, `npm rm`, `git rm`, etc.) that prevented past false positives.

```bash
# 1. Back up BOTH safety gates before the hardened body overwrites either one.
#    The hardened gate replaces both the project-level gate and the
#    user-level (global) gate. Without both backups, uninstall is one-way.
cp .claude/hooks/safety-gate.sh .claude/hooks/safety-gate.sh.core-backup
cp ~/.claude/hooks/safety-gate.sh ~/.claude/hooks/safety-gate.sh.core-backup 2>/dev/null \
  || echo "no global gate to back up (fresh install ok)"

# 2. Verify the wizard wrote the hardened body to the project-level gate.
#    The wizard generates the body during Step 11 from the E5 template in
#    blueprints/xantham-templates-v31.md. The string "HARD BLOCKED" only
#    appears in the hardened gate, not the core one.
grep -q "HARD BLOCKED" .claude/hooks/safety-gate.sh && echo "OK: hardened gate active" || echo "FAIL: re-run Step 11 generation"

# 3. Mirror the hardened body to the GLOBAL gate at ~/.claude/hooks/safety-gate.sh
#    so destructive commands are blocked in every Claude Code project on this
#    machine, not just this one. The script handles the path + header rewrite.
bash scripts/sync-safety-gates.sh

# 4. Make both executable
chmod +x .claude/hooks/safety-gate.sh ~/.claude/hooks/safety-gate.sh
```

Note: Windows path conventions differ. The global gate on Windows lives at `%USERPROFILE%\.claude\hooks\safety-gate.sh` (under Git Bash) or `\\wsl$\Ubuntu\home\<user>\.claude\hooks\safety-gate.sh` (under WSL). Match whichever shell hosts your Claude Code install.

**Uninstall**
Restore the `.core-backup` copy on BOTH gates. The hardened gate replaced both, so a project-only restore leaves the global gate enforcing E5 rules in every other Claude Code project on this machine.

```bash
# 1. Restore the project-level gate
mv .claude/hooks/safety-gate.sh.core-backup .claude/hooks/safety-gate.sh

# 2. Restore the global gate (matching what's at ~/.claude/hooks/safety-gate.sh).
#    Skip this only if step 1 of install reported "no global gate to back up"
#    (clean machine), in which case delete the global gate entirely.
if [ -f ~/.claude/hooks/safety-gate.sh.core-backup ]; then
  mv ~/.claude/hooks/safety-gate.sh.core-backup ~/.claude/hooks/safety-gate.sh
else
  rm ~/.claude/hooks/safety-gate.sh
fi

# 3. Confirm both restored gates are still executable
chmod +x .claude/hooks/safety-gate.sh
[ -f ~/.claude/hooks/safety-gate.sh ] && chmod +x ~/.claude/hooks/safety-gate.sh
echo "OK: E5 uninstalled, both safety gates restored"
```

Why both. The two gates fire on every tool call independently. Diverging them means one blocks what the other allows, which is debug-hostile. See the project + global gate sync rule in the orchestrator's safety memories.

**Verify**
```bash
# Mac / Linux / Windows-Git-Bash. Each line exercises the actual capability.

# 1. Both gates are present and executable
[ -x .claude/hooks/safety-gate.sh ]    && echo "OK: project gate executable"
[ -x ~/.claude/hooks/safety-gate.sh ]  && echo "OK: global gate executable"

# 2. Hard-block path: feed the gate a hard-blocked command and confirm
#    it refuses (non-zero exit) WITHOUT consulting the approval file.
HARD_PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}'
echo "$HARD_PAYLOAD" | bash .claude/hooks/safety-gate.sh >/dev/null 2>&1
[ $? -ne 0 ] && echo "OK: project gate hard-blocks force-push to main"

# 3. Approval-gated path: feed a destructive-but-approvable command,
#    confirm it blocks, then write the approval, confirm it now passes.
APPROVABLE='{"tool_name":"Bash","tool_input":{"command":"rm test-install-verify-file.txt"}}'
echo "$APPROVABLE" | bash .claude/hooks/safety-gate.sh >/dev/null 2>&1
BLOCKED_EXIT=$?
mkdir -p data && echo "rm test-install-verify-file.txt" >> data/approved.txt
echo "$APPROVABLE" | bash .claude/hooks/safety-gate.sh >/dev/null 2>&1
APPROVED_EXIT=$?
[ "$BLOCKED_EXIT" -ne 0 ] && [ "$APPROVED_EXIT" -eq 0 ] \
  && echo "OK: approval-file flow works"
# cleanup the approval entry
sed -i.bak '/^rm test-install-verify-file.txt$/d' data/approved.txt && rm -f data/approved.txt.bak

# 4. Word-boundary correctness: the gate should NOT block "format" or
#    "arm" just because they contain the letters "rm".
INNOCENT='{"tool_name":"Bash","tool_input":{"command":"echo formatted"}}'
echo "$INNOCENT" | bash .claude/hooks/safety-gate.sh >/dev/null 2>&1
[ $? -eq 0 ] && echo "OK: word-boundary regex spares innocent matches"

# 5. Global gate produces the same verdicts (sanity check on sync)
echo "$HARD_PAYLOAD" | bash ~/.claude/hooks/safety-gate.sh >/dev/null 2>&1
[ $? -ne 0 ] && echo "OK: global gate hard-blocks force-push too"

echo "OK: E5 installed"
```

---

### E6 - Amazing Memory (active recall + dream consolidation)

**Purpose**
Two upgrades on top of the Core memory layer. (1) Active recall: before generating a non-trivial Telegram reply, the orchestrator extracts entities from the inbound message (URLs, project names, named persons, file paths) and surfaces relevant memory automatically. Closes the bug class where a long-lived project exists but nothing semantically points at it, so the orchestrator forgets it. (2) Dream consolidation: a manual or scheduled 4-phase pass (orient → gather → consolidate → prune) that merges contradictions, drops stale entries, normalises dates, and rebuilds `MEMORY.md`. Hard $1 cost cap per run.

**How it works**

Two modes wrapped in one skill at `.claude/skills/{{orchestrator_lower}}-memory/SKILL.md`.

*Mode A - Active recall (per-turn, automatic).*
Pipeline runs on every non-trivial Telegram inbound:
- `scripts/active-recall-entities.sh` extracts URLs / project names (matched against `docs/projects.md`) / named persons (matched against the Profile bucket) / file paths via regex (1-2 ms)
- `scripts/active-recall.sh` dispatches `scripts/memory-search.sh` per entity, capped at 2 entities, top-3 hits each
- Within-session 1 h TTL cache at `data/runtime/active-recall-cache.tsv` - sub-50 ms warm hits, ~280 ms cold
- Skip-list applied automatically: greetings (`hi`, `hey`, `gm`, `sup`), one-word confirmations (`yes`, `ok`), commands (`sync`, `wrapup`, `healthcheck`, `help`, `team`, `projects`, `status`, `monitor`, `deploy`, `history`, `brain`, `notes`)
- Total latency budget: <200 ms median added to first reply

*Mode B - Dream consolidation (manual + scheduled).*
Four phases, one bash script per phase under `scripts/dream/`:
- `phase1-orient.sh` - JSON state snapshot (memory file count, profile last_updated, corrections-promoted count, recent reflections list)
- `phase2-gather.sh` - scan last N session telegram + corrections + reflections + audit log for repeated patterns / contradictions / decisions
- `phase3-consolidate.sh` - LLM-driven proposal pass (dry-run by default), normalise relative dates, drop contradicted entries, merge overlapping. Hard $1 cost cap with abort + `aborted-cost.md` if projected over. 100K input-token guardrail.
- `phase4-prune.sh` - rebuild `MEMORY.md` index (capped at 200 lines), re-embed via post-commit hook, write `data/dream-runs/<ts>/changes.md`

Orchestrator: `bash scripts/dream.sh --full-cycle [--turn-id <id>] [--dry-run]` runs all 4 phases sequentially. Manual trigger via `dream` / `/dream` / "consolidate memory". Scheduled via Stop hook on session end if 24 h + 5 sessions both elapsed since last run.

*Compilation passes (cognitive-overlay maintenance).*
Three cadences, all skill-driven (no cron):
- Daily: `scripts/roll-episodic.sh` writes `memory/episodic/<date>.md` from telegram tail + reflection + commits, wired into the session-end Stop hook
- Weekly: `scripts/weekly-memory-compile.sh` Sundays via `bash scripts/maintain.sh` - extracts repeated patterns from past-week's episodic + writes `data/dream-proposals/weekly-<date>.md`
- Monthly: `scripts/monthly-memory-retrospective.sh` first-Sunday-of-month - runs `dream --full-cycle` + writes retrospective covering token spend, hit rates, stale rate, growth chart

**Cost**
- Active recall: $0 (sqlite-vec + cache, pure local compute)
- Dream consolidation: capped at $1/run via Anthropic API. Abort if projected over.

**Token usage**
- Active recall: zero (local sqlite-vec lookup)
- Dream phase 3: budgeted at 100K input tokens max, $1 cap

**Dependencies**
- E1 sqlite-vec extension installed and indexing (Mode A search calls into it)
- Anthropic API key for dream phase 3 (set as `ANTHROPIC_API_KEY` env)
- Existing core memory layer + post-commit hook
- Bash + Python 3 (already required by Core)

**Install (Mac)**
```bash
# 1. Confirm E1 (sqlite-vec) is installed and indexing
bash scripts/memory-search.sh "test query" >/dev/null && echo "E1 ok"

# 2. Create cognitive-overlay subdirs
mkdir -p memory/episodic memory/semantic/feedback memory/semantic/project memory/semantic/reference memory/semantic/note memory/semantic/user memory/procedural

# 3. Move existing flat type-prefix files into the semantic subdirs.
#
#    SAFETY: create a backup branch FIRST so the migration is reversible.
#    If you re-run the upgrade, the existing backup branch will collide
#    and the script aborts with a clear hint instead of silently overwriting.
#
#    Idempotent: the [ ! -f "$dest" ] guard inside the for-loop below makes
#    a re-run a no-op rather than crashing on "destination exists" if a
#    same-named file was already moved (or re-created post-migration).
BACKUP_BRANCH="backup/v30-pre-upgrade-$(date +%s)"
if git show-ref --verify --quiet "refs/heads/$BACKUP_BRANCH"; then
  echo "ABORT: backup branch '$BACKUP_BRANCH' already exists."
  echo ""
  echo "  This means one of two things:"
  echo "  1. You are re-running the v30 -> v31 upgrade. The migration"
  echo "     already happened on the prior run. Skip this step (3) and"
  echo "     continue from step 4."
  echo "  2. You created this branch manually. Delete it with"
  echo "     'git branch -D $BACKUP_BRANCH' (your call) and re-run."
  echo ""
  exit 1
fi
git branch "$BACKUP_BRANCH"
echo "OK: backup branch created: $BACKUP_BRANCH"
echo "    rollback with: git reset --hard $BACKUP_BRANCH"


for type in feedback project reference note user; do
  for f in memory/${type}_*.md; do
    [ -f "$f" ] || continue
    dest="memory/semantic/${type}/$(basename "$f")"
    if [ ! -f "$dest" ]; then
      git mv "$f" "$dest"
    else
      echo "already moved: $dest (skipping)"
    fi
  done
done

# 4. Drop in the {{orchestrator_lower}}-memory skill
mkdir -p .claude/skills/{{orchestrator_lower}}-memory
# (copy SKILL.md from the templates section in this blueprint)

# 5. Drop in the active-recall scripts
chmod +x scripts/active-recall-entities.sh scripts/active-recall.sh

# 6. Drop in the dream scripts (phase1-4 + orchestrator)
mkdir -p scripts/dream
chmod +x scripts/dream/phase1-orient.sh scripts/dream/phase2-gather.sh scripts/dream/phase3-consolidate.sh scripts/dream/phase4-prune.sh
chmod +x scripts/dream.sh

# 7. Drop in the compilation-pass scripts
chmod +x scripts/roll-episodic.sh scripts/weekly-memory-compile.sh scripts/monthly-memory-retrospective.sh

# 8. Drop in the profile-bucket update script
chmod +x scripts/update-profile.sh
# Creates memory/profile_<user>.md with frontmatter scaffold if missing.

# 9. Wire the Stop hook to roll episodic on session end
#    (append to scripts/session-end-sync.sh):
#    bash scripts/roll-episodic.sh || true
#    bash scripts/update-profile.sh || true

# 10. Wire weekly + monthly triggers into scripts/maintain.sh
#    (the maintain script auto-detects Sunday + first-Sunday-of-month and dispatches)

# 11. Re-embed (the cognitive-overlay move invalidates old chunk paths)
python3 scripts/embed-memories.py

# 12. Smoke
bash scripts/dream.sh --full-cycle --dry-run
ls memory/episodic/  # expect today's date.md after first session-end
ls memory/profile_*.md  # expect a profile file for the user
```

**Install (Windows, Git Bash or WSL2)**
```bash
# Identical to Mac steps above. Run inside Git Bash (winget install Git.Git)
# or WSL2 (wsl --install). PowerShell-only installs will not work because
# the dream scripts, active-recall scripts, and update-profile script are bash.

# If running under WSL, the Python 3 in WSL is what python3 scripts/embed-memories.py
# binds to. Make sure sqlite-vec is installed in that interpreter, not Windows-side:
wsl -- pip install sqlite-vec

# All other commands (mkdir, git mv, chmod, bash) are identical.
```

**Scheduled cadence**

The three compilation passes plus the dream consolidator have different scheduling needs depending on OS.

Mac and Linux: hook the Stop hook for daily rolls. Weekly and monthly cadences run inside `scripts/maintain.sh`, which the orchestrator invokes on Mondays during the greeting-digest path. No launchd job required, and that's deliberate. macOS 15 TCC blocks launchd-spawned bash from executing scripts under `~/Documents/`, so any always-on launchd job would die silently. See the Troubleshooting section for the AppleScript .app wrapper recipe if you want a true background schedule.

Windows: same Stop hook for daily, same `maintain.sh` for weekly and monthly. If you want the maintenance pass to fire even when Claude Code isn't running, register a Task Scheduler job:

```powershell
# Open Task Scheduler, Create Basic Task
# Name: {{orchestrator_lower}}-maintain-weekly
# Trigger: Weekly, Sundays, 09:00
# Action: Start a program
#   Program: C:\Program Files\Git\bin\bash.exe
#   Arguments: -c "cd C:/Users/<you>/Documents/MyAgent && bash scripts/maintain.sh"
```

A schtasks one-liner does the same thing if you prefer the CLI:

```powershell
schtasks /Create /SC WEEKLY /D SUN /ST 09:00 /TN "{{orchestrator_lower}}-maintain-weekly" /TR "\"C:\Program Files\Git\bin\bash.exe\" -c \"cd C:/Users/<you>/Documents/MyAgent && bash scripts/maintain.sh\""
```

Subdir-recursion + dot-prune are baked into every iterator. `find memory/ -name "*.md" -not -path "*/.*"` is the canonical pattern. Any new script that reads memory MUST follow it, otherwise dot-dir carveouts and gitignored subdirectories leak into the index.

**Uninstall**
- Remove `.claude/skills/{{orchestrator_lower}}-memory/`
- Remove the active-recall directive from CLAUDE.md Core loop step 3a
- Remove `scripts/active-recall*.sh`, `scripts/dream/`, `scripts/roll-episodic.sh`, `scripts/weekly-memory-compile.sh`, `scripts/monthly-memory-retrospective.sh`
- Optional: revert the cognitive-overlay subdir layout (move semantic/ files back to flat). The post-commit hook re-embeds automatically.

**Verify**
```bash
# Mac / Linux / Windows-Git-Bash. Each line exercises the actual capability.

# 1. Skill file is in place
[ -f .claude/skills/{{orchestrator_lower}}-memory/SKILL.md ] \
  && echo "OK: memory skill present"

# 2. Active-recall pipeline emits a <memory> block for a real entity
echo "https://example.com" | bash scripts/active-recall.sh 2>/dev/null \
  | grep -q "<memory>" \
  && echo "OK: active recall emits memory block for URL entity"

# 3. Active-recall cache is created on first run (1h TTL)
[ -f data/runtime/active-recall-cache.tsv ] \
  && echo "OK: active-recall cache file created"

# 4. Dream orchestrator runs all 4 phases dry-run with no errors AND
#    respects the dry-run guarantee (no proposals applied to memory/)
bash scripts/dream.sh --full-cycle --dry-run >/dev/null 2>&1 \
  && echo "OK: dream.sh --full-cycle --dry-run completes cleanly"

# 5. Cognitive-overlay subdirs exist and are recursable by the canonical pattern
[ -d memory/episodic ] && [ -d memory/semantic ] && [ -d memory/procedural ] \
  && find memory/ -name "*.md" -not -path "*/.*" | head -1 | grep -q . \
  && echo "OK: cognitive-overlay subdirs present and iterable"

# 6. Profile bucket file exists with frontmatter (created by update-profile.sh)
ls memory/profile_*.md >/dev/null 2>&1 \
  && head -5 memory/profile_*.md | grep -q "^---$" \
  && echo "OK: profile bucket present with frontmatter"

echo "OK: E6 installed"
```

**Tests**
The E6 install ships with 10 regression tests under `tests/memory/`:
- `test_memory_search_recurses.sh`, `test_embed_recurses.sh`, `test_freshness_recurses.sh` - cognitive-overlay subdir recursion
- `test_episodic_roll.sh`, `test_daily_episodic_hook.sh` - daily episodic roll + Stop hook wiring
- `test_entity_extraction.sh`, `test_active_recall.sh`, `test_active_recall_cache.sh` - Mode A pipeline + 1 h TTL cache
- `test_dream_phase1.sh`, `test_dream_phase2.sh`, `test_dream_phase3.sh`, `test_dream_phase4.sh`, `test_dream_orchestrator.sh` - Mode B 4-phase + orchestrator
- `test_weekly_compile.sh`, `test_monthly_retrospective.sh` - compilation passes

Run all with `for t in tests/memory/test_*.sh; do bash "$t" || echo "FAIL: $t"; done`.

---


## Optional companion app: Obsidian

Obsidian is a free local markdown editor + knowledge-graph viewer. Your `memory/`, `Library/`, `agent-memory/`, and `docs/` directories are all interconnected markdown, which is the exact format Obsidian was built for. Pointing an Obsidian vault at the project root gives you a graph view, backlinks, full-text search, and (with the Smart Connections plugin) semantic search over the whole knowledge base, all without writing a single line of code.

Obsidian does NOT replace anything your orchestrator already does. It is a viewer for the same files {{orchestrator_name}} reads + writes. Two interfaces over one source of truth.

### Why install it

- **Graph view.** Visual representation of your knowledge base. Each file is a node, each markdown link is an edge. Color groups for the major directories (feedback / project / reference / Library / agent-memory / episodic). Reveals the structure of your system in one glance.
- **Backlinks per file.** Open any file, the right panel shows every other file that references it. Useful when refactoring memories or hunting connected concepts.
- **Full-text search with rich previews.** Faster than `grep -r` for human reading. sqlite-vec is for agent recall; Obsidian search is for your browsing.
- **Smart Connections plugin.** Local semantic search over the vault using Ollama. Different from sqlite-vec because it surfaces relations as you browse (right panel, real-time), not via command-line query. Two semantic-search systems on the same files: one for the orchestrator, one for you.
- **Mobile editing (optional).** Obsidian Mobile lets you edit memory files from your phone. Not recommended for read-write if your orchestrator is also writing the same files (sync conflicts). View-only on mobile is fine.

### What Obsidian does NOT need

- Obsidian Sync (paid £4/mo). Skip it. Your vault is already in git, pushed to your private repo. Git history covers most of what Sync's version-history feature gives you.
- Cloud accounts. Local-only is the cleanest privacy posture.
- Always-on. Obsidian is launched on demand, not a daemon. Closing it doesn't break your orchestrator.
- A separate MCP server. Your orchestrator already has direct file access to the vault; an Obsidian MCP would couple two interfaces that work better as independent layers over the same files.

### Installation (~5 min)

1. **Install:** `brew install --cask obsidian` on Mac, `winget install Obsidian.Obsidian` on Windows, or download from https://obsidian.md.
2. **Open vault:** launch Obsidian, click "Open folder as vault," navigate to your orchestrator project root (`~/Documents/{{orchestrator_name}}` or wherever you installed). Click Open. Trust the vault when prompted.
3. **Pre-baked config (already in this repo):** the wizard ships a `.obsidian/` directory with sensible defaults (excluded files for noisy dirs, graph color groups by directory, core plugins enabled). First launch picks these up automatically. No manual settings walk needed.
4. **Smart Connections (recommended):** Settings → Community plugins → Turn on → Browse → search "Smart Connections" → Install + Enable. On first run it'll ask which embedder. Pick **Ollama** + the `nomic-embed-text` model (matches what your orchestrator's E1 sqlite-vec uses, so the two semantic-search systems share an embedding space). If you don't have the model pulled yet: `ollama pull nomic-embed-text`. First-vault indexing takes 2-5 minutes.
5. **Try it:** Cmd+G opens graph view. Cmd+Shift+F opens full-text search. Cmd+O jumps to any file by name. Click any file and the right panel shows backlinks.

### Pre-baked vault config (`.obsidian/` directory)

Files committed in the repo:
- `app.json` - excluded files list (data/runtime, data/audit, telegram-history, youtube-summaries, dream-runs, node_modules, .next, plugin caches, archived agent channels). Markdown link format set to shortest. Frontmatter visible.
- `core-plugins.json` - graph view, backlinks, outgoing-links, page-preview, outline, tag-pane, properties, file-recovery on. Templates off.
- `community-plugins.json` - smart-connections enabled (still requires the Settings → Community plugins → Browse install on first launch; this flag just toggles activation post-install).
- `graph.json` - color groups per directory (feedback purple, project teal, reference orange, Library coral, agent-memory green, episodic grey).

Workspace state (`workspace.json`, plugin caches) is gitignored per-machine.

### Why graph view sometimes looks sparse

Most individual feedback / project memories are STANDALONE. They don't reference each other. The connections concentrate around hub files: `memory/MEMORY.md` (the index), `Library/<domain>/README.md` routers, `memory/profile_{{user_name_lower}}.md`. Filter the graph to one hub to see the proper hub-and-spoke. The orphan-looking nodes are real, they're just standalone rules.

To see more edges: graph view's settings panel → turn on "Show unresolved links" + "Show orphans." Faded edges appear for links Obsidian's path resolver can't fully match (your orchestrator writes standard markdown links, not Obsidian wikilinks; resolution depends on path-from-current-file).

---


## Reliability stack — supervisor + MCP observability (recommended, all modes)

If you rely on the Telegram channel for daily use, install this. Without it, an MCP disconnect leaves you silently waiting at your phone with no way to know the orchestrator can't reach you. The stack catches the disconnect within ~30 seconds, recovers automatically, and surfaces a `/mcp-health` slash command so you can see what happened after the fact.

Shipped 2026-05-13 after a real incident: the Telegram MCP plugin disconnected 3x in 3 hours during a heavy parallel-dispatch session. Each time the orchestrator was silent for ~20+ minutes before the user noticed — no logs, no auto-restart, no alert path. The MCP is the only channel from the orchestrator to your phone, so its liveness is mission-critical.

### What you get

Five layers, each independently useful and independently testable.

1. **stdio-safe logging wrapper** (`scripts/telegram-mcp-wrap.sh`) — opt-in wrapper around the bun child that captures stderr to a daily log under `data/logs/telegram-mcp/` without touching stdin/stdout. Diagnostic when Layer 2 alone is not enough. Currently NOT enabled by default — flip on when the watchdog flags an issue you want to root-cause.
2. **Health-probe watchdog** (`scripts/telegram-mcp-watchdog.sh`) — polls every 10s. Probes for `~/.claude/channels/telegram/bot.pid` + ps + lsof for the bun child. Writes one JSONL row per probe to `data/telegram-mcp-health.jsonl`. On Mac, runs via launchd (`~/Library/LaunchAgents/com.{{orchestrator_lower}}.telegram-mcp-watchdog.plist`); on Windows, via a Task Scheduler job. Streak counter tracks consecutive `down` probes.
3. **Tiered auto-recovery** (same watchdog script) — streak=2 (≈20s degraded) fires a detection alert via Layer 4 with no process action. Streak=3 (≈30s degraded) reaps stale bun rooted at the plugin path (`pkill -f 'bun.*claude-plugins-official/external_plugins/telegram'`), writes `data/runtime/telegram-mcp-reinit-needed.flag`, fires Layer 4 alert. Critical: never kills the parent `claude` process. That's the supervisor's job (next section). Streak-based alerting (`==ALERT_AT`, not `>=`) prevents spam during long outages. Alert tags rate-limited to 20/day per tag.
4. **Direct-curl alert path** (`scripts/notify-telegram-direct.sh`) — POSTs directly to `api.telegram.org/bot<TOKEN>/sendMessage` using the bot token from `~/.claude/channels/telegram/.env`. Bypasses the dead MCP entirely. This is the only escalation that survives an MCP outage.
5. **`/mcp-health` slash command** (`scripts/mcp-health-report.sh`) — reports uptime %, disconnect count, longest gap, probe RTT p50/p95/p99 over a configurable window (default 24h; `--window 6h` / `--window 1h`; `--json` for raw).

### Install (Mac)

```bash
# 1. Drop in the scripts (templates in xantham-templates-v31.md):
#    scripts/telegram-mcp-wrap.sh
#    scripts/telegram-mcp-watchdog.sh
#    scripts/notify-telegram-direct.sh
#    scripts/mcp-health-report.sh
chmod +x scripts/telegram-mcp-wrap.sh scripts/telegram-mcp-watchdog.sh \
         scripts/notify-telegram-direct.sh scripts/mcp-health-report.sh

# 2. Make sure your Telegram bot token is at ~/.claude/channels/telegram/.env
#    The plugin writes this on first connect. If missing, set it manually:
#    echo 'TELEGRAM_BOT_TOKEN=<your-bot-token>' > ~/.claude/channels/telegram/.env
#    echo 'TELEGRAM_CHAT_ID=<your-chat-id>' >> ~/.claude/channels/telegram/.env
chmod 600 ~/.claude/channels/telegram/.env

# 3. Install the watchdog as a launchd job via an AppleScript .app wrapper.
#    Macos TCC blocks plain bash launchd jobs that touch ~/Documents/,
#    so we wrap in an .app and grant Full Disk Access to that bundle.
#    The wizard's scripts/install-launchd-wrappers.sh handles this end to end.
bash scripts/install-launchd-wrappers.sh

# 4. Grant Full Disk Access to the .app bundles in System Settings ->
#    Privacy & Security -> Full Disk Access. Add each .app in ~/Applications/
#    that starts with com.{{orchestrator_lower}}.

# 5. Verify the watchdog is firing
tail -f data/telegram-mcp-health.jsonl
# You should see a new JSON row every ~10 seconds.

# 6. Register /mcp-health as a slash command (CLAUDE.md commands table)
#    Already wired in the v31 template; if you're upgrading, see the
#    Commands section in xantham-templates-v31.md.
```

### Install (Windows, Git Bash or WSL2)

```bash
# Identical script drop-in. The launchd path is Mac-only; on Windows, register
# the watchdog as a Task Scheduler job that runs at logon and stays alive.

# 1. Same chmod + script drop-in steps as Mac.

# 2. Register the watchdog as a recurring Task Scheduler task:
#    Open Task Scheduler (taskschd.msc), Create Task (not Basic Task).
#    General: name "{{orchestrator_lower}}-mcp-watchdog", "Run whether user is logged on
#    or not" off, "Run with highest privileges" off (no admin needed).
#    Triggers: At log on (of your user).
#    Actions: Start a program
#      Program: C:\Program Files\Git\bin\bash.exe
#      Arguments: -c "while true; do bash 'C:/Users/<you>/Documents/MyAgent/scripts/telegram-mcp-watchdog.sh'; sleep 10; done"
#    Settings: Allow task to be run on demand. If task fails, restart every 1 min,
#    up to 999 times. Stop task if it runs longer than 30 days (default is fine).

# 3. Verify the watchdog is firing
tail -f data/telegram-mcp-health.jsonl
```

### Uninstall

```bash
# Mac
launchctl unload ~/Library/LaunchAgents/com.{{orchestrator_lower}}.telegram-mcp-watchdog.plist
rm ~/Library/LaunchAgents/com.{{orchestrator_lower}}.telegram-mcp-watchdog.plist
rm -rf ~/Applications/com.{{orchestrator_lower}}.telegram-mcp-watchdog.app

# Windows
schtasks /Delete /TN "{{orchestrator_lower}}-mcp-watchdog" /F

# All platforms - remove the scripts if you don't want them around
rm scripts/telegram-mcp-{wrap,watchdog}.sh scripts/notify-telegram-direct.sh scripts/mcp-health-report.sh
```

### Verify

```bash
# 1. Watchdog is firing (look for fresh rows under 30s old)
tail -1 data/telegram-mcp-health.jsonl | jq .timestamp

# 2. /mcp-health report works end-to-end
bash scripts/mcp-health-report.sh --window 1h

# 3. Direct-curl alert path works (this WILL send a real Telegram message)
bash scripts/notify-telegram-direct.sh test-alert "Reliability stack verify - $(date)"
```

---

## Supervisor wrapper — zero-touch session recovery (recommended, all modes)

Pairs with the MCP observability stack above. Without the supervisor, the auto-restart daemon below would kill the orchestrator's `claude` process on persistent MCP failure but leave you at a dead terminal with no way to re-enter the conversation. The supervisor wraps `claude` in a re-exec loop so any exit is followed by `claude --resume` on the same session.

### What you get

- **`bin/{{orchestrator_lower}}-launch.sh`** — supervisor wrapper that holds the TTY anchor while `claude` runs as a child. On non-clean exit (Tier-3 kill, crash, OOM), the wrapper immediately re-execs `claude --resume`. On clean exit (code 0, e.g. user typed `/exit`), the loop ends and the supervisor exits.
- **Crash-loop protection.** 3 fast-failures in 60 seconds pauses the loop for 60s; 5 fast-failures total exits the supervisor with code 7. Prevents a tight crash loop from burning CPU.
- **Emergency disable.** `touch ~/.{{orchestrator_lower}}-no-supervisor` — the loop checks for this marker each iteration and exits cleanly. Remove the file to re-enable.
- **First-launch vs re-exec distinction.** First launch passes through the user's original args (so `{{orchestrator_lower}}` starts fresh and `{{orchestrator_lower}} --resume` does what it says). Subsequent re-execs after a non-clean exit force `--resume` so the new claude lands back in the killed session. Without this distinction, every fresh launch would silently resume the wrong session.

### Install (Mac and Linux)

```bash
# 1. Drop in the supervisor wrapper (template in xantham-templates-v31.md)
#    bin/{{orchestrator_lower}}-launch.sh
mkdir -p bin
chmod +x bin/{{orchestrator_lower}}-launch.sh

# 2. Route your shell alias through the supervisor.
#    Add to ~/.zshrc (or ~/.bashrc):
#      <orchestrator>() {
#        bash $HOME/Documents/MyAgent/bin/{{orchestrator_lower}}-launch.sh "$@"
#      }
#      <orchestrator>-resume() {
#        bash $HOME/Documents/MyAgent/bin/{{orchestrator_lower}}-launch.sh --resume "$@"
#      }
#    Reload: source ~/.zshrc

# 3. Verify the wrapper runs and starts claude
<orchestrator>
# You should see "[<orchestrator>-launch] supervisor starting (pid=...)" and then claude's
# usual prompt. Type /exit; the wrapper logs "exit code 0, loop ending".
```

### Install (Windows, Git Bash)

```bash
# The supervisor is pure bash so it runs identically under Git Bash. The shell
# function definition goes in ~/.bashrc (Git Bash uses bash, not PowerShell):
<orchestrator>() {
  bash "$HOME/Documents/MyAgent/bin/{{orchestrator_lower}}-launch.sh" "$@"
}

# If you want a PowerShell entry point too, drop a .ps1 wrapper at the same
# location that just shells out:
#   bash "$HOME\Documents\MyAgent\bin\<orchestrator>-launch.sh" $args
# Save as <orchestrator>.ps1 in a directory on your $PATH.
```

### Tier-3 auto-restart self-heal (optional, requires supervisor)

If you want zero-touch recovery from a persistent MCP failure (not just session-end), install the auto-restart daemon. When the watchdog writes `data/runtime/telegram-mcp-reinit-needed.flag` AND the orchestrator has been silent for ≥120s (idle gate, prevents kill-mid-task), the daemon SIGTERMs `claude`. The supervisor catches the non-zero exit and re-execs with `--resume`. State capture / restore makes the new session aware of pending Telegram replies.

```bash
# Mac install
chmod +x scripts/<orchestrator>-auto-restart.sh scripts/<orchestrator>-session-checkpoint.sh
# Wire the checkpoint into the Stop hook
echo 'bash scripts/<orchestrator>-session-checkpoint.sh || true' >> scripts/session-end-sync.sh
# Wire the daemon into launchd via the wrapper installer
bash scripts/install-launchd-wrappers.sh  # picks up the new plist

# Wire the SessionStart checkpoint-restore (extends your existing session-start hook)
# In scripts/session-start-persistence-inject.sh, add the block that reads
# data/runtime/<orchestrator>-checkpoint.json if mtime < 10 min and surfaces it as the
# FIRST section of the persistent-state inject. Template in xantham-templates-v31.md.
```

### Tier-1 MCP hardening (recommended, baked into the supervisor)

Two changes inside `bin/{{orchestrator_lower}}-launch.sh` target the two highest-volume Telegram MCP failure modes:

1. **`export MCP_TIMEOUT=3600000`** — Claude Code's MCP client SIGTERMs healthy stdio MCP servers on a wall-clock keepalive timer (claude-code issue #40207, open since 28 Mar 2026, no upstream fix). Default is ~60s. Stretching to 3.6M ms (1h) means the kill happens at most once per hour rather than every minute. Keeps the bun MCP child alive long enough that the watchdog does not see a `no_pid_file` cascade on every keepalive boundary.
2. **Pre-launch `pkill -f 'bun.*claude-plugins-official/external_plugins/telegram'`** — if a prior crash leaves a bun child rooted at the official Telegram plugin path, the new plugin instance fights it for the Telegram Bot API long-poll (HTTP 409 "Conflict: terminated by other getUpdates request") which crashes both. Killing any stale bun before the new claude launches guarantees a clean handoff. 500ms grace via `/bin/sleep 0.5` so the kernel reaps the dead child before claude tries to bind the same long-poll.

Both fixes are reversible: unset `MCP_TIMEOUT` to revert (1); comment the pkill line to revert (2). Both are baked into the v31 supervisor template, no extra install step.

### Uninstall (all platforms)

```bash
# Remove the shell function from ~/.zshrc / ~/.bashrc and reload.
rm bin/{{orchestrator_lower}}-launch.sh
launchctl unload ~/Library/LaunchAgents/com.{{orchestrator_lower}}.auto-restart.plist 2>/dev/null
rm ~/Library/LaunchAgents/com.{{orchestrator_lower}}.auto-restart.plist 2>/dev/null
rm scripts/<orchestrator>-auto-restart.sh scripts/<orchestrator>-session-checkpoint.sh 2>/dev/null
```

### Verify

```bash
# 1. Wrapper runs
which <orchestrator>
# Expect a shell function pointing at bin/{{orchestrator_lower}}-launch.sh

# 2. MCP_TIMEOUT is exported during a launch (use a fresh subshell)
bash -c 'env | grep MCP_TIMEOUT'

# 3. Crash-loop protection triggers (this WILL pause for 60s after 3 fast crashes)
#    Skip this in real installs unless you really want to test it.
#    See xantham-templates-v31.md for the manual procedure.

# 4. SessionStart checkpoint-restore block appears in the inject (if installed)
bash scripts/session-start-persistence-inject.sh | head -20
```

---


## Changelog

### v31 - memory and meta-cognition cut

- Profile bucket promoted to a first-class section (single `memory/profile_<user>.md`, mutable narrative, per-session updates via `scripts/update-profile.sh`). Karpathy three-bucket pattern explicit: Memory + Knowledge + Profile.
- E6 Amazing Memory expanded with Mac AND Windows install for `scripts/active-recall.sh`, `scripts/dream.sh --full-cycle`, `scripts/roll-episodic.sh`, `scripts/weekly-memory-compile.sh`, `scripts/monthly-memory-retrospective.sh`, `scripts/update-profile.sh`. Subdir-recursion + dot-prune documented as a hard requirement on every iterator.
- Episodic structure aligned to flat `memory/episodic/<YYYY-MM-DD>.md` everywhere (matches on-disk reality).
- New skill: `<orchestrator>-reflection`. Six-stage chain-pattern-interrupt fires before fuzzy briefs and first-time multi-agent fan-out. Pre-hoc plan-critique, not post-hoc verification.
- Council pattern documented as orchestrator-invoked for high-stakes ambiguous decisions. Three-agent anonymised peer-ranked debate. Internal only, never exposed as a slash command.
- Forked-subagents habit added to the orchestration skill: when forking many subagents, define inputs and acceptance criteria upfront, never blank-dispatch.
- MCP layer expanded. Reddit MCP Buddy (subreddit browsing + search), Pipedream (hub MCP wrapping ~2,500 third-party APIs through one OAuth), and Consensus (200M+ peer-reviewed papers, anonymous tier works without signup) added with Mac + Windows install commands. Karpathy guidelines plugin available as an optional Mode-Advanced add-on, not default.
- Auth failover added. `scripts/auth-fallback.sh` flips Claude Code between Max OAuth and a separately-billed API key. 4th SLO canary pings `/v1/messages` every 5 min, writes `data/runtime/auth-degraded.flag` after 3 consecutive failures. Mac path uses launchd, Windows path uses Task Scheduler.
- Operating principles section added near the top: built-to-scale rule (back-compat-first, designed for 100x current load from day one), reply-first rule, verify-before-claiming-done rule, plan-before-code rule.
- Troubleshooting block added: macOS 15 TCC blocks launchd-spawned bash from executing scripts under `~/Documents/`. AppleScript .app wrapper recipe + new-mac re-enable steps included.
- `telegram-signal.sh` reframed. It survives v31 as a generic Telegram alert utility used by the auth canary alert path. Cross-referenced from the auth-failover section.
- Removed in v31: `scripts/proactive-trigger-daemon.sh`, `scripts/proactive-daemon.sh`, `scripts/signal-schedule.sh`, `scripts/signal-fire-from-schedule.sh`, AppleScript `signal-fire-wrapper.applescript`, all proactive-trigger and signal-fire references as live systems. The systems were deleted in early May 2026 and never come back without an explicit decision to revive them.
- sqlite-vec chunk count reference updated. Mature installs run 1000-1500 chunks across `memory/`, `agent-memory/`, and `docs/`.

### v30 - production-ready public release
- Self-installing wizard with Q0 preflight (Node 18, Git, jq, sqlite3, bun) as a hard gate
- Mode picker (Simple vs Advanced) with full pre-decision content
- Dual-OS coverage on every install / setup / runtime command (Mac + Windows / Git Bash / WSL2)
- Bot creation walkthrough with @BotFather expanded to 8 explicit steps
- 8 skill template bodies (sync, maintenance, orchestration, brain, safety, observability, blueprint-updates, optional youtube-queue)
- 30+ scripts and hooks templated with placeholders
- 40+ starter feedback memory seeds shipping a behavioural baseline from day-zero
- 9 CLAUDE.md command handlers with explicit empty-state branches (no silent crashes)
- SETUP-CHECKLIST: 12 numbered Steps + 5 Advanced sub-steps walking from "wizard done" to "first memory committed and verified"
- USER-GUIDE with B1-B4 troubleshooting blocks
- Status emoji convention (🔹 done / 🔸 running / 🔸🔴 blocked) baked into the orchestrator's voice
- Customisation-preserving upgrade walkthrough (3-way merge: pristine + customised + user-added)
- DIAGNOSTIC-CHECKLIST.md fallback when any generation step fails
- E2 Graphiti dropped (single-user knowledge graphs underutilised; flat markdown + sqlite-vec semantic search is the better path)
- E6 Amazing Memory added (active recall pre-turn + 4-phase dream consolidation + cognitive overlay episodic/semantic/procedural; closes the bug class where long-lived projects exist but nothing semantically points at them)
- Day-1 user experience docs included in the wizard output: SETUP-CHECKLIST, USER-GUIDE, BACKUP-AND-RECOVERY, FIRST-WEEK, PITFALLS, MEMORY-HYGIENE

### v29 - five extensions split out
- Core stays minimal (orchestrator + agents + Telegram + NotebookLM Brain + safety gate)
- Extensions opt-in: E1 sqlite-vec semantic memory, E3 Agent Teams shared whiteboard, E4 Observability audit layer, E5 Hardened safety gate
- Per-extension install + uninstall scripts, version-stamp file `.{{orchestrator_lower}}-blueprint-version`

### v31.3 - reliability stack + Codex advisor + settings.json adoptions from 2026-05-12 / 2026-05-13 / 2026-05-14 upgrade slate

- **Reliability stack (recommended, all modes) — Telegram MCP observability + supervisor.** Five-layer observability (`scripts/telegram-mcp-wrap.sh` stdio-safe logging wrapper, `scripts/telegram-mcp-watchdog.sh` 10s health-probe via launchd or Task Scheduler, tiered streak-based auto-recovery, `scripts/notify-telegram-direct.sh` direct-curl alert path bypassing dead MCP with 20/day cap per tag, `scripts/mcp-health-report.sh` + `/mcp-health` slash command). Streak=2 fires detection alert, streak=3 reaps stale bun + writes reinit flag. Never kills the parent `claude` process. Born from a real incident where the MCP disconnected 3x in 3 hours with no logs and no alert path; user silently waited 20+ minutes each time. New main-blueprint section "Reliability stack" above the Changelog covers the full install + uninstall + verify for Mac and Windows.
- **Supervisor wrapper (recommended, all modes).** `bin/{{orchestrator_lower}}-launch.sh` wraps `claude` in a re-exec loop so any non-clean exit triggers `claude --resume` on the same session. Without this anchor, the auto-restart daemon below would kill claude on persistent MCP failure but leave the user at a dead terminal. First launch passes through user args (so a fresh start stays fresh); subsequent re-execs force `--resume`. Crash-loop protection: 3 fast-failures in 60s pauses for 60s, 5 fast-failures total exits with code 7. Emergency disable via `touch ~/.{{orchestrator_lower}}-no-supervisor`.
- **Tier-3 auto-restart self-heal (optional, requires supervisor).** Daemon at `~/Library/LaunchAgents/com.{{orchestrator_lower}}.auto-restart.plist` polls every 30s. When watchdog writes `data/runtime/telegram-mcp-reinit-needed.flag` AND orchestrator is idle ≥120s (idle gate, prevents kill-mid-task), SIGTERMs `claude`. Supervisor catches the non-zero exit and re-execs `--resume`. `scripts/{{orchestrator_lower}}-session-checkpoint.sh` captures state every Stop hook to `data/runtime/{{orchestrator_lower}}-checkpoint.json`; `scripts/session-start-persistence-inject.sh` reads it and surfaces a "self-heal checkpoint" block as the FIRST section of the persistent-state inject when <10 min old. New session knows about pending replies, last project, recent commits.
- **Tier-1 Telegram MCP hardening (baked into the supervisor template).** Two changes in `bin/{{orchestrator_lower}}-launch.sh`:
  1. `export MCP_TIMEOUT=3600000` — neutralises claude-code issue #40207 keepalive SIGTERM (default ~60s default; stretched to 1h means once-per-hour at worst).
  2. Pre-launch `pkill -f 'bun.*claude-plugins-official/external_plugins/telegram'` — prevents HTTP 409 Conflict on Telegram Bot API long-poll when a stale bun from a prior crash fights the new plugin. 500ms grace for kernel reap.
- **Codex read-only advisor + ensemble + reviewer pattern (optional, requires OpenAI API key).** `scripts/codex.sh` 7-subcommand wrapper (generate / debug / refactor / test / audit / architect + diff-review variants) — read-only orchestrator-restrained interface to OpenAI's Codex CLI, output goes to stdout or a markdown sidecar, never touches files directly. `scripts/ensemble.sh` fans the same redacted prompt past your orchestrator + Codex with a synthesis report (agreements / disagreements / verdict). Both `{{orchestrator_lower}}-codex-ensemble` and `{{orchestrator_lower}}-codex-reviewer` skills ship as **judgment-based + explicit-trigger only** — they do NOT auto-fire on every ship/deploy/migrate or on every specialist-agent build. The orchestrator decides per-diff whether codex earns its cost + iteration overhead; the user retains explicit overrides via `ensemble <task>` / `codex review` / `review <project>`. Daily cap 20 runs + soft $5/day spend cap. Opt-out via env vars `CORTANA_ENSEMBLE_DISABLED=1` / `CORTANA_CODEX_REVIEW_DISABLED=1` (rename namespace for your fork). Daily release scans via launchd: `com.{{orchestrator_lower}}.anthropic-scan.plist` + `com.{{orchestrator_lower}}.codex-scan.plist`.
- **Codex reviewer skill (optional, sibling to ensemble).** `{{orchestrator_lower}}-codex-reviewer` skill at `.claude/skills/{{orchestrator_lower}}-codex-reviewer/SKILL.md`. Judgment-based + explicit-trigger only (no auto-fire on every build). Invoke when the diff is high-stakes (regulated, security-sensitive, unfamiliar codebase, suspected blind spot) OR on explicit user trigger. Runs `scripts/codex.sh review-uncommitted <project_dir>` on the staged + unstaged diff, surfaces P0 (blocks ship), P1 (fix-before-submit), P2 (polish), and the orchestrator iterates inline up to 3 rounds until clean. Pairs with `{{orchestrator_lower}}-codex-ensemble`: reviewer is per-commit + diff-scoped, ensemble is per-release + decision-scoped. Shares the 20-call/day cap with ensemble.
- **Safety-gate hardening.** Three commits:
  1. Expanded destructive-op coverage: Prisma reset, Postgres CLI delete, MongoDB destructive ops, Supabase/Neon/Wrangler/Vercel/AWS/GCP/Terraform/Kubernetes/Docker prune, Redis FLUSHDB/FLUSHALL. Skip-checks for `git commit` + `echo` so commit messages naming destructive ops in post-mortems don't trigger false-positive blocks.
  2. Codex+ensemble bypass-flag hard-blocks: `--no-redact / --skip-redact / --unsafe / --dangerous / --bypass` blocked at both the wrapper arg-parse layer AND the Bash-tool gate layer (defense in depth).
  3. Modern OpenAI key redaction: `scripts/redact-secrets.sh` adds `sk-proj-` (project-scoped) + `sk-svcacct-` (service-account) patterns, redacted to `REDACTED_OPENAI_PROJECT` / `REDACTED_OPENAI_SERVICE`. The legacy `sk-[A-Za-z0-9]{20,}` pattern didn't match the hyphenated modern shapes.
  4. Per-invocation env-scrub on ensemble CLI calls to prevent cred leak when the wrapper subshells out.
- **Claude Code v2.1.139 + v2.1.140 settings adoptions.**
  - `skillOverrides` — explicit allowlist of skills to disable / restrict to name-only. Reduces context bloat on every session. Common installs flip 50+ default skills off and 5-10 to name-only.
  - Hook `continueOnBlock` — lets a hook block a tool call AND let Claude Code keep going with a corrected prompt. Used by the banned-language gate to auto-log + retry.
  - Hook `args` — pass static args into hook invocations from settings.json (cleaner than env-var smuggling).
  - `CLAUDE_PROJECT_DIR` — Claude Code now exports this so hooks have a stable repo-root reference regardless of cwd.
- **AI cost dashboard truth rule.** Estimator outputs from preview endpoints + cost-calc helpers are UPPER-BOUND, not actual. Trust the provider dashboard (Anthropic / OpenAI / Gemini) for real spend. Don't quote estimator numbers without flagging them as upper-bound.
- **AI-spend-guard five-layer pattern.** Floor for any new AI callsite that calls an LLM API directly (not via your orchestrator). Layers: hard daily cap, per-IP rate limit, per-feature soft budget with telemetry at 80%, pre-call estimator gate, audit log JSONL with estimated + actual cost.
- **Slash-command MCP-restart rule.** Slash commands that touch the plugin/MCP layer (`/mcp`, `/commands`, `/plugin marketplace add`, `/plugin install`) RESTART the Telegram MCP mid-session and drop in-flight inbound on the floor. Do NOT use these slash commands when the Telegram MCP is active. Workaround: use `claude plugin` from Bash instead — it doesn't traverse the restart path.

### v31.2 - infra hardening + perma-rules from 2026-05-09 / 2026-05-10 upgrade slate
- **Banned-language gate hook** (`.claude/hooks/banned-language-gate.sh` + perl helper). PreToolUse blocks medical-claim words / marketing superlatives / AI-tells from leaking into orchestrator replies AND files written under `Library/`, `docs/`, app strings. Reads from `Library/app-store-compliance/banned-language-list.md` + allowlist. ~45ms per fire (60s cache). Configurable via `BANNED_LANG_GATE_PATHS` / `BANNED_LANG_GATE_DEBUG=1` / emergency bypass `BANNED_LANG_GATE_OFF=1`.
- **Per-agent MCP scoping** (`scripts/sync_agent_skills.py`). Lifted from `anthropics/claude-financial-services`. Each `.claude/agents/<name>.md` declares `mcps:` in YAML frontmatter; script generates per-agent `.mcp.json`, validates against live `claude mcp list`, reports drift. Estimated 6-8k tokens saved per dispatch when Claude Code wires per-agent loading.
- **Architectural-role tagging** (`scripts/tag-architectural-role.sh` + `scripts/check-trunk-edits.sh`). Convention: every long-lived markdown carries `architectural_role:` of `trunk` / `branch` / `leaf`. Trunk-edit watcher flags commits touching trunk files in healthcheck. Convention doc: `Library/agentic-engineering/architectural-role-tagging.md`.
- **Agent-readiness audit script** (`scripts/agent-readiness-audit.sh`). Factory.ai-style 8-pillar pattern adapted for orchestrator-system scope: memory hygiene, skill coverage, tool budget, agent crew utilisation, hook reliability, blueprint drift, correction patterns, external dependencies. Quarterly trigger (first Monday of Jan/Apr/Jul/Oct) lives in `<orchestrator>-maintenance` skill. Read-only.
- **Reverse-prompt Monday self-improvement** (`scripts/reverse-prompt-weekly.sh` + approve/reject siblings). Every Monday session-start, orchestrator looks at her own last 7 days (telegram + git + YouTube summaries + corrections + memory writes) and self-suggests 3 workflow improvements. Hard-gated to Monday. Cost-bounded. Approval rate tracked in `data/runtime/reverse-prompt-stats.jsonl`.
- **Per-person profile files** (`memory/profile/<name>.md`). Auto-discovered from basenames via `scripts/active-recall-entities.sh`. Populator: `scripts/profile-person-update.sh` (single-fact / scan-tail / list modes). PII guardrail rejects facts containing phone / email / postcode patterns.
- **HTML greeting digest pilot** (`scripts/render-html-digest.sh` + `.py`). Opt-in via `GREETING_DIGEST_FORMAT=html`. Reads same data sources as markdown greeting, emits self-contained dark-theme HTML with embedded CSS, no JS, no external deps. Markdown stays default; pilot validates the human-engagement thesis.
- **AI-SEO on ship** (`scripts/ai-seo-on-ship.sh` + `<orchestrator>-ai-seo` skill). Auto-fires on every `ship <project>` / `deploy <project>` for projects with public web surface. Generates robots.txt (LLM-bot allowlist for GPTBot/ClaudeBot/PerplexityBot/Google-Extended/Applebot-Extended), sitemap.xml, llm.txt (llmstxt.org standard), `.well-known/schema.json` (JSON-LD), pricing.md. Idempotent.
- **Orphan MCP reaper** (`scripts/reap-orphan-mcp.sh`). Detects bun/node/python MCP server processes reparented to PID 1 (cwd inside `~/.claude/plugins/`, uptime > 10 min) and kills them. Catches the failure mode where MCP connection breaks + Claude Code spawns a fresh subprocess without the orphan dying. Wired into session-end-sync in DRY-RUN mode (logs to `data/runtime/orphan-mcp-kills.log`). Healthcheck section 12 surfaces orphan count.
- **SessionEnd subprocess guard** (`scripts/session-end-sync.sh` + `.claude/hooks/session-start-hook.sh`). Closes a Claude Code lifecycle hazard: every child `claude` invocation (`claude -p` headless, `claude plugin install`, SDK subagent dispatch, any tooling that shells out to `claude` from inside the repo) fires the SessionEnd hook on its own exit, not just the real interactive session end. Without the guard, the session-end-sync hook (HANDOFF rebuild + reflection write + per-person profile scan + orphan-MCP reap) runs on EVERY child exit, sometimes 10+ times per real session. The heavy I/O can destabilise the parent session's MCP sockets (Telegram / Gmail / Supabase / etc), producing visible `SessionEnd hook [...] failed: Hook cancelled` surfaces and 1-3 min MCP disconnects per child exit.

  **Detection** (two layers, cheapest first, both inside `scripts/session-end-sync.sh`):

  1. **Layer 1, payload-vs-marker.** SessionEnd stdin payload includes the firing session's UUID (`session_id` field). A marker file at `data/runtime/active-session.json` holds the parent session's UUID. Mismatch = child, skip. Match = real session-end, run full hook.
  2. **Layer 2, `CLAUDE_CODE_ENTRYPOINT` fallback.** Used when Layer 1 is indeterminate (marker absent, marker corrupted, payload missing). `CLAUDE_CODE_ENTRYPOINT=cli` = interactive parent. Anything else (`sdk-cli`, etc) = child.

  **Marker-write guard.** The SessionStart hook only writes the marker when BOTH `source=startup` AND `CLAUDE_CODE_ENTRYPOINT=cli`. Without the entrypoint gate, a child invocation's SessionStart would overwrite the parent's marker with its own UUID and its subsequent SessionEnd would then match, so the guard misfires and the full hook runs on the child anyway.

  **Audit.** Skipped fires write a JSONL entry to `data/audit/<YYYY-MM-DD>.jsonl` (same daily file as the PostToolUse audit) with `tool: "SessionEnd"`, `output: "skipped (subprocess child)"`, and a `session_end` object containing the mismatched IDs + entrypoint + skip reason. Override for manual operator invocation: `SESSION_END_FORCE=1 bash scripts/session-end-sync.sh`.

  **Platform notes.** Hazard is platform-neutral. The same child-claude-fires-SessionEnd race hits Mac, Linux, and Windows (WSL or native PowerShell shelling out to `claude.exe`) identically. The guard logic is pure bash + jq with no platform-specific syscalls. On Mac and Linux the script runs as-is. On Windows, run it under WSL or Git-Bash; the underlying detection (env vars + a JSON marker file under `data/runtime/`) works in any POSIX shell. The hazard exists wherever a session-end hook is wired to run heavy work, so if your orchestrator's SessionEnd hook touches shared sockets, the same guard pattern applies.
- **Karpathy AutoResearch wrapper** (`scripts/auto-research.sh`). Wraps Karpathy's published `karpathy/autoresearch` repo by reference at `~/.local/autoresearch`. Adapts Karpathy's ML-experiment loop for skill optimisation per the 3-level criteria framework (hard rules / LLM-judge / pure-creativity-out-of-scope). Hard caps: 15 iterations + $5 budget per run. Dry-run default. Handbook: `Library/agentic-engineering/auto-improvement-loops.md`.
- **YouTube claim verification gate** (`scripts/verify-yt-claims.sh`). Runs after every YouTube summary write + before Library promotion. Extracts named entities, writes `<video_id>.verified.md` sidecar, orchestrator fills status (verified / unverified / partial / skipped) via WebSearch + Consensus MCP. Library promotion BLOCKED for unverified entities. Closes the failure mode where YouTube summaries were taken at face value + propagated as upgrade candidates without verification.
- **Spec-kit bridge skill** (`<orchestrator>-spec-kit-bridge` at `.claude/skills/<orchestrator>-spec-kit-bridge/SKILL.md`). Integrates github/spec-kit (95k stars, MIT, official GitHub spec-driven-development toolkit) into the orchestrator's plan-first chain. Pinned at v0.8.8.dev0 via `uv tool install specify-cli==0.8.8.dev0 --from git+https://github.com/github/spec-kit.git@v0.8.8`. Fires BEFORE engineering agent dispatch on greenfield builds with budget >4h. Walks 6 phases: init -> constitution (3-5 non-negotiable principles) -> spec (priority-ordered MVP user stories + numbered FRs + measurable SCs) -> clarify (max 3 NEEDS-CLARIFICATION markers) -> plan (technical context + constitution check) -> tasks (atomic dependency-ordered T-XYZ-NN) -> analyze (cross-artifact consistency gate). Skip for bug fixes, ops work, refactors, brownfield, <4h tasks. Orchestration habit `plan-first` escalates to spec-kit on greenfield + >4h. Pilot evidence: spec-kit's `/speckit-analyze` cross-artifact gate caught 5 issues a council-derived brief had missed (budget mismatch ~25 percent over, hard-blocker naming gap masquerading as a soft note, success-criterion verifiability under privacy constitution, gap with no acceptance scenario, citation hand-waving). Two of those (budget + naming) are blockers that would have hit mid-build.
- **Three perma-rules in CLAUDE.md core loop:**
  - Rule 9 published-repo-first: WebSearch GitHub + npm + PyPI before framing ANY upgrade as "build custom X". Default to install/wrap or fork/adapt over build-from-scratch. Only build custom when no published fit OR fit-gap is documented.
  - Rule 10 verify YouTube claims: every video summary triggers `verify-yt-claims.sh` before Library promotion. Library promotion + upgrade-candidate dispatch BLOCKED for unverified entities.
  - Rule 11 spec-kit on greenfield + >4h: plan-first escalates to the full spec-kit pipeline (constitution -> spec -> plan -> tasks -> analyze) before engineering agent dispatch.

### v31.1 - platform-tactical social specialist added
- Roster expanded to 9 specialists by splitting Natalie's growth role: Natalie keeps strategy + ASO + paid + brand, new Maya specialist takes platform-tactical execution (TikTok / IG / X / YouTube / Reddit content + algorithm + viral hooks + creator-economy + community management). Total team is 9 specialists + 1 orchestrator = 10 agents.

### v28 - additional specialist agents
- Roster expanded to 8 specialists (engineering, research, growth, deploy, writing, trading, business, human dynamics) plus orchestrator = 9 agents total. The social split came later in v31.1.

### v27 - first stable
- Master orchestrator + memory layer + Telegram + NotebookLM Brain
- Markdown-first memory pattern (memory/ as source of truth, sqlite-vec optional)

### Earlier versions
Not documented. Core loop + safety gate + routing table existed from v1.

---

## Upgrade guide

### Fresh install → v31
1. Hand this file to a Claude Code session. Tell it: "install v31 in Simple mode" OR "install v31 in Advanced mode, all extensions."
2. The session reads the Core section and walks you through it.
3. If Advanced, it offers each remaining extension (E1, E3, E4, E5, E6) in sequence with the install steps above.
4. After core + extensions, the session offers the Reliability stack (recommended for any install with active Telegram use) and the Codex advisor (optional, requires OpenAI API key).
5. When done, it writes `.{{orchestrator_lower}}-blueprint-version` with the installed version + which extensions are on + which reliability components are on.

### v30 → v31
1. Tell Claude Code: "I'm on v30, upgrade me to v31."
2. It reads `.{{orchestrator_lower}}-blueprint-version`. Then it walks these upgrade steps:
   - **Profile bucket.** Create `memory/profile_<user>.md` with the v31 frontmatter scaffold if missing. Drop in `scripts/update-profile.sh`. Wire into `scripts/session-end-sync.sh`.
   - **Reflection skill.** Drop `.claude/skills/<orchestrator>-reflection/SKILL.md` from the template. No data migration.
   - **MCP additions.** Offer Reddit MCP Buddy, Pipedream, Consensus install. Skip if you already installed these manually. Karpathy plugin offered as Mode-Advanced opt-in.
   - **Auth failover.** Optional. Run only if you want OAuth fallback. Provision API key, add the canary script, schedule via launchd (Mac) or Task Scheduler (Windows).
   - **v31.2 hardening (auto-applied).** Banned-language gate, per-agent MCP scoping, architectural-role tagging, agent-readiness audit script, reverse-prompt Monday self-improvement, per-person profile files, HTML greeting digest pilot, AI-SEO skill on ship, orphan MCP reaper, SessionEnd subprocess guard, AutoResearch wrapper, YouTube claim verification gate, spec-kit bridge skill.
   - **v31.3 reliability stack (recommended).** Drop in `scripts/telegram-mcp-{wrap,watchdog}.sh`, `scripts/notify-telegram-direct.sh`, `scripts/mcp-health-report.sh`, `bin/{{orchestrator_lower}}-launch.sh` (supervisor wrapper with MCP_TIMEOUT + pre-launch pkill), `scripts/{{orchestrator_lower}}-auto-restart.sh`, `scripts/{{orchestrator_lower}}-session-checkpoint.sh`. Install launchd plists via `scripts/install-launchd-wrappers.sh` (or Task Scheduler equivalents on Windows). Grant Full Disk Access to the new `.app` wrappers on Mac. Wire the shell function in `~/.zshrc` / `~/.bashrc`. Add `/mcp-health` to CLAUDE.md commands.
   - **v31.3 Codex advisor (optional).** Drop in `scripts/codex.sh` + `scripts/ensemble.sh`, install the OpenAI Codex CLI (`pip install codex-cli` or per upstream docs), provision an OpenAI API key, set `OPENAI_API_KEY` in `~/.zshrc`. Install the `{{orchestrator_lower}}-codex-ensemble` skill. Install daily release-scan launchd plists if you want the morning scans. Opt-out via `CORTANA_ENSEMBLE_DISABLED=1` (or your own orchestrator-prefixed env var).
   - **v31.3 Claude Code v2.1.139+ settings.** Add `skillOverrides` block to `.claude/settings.json` (defaults disable 50+ low-relevance skills; flip the ones you want back to `name-only` or `enabled`). Update hooks to use `continueOnBlock` + `args` where appropriate. Update hook scripts to read `$CLAUDE_PROJECT_DIR` instead of computing repo root manually.
   - **v31.3 safety-gate updates.** Sync the expanded destructive-op coverage + Codex bypass-flag hard-blocks + modern OpenAI key redaction patterns to both `.claude/hooks/safety-gate.sh` and `~/.claude/hooks/safety-gate.sh` via `bash scripts/sync-safety-gates.sh`.
3. Removed in v31: any leftover `scripts/proactive-trigger-daemon.sh`, `scripts/proactive-daemon.sh`, `scripts/signal-schedule.sh`, `scripts/signal-fire-from-schedule.sh`, AppleScript `signal-fire-wrapper.applescript`. The upgrade walks an uninstall path: unload the launchd jobs, remove the `.app` wrappers from `~/Applications/`, archive the scripts to `scripts/archive/`. Telegram-signal.sh stays.
4. Sets `blueprint_version: v31.3` in `.{{orchestrator_lower}}-blueprint-version`.

### v29 → v31
1. Tell Claude Code: "I'm on v29, upgrade me to v31."
2. Run the v29 → v30 path (Graphiti drop if `E2_graphiti: true`), then the v30 → v31 path above.

### v28 → v31
1. Tell Claude Code: "I'm on v28, upgrade me to v31."
2. It reads `.{{orchestrator_lower}}-blueprint-version` (creates it if missing). Since v28 didn't stamp one, it'll assume no extensions installed.
3. For each available extension (E1, E3, E4, E5, E6), it asks: "Install this? (y/n)" with a link to the extension section above. E2 is skipped (no longer offered).
4. It installs picked ones plus the v31 deltas (Profile bucket, reflection skill, MCP additions if accepted, auth failover if accepted).
5. Updates `.{{orchestrator_lower}}-blueprint-version` to `v31`.

### v27 → v31
1. Same as v28 → v31 path. v27 → v28 only added more agents (non-breaking); same Core.

### Partial install - add one extension later
`bash scripts/install-blueprint.sh --add E3` - asks about E3 only, installs if you say yes, updates the version file.

### Per-extension uninstall
`bash scripts/install-blueprint.sh --remove E3` - uninstall steps for E3, marks it off in the version file.

### Version file format
`.{{orchestrator_lower}}-blueprint-version` (YAML):
```yaml
blueprint_version: v31.3
installed: 2026-04-21T01:00:00Z
upgraded: 2026-05-14T08:00:00Z   # v30 -> v31.3 (Profile bucket + reflection skill + MCP additions + auth failover + v31.2 hardening + reliability stack + Codex advisor + v2.1.139 settings; signal-fire removed)
mode: advanced
extensions:
  E1_sqlite_vec: true
  E2_graphiti: false   # deprecated as of v30 - not offered to new installs
  E3_agent_teams: true
  E4_observability: true
  E5_hardened_safety: true
  E6_amazing_memory: true
reliability:
  mcp_observability: true         # 5-layer Telegram MCP watchdog + alert path
  supervisor_wrapper: true        # bin/<orchestrator>-launch.sh re-exec loop
  tier3_auto_restart: true        # idle-gated kill-and-resume daemon (requires supervisor)
  tier1_mcp_hardening: true       # MCP_TIMEOUT + pre-launch pkill, baked into supervisor
codex:
  codex_advisor: false            # scripts/codex.sh + scripts/ensemble.sh (requires OpenAI API key)
  daily_scans: false              # daily Anthropic + Codex agentic release scans via launchd
```

---

## Before you install: prerequisites

Install these on your machine BEFORE running the install command. The wizard will check for them and refuse to start if any are missing.

**All platforms:**
- **Claude Code** - the CLI (`claude` command must work). Get it from claude.com/claude-code.
- **Node.js** v18 or newer - Mac `brew install node` / Windows `winget install OpenJS.NodeJS` / Linux `sudo apt install nodejs`
- **Git** - Mac `brew install git` / Windows `winget install Git.Git` (Git for Windows includes bash, REQUIRED for the hook pipeline) / Linux `sudo apt install git`
- **jq** - Mac `brew install jq` / Windows `winget install jqlang.jq` / Linux `sudo apt install jq`
- **SQLite** - Mac `brew install sqlite3` (already on macOS 10.4+, run `which sqlite3` to confirm before installing) / Windows `winget install SQLite.SQLite` / Linux `sudo apt install sqlite3`
- **bun** - Mac/Linux `curl -fsSL https://bun.sh/install | bash` / Windows `powershell -c "irm bun.sh/install.ps1 | iex"` (required for the Telegram plugin)
- **Python 3** v3.10 or newer - required for `scripts/embed-memories.py` (E1) and the dream consolidator (E6). The Python interpreter must have sqlite3 built with loadable extensions enabled.
  - Mac: `brew install python@3.12` (3.12 confirmed working; 3.10 and 3.11 also fine). Verify: `python3 --version` returns 3.10+.
  - Windows: download the installer from https://www.python.org/downloads/ and tick "Add python.exe to PATH" during install. Verify in Git Bash: `python3 --version` (or `python --version` depending on which alias the installer registered). If E1 / E6 install reports `embed-memories: no Python with loadable sqlite extensions found`, install via `uv python install 3.13` instead (uv ships an interpreter with the right sqlite build flags).
  - Linux: most distros from 2023 onward ship `python3` at 3.10+ (Ubuntu 22.04+, Debian 12+, Fedora 37+). Run `python3 --version` to confirm. Untested in CI but reported working. If your distro ships 3.8 or 3.9, install 3.10+ via `pyenv` or your distro's `python3.12` package.

**Optional (install only if you'll use the matching feature):**
- **gh** (GitHub CLI) - for automatic repo creation. Mac `brew install gh` / Windows `winget install GitHub.cli` / Linux follow github.com/cli/cli install docs. Run `gh auth login` after installing.
- **ffmpeg** - for the YouTube watch queue. Mac `brew install ffmpeg` / Windows `winget install Gyan.FFmpeg`
- **yt-dlp** - for the YouTube watch queue. Mac `brew install yt-dlp` / Windows `winget install yt-dlp.yt-dlp`
- **notebooklm-py** - for the AI Brain feature (the wizard installs this automatically if you pick the Brain at Q10).

**Windows note:** Plain PowerShell cannot run the .sh hook pipeline. You need either Git for Windows (which ships Git Bash) or WSL2. Git Bash is the lighter option and is what the rest of this blueprint assumes for Windows users.

**Windows - run this ONCE before you clone any blueprint-related repo or edit any hook script:**

```powershell
git config --global core.autocrlf input
```

Without this, Windows editors (Notepad, VS Code with default settings) save hook scripts with CRLF line endings, and the bash hooks fail with cryptic errors like `\r: command not found` or `bad interpreter`. The `input` setting checks files in as LF and leaves your working tree as-is.

If you've already cloned and your hooks are throwing `\r` errors, fix existing files in-place: `find .claude/hooks scripts -type f \( -name '*.sh' -o -name '*.bash' \) -print0 | xargs -0 dos2unix`. Install dos2unix first via `winget install MSYS2.MSYS2 ; pacman -S dos2unix`, or simpler: re-clone after fixing the global config.

If you don't have an existing project folder, create one now and `cd` into it before running the install command:

- Mac/Linux: `mkdir ~/Documents/MyAgent && cd ~/Documents/MyAgent`
- Windows (PowerShell): `mkdir $HOME\Documents\MyAgent ; cd $HOME\Documents\MyAgent`

---

## Install command

If you've never run Claude Code from a terminal, here is the literal first step:

- **Mac:** open Terminal (press Cmd+Space, type `Terminal`, hit Enter). Type `cd ~/Documents/MyAgent && claude` and hit Enter. You will see a `>` prompt.
- **Windows:** open PowerShell (press Win, type `PowerShell`, hit Enter). Type `cd $HOME\Documents\MyAgent ; claude` and hit Enter. You will see a `>` prompt.
- **Linux:** open your terminal, `cd ~/Documents/MyAgent && claude`. You will see a `>` prompt.

Once you see that prompt, paste the line below as your first message:

```
Read the Xantham System v31 blueprint at https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/xantham-system-v31.md and the companion templates appendix at https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/xantham-templates-v31.md. Run the full setup wizard from the landing file, pulling template bodies from the appendix when generation steps reference them. Walk me through every step, ask me one question at a time, don't assume any values. Guide me through getting whatever you need (Telegram bot token, NotebookLM notebook, agent name, etc.) as the wizard reaches each one.
```

If you forked this blueprint to your own GitHub repo, replace the URL above with your fork's raw URL.

**What happens next.** The wizard will ask you 15 questions one at a time. Each question shows up in this chat. There is no progress bar, just answer each one. It takes about an hour end-to-end (30-45 minutes if your prereqs Node 18 / Git / jq / sqlite3 / bun are already installed). After the last question, you will see "Setup complete" and a list of files to verify.

The wizard handles everything else interactively:
- Runs a preflight check confirming all the prerequisites above are present.
- Detects your OS (with confirmation).
- Asks you to pick Simple or Advanced mode AFTER showing what each one includes.
- Walks you through creating a Telegram bot via @BotFather (step-by-step) when it gets to the messaging step.
- Walks you through creating a NotebookLM notebook (or skipping the AI Brain for now) when it gets to the memory step.
- Asks you to name your orchestrator at the right point in the flow.
- Picks sensible defaults for everything else and confirms before applying.

You don't need ANY of the optional values (bot token, notebook ID, etc.) to start. The wizard guides you through creating them.

If you already have some values handy (e.g. an existing bot token), you can mention them when the wizard asks, but you don't have to. The wizard never blocks waiting on something it can guide you to create.

---

## Post-install verification - required before first real session

After the install wizard finishes, the user typically closes that session and starts a fresh terminal session named after their agent (e.g. `{{orchestrator_lower}}<enter>` (e.g. `myagent<enter>`)). The fresh session has zero context about which install steps actually completed. So things like terminal alias breakage (especially on Windows where the PowerShell profile setup often fails on first try) sit silently broken until the user notices and asks Claude to fix.

The wizard MUST close that gap. At the end of install, the wizard generates `SETUP-CHECKLIST.md` at the project root with one checklist item per setup step. The first new session reads this file and verifies each item before doing real work.

### What the wizard generates

`SETUP-CHECKLIST.md` template the wizard fills in with the user's actual values:

```markdown
# Setup checklist for {{orchestrator_name}}

Each verify step below is a command. Type it into your terminal (the same terminal where you ran `{{launch_cmd}}`), press enter, and check the output. If you see something unexpected, copy the output and paste it to {{orchestrator_name}} and it will fix it.

If you are reading this from a fresh `{{launch_cmd}}` session for the first time after install: walk through every item below in order. Run the verify command. If it does not return the expected output, follow the fix-if-broken instructions or ask {{orchestrator_name}} to fix it.

Mark each box as you confirm. Do not skip Windows-specific items if you are on Windows.

This checklist is mode-aware. The wizard wrote `data/runtime/install-mode.json` with either `{"mode": "simple"}` or `{"mode": "advanced"}`. Sections labelled **(Advanced mode only)** are pre-marked SKIP-IF-SIMPLE so you do not chase missing components you never installed. Verify with: `cat data/runtime/install-mode.json`.

---

## Step 1: Claude Code installed and in PATH

- [ ] **`claude --version` returns a version string**
  Verify: `claude --version`
  Expected: a version string such as `2.1.x`.
  Fix: install from claude.com/claude-code, restart your terminal.

---

## Step 2: Project root has the right files

- [ ] **Required files exist**
  Verify (Mac/Linux/Git-Bash): `ls CLAUDE.md docs/projects.md scripts/healthcheck.sh memory/MEMORY.md`
  Verify (Windows PowerShell): `Get-ChildItem CLAUDE.md, docs/projects.md, scripts/healthcheck.sh, memory/MEMORY.md`
  Expected: every file lists. No "No such file" errors.

---

## Step 3: Healthcheck passes

- [ ] **`bash scripts/healthcheck.sh` exits 0**
  Verify (Mac/Linux/Git-Bash): `bash scripts/healthcheck.sh`
  Verify (Windows PowerShell): `bash scripts/healthcheck.sh` (Git Bash must be installed; the script is bash-only)
  Expected: exits 0, shows green status across Telegram + memory + safety gate + project docs + MCP. Optional components (Brain, sqlite-vec, observability) show as warnings in Simple mode and hard-fails in Advanced mode.
  Fix: read each red item; healthcheck prints the suggested remediation.

---

## Step 4: Statusline shows context % + 5h window

Recommended for everyone, critical for power users.

- [ ] **Bottom-of-screen statusline visible**
  This adds `cwd | model | context% | 5h% | branch` to every Claude Code session so you can see when the context window is filling up (the most common cause of "the agent got worse" complaints).
  Verify: look at the bottom-of-screen statusline of THIS Claude Code session.
  Expected: `~/<project> | claude-opus-4-7[1m] | XX% context | XX% 5h | main`
  Fix (Mac/Linux/Git-Bash): `chmod +x ~/.claude/statusline-command.sh` then `grep -A1 statusLine ~/.claude/settings.json` to confirm the `command` field points at that script.
  Fix (Windows PowerShell): `Select-String -Pattern 'statusLine' -Path "$env:USERPROFILE\.claude\settings.json"` to confirm the entry. Statusline scripts run via Git Bash on Windows.
  Restart Claude Code (close and reopen the terminal). If still missing, paste your `~/.claude/settings.json` to {{orchestrator_name}} and it will diagnose.

---

## Step 5: Terminal alias `{{launch_cmd}}` works

- [ ] **Mac/Linux/Git-Bash: alias resolves**
  Verify: close and reopen your terminal, then run `{{launch_cmd}}`.
  Expected: a fresh Claude Code session opens at the project root with the right CLAUDE.md loaded.
  Fix: source your shell profile (`source ~/.zshrc` or `source ~/.bashrc`).

- [ ] **Windows PowerShell: alias resolves** (KNOWN-FRAGILE)
  Windows fails on first try in roughly 80% of installs. The PowerShell profile setup needs one of these three fixes: (a) enable script execution policy, (b) restart PowerShell, or (c) fix the path written to the profile.
  Verify: close and reopen PowerShell, then run `{{launch_cmd}}`.
  Expected: fresh Claude Code session opens.
  Fix: paste the error back to your agent and say "the `{{launch_cmd}}` alias does not work on PowerShell, fix it." It will:
  1. Check `Get-ExecutionPolicy` (must be `RemoteSigned` or `Unrestricted` for `$PROFILE` scripts)
  2. Check `$PROFILE` exists and has the function definition
  3. Fix path quoting issues (the most common failure is unquoted Windows paths containing spaces, e.g. `C:\Users\Some Name\...`)
  4. Verify the alias resolves with `Get-Command {{launch_cmd}}`

- [ ] **`{{launch_cmd}}-resume` works**
  Verify: from your terminal run `{{launch_cmd}}-resume`.
  Expected: opens Claude Code in resume mode.
  Fix: same as above. On Windows, almost always needs a one-shot agent fix on first install.

---

## Step 6: Hooks executable + wired

- [ ] **All hooks present and executable**
  Verify (Mac/Linux/Git-Bash): `ls -la .claude/hooks/*.sh`
  Expected: each hook shows `-rwxr-xr-x` (executable bit set on owner/group/other). Count matches the number of hooks the wizard installed (Core mode: at least `safety-gate.sh` + `log-telegram-hook.sh`; Advanced mode adds the rest per E1-E5).
  Verify (Windows PowerShell): `Get-ChildItem .claude\hooks\*.sh` - chmod is irrelevant on NTFS, but Git for Windows respects the executable bit via its config layer. Confirm via running any reply once and checking `data/audit/$(date +%Y-%m-%d).jsonl` exists (Advanced mode with E4 only).
  Fix: `chmod +x .claude/hooks/*.sh` (Mac/Linux/Git-Bash). Windows: re-clone or re-run the wizard's hook-write step.

---

## Step 7: Safety gate fires on a real destructive command

This is a deterministic specimen test. We create a canary file, then ask the gate to delete it. The gate should INTERCEPT the command. If it does not, the hook is not wired.

- [ ] **Safety gate intercepts `rm -rf` on a canary file**

  Run in your terminal:

  Mac/Linux/Git-Bash:
  ```bash
  touch test-canary
  rm -rf test-canary
  ```

  Windows PowerShell:
  ```powershell
  New-Item test-canary -ItemType File
  bash -c "rm -rf test-canary"
  ```

  Expected output for the second command (the gate prints to stderr and exits non-zero before the deletion runs):
  ```
  BLOCKED: Recursive or forced file deletion detected. Ask the user for approval. If approved, write the exact command to {{project_path}}/data/approved.txt (one command per line) then retry.
  ```

  The `test-canary` file should still exist (the gate stopped the deletion). The point is to verify the gate fires, not to actually delete the canary.

  Cleanup: tell {{orchestrator_name}} `clean up the test-canary file` and let it use its standard pre-approval flow, OR delete the file manually via your file manager / Finder / Explorer (no need to fight the gate to remove a one-byte canary).

  Fix if the gate did NOT fire (the rm-rf executed silently and the file vanished):

  Mac/Linux/Git-Bash:
  ```bash
  ls -la .claude/hooks/safety-gate.sh
  cat .claude/settings.json | grep -A2 '"PreToolUse"'
  ```

  Windows PowerShell:
  ```powershell
  Get-ChildItem .claude\hooks\safety-gate.sh
  Select-String -Pattern '"PreToolUse"' -Path .claude\settings.json -Context 0,2
  ```

  Expected: `safety-gate.sh` exists and is executable, AND `.claude/settings.json` has a `PreToolUse` hook entry with `command` pointing to `.claude/hooks/safety-gate.sh`. If either is missing, re-run the wizard's hook-install step or copy the template body from `blueprints/xantham-templates-v31.md` → `## Template: .claude/hooks/safety-gate.sh`. Also verify the global gate at `~/.claude/hooks/safety-gate.sh` exists (run `bash scripts/sync-safety-gates.sh` if not).

---

## Step 8: MCP servers connected

- [ ] **`/mcp` slash command shows green for every server**
  Verify: in this Claude Code session, type `/mcp` (slash command, not bash).
  Expected: every MCP server in your `.mcp.json` shows status `connected`.
  Fix: red entries need either (a) an OAuth completion in the browser (Notion, HubSpot, Pipedream and any other auth-required server) or (b) a process restart via `/mcp restart <name>`. Click through the auth links Claude provides. If a server stays red after both, paste the `/mcp` output back and ask Claude to diagnose.

---

## Step 9: First Telegram message

IMPORTANT: your laptop session must stay open and active for any Telegram message to land. The system polls for messages every few seconds; if the laptop sleeps or the Claude Code session closes, messages queue but are not replied to until you resume.

If you skipped Telegram during install, skip this entire section.

- [ ] **First "hi" arrives at the bot and gets a welcome reply**

  1. Make sure THIS Claude Code terminal stays open and your laptop is awake. (Tip on Mac: open a second terminal tab and run `caffeinate -i` to prevent sleep during the rest of this checklist. Tip on Windows: Settings -> System -> Power -> Screen and sleep -> set "When plugged in, put my device to sleep after" to "Never".)
  2. Open Telegram on your phone.
  3. Find your bot - search by the @username you set during the wizard, or by the bot's display name.
  4. Send: `hi`
  5. Within 5 to 10 seconds, a welcome reply from {{orchestrator_name}} arrives. If nothing arrives in 30 seconds, see Troubleshooting B1 below.

  Verify: the reply explicitly mentions running `/telegram:access` to approve your phone for ongoing access.

  If you do NOT see this welcome within 30 seconds: see Troubleshooting B1 in `USER-GUIDE.md` ("Bot didn't reply to my first Telegram message"). Most common cause is laptop sleep or the session being closed.

---

## Step 10: Verify `/telegram:access` skill works

The first-Telegram welcome instructs the user to run `/telegram:access` to approve their phone. If the skill is not installed, the user dead-ends. This step verifies the skill works BEFORE you rely on it.

- [ ] **`/telegram:access` opens the access-management flow**

  In your Claude Code terminal, type: `/telegram:access`

  Expected: a skill loads and presents a list of pending pairing requests. Your phone's pairing request from Step 9 should be the first one. Approve it.

  Verify the approval landed:

  Mac/Linux/Git-Bash:
  ```bash
  cat .claude/skills/telegram-access/access.json
  ```

  Windows PowerShell:
  ```powershell
  Get-Content .claude\skills\telegram-access\access.json
  ```

  Expected: your phone's `user_id` (a numeric Telegram ID) appears in the allowlist with a recent timestamp.

  Fix if `/telegram:access` is unrecognised: the `telegram` plugin (which ships the `telegram:access` skill) failed to install. Run:
  ```bash
  claude plugin marketplace add claude-plugins-official
  claude plugin install telegram@claude-plugins-official
  ```
  Then re-launch Claude Code (close and reopen) and retry `/telegram:access`. The slash command lives inside the `telegram` plugin, there is no separate `telegram-access` plugin to install.

---

## Step 11: Verify auto-embedding post-commit hook

This hook is what makes new memory files searchable across sessions via sqlite-vec. Without it, `memory-search.sh` cannot find anything you save.

**Skip this step if you picked Simple mode.** The auto-embedding post-commit hook is Advanced-mode only because it depends on sqlite-vec, which is itself part of the E1 semantic-memory extension. Simple-mode installs use grep + the MEMORY.md index file for memory lookup, so the hook is not needed and `scripts/install-git-hooks.sh` is not generated. Move to Step 12.

- [ ] **Post-commit hook is installed and executable** (Advanced mode only)

  Mac/Linux/Git-Bash:
  ```bash
  ls -la .git/hooks/post-commit
  grep -l embed-memories .git/hooks/post-commit
  ```

  Windows PowerShell:
  ```powershell
  Get-ChildItem .git\hooks\post-commit
  Select-String -Pattern 'embed-memories' -Path .git\hooks\post-commit
  ```

  Expected: the file exists, shows `-rwxr-xr-x` permissions on Mac/Linux, and the grep returns the file path (meaning the embed-memories invocation is wired).

  Fix if missing or non-executable:
  ```bash
  bash scripts/install-git-hooks.sh
  ```
  This installs and chmod-es the post-commit hook on Mac, Linux, and Windows-Git-Bash. Re-run it any time the hook goes missing.

---

## Step 12: First memory exercise (closes the loop end-to-end)

This step proves the full chain works: Telegram intent -> orchestrator parses memory-save -> file written -> committed -> post-commit hook embeds -> memory-search returns it.

- [ ] **A memory written from Telegram is searchable seconds later**

  On Telegram, send: `remember that I prefer concise replies`

  Expected reply from {{orchestrator_name}} confirms with the line:
  ```
  Saved to memory/feedback_concise_replies.md (will be searchable from any session via memory-search.sh).
  ```

  Verify the memory landed:

  Mac/Linux/Git-Bash:
  ```bash
  ls memory/ | head -10              # should include feedback_concise_replies.md
  git log -1 --name-only             # should show the new file in the most recent commit
  bash scripts/memory-search.sh "concise"  # Advanced mode only - see note below
  ```

  Windows PowerShell:
  ```powershell
  Get-ChildItem memory\ | Select-Object -First 10
  git log -1 --name-only
  bash scripts/memory-search.sh "concise"
  ```

  Fix if the file did not land: the memory-save handler is missing from CLAUDE.md. Ask {{orchestrator_name}} in this session: `save 'I prefer concise replies' to memory and confirm.` It will write the file directly. If that also fails, paste your CLAUDE.md and ask it to add a memory-save handler.

  Note for Simple mode: `memory-search.sh` requires sqlite-vec which is Advanced-only. Simple-mode users skip the third verify command - the markdown file existing in `memory/` and being committed is sufficient. Future sessions read memory via grep and the index file, not vector search.

  Fix if memory-search returns nothing in Advanced mode: the post-commit hook did not embed (revisit Step 11) OR sqlite-vec is not installed (run `pip install sqlite-vec` and re-run `bash scripts/embed-memories.sh`).

---

## (Advanced mode only - skip if you picked Simple)

If `cat data/runtime/install-mode.json` shows `"mode": "simple"`, skip this entire section. Simple-mode installs do not have these components, and the orchestrator's `healthcheck` handler treats them as warnings, not failures.

### Step A1: E1 sqlite-vec - Ollama running + index populated

- [ ] **Ollama up and serving the embed model**
  Verify (Mac): `brew services list | grep ollama` shows started; `curl -s localhost:11434/api/tags` returns models.
  Verify (Windows): `Get-Service Ollama` returns Status `Running`; `curl -s localhost:11434/api/tags` returns models.
  Index: `ls -la data/vector-memory.db` (file exists, > 1MB after first embed).
  Fix: restart Ollama (`brew services restart ollama` / `Restart-Service Ollama`). Re-run `bash scripts/embed-memories.sh` to regenerate the index.

### Step A2: E3 Agent Teams flag set

- [ ] **Experimental Agent Teams env value present**
  Verify (Mac/Linux/Git-Bash): `grep CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS .claude/settings.json`
  Verify (Windows PowerShell): `Select-String -Pattern 'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' -Path .claude\settings.json`
  Expected: value is `"1"` under the `env` section.
  Fix: edit `.claude/settings.json`, set the env value to `"1"`.

### Step A3: E4 Observability audit hook firing

- [ ] **Audit log captures tool calls**
  Verify (Mac/Linux/Git-Bash): open this fresh session, run any tool call (e.g. `ls`), then `cat data/audit/$(date +%Y-%m-%d).jsonl | tail -3`.
  Verify (Windows PowerShell): `Get-Content data\audit\$((Get-Date).ToString('yyyy-MM-dd')).jsonl -Tail 3`
  Expected: at least one JSONL line per recent tool call.
  Fix: PostToolUse hook entry missing in `.claude/settings.json`. Re-install per the E4 section.

### Step A4: E5 Hardened safety active

- [ ] **Force push to a protected branch is hard-blocked**
  Verify: in this session, ask the agent: `try git push --force origin main on a throwaway branch (do not actually push, just trigger the gate)`. The agent will issue the bash call.
  Expected: hard-blocked with the banner `HARD BLOCKED: Force push to protected branch - destroys shared history.` (HARD BLOCKED cannot be approved through the gate; it must be run manually in a plain terminal if truly needed.)
  Fix: confirm `.claude/hooks/safety-gate.sh` is the hardened version (look for the literal string `protected branch` in the script body).

### Step A5: E6 Brain (NotebookLM) accessible

- [ ] **`notebooklm-py` CLI loads**
  Verify: `notebooklm --help` (just confirm the CLI loads without error).
  Expected: the help text prints. The exact subcommand verbs vary by `notebooklm-py` release - run `notebooklm <verb> --help` for any specific operation (sources, ingest, etc.).
  Fix: re-auth via the steps printed by the install. The current `notebooklm-py` flow opens a Google OAuth page in your default browser; sign in with the Google account that owns the target NotebookLM notebook. If the CLI itself is missing, reinstall: `pip install notebooklm-py`.

---

## When all boxes are ticked

Delete or rename this file:

Mac/Linux/Git-Bash:
```bash
mv SETUP-CHECKLIST.md data/SETUP-CHECKLIST.md.done
```

Windows PowerShell:
```powershell
Move-Item SETUP-CHECKLIST.md data\SETUP-CHECKLIST.md.done
```

The next fresh session will not re-prompt you to verify.

If a future install adds new components (extension upgrade, new MCP server, new hook), regenerate the checklist with `bash scripts/regenerate-setup-checklist.sh` so the new items get verified before the next real session.
```

The wizard's last action before saying "install complete" should be: write this file (with `<agent-name>` substituted), confirm the file exists, and tell the user explicitly:

> Setup complete. I have written `SETUP-CHECKLIST.md` to your project root. Close this session, open a fresh terminal, run `<agent-name>` (or `<agent-name>-resume`), and the first thing your fresh orchestrator session will do is walk through the checklist. Do not start real work until every box is ticked.

The CLAUDE.md template (later in this blueprint) includes a corresponding directive: any first-time session that finds `SETUP-CHECKLIST.md` at the project root must read it, run each verify command, and fix failures before any other work. After all boxes are ticked, rename the file to `data/SETUP-CHECKLIST.md.done` so the prompt does not re-fire next session.

---

## Day-1 user experience

The verification checklist closes the "is the system actually installed" gap. This section closes the "what do I do now" gap. The wizard generates these eight files at the project root so a brand-new user who just opened a fresh `<agent-name>` session has everything they need to start operating without grep-ing through CLAUDE.md.

### `USER-GUIDE.md` - the user-facing command reference

Operational config lives in CLAUDE.md (the agent reads it). Day-1 commands need to live somewhere the user reads. The wizard writes `USER-GUIDE.md` at the project root with this shape:

```markdown
# Using your AI command centre

This is your day-one cheat sheet. Bookmark it, print it, leave it open in another tab. Everything you can do with `{{launch_cmd}}` is here.

## How to start a session

Open a terminal and run:

- `{{launch_cmd}}` - start a fresh Claude Code session in your project root
- `{{launch_cmd}}-resume` - pick up where the last session left off

That is it. From inside the session you can talk to {{orchestrator_name}} in plain English OR use any of the commands below.

## Top commands (memorise these five)

| Command | What it does |
|---|---|
| `help` | Lists every command available |
| `team` | Shows your specialist crew with `@<name>` invocation hints |
| `projects` | Shows your project roster |
| `sync <project>` | Saves a snapshot of where you are on a project (memory + handoff + commit) |
| `healthcheck` | Verifies every part of the system is working |

## Talking to {{orchestrator_name}}

You don't need commands for most things. Just say what you want:

- `what's the status on <project>?` - {{orchestrator_name}} reads memory, summarises
- `send <specialist-name> to fix the build` - {{orchestrator_name}} dispatches that specialist with context
- `how did we solve <past-issue> last week?` - {{orchestrator_name}} searches memory + recalls
- `remind me to check the deploy in 3 days` - {{orchestrator_name}} creates a calendar event
- `what's in my queue?` - {{orchestrator_name}} lists pending YouTube videos / emails / tasks

## Sending content to {{orchestrator_name}} (Telegram only)

If you set up Telegram during install:
- Paste a YouTube URL -> auto-queued for summary later
- Paste a YouTube playlist URL -> latest 15 videos auto-queued, dedup'd against already-watched
- Send a screenshot -> {{orchestrator_name}} reads the image
- Send any text -> {{orchestrator_name}} processes as a message
- Just say `hi` first thing in the morning -> {{orchestrator_name}} runs maintenance + gives you the morning digest

## Background work

- Spawning specialists: say `send <specialist> to do X` or `have <specialist> handle Y`. They run in parallel.
- Long tasks: {{orchestrator_name}} dispatches in background, gives you a 1-line acknowledgement, pings you when done.
- Scheduling: say `every Monday at 9am, ask <specialist> to do a frontier scan` - {{orchestrator_name}} sets up a routine.

## Sync rhythm

Recommended:
- After every meaningful work block: `sync <project>` so the snapshot doesn't drift
- End of day: `wrapup` (saves session summary, commits memory, pushes Brain if enabled)
- Monday morning: just say `hi` and the maintenance protocol fires automatically

## When things go wrong (quick reference)

- {{orchestrator_name}} seems confused: `healthcheck` first
- Memory feels stale: `sync <project>` to rebuild the snapshot
- Telegram not responding: see Troubleshooting **B1** below (most common cause: laptop is asleep or session is closed)
- Terminal alias broken (especially Windows): re-read `SETUP-CHECKLIST.md` if it exists, otherwise ask {{orchestrator_name}} in this session `the alias is broken, fix it`

For deeper troubleshooting, jump to the Troubleshooting section below.

## Where to read more

- **CLAUDE.md** - the agent's own operating config (what it does, not what you do)
- **HANDOFF.md** - what the last session was working on
- **memory/** - every fact and rule {{orchestrator_name}} has saved
- **docs/projects.md** - your project list with paths + descriptions

## Customising {{orchestrator_name}}

- Adjust voice / personality: just tell {{orchestrator_name}} `from now on be more concise` / `use more dry humour` / etc. It saves the rule to memory.
- Add a new specialist to the crew: ask {{orchestrator_name}} to create one - give it a name, domain, and starting context. It walks the multi-place update.
- Change a command: tell {{orchestrator_name}} `change the projects command to also show live URLs`. It updates CLAUDE.md.

## Reaching {{orchestrator_name}} on the move

If you set up Telegram, your bot is your portable command line. Anything you can do at the terminal you can do from your phone. {{orchestrator_name}} replies on the same channel you messaged from.

## Sessions and the context window

Every Claude Code session has a finite context window - roughly 200k tokens on Sonnet, more on Opus. Your statusline (set up during install) shows current usage as a percentage. This matters because the more context you fill, the slower and less reliable {{orchestrator_name}} gets.

**The rule of thumb:**

| Context % | What to do |
|---|---|
| 0-49% | Keep going. You have headroom for big tasks. |
| 50-79% | Wrap up the current thread before starting anything new. Run `sync <project>` or `wrapup` to capture state. |
| 80-94% | Finish the immediate sentence then start a fresh session via `{{launch_cmd}}` (NOT resume). Past 80% {{orchestrator_name}} starts dropping older context to make room and answers can drift. |
| 95%+ | Stop. Save state immediately. Open a fresh `{{launch_cmd}}` and explicitly tell the new session what you were just doing. |

**`{{launch_cmd}}` vs `{{launch_cmd}}-resume`:**
- `{{launch_cmd}}` opens a FRESH session. Empty context, full window available. Use this for new work or when the previous session's context is full.
- `{{launch_cmd}}-resume` continues your last session. Inherits all of last session's context - including what filled it up. Use only when you actively need the prior context (mid-debug, complex multi-step task in flight).

When in doubt, fresh. {{orchestrator_name}}'s memory layer (sqlite-vec + markdown in Advanced mode, markdown only in Simple mode) survives across sessions, so a fresh session can still recall everything important. The context window is just for the current conversation.

**Watching the 5h window:**

Your statusline also shows your 5-hour Claude Max usage. Same colour code: blue under 80%, yellow 80-94%, red 95%+. Past 95% you get rate-limited until the window resets. If you're approaching 95% mid-task, dispatch background specialists (they run on separate budgets) instead of doing more inline work.

**Why this matters more than people think:**

Most "the agent got worse" complaints are actually "the context window is too full." A 95%-full session forgets things from the start of the conversation, hallucinates, and drops sub-agent results. A fresh session with the same task always works better. Treat the statusline like a fuel gauge.

---

## Troubleshooting

### B1. Bot didn't reply to my first Telegram message

**Most common cause:** your laptop is asleep, or the {{orchestrator_name}} session is closed. {{orchestrator_name}} polls Telegram from inside an active Claude Code session - if no session is running, no messages get processed.

**Diagnostic checklist (work top to bottom):**

1. **Is your terminal showing the {{orchestrator_name}} TUI?** Look for the literal text "Welcome to Claude Code" near the top and a `>` input prompt at the bottom. If you see your normal shell prompt instead (`$` or `%` or `PS C:\>`), the session ended. Run your launch command:

   Mac/Linux/Git-Bash:
   ```bash
   {{launch_cmd}}
   ```
   Windows PowerShell:
   ```powershell
   {{launch_cmd}}
   ```

2. **Is your laptop's display awake?** Telegram polling pauses on sleep.

   Mac: open a second terminal tab, run `caffeinate -i` to keep the laptop awake while a long task runs.
   Windows: Settings -> System -> Power -> Screen and sleep -> set sleep to "Never" while plugged in.

3. **Run `/mcp` in your Claude Code terminal.** The `telegram` server should show `connected`. If it shows `disconnected` or `error`:
   - Try `/mcp restart telegram` (slash command from inside Claude Code).
   - If that fails, check `data/runtime/telegram.json` exists and contains a valid bot token. Re-paste the token from BotFather if needed.

4. **Run the healthcheck:**

   Mac/Linux/Git-Bash:
   ```bash
   bash scripts/healthcheck.sh
   ```
   Windows PowerShell:
   ```powershell
   bash scripts/healthcheck.sh
   ```
   Look for the Telegram section. If anything shows red, follow the inline remediation it prints.

5. **Pairing not approved.** First-message arrivals from a not-yet-allowlisted user_id may be silently dropped by the `/telegram:access` skill's policy. Run `/telegram:access` from your terminal and approve any pending pairing.

6. **Token mismatch.** If another Claude Code session on another machine has the same bot token, it will steal messages (the Telegram `getUpdates` API is single-consumer). Close all other sessions sharing the token. Only one session per token.

7. **Still nothing after the above:** send another Telegram message. The first message can hit the session before MCP boot completes (window of about 5 to 15 seconds right after launch). A second message sent 30+ seconds after launch lands cleanly in nearly every reported case.

If still stuck, paste the output of `bash scripts/healthcheck.sh` plus the result of `/mcp` to {{orchestrator_name}} in this session. It will diagnose.

### B2. Safety gate blocked a command I actually want to run

The safety gate uses pattern matching. Some legitimate commands match destructive patterns. The gate is intentionally conservative - false positives are a known cost of preventing real disasters.

**Approve a one-time command:**

1. Read the BLOCKED banner. It tells you the category (`rm-rf`, `sql-drop`, etc.) and the command that was blocked.
2. If you genuinely want to run it, ask {{orchestrator_name}}: `approve the last blocked command`. It will write the exact command to `data/approved.txt` (one command per line, with a 30-day TTL).
3. Retry the command in this session. The gate sees the pre-approval, allows it, and removes the approval (one-time use).

**Adjust patterns long-term:**

If a specific pattern causes repeated false positives, edit `.claude/hooks/safety-gate.sh` and make the regex more specific. For example, if a CLI tool's `rm` subcommand keeps getting blocked, add it to the whitelist near the top of Category 2. Be careful not to weaken the gate for genuinely dangerous commands.

**HARD BLOCKED commands cannot be approved through the gate.** These are catastrophic operations (`rm -rf /`, `git push --force` to a protected branch, `git filter-branch`) and must be run manually in a plain terminal if you truly need them.

### B3. Memory written but not searchable

You sent `remember that I prefer concise replies`, {{orchestrator_name}} confirmed it saved, but `bash scripts/memory-search.sh "concise"` returns nothing.

**Likely causes:**

1. **Post-commit hook missing.** Run:

   Mac/Linux/Git-Bash:
   ```bash
   ls -la .git/hooks/post-commit
   ```
   Windows PowerShell:
   ```powershell
   Get-ChildItem .git\hooks\post-commit
   ```
   If absent or non-executable: `bash scripts/install-git-hooks.sh`.

2. **sqlite-vec not installed (Advanced mode only).** Run `pip install sqlite-vec` then `bash scripts/embed-memories.sh` to backfill the index.

3. **Simple mode.** Simple-mode installs do not have sqlite-vec. Memory files exist in `memory/` and are read via grep + the `MEMORY.md` index, not vector search. The markdown file landing is sufficient. Verify with:

   Mac/Linux/Git-Bash:
   ```bash
   ls memory/ | grep concise
   ```
   Windows PowerShell:
   ```powershell
   Get-ChildItem memory\ -Filter '*concise*'
   ```

### B4. Setup-checklist step keeps failing

You ran a verify command from `SETUP-CHECKLIST.md`, the output didn't match, and the fix-if-broken didn't help.

Paste the verify command + the actual output to {{orchestrator_name}} in this session. Say: `step <N> of SETUP-CHECKLIST is failing, here's what I see, please diagnose and fix`. It has full context for every step in the checklist. Most failures resolve in one or two follow-ups; if the same step keeps failing after three exchanges, jump to Troubleshooting B1 in `USER-GUIDE.md` for the install-wide reset path.

If the failure is on Step 7 (safety gate) or Step 11 (post-commit hook), the most reliable fix is re-running the relevant install script:
- Safety gate: `bash scripts/sync-safety-gates.sh`
- Post-commit hook: `bash scripts/install-git-hooks.sh`
```

### First-contact behaviour (CLAUDE.md addition - single flag for both channels)

The CLAUDE.md template gets ONE first-contact handler that covers both terminal-first and Telegram-first arrivals via a single flag at `data/runtime/first-contact.flag`. The first session OR first Telegram message - whichever fires first - sends the welcome on its native channel and touches the flag. The OTHER channel sees the flag exists and skips its welcome. Net: every install gets exactly ONE welcome on the channel the user actually used first, never two.

```markdown
## First-contact behaviour (single flag covers both channels)

The flag `data/runtime/first-contact.flag` is the bookkeeping for whether the user has been introduced to {{orchestrator_name}}. It does not exist after install. Whichever channel sees the user first (terminal session OR Telegram message) does the introduction and creates the flag. After that, neither channel re-introduces.

### Path A: terminal-first

If a session starts with no inbound message AND `data/runtime/first-contact.flag` does not exist:

1. Output (terminal-visible, NOT via Telegram): "Hi, I'm {{orchestrator_name}}. This looks like your first session. Read USER-GUIDE.md at the project root for the day-one cheat sheet, OR just tell me what you want to work on. Common starting moves: `help`, `projects`, `healthcheck`, or send any project name."
2. Touch `data/runtime/first-contact.flag` so neither this terminal greeting nor the Telegram welcome fires again.
3. Wait for the user.

### Path B: Telegram-first

If a Telegram message arrives AND `data/runtime/first-contact.flag` does not exist:

1. Reply via the Telegram tool: "Hi, I'm {{orchestrator_name}} on Telegram. This is your first message to me. Before I can take messages from you for real, you need to approve this chat once. Switch to your laptop terminal (the one running `{{launch_cmd}}`). Type `/telegram:access` and press enter. You'll see a prompt asking to approve this Telegram chat. Type `yes`. From then on, every Telegram message lands here and I respond on this thread. Once approved, I do everything I do in your terminal, plus auto-queue YouTube URLs, accept screenshots, and reply on the move. Top commands: `help`, `projects`, `sync <project>`, `wrapup`. Or just talk to me normally and I'll route to the right specialist agent."
2. Touch `data/runtime/first-contact.flag` so neither this Telegram welcome nor the terminal greeting fires again.
3. Then handle the user's actual message normally.

Do NOT re-introduce on subsequent sessions or messages once the flag exists - the user has been oriented. If the user explicitly asks to re-trigger the intro (rare - usually for testing), they can `rm data/runtime/first-contact.flag` and start a fresh session or send a fresh Telegram message.
```

Wizard generation note: the install wizard MUST NOT pre-create `data/runtime/first-contact.flag`. It only creates `data/runtime/install-mode.json` and other config files. Leaving `first-contact.flag` absent is what triggers the welcome on whichever channel the user uses first.

### `BACKUP-AND-RECOVERY.md` - what to back up + how to restore

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

- `data/runtime/` (Telegram bot token, session state, lock files) - gitignored, contains secrets
- `data/vector-memory.db` (sqlite-vec semantic index) - gitignored, regenerable but takes minutes
- `~/.claude/` (Claude Code CLI auth, hook installs at user scope) - never in any repo
- Shell profile (`~/.zshrc` / `~/.bashrc` / PowerShell `$PROFILE`) - terminal aliases live here
- Any `.env` files inside `infra/`

## Recommended backup approach

1. **Push the repo to GitHub on every meaningful change** (the post-commit hook + your sync rhythm handle this if you stay disciplined)
2. **Each Sunday:** ask your agent: "back up my runtime folder." It zips `data/runtime/` (which holds your Telegram bot token, session state, lock files) and drops a date-stamped copy at `~/Documents/<your-orchestrator>-backups/`. To restore, ask: "restore runtime from last Sunday's backup." If you'd rather hold the backup off-machine, copy the dated zip to an encrypted external drive or a password manager attachment.
3. **Document your shell aliases** in this file so you can recreate them on a fresh machine.

## Restoring on a new Mac

1. Install Claude Code (claude.com/claude-code), log in.
2. Install dependencies per the blueprint (Mac/Windows commands inside).
3. `git clone <your-repo-url>` to your Documents directory.
4. `cd` into the repo.
5. Restore `data/runtime/` from your backup (paste files in).
6. Run `bash scripts/healthcheck.sh` - it tells you what's missing.
7. Open `SETUP-CHECKLIST.md` (or regenerate it) and walk through every item.
8. Re-pair your Telegram bot if needed (`/telegram:configure` skill or paste the token to the agent).

## Restoring on a new Windows machine

Same steps via Git Bash or WSL2. The blueprint's Windows-specific install commands cover the dependencies.

## Restoring just your AI Brain notebook

Brain content is in NotebookLM (notebook ID stamped in `data/runtime/brain.json`). On a new machine, install `notebooklm` CLI, log in with the same Google account, and the notebook is already there. Source files (snapshots) are not redownloaded automatically - they were one-way pushed. The notebook itself is the canonical store.
```

### Statusline - context-window + 5h budget visibility

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

### `scripts/upgrade-{{orchestrator_lower}}.sh` - the update path with customisation preservation

When a user has been on an older blueprint (say v29) and the upstream version (v31) ships, they may have ALSO added their own hooks, skills, scripts, and CLAUDE.md sections in the meantime. A naive overwrite would blow those away. This script does the opposite: it diffs three ways and asks the user before touching anything customised.

```bash
#!/usr/bin/env bash
# upgrade-{{orchestrator_lower}}.sh - bump from current blueprint version to latest, preserving
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

if [ ! -f .{{orchestrator_lower}}-blueprint-version ]; then
  echo "No .{{orchestrator_lower}}-blueprint-version found. Are you in a Xantham System repo?" >&2
  exit 1
fi

CURRENT=$(grep '^blueprint_version:' .{{orchestrator_lower}}-blueprint-version | awk '{print $2}')
echo "Current blueprint version: $CURRENT"

# Fetch latest from canonical source
LATEST_URL="https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/xantham-system-latest.md"
echo "Fetching latest blueprint from: $LATEST_URL"
curl -fsSL "$LATEST_URL" -o "${TMPDIR:-/tmp}/latest-blueprint.md"
LATEST=$(grep '^# Xantham System - Blueprint' "${TMPDIR:-/tmp}/latest-blueprint.md" | sed 's/.*Blueprint //')
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
  curl -fsSL "$ARCHIVE_URL" -o "${TMPDIR:-/tmp}/old-baseline.md" || {
    echo "Could not fetch old baseline. Will proceed without it (every modified file will be flagged for review)." >&2
  }
  [ -f "${TMPDIR:-/tmp}/old-baseline.md" ] && OLD_BASELINE="${TMPDIR:-/tmp}/old-baseline.md"
fi

echo ""
echo "Now running the three-way upgrade walkthrough via Claude Code."
echo ""
echo "Open a fresh Claude Code session at $REPO_ROOT and paste:"
echo ""
echo "---"
echo "Read ${TMPDIR:-/tmp}/latest-blueprint.md (target version $LATEST)."
echo "Read $OLD_BASELINE (my current baseline, $CURRENT)."
echo "Walk the customisation-preserving upgrade per the public blueprint section"
echo "'Upgrade walkthrough (customisation-preserving)'."
echo ""
echo "Steps:"
echo "1. For every file the new blueprint defines, three-way diff:"
echo "   - my current copy"
echo "   - the old-baseline copy ($OLD_BASELINE)"
echo "   - the new copy (${TMPDIR:-/tmp}/latest-blueprint.md)"
echo "2. Bucket each: pristine, customised, user-added."
echo "3. Show me the per-bucket summary before touching anything."
echo "4. For pristine files, ask once: OK to bulk-upgrade all? yes/no."
echo "5. For customised files, walk one at a time: keep mine, take new, or show diff first."
echo "6. For user-added files, list them and confirm I know they will be preserved."
echo "7. Apply only the changes I approved."
echo "8. Update .{{orchestrator_lower}}-blueprint-version to $LATEST."
echo "9. Regenerate SETUP-CHECKLIST.md so I can verify the upgrade landed."
echo "10. Print a summary of what changed + what was preserved."
echo "---"
```

The blueprint section that Claude Code reads when it executes the walkthrough is below.

### Upgrade walkthrough (customisation-preserving)

When a user runs `bash scripts/upgrade-{{orchestrator_lower}}.sh` and pastes the resulting prompt into a fresh Claude Code session, the agent walks this protocol:

**Phase 1 - Inventory.** Catalog every file the new blueprint defines. For each, record three checksums:
- the user's current file (if it exists)
- the old-baseline file (if available)
- the new blueprint file

**Phase 2 - Bucket.** Each file falls into one of:
- **Pristine:** user's current file matches old-baseline (or doesn't exist + new blueprint adds it). Safe to take the new version.
- **Customised:** user's current file differs from old-baseline. The user has modified it. Take the new version blindly = clobber their work.
- **User-added:** user has files that aren't in old-baseline OR new blueprint (custom hooks, custom skills, custom scripts, custom CLAUDE.md sections wrapped in user-section markers). Preserve untouched.

**Phase 3 - Summarise BEFORE touching anything.** Output something like:
```
Upgrade plan: v29 -> v31

PRISTINE (15 files, safe to upgrade): scripts/healthcheck.sh, .claude/hooks/safety-gate.sh, ...
CUSTOMISED (3 files, will ask per file):
  - CLAUDE.md (you added a custom routing table)
  - scripts/log-telegram.sh (you added a redaction call)
  - .claude/skills/{{orchestrator_lower}}-sync/SKILL.md (you tweaked the sync cadence)
USER-ADDED (8 files, untouched): .claude/hooks/my-custom-hook.sh, .claude/skills/my-custom-skill/SKILL.md, ...

OK to proceed? (yes / show me a customised file first / cancel)
```

**Phase 4 - Bulk-approve pristine.** One yes/no for the whole pristine bucket. If yes, copy all new versions over.

**Phase 5 - Per-file walk for customised.** For each customised file, show:
- A 3-way diff (current vs new, with old-baseline as common ancestor)
- Three options: **keep mine** (do nothing), **take new** (overwrite), **merge** (Claude attempts a 3-way merge, presents the result, asks for approval)
- If the user picks merge and it cleanly applies (no conflict), accept. If conflicts, fall back to per-hunk choices.

**Phase 6 - User-added confirmation.** List user-added files. Confirm with the user that the agent recognises them as user contributions and will not touch them. This step exists to surface any files the user FORGOT they added.

**Phase 7 - Apply + verify.** Once all approvals are in:
- Apply the changes
- Update `.{{orchestrator_lower}}-blueprint-version` to the new version
- Regenerate `SETUP-CHECKLIST.md` so the user verifies the upgrade landed
- Run `bash scripts/healthcheck.sh` to confirm no breakage
- If healthcheck fails, the agent investigates + offers a rollback (`git checkout` of the previous state)

**Phase 8 - Summary.** Output:
```
Upgrade complete: v29 -> v31

Upgraded (15 files): healthcheck.sh, safety-gate.sh, ... (full list)
Took new (1 customised file): scripts/log-telegram.sh
Kept yours (1 customised file): CLAUDE.md
Merged (1 customised file): .claude/skills/{{orchestrator_lower}}-sync/SKILL.md
Preserved untouched (8 user-added files): my-custom-hook.sh, my-custom-skill/SKILL.md, ... (full list)
New since v29: USER-GUIDE.md, SETUP-CHECKLIST.md, FIRST-WEEK.md, ... (full list of new components)

Run SETUP-CHECKLIST.md to verify the upgrade landed cleanly.
```

**Why this matters:** users who've been operating for months will have evolved their setup. A naive upgrade that overwrites everything is hostile to that investment. This protocol lets users adopt new upstream features (auto-digest improvements, new hooks, new skills) while preserving every personal addition they've made.

### `BLUEPRINT-MARKERS.md` - convention for user-added sections inside blueprint files

Some users will modify CLAUDE.md or other shared files in-place (rather than adding new files). To preserve their additions across upgrades, the upgrade walkthrough recognises sections wrapped in marker comments:

```markdown
<!-- USER-CUSTOM-SECTION:start name="my-custom-routing" -->
... my custom rules go here ...
<!-- USER-CUSTOM-SECTION:end -->
```

When the upgrade overwrites a customised file, it preserves any USER-CUSTOM-SECTION blocks at the same logical location in the new file. If the new blueprint version has restructured the file, the agent prompts the user to manually re-place the preserved blocks.

Recommended: tell users to wrap their custom CLAUDE.md additions in these markers BEFORE upgrading. The pre-upgrade prompt should include:

> "Have you customised CLAUDE.md or other blueprint-shipped files? If yes, wrap your custom sections in USER-CUSTOM-SECTION markers before continuing the upgrade. Any unmarked customisations will trigger the per-file walk."

### `FIRST-WEEK.md` - daily-ops guide

The wizard writes:

```markdown
# Your first week with <agent-name>

Day 1: just play. Run `help`, `projects`, `team`. Send a casual message on Telegram. Watch the agent respond. Do not over-plan.

Day 2-3: pick one real project. Add it via `register a new project called X`. Use `sync X` after each work block. Notice how the agent picks up context faster on day 3 than day 1 - that is memory working.

Day 4: try a complex task. "Send Kai to refactor the auth flow in X." Watch the agent dispatch, work in background, and come back with results. This is the multi-agent pattern.

Day 5: make a correction. When the agent gets something wrong, just tell it "no, do it like this." It saves the correction to memory and won't make the same mistake again.

Day 6: trigger maintenance. Just say `hi` Monday morning. The agent runs healthcheck, surfaces stale items, suggests next priorities.

Day 7: review. Type `wrapup` at end of day. Agent commits memory, pushes the Brain snapshot, and writes a HANDOFF for next week.

If you have done all seven, you are operating at full capability.
```

### `PITFALLS.md` - common things not to do

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

That directory has your Telegram bot token, session state, and lock files. Losing it forces you to re-pair everything. Back it up weekly per BACKUP-AND-RECOVERY.md.

## Do not run `git push --force` on main

The hardened safety gate (E5) blocks this hard, but if you somehow get past it: stop, pull, resolve, re-push. Force-push to main destroys shared history. Same on production / develop / release.

## Do not reinstall the orchestrator over an existing install without backing up

Re-running the wizard on a populated repo can overwrite CLAUDE.md / settings / memory. Always backup the entire repo first: `git branch backup/$(date +%s) && git push origin backup/$(date +%s)`.

## Do not run multiple `<agent-name>` aliases pointing at different repos

Confusion. Each agent name should map to one project. Use `<agent-name>` for your orchestrator, a different name for any other personal AI you build.

## Do not assume the AI Brain is canonical

The Brain (NotebookLM) is a search-and-summary layer on top of memory snapshots. The CANONICAL store is `memory/*.md`. If they disagree, trust memory files.
```

### `MEMORY-HYGIENE.md` - what to commit, what to gitignore

The wizard writes:

```markdown
# Memory hygiene

The agent saves memory automatically. You usually don't need to think about it. This doc is for the corner cases.

## What auto-commits

- Anything the agent saves to `memory/<type>_<topic>.md` via its core loop step 6
- Anything the agent saves to `agent-memory/<agent-name>/<file>.md`
- The auto-regenerated `memory/MEMORY.md` index (post-commit hook)
- `data/vector-memory.db` SHA / chunk count tracking (NOT the .db itself; that's gitignored)

## What is gitignored (locally only)

- `data/vector-memory.db` (regenerable from `bash scripts/embed-memories.sh`)
- `data/runtime/*` (secrets, session state, lock files)
- `data/audit/*.jsonl` (you can archive these via `bash scripts/audit-archive.sh 30` to push older ones into git)
- `data/youtube-watch-queue.jsonl` and `data/youtube-playlists.jsonl` (local ops state)
- `infra/*/.env` (API keys)

## When to manually save a memory

If the agent missed something important, tell it: "save this to memory: <fact>." It writes a file, commits, and the post-commit hook re-embeds. You should rarely need to do this - the core loop handles it.

## When to clean up memory

Memories accumulate. Once a quarter:
- Run `bash scripts/check-memory-freshness.sh` to surface stale entries (past their TTL)
- Walk through and either re-verify (set `last_verified` to today) or delete (`rm memory/<file>.md`)
- Delete invalidates the post-commit hook auto-removes the chunk from sqlite-vec
```

### `scripts/regenerate-setup-checklist.sh` - for when new components arrive

The wizard writes a stub:

```bash
#!/usr/bin/env bash
# regenerate-setup-checklist.sh - re-write SETUP-CHECKLIST.md based on
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

### Wizard's final action sequence

After install, the wizard writes all of these files. **Gate the SETUP-CHECKLIST emit on the success of every Generation Order step (1-18).** If any earlier step failed, swap SETUP-CHECKLIST.md for DIAGNOSTIC-CHECKLIST.md (see Generation Order Step 19 for the template).

**Project root - on full success:**
1. `SETUP-CHECKLIST.md` (verification - emitted only if all generation steps succeeded)
2. `USER-GUIDE.md` (day-1 cheat sheet, includes session management + context window guidance)
3. `BACKUP-AND-RECOVERY.md` (restore docs)
4. `FIRST-WEEK.md` (daily-ops guide)
5. `PITFALLS.md` (anti-patterns)
6. `MEMORY-HYGIENE.md` (memory rules)
7. `scripts/upgrade-{{orchestrator_lower}}.sh` (future bump path)
8. `scripts/regenerate-setup-checklist.sh` (regen helper)

**Project root - on partial failure (any Generation Order step 1-18 errored):**
- `DIAGNOSTIC-CHECKLIST.md` REPLACES `SETUP-CHECKLIST.md`. Lists every failed step with retry hints.
- Items 2-8 above are still written (the diagnostic doesn't block the rest of the docs).

**User scope (one-time, applies to every Claude Code session on this machine):**
9. `~/.claude/statusline-command.sh` (the bash script that renders the statusline)
10. `~/.claude/settings.json` updated to add the `statusLine` block pointing at that script

Plus update the CLAUDE.md template with the unified First-contact behaviour block (covers both terminal-first and Telegram-first arrivals via a single `data/runtime/first-contact.flag`) + the SETUP-CHECKLIST first-session-check block (both already shown).

Then the wizard tells the user:

> 🔹 Setup complete. Six files written to your project root + two scripts under scripts/ + the statusline at ~/.claude/. SETUP-CHECKLIST.md is the one to read first. USER-GUIDE.md is your day-1 cheat sheet (includes when to start a fresh session vs resume, what the context % means). BACKUP-AND-RECOVERY.md tells you what to back up. FIRST-WEEK.md is your week-1 ops guide. PITFALLS.md is what NOT to do. MEMORY-HYGIENE.md is the memory rules. Close this session, run `<agent-name>` from your terminal, and the first session will walk SETUP-CHECKLIST.md before any real work. You'll see the new statusline at the bottom showing your context window - watch it as you work, especially past 50%.

Or, if any step failed:

> 🔸🔴 Setup partially failed. I wrote DIAGNOSTIC-CHECKLIST.md to your project root with the failed step + retry hints. Read it first, fix what's flagged, then re-run the install wizard - it detects what's already in place via the directory tree + `data/runtime/install-mode.json` and resumes from the first unfinished step.

---

# Full reference - Core install wizard, templates, patterns, troubleshooting

The sections above cover the v29-v31 additions (mode chooser, extensions, versioning, OS coverage, Profile bucket, reflection skill, MCP catalogue, auth failover).
What follows is the complete Core install guide inherited from v28: the 15-question setup wizard,
every template file (CLAUDE.md, settings.json, agents, scripts, hooks), advanced patterns,
and the full troubleshooting catalogue. Skip to any section from the headings; nothing in here
is required if you've already installed Core via Simple mode - these are the full templates
the wizard uses under the hood.

## Prerequisites

Before starting the wizard, ensure the following are installed. The wizard's Q0 preflight stage checks for these and refuses to advance if any are missing.

**All platforms:**
- **Claude Code** - the CLI (`claude` command must work). Get it from claude.com/claude-code.
- **Node.js** v18+:
  - Mac: `brew install node`
  - Windows: `winget install OpenJS.NodeJS`
  - Linux: `sudo apt install nodejs`
- **Git**:
  - Mac: `brew install git`
  - Windows: `winget install Git.Git` (Git for Windows includes Git Bash, REQUIRED for the hook pipeline)
  - Linux: `sudo apt install git`
- **jq**:
  - Mac: `brew install jq`
  - Windows: `winget install jqlang.jq`
  - Linux: `sudo apt install jq`
- **SQLite**:
  - Mac: already on macOS 10.4+, run `which sqlite3` to confirm. If missing, `brew install sqlite3`.
  - Windows: `winget install SQLite.SQLite`
  - Linux: `sudo apt install sqlite3`
- **bun** - required for the Telegram plugin and some Claude Code plugins:
  - Mac/Linux: `curl -fsSL https://bun.sh/install | bash`
  - Windows: `powershell -c "irm bun.sh/install.ps1 | iex"`

**Optional:**
- **gh** (GitHub CLI) - for automatic repo creation:
  - Mac: `brew install gh`
  - Windows: `winget install GitHub.cli`
  - Linux: follow github.com/cli/cli install docs
  - Run `gh auth login` after installing on any platform.
- **notebooklm** - for the AI Brain feature (installed during setup if selected; no OS branch).

## Instructions for Claude Code

Read this entire section carefully before asking the first question. You are about to run an interactive setup wizard that builds a multi-agent AI command centre.

### How to run the wizard

1. Read this full document first. Understand all four parts before you start asking questions.
2. Ask the questions below **one at a time**. Wait for the user's answer before moving to the next question.
3. Store each answer as a variable using the `{{placeholder}}` names specified. You will need every one of them when generating files from the templates in `blueprints/xantham-templates-v31.md`.
4. Some questions have branching logic -- only ask them if the conditions are met.
5. After all questions are answered, generate every file listed in the "Generation Order" section using the templates in `blueprints/xantham-templates-v31.md`. Substitute all `{{placeholders}}` with the user's answers.
6. Run the post-setup validation checks.
7. Print the setup summary.

### Variable reference

These are the variables you will collect. Every template in the companion file `blueprints/xantham-templates-v31.md` references them by these exact names.

| Variable | Type | Set by question |
|---|---|---|
| `{{os}}` | mac / windows / linux | Q0 (silent uname-s probe; user-confirmed if unknown) |
| `{{install_mode}}` | simple / advanced | Q0.5 |
| `{{orchestrator_name}}` | string | Q1 |
| `{{orchestrator_name_lower}}` | string (lowercase of above) | Derived from Q1 |
| `{{orchestrator_lower}}` | string (alias of `{{orchestrator_name_lower}}`) | Derived from Q1 (same value, shorter token used in 100+ template sites) |
| `{{purpose}}` | personal / work / both | Q3 |
| `{{work_type}}` | software-dev / data-science / general-office / custom | Q4 (conditional) |
| `{{plan}}` | max-20x / max-5x / pro | Q5 |
| `{{messaging}}` | telegram / terminal | Q6 |
| `{{telegram_token}}` | string | Q6 (conditional, if telegram) |
| `{{agent_preset}}` | solo-dev / full-team / dev-team / custom | Q7 |
| `{{agents}}` | list of {role, name} | Q7 |
| `{{spawn_aggressiveness}}` | conservative / balanced / aggressive | Q7.5 |
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
| `{{user_name}}` | string (the user's preferred name) | Derived: read `git config user.name`, fall back to asking once if empty |
| `{{user_name_lower}}` | string (lowercase of above) | Derived from `{{user_name}}` |
| `{{orchestrator_name_upper}}` | string (uppercase of orchestrator name) | Derived from Q1 |
| `{{project_root}}` | string (absolute path to the repo root, may differ from project_path if Claude is run from a subdir) | Derived: `git rev-parse --show-toplevel`, fall back to `{{project_path}}` |
| `{{telegram_chat_id}}` | string (the user's Telegram chat ID) | Q6 (conditional, captured on first /start to the bot) |
| `{{notebook_id}}` | string (Google NotebookLM notebook ID for the Brain) | Q10 (conditional, if brain=yes; user pastes from notebooklm.google.com URL) |
| `{{private_dir_name}}` | string (basename for a user-private dot-prefixed subdirectory under `memory/`) | Default `noprivatedir` if not configured. Used as the dot-dir basename in `memory/.<name>/` and as a grep filter in dream phase 3 + 4. Defaulting to `noprivatedir` ensures the filter never matches by accident when no private dir exists. |
| `{{person_1}}` through `{{person_5}}` | string (named persons to extract during active-recall, e.g. spouse, partner, key colleagues) | Substituted from a structured `## People` section in `profile_<user>.md` if present. Empty slots are skipped by the loop, so unused tokens stay benign. |
| `{{user_email_literal}}` | string (real email for export-blueprint sed source) | Empty at install. User fills in once post-install when they first run `scripts/export-blueprint.sh`. |
| `{{user_name_literal}}` | string (real full name for export-blueprint sed source) | Empty at install. Same one-time fill-in pattern. |
| `{{user_first_name_literal}}` | string (bare first name for word-boundary substitution) | Empty at install. Same one-time fill-in pattern. |
| `{{notebook_id_literal}}` | string (real NotebookLM notebook ID for export-blueprint) | Empty at install. Filled in only if Brain extension installed. |
| `{{telegram_chat_id_literal}}` | string (real Telegram chat ID for export-blueprint) | Empty at install. Filled in only if Telegram messaging configured. |
| `{{home_dir_literal}}` | string (real home dir for export-blueprint path substitution) | Empty at install. User fills in once post-install. |
| `{{company_name_literal}}` | string (optional, for export-blueprint company-name redaction) | May stay empty if user is solo / no employer reference in their blueprints. |

### Derived values

After collecting answers, compute these before generating files:

- `{{orchestrator_name_lower}}` = lowercase version of `{{orchestrator_name}}`, spaces replaced with hyphens
- `{{orchestrator_lower}}` = same value as `{{orchestrator_name_lower}}` (shorter alias used in 100+ template sites)
- `{{shell_profile}}` = `~/.zshrc` on Mac, `~/.bashrc` on Linux, PowerShell profile on Windows
- `{{package_manager}}` = `brew` on Mac, `apt` on Linux, `winget` on Windows
- `{{project_path}}` = the absolute path of the current working directory (where the user is running Claude Code)
- `{{db_name}}` = `{{orchestrator_name_lower}}.db`
- `{{agent_count}}` = length of `{{agents}}` list (specialist count only, does NOT include the orchestrator). Templates that say "crew of N specialist agents" use this directly. Templates that need the team total (orchestrator + specialists) compute it inline as `{{agent_count}}+1`.
- For each agent in `{{agents}}`: `{{agent_<role>_name}}` = the name the user chose for that role
- `{{user_name}}` = `git config --global user.name` if set; otherwise the wizard asks once: "What name should the orchestrator use when addressing you?" Stored for templates that need to greet the user by name (greeting digests, telegram replies, profile narratives)
- `{{user_name_lower}}` = lowercase version of `{{user_name}}`, used for matching their Telegram handle in audit-log filtering
- `{{plan_name}}` = human-readable plan label derived from `{{plan}}`: `Claude Max 20x` if `{{plan}}=max-20x`, `Claude Max 5x` if `{{plan}}=max-5x`, `Claude Pro` if `{{plan}}=pro`. Used in Q7.5 warning text + any other template that wants a friendly plan label.
- `{{context_warning_threshold}}` = pre-compaction sync trigger percentage derived from `{{plan}}`: `85` if `{{plan}}=max-20x`, `75` if `{{plan}}=max-5x`, `60` if `{{plan}}=pro`. Used in the CLAUDE.md pre-compaction sync section so the trigger matches the plan's 1M / 200k / smaller context window respectively.
- `{{spawn_aggressiveness_block}}` = the literal habit text the wizard writes into the CLAUDE.md "Agent spawning rules" section, picked by `{{spawn_aggressiveness}}`:
  - `conservative`: "Run work sequentially, one specialist at a time. Spawn parallel agents only when explicit user request."
  - `balanced`: "Default to 2-3 parallel specialists when work decomposes cleanly. Fan out further only on explicit user request or for sprints clearly bigger than 3 lanes."
  - `aggressive`: "Default to aggressive parallel dispatch. Spawn 5-16 specialists for big sprints. Use Agent Teams channel pattern when work has cross-talk. Watch the 5-hour rolling rate limit on Max 20x."

---

## The Questions

### Q0: Preflight checks

Q0 is a HARD GATE. The wizard does not ask any other question until Q0 passes. Goal: confirm every prerequisite (Node 18+, Git, jq, sqlite3, bun, claude CLI) is installed before any user-facing decision. Without these, later steps fail in confusing ways and the user has to start over.

**Step 1.** Detect the user's OS in one prompt-free check (used only to pick the right install commands when something is missing). Run a single Bash probe via the Bash tool:

```bash
case "$(uname -s 2>/dev/null)" in
  Darwin) echo "OS=mac" ;;
  Linux) echo "OS=linux" ;;
  MINGW*|MSYS*|CYGWIN*) echo "OS=windows" ;;
  *) echo "OS=unknown" ;;
esac
```

If `OS=unknown`, ask the user once: "I could not detect your OS. Are you on Mac, Windows, or Linux?" Store as `{{os}}`.

**Step 2.** Run the preflight probe. Generate `scripts/preflight.sh` from the body below now, mark it `+x`, and execute it. The wizard then parses MISSING lines.

```bash
#!/usr/bin/env bash
# scripts/preflight.sh - hard gate before the install wizard proceeds.
# Exit 0 = all prereqs present. Exit 1 = at least one missing (printed to stdout).
set -u

REQUIRED=(claude node git jq sqlite3 bun)
MISSING=()
for cmd in "${REQUIRED[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "OK: $cmd ($(command -v "$cmd"))"
  else
    echo "MISSING: $cmd"
    MISSING+=("$cmd")
  fi
done

# Node version check (must be >=18)
if command -v node >/dev/null 2>&1; then
  NODE_MAJOR=$(node -p "process.versions.node.split('.')[0]" 2>/dev/null || echo 0)
  if [ "${NODE_MAJOR:-0}" -lt 18 ]; then
    echo "MISSING: node>=18 (found v${NODE_MAJOR})"
    MISSING+=("node>=18")
  fi
fi

if [ "${#MISSING[@]}" -gt 0 ]; then
  echo "---"
  echo "Preflight FAILED. Missing: ${MISSING[*]}"
  exit 1
fi

echo "---"
echo "Preflight CLEAN. All prerequisites present."
exit 0
```

**Step 3.** Print the verdict to the user as a 🔹 / 🔸🔴 block:

- All present: `🔹 Preflight CLEAN. claude / node / git / jq / sqlite3 / bun all detected. Proceeding to Q0.5.`
- Anything missing: `🔸🔴 Preflight FAILED. Missing: <list>.` Then print the OS-specific install commands for each missing prerequisite, side-by-side Mac and Windows. Use this lookup:

| Prereq | Mac (Homebrew) | Windows (winget, run from PowerShell or Git Bash) | Linux (apt) |
|---|---|---|---|
| `claude` | Install from claude.com/claude-code | Install from claude.com/claude-code | Install from claude.com/claude-code |
| `node` (v18+) | `brew install node` | `winget install OpenJS.NodeJS` | `sudo apt install nodejs` |
| `git` | `brew install git` | `winget install Git.Git` | `sudo apt install git` |
| `jq` | `brew install jq` | `winget install jqlang.jq` | `sudo apt install jq` |
| `sqlite3` | `brew install sqlite3` | `winget install SQLite.SQLite` | `sudo apt install sqlite3` |
| `bun` | `curl -fsSL https://bun.sh/install \| bash` | `powershell -c "irm bun.sh/install.ps1 \| iex"` | `curl -fsSL https://bun.sh/install \| bash` |

**Step 4.** Refuse to advance. Tell the user: "Install the missing prerequisites with the commands above, then come back to this same Claude Code session and say `retry`. I will re-run the preflight probe and continue from this point." Wait for `retry` and re-run Step 2. Loop until preflight is clean. Do NOT ask Q0.5 or any later question until Step 2 prints `Preflight CLEAN`.

**Affects:** Whether the wizard proceeds at all. The OS value detected here also drives shell profile path, package manager defaults, hook line endings, and shell function format (bash/zsh vs PowerShell wrapper around Git Bash).

After Q0 passes, confirm the OS-derived defaults out loud:
- Mac: shell profile = `~/.zshrc`, package manager = `brew`
- Windows: shell profile = PowerShell `$PROFILE` AND Git Bash `~/.bashrc`. Package manager = `winget`. Hooks run via Git Bash (shipped with Git for Windows).
- Linux: shell profile = `~/.bashrc`, package manager = `apt`

Then continue to Q0.5.

---

### Q0.5: Pick your mode

Show both modes' contents in detail, THEN ask. The user cannot pick blind. This question's answer drives Q16-Q19 gating, the SETUP-CHECKLIST advanced-mode rows, and the healthcheck command's failure-vs-warn behaviour.

Tell the user:

> You have two install paths. Read both before you pick.
>
> **Simple mode** (default - get running fast)
>
> Includes:
> - Orchestrator (your AI itself, named at the next question)
> - Specialist crew (9 specialists - engineering, research, growth, social, infra, writing, trading, business, human dynamics)
> - Markdown memory system (memory/*.md, semantic-grep is enough at this scale)
> - Telegram channel (control the system from your phone)
> - NotebookLM Brain integration (optional cross-session search via Google's NotebookLM)
> - Session cron + compaction defence
> - Basic safety gate (blocks rm -rf, DROP TABLE, force push, sudo)
>
> Setup time: ~20 minutes.
> Idle RAM: ~500 MB.
> Disk: ~200 MB.
> Monthly cost: $0 on top of your Claude Max subscription.
>
> **Advanced mode** (everything Simple has, plus four extensions)
>
> Adds:
> - **E1 Semantic memory** - Ollama runs Nomic-embed locally + sqlite-vec stores 768-dim vectors for every memory chunk. Lets you ask "find the rule about timezones" without remembering the file name. ~10 min extra install. Free.
> - **E3 Agent Teams + channel.md whiteboard** - multiple agents share a live append-only markdown whiteboard so they don't duplicate work or step on each other. ~5 min extra install. Free.
> - **E4 Observability audit layer** - PostToolUse hook writes one JSON line per tool call to `data/audit/YYYY-MM-DD.jsonl`. Live viewer + history search + 30-day archive retention. ~5 min extra install. Free.
> - **E5 Hardened safety gate** - hard-blocks force-push to main/master/production/release/develop (cannot be approved through the hook), fixes word-boundary `rm` false-positives (no more breaking on `format`), blocks history-rewrites (`filter-branch`, `reflog expire`). ~5 min extra install. Free.
>
> Setup time: ~45-60 minutes total.
> Idle RAM: ~1.5 GB.
> Disk: ~2-3 GB.
> Monthly cost: $0 on top of your Claude Max subscription.
>
> **Recommendation:** install Simple first. Use it for a week. Add extensions one by one as you feel the pain points they solve. You can upgrade any time with `bash scripts/install-blueprint.sh --add E<N>`.
>
> 1. **Simple** (recommended)
> 2. **Advanced** (full stack)

**Valid answers:** Simple, Advanced (or 1, 2)
**Default:** Simple.
**Affects:** Whether the wizard asks Q16-Q19 (only asked in Advanced mode), what the SETUP-CHECKLIST verifies (advanced-mode rows are gated on this answer), how the `healthcheck` command treats missing optional components (warn in Simple, fail in Advanced).

**Persist the choice immediately.** After the user answers, write `data/runtime/install-mode.json` with mode 0600 perms. Downstream questions and post-install scripts read this file:

```bash
mkdir -p data/runtime
cat > data/runtime/install-mode.json <<EOF
{
  "mode": "{{install_mode}}",
  "decided_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
chmod 0600 data/runtime/install-mode.json
```

Windows note: on Git Bash, the `chmod 0600` works against the NTFS ACL via Git's POSIX shim. From plain PowerShell the equivalent is `icacls data\runtime\install-mode.json /inheritance:r /grant:r "$env:USERNAME:(R,W)"` - use only if the user is on PowerShell rather than Git Bash.

Store the answer as `{{install_mode}}` (`simple` or `advanced`).

---

### Q1: Name your orchestrator

Ask:
> What would you like to name your orchestrator? This is your AI assistant's identity -- the name it uses when talking to you, the name in the database, the name in every config file. Pick something you want to see every day.
>
> Examples: Cortana, Jarvis, Friday, Atlas, Nova, Sage, or anything you like.

**Valid answers:** Any string. No restrictions.
**Default:** None -- this must be chosen.
**Affects:** Every file in the system. The orchestrator name appears in CLAUDE.md, the database filename, shell launch commands, agent configs, help text, team text, and all scripts. This is the single most important variable.

---

### Q2: (folded into Q0)

Q2 in v29 was "Operating system" - the OS detect now happens silently inside Q0 Step 1 (single `uname -s` probe) because the preflight needs that value to print the right install commands. The wizard skips this slot. All later question numbers stay the same as v29 to keep the v29-to-v30 upgrade path mechanical.

**Note for the wizard:** if you previously generated a v29 install you will see a `Q2` slot - silently skip it. Q0 is the new home for OS detection.

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

Tell the user. The numbered list below is identical on Mac and Windows because Telegram's apps are visually identical across platforms - the only difference is which OS the user is reading this from in their Claude Code terminal.

> Let's create your Telegram bot. Eight steps, two minutes. Do this on your phone for the smoothest path - the desktop Telegram app works too, but the search box and tap targets are bigger on mobile.
>
> **Step 1.** Open the **Telegram** app on your phone (or telegram.org/desktop if you don't have the app).
>
> **Step 2.** Tap the **search icon** at the top of the chat list. Type `@BotFather` (the leading `@` is optional - both work). The first result with the blue verification checkmark is the official one. Tap it.
>
> **Step 3.** You'll land on BotFather's chat screen. Tap **Start** at the bottom of the screen. BotFather replies with a list of slash-commands.
>
> **Step 4.** Type `/newbot` as your message and send it. BotFather replies "Alright, a new bot. How are we going to call it?"
>
> **Step 5.** Send a **display name** - this is what shows in Telegram chats. The orchestrator's name works perfectly: send `{{orchestrator_name}}`. (You can pick anything; this is just the label.)
>
> **Step 6.** BotFather replies "Good. Now let's choose a username for your bot." Send a **username ending in `bot`**. Try `{{orchestrator_name_lower}}_bot` first - if it's taken, BotFather will say so and you can try `{{orchestrator_name_lower}}bot` or `my_{{orchestrator_name_lower}}_bot`. Lowercase, underscores allowed, must end in `bot`.
>
> **Step 7.** BotFather replies "Done! Congratulations on your new bot." and includes a line that starts with `Use this token to access the HTTP API:` followed by a long string like `7123456789:AAHxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`. **Long-press (mobile) or triple-click (desktop) the token to select it, then copy.**
>
> **Step 8.** Come back to **this Claude Code chat** (the same window where you typed the install command - NOT into Telegram, NOT into a separate terminal). Paste the token as your next message. I'll save it to `data/runtime/telegram.json` (mode 0600, gitignored, never committed) and wire the rest of the install.
>
> **A word on safety.** This token is like a password for your bot. Anyone who has it can read every message your bot receives and send messages as your bot. Treat it like a password. Never paste it into a screenshot, never share it in a public chat or repo, never email it. If you think it leaked, go back to @BotFather and send `/revoke` to kill the old token, then `/token` for a fresh one.

After they paste the token, store it as `{{telegram_token}}`.

Then tell them:
> 🔹 Token saved. I'll install the Telegram plugin during setup. After setup completes you'll send a message from your phone and {{orchestrator_name}} will reply.
>
> **Important:** the very first message from your phone won't get a reply until you approve the pairing in your Claude Code terminal. This is a one-time security step that prevents random people from messaging your bot. The wizard runs `/telegram:access` for you at the end of setup, so you'll see the prompt naturally.

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
> **Solo Dev** (2 specialists, 3 agents total) -- lean and fast
> - Orchestrator (that's {{orchestrator_name}})
> - Engineer -- code, architecture, debugging, reviews
> - Researcher -- analysis, market research, tech evaluation
>
> **Full Team** (9 specialists, 10 agents total) -- covers everything
> - Orchestrator
> - Engineer -- code, architecture, debugging
> - Researcher -- analysis, market research, intel
> - Growth -- ASO, launch playbooks, paid + organic strategy, brand positioning
> - Social -- platform-tactical content for TikTok / IG / X / YouTube / Reddit, algorithm play, viral hooks
> - DevOps -- deploy, CI/CD, infra, monitoring
> - Writer -- blog posts, docs, emails, presentations
> - Business -- revenue, pricing, partnerships, contracts
> - Trading -- strategies, backtesting, portfolio, markets
> - Human dynamics -- negotiation, persuasion, networking, cold outreach
>
> **Dev Team** (8 specialists, 9 agents total) -- built for software shops
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
- Researcher: "Rose, Scout, Sage, Aria"
- Marketing: "Natalie, Harper, Blaze, Zara"
- DevOps: "Marco, Bolt, Flux, Sigma"
- Writer: "Isabella, Pen, Quinn, Muse"
- Business: "Elena, Sterling, Blake, Morgan"
- Trading: "Warren, Quant, Ledger, Apex"
- Lead Engineer: "Kai, Chief, Principal, Arch"
- Frontend: "Pixel, React, Vue, Canvas"
- Backend: "Core, Node, Rust, Stack"
- QA: "Test, Guard, Proof, Check"
- Security: "Shield, Vault, Sentinel, Cipher"
- Technical Writer: "Docs, Scribe, Quill, Ink"

You can ask them to name multiple agents at once to save time:
> Let's name your agents. Give me names for each role (or hit enter for the suggestion):
> - Engineer (suggestion: Kai):
> - Researcher (suggestion: Rose):
> [etc.]

Store the complete roster as `{{agents}}` -- a list of `{role, name}` pairs.

---

### Q7.5: Agent spawn aggressiveness

Decides how many agents your orchestrator dispatches in parallel for medium-and-larger tasks. This is the "how conservative do you want me to be with tokens" knob.

Ask:
> One more thing on the team setup, how aggressive should parallel agent dispatch be?
>
> **Conservative (1 at a time)** -- the orchestrator runs work sequentially, one specialist at a time. Easiest on a Pro or Max 5x plan. Slower wall-clock but predictable token usage. Pick this if you want to feel each token before it's spent.
>
> **Balanced (up to 3 in parallel)** -- the orchestrator runs 2-3 specialists in parallel when work decomposes cleanly (e.g. researcher + writer + engineer on the same project). Comfortable on Max 5x, safe on Max 20x. Good default.
>
> **Aggressive (up to 16 in parallel)** -- the orchestrator fans out to 5-16 specialists for big build sprints. Requires Max 20x to be comfortable; even then, watch the 5-hour rolling rate limit if you're running 8+ heavy-research or build agents at once. Pick this if you want maximum throughput and you've used multi-agent work before.
>
> You can change this any time later by editing the line in CLAUDE.md. The default is **Balanced** if you don't pick.

Store the answer as `{{spawn_aggressiveness}}` with values `conservative` / `balanced` / `aggressive`. The wizard's CLAUDE.md generation step uses this to bake the right orchestration habits into the file:

- **Conservative**: writes "Run work sequentially, one specialist at a time. Spawn parallel agents only when explicit user request." into the orchestration section.
- **Balanced**: writes "Default to 2-3 parallel specialists when work decomposes cleanly. Fan out further only on explicit user request or for sprints clearly bigger than 3 lanes."
- **Aggressive**: writes "Default to aggressive parallel dispatch. Spawn 5-16 specialists for big sprints. Use Agent Teams channel pattern when work has cross-talk. Watch the 5-hour rolling rate limit on Max 20x."

If the user is on Pro or Max 5x (Q5 answer) and picks Aggressive, warn them once:
> Heads up: you're on {{plan_name}}. Aggressive parallel dispatch can chew through your 5-hour window fast if you spawn 8+ heavy agents. You can still pick it, but Balanced is usually the right call below Max 20x. Confirm Aggressive or want to switch to Balanced?

If they confirm Aggressive on a smaller plan, respect it. Don't second-guess twice.

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

**Before this question, show the user the three memory layers so they can pick what they actually need.**

> Quick context. Your agent has up to three memory layers. Most users only need the first.
>
> 1. **Local memory files**: always on, free. Your agent's notebook of facts, decisions, project state. Lives in `memory/` as plain markdown.
> 2. **Knowledge library**: optional folder for hand-written reference docs your agent should know (handbooks, playbooks, internal wiki).
> 3. **AI Brain (NotebookLM)**: optional Google service for cross-session "have we discussed this before" questions across a long archive.
>
> Pick #2 if you have specific reference docs you want your agent to know. Pick #3 only if you do enough work to want a long-term searchable archive. Otherwise just keep #1 (the default) and skip the next two questions.

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
> After setup, you'll need to install and authenticate the NotebookLM CLI. Three commands.
>
> **Step 1.** In your terminal, install the CLI.
>   - Mac/Linux: `pip install 'notebooklm-py[browser]'`
>   - Windows (PowerShell or Git Bash): `pip install notebooklm-py[browser]`
>
> If you see "command not found: pip" or similar, install Python first from python.org and try again. Once `pip install` finishes, the `notebooklm` command is on your PATH.
>
> **Step 2.** Log in. Run `notebooklm login` and follow the browser window that opens. Sign in with the Google account you want the Brain to live under.
>
> **Step 3.** Create your notebook: `notebooklm create "{{orchestrator_name}} Brain"`. It prints a notebook ID. Copy it.
>
> **Step 4.** Paste the notebook ID as your next message in this chat (the same chat where you ran the install command). I'll write it to `data/runtime/brain.json` and wire up the `brain` command.
>
> We can do this now or after the rest of setup, your call.

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

**After the install commands run, the wizard must pause and walk the user through a session reload.** Plugins (including the Telegram plugin) and any hook updates do not take effect in the current Claude session. The new tools, slash commands, and hooks only register on next launch.

The wizard must capture the current session id BEFORE prompting reload, so the user can come back to the same conversation. Run:

```bash
SESSION_ID=$(claude session current 2>/dev/null || echo "")
```

(If `claude session current` is unavailable on the user's Claude Code version, fall back to: print to chat "Your session ID is in the top-right corner of the Claude Code window, copy it before you close.")

Then present the user with the exact resume sequence:

> Heads up, this is the one step you have to do yourself. Plugins and hooks just installed do not become active in the current session. You need to **close this Claude Code session, open a fresh terminal, and resume the same conversation** so we can continue setup with the new tools active.
>
> Here is exactly how:
>
> **1. Exit this session cleanly.** Press `Ctrl+C` twice, or type `/exit`, or close the terminal window.
>
> **2. Open a fresh terminal.** Same kind you opened to start the install (Terminal on Mac, PowerShell on Windows).
>
> **3. Resume this exact session.** Run one of these (whichever lands sooner):
>
> ```bash
> # Option A, your agent's launch alias (if it was created in earlier steps)
> {{orchestrator_lower}}-resume
> ```
>
> ```bash
> # Option B, direct Claude Code resume flag
> cd {{install_dir}} && claude --resume {{session_id}}
> ```
>
> ```bash
> # Option C, latest-session shortcut
> cd {{install_dir}} && claude --continue
> ```
>
> **4. Tell me "resumed".** I'll verify the plugin loaded + continue the install.

If the user reports the resume failed (alias not found, session id stale), guide the recovery STEP BY STEP. Do not throw three options at them and walk away. Walk them through one at a time.

**Step 1: try sourcing the shell profile**

> First, the alias is probably installed but your shell config did not pick it up in the new terminal. Try this:
>
> **Mac**: `source ~/.zshrc`
> **Windows PowerShell**: `. $PROFILE`
> **Linux (bash)**: `source ~/.bashrc`
>
> Then retry: `{{orchestrator_lower}}-resume`
>
> Did the alias work this time? (yes / no)

**Step 2 (if step 1 still failed): use the regular Claude resume command as the fallback**

> No problem. Use the regular Claude command instead, this brings you back to the same session AND keeps the install going under the same permissions:
>
> ```bash
> cd {{install_dir}} && claude --dangerously-skip-permissions --resume {{session_id}}
> ```
>
> Paste that into the fresh terminal. You should land back in the same conversation we were having.
>
> Once you are back in, tell me "alias didn't work" and I will fix it as the next step of the install. Don't worry about it now, the install continues and the alias gets re-wired before we finish.

**Step 3 (if even step 2 fails because the session id is stale)**

> The session expired or got cleaned up. Last resort, run a fresh session that picks up the most recent state:
>
> ```bash
> cd {{install_dir}} && claude --dangerously-skip-permissions --continue
> ```
>
> Or if even that does not work, start a fully fresh session:
>
> ```bash
> cd {{install_dir}} && claude --dangerously-skip-permissions
> ```
>
> When you are back in, tell me "starting fresh, install was at Q14 plugins". I will re-read your install state from `data/runtime/install-state.json` and pick up exactly where we left off.

**After the user successfully resumes (any path), the FIRST thing the wizard does is verify**:

1. The plugin actually loaded (check with `claude plugin list` or equivalent inside the session)
2. The alias actually works in their fresh shell (run the alias name as a sanity check, if it fails again, fix the alias by inspecting their shell rc file, identifying which one their terminal actually sources, writing the alias line into the right file)
3. The Telegram plugin specifically can reach the bot (send a test message from the user's phone and confirm it shows in the session, OR `curl -s "https://api.telegram.org/bot<TOKEN>/getMe"` returns `ok: true` for the token in `data/runtime/telegram.json`)

Only when all three pass does the wizard move on to Q15. If any verification fails, fix it before continuing. This is the hand-holding step where "fix the alias issue" lives, so the user does not have to debug their own shell config.

Store the session capture as `{{session_id}}` (for the prompt template above) and `{{resume_command}}` (the alias if available, else the `--resume` line).

**Affects:** Whether the wizard pauses for a session reload after Q14, whether the SETUP-CHECKLIST.md tells the user how to resume cleanly, whether the install resumes the same conversation or restarts fresh.

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
> - **Folder path:** (absolute path - see below - or "create" to make a new folder under your home directory)
> - **One-line description:** (what does this project do?)
> - **Tech stack:** (e.g., "Next.js, TypeScript, Postgres", "Python, FastAPI, Redis")

**How to grab an absolute path if you've never done it:**
- **Mac:** open the folder in Finder. Drag the folder onto Terminal - Terminal pastes the absolute path.
- **Windows:** open the folder in File Explorer. Hold Shift and right-click the folder, choose "Copy as path". Paste here.
- **Linux:** in a terminal, `cd` into the folder and run `pwd` - it prints the absolute path.
- Or just type "create" and the wizard makes a fresh folder under `~/Documents/<project-name>` for you.

Store as `{{first_project}}` with all four fields.

**Valid answers for "Register or Skip":** Register, Skip (or 1, 2)
**Default:** Skip.
**Affects:** Whether register-project.sh runs during setup, whether a project entry appears in docs/projects.md.

---


## Q16-Q19: Power-user extensions (Advanced mode only)

**Gate:** ask Q16-Q19 only if `{{install_mode}}` (set at Q0.5) is `advanced`. If `{{install_mode}}` is `simple`, skip the entire block - tell the user "Simple mode skips Q16-Q19. You can add any extension later with `bash scripts/install-blueprint.sh --add E<N>`." and proceed straight to Generation Order.

If Advanced, walk through each extension, explain what it does, the cost / time / tradeoffs, and ask whether to install now or later.

Note: v29 numbered these Q16-Q20 with Q17 reserved for the now-removed Graphiti extension. v30 dropped Q17 entirely and renumbered.

For each extension below, use the full "explain before asking" pattern - show the user **what it is**, **how it works**, **what it costs**, **what it requires**, and **who benefits** before taking a yes/no.

---

### Q16: E1 - Semantic memory (sqlite-vec + Nomic-embed)

Ask:
> Your memory system is a pile of markdown files. To find "have we hit this before?" you'd grep for exact strings - which fails on paraphrases, misses synonyms, and misses context. Semantic memory solves that.
>
> **What you get:** a local vector-search index over every memory file. Query it like: `bash scripts/memory-search.sh "alpha channel icon issue"` - it returns the top 5 matching memory chunks with file paths + similarity scores. 95 ms median latency.
>
> **How it works:** Ollama runs Nomic-embed-text (a 137M-parameter embedding model) locally on your Mac. Every memory chunk gets embedded into a 768-dimensional vector, stored in a tiny sqlite-vec database. Search queries get embedded the same way and nearest-neighbour matched.
>
> **What it costs:**
> - **Money:** £0. No API calls. Weights are free, compute is local.
> - **Disk:** ~300 MB (Nomic-embed model) + ~10-15 MB (vector DB for a typical 1000-1500 chunk corpus; mature installs after a few weeks of use).
> - **RAM:** ~500 MB when Ollama is active, 0 when idle (Ollama auto-unloads after 5 min).
> - **Install time:** ~10 minutes.
>
> **Pain it solves:** "I know we decided something about X, but I can't remember exactly what I called it in the memory file." Grep can't help you there; this can.
>
> 1. **Install now** - I'll walk you through Ollama + sqlite-vec + the first embed
> 2. **Skip** - add later with `bash scripts/install-blueprint.sh --add E1`

**Valid answers:** Install, Skip (or 1, 2)
**Default:** Install (if Advanced mode - sqlite-vec is the single biggest daily-use improvement over base Core).
**Affects:** Whether Ollama is installed, whether `data/vector-memory.db` exists, whether the post-commit embed hook is live, whether `bash scripts/memory-search.sh` is usable.

---

### Q17: E3 - Agent Teams + channel.md whiteboard

Ask:
> When two agents work on the same project in parallel, each one's decisions are invisible to the other until both report back. Agent Teams + the channel.md pattern fix that - agents share a live markdown whiteboard and can send peer-to-peer messages.
>
> **What you get:**
> - `TeamCreate`, `SendMessage`, `TeamDelete` tools for live agent-to-agent messaging (Claude Code 2.1.32+)
> - A `data/agent-channels/<task>.md` shared whiteboard where every agent Edit-appends progress, decisions, blockers. The orchestrator re-reads between its own tool calls to resolve cross-agent state.
>
> **How it works:** A single env flag (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) enables the team primitives. The whiteboard pattern is append-only markdown. When the task ships, archive the channel to `data/agent-channels/archive/YYYY-MM/`.
>
> **What it costs:** £0. Just a feature flag and a directory.
>
> **Install time:** ~5 minutes.
>
> **Pain it solves:** "I sent Kai to build the API and Marco to deploy it. Marco needs Kai's schema decisions but they don't know about each other." With Teams, they share context live.
>
> **Experimental:** this is an experimental Claude Code feature. Worth trying. If it's unstable, turn the flag off and the whiteboard still works as a plain-file pattern.
>
> 1. **Install now** - flip the flag + create the directory
> 2. **Skip** - default sequential agent spawning, no shared context

**Valid answers:** Install, Skip (or 1, 2)
**Default:** Install (low cost, high ceiling).
**Affects:** `.claude/settings.json` env block, `data/agent-channels/` directory creation, whether CLAUDE.md mentions the channel.md pattern in orchestration habits.

---

### Q18: E4 - Observability audit layer

Ask:
> Every tool call your agents make can be logged to a local audit file, so when a background agent runs for 10 minutes you can read what it actually did without tailing a transcript.
>
> **What you get:**
> - A PostToolUse hook that writes one JSON line per tool call to `data/audit/YYYY-MM-DD.jsonl` (async, non-blocking)
> - `bash scripts/{{orchestrator_lower}}-live.sh --follow` - a pretty-printed live viewer with filters (by tool, project, day, failed-only)
> - `bash scripts/audit-archive.sh` - retention (gzip-archives logs >=30 days old into `data/audit/archive/YYYY/MM.jsonl.gz`, committed to git so the forensic trail is permanent)
> - `bash scripts/history.sh <query>` - unified search across Telegram conversation history, audit log (live + archived), git commit log, and memory markdown
>
> **How it works:** a Bash hook under `.claude/hooks/audit-log-hook.sh` receives the tool payload on stdin after each tool call, extracts name / input / output / success, strips secret patterns, appends to today's JSONL file.
>
> **What it costs:** £0. Pure local Bash.
>
> **Privacy:** audit logs are gitignored (never leave your machine). Regex scrubs common secret shapes (api_key, token, password, bearer, authorization) before write. Input and output summaries capped at 240 chars.
>
> **Install time:** ~5 minutes.
>
> **Pain it solves:** "Kai said he committed the fix but I can't see what he did." Now you can - live tail shows every bash, every edit, every Agent spawn in real time.
>
> 1. **Install now** - copy the hook + scripts, wire into settings.json
> 2. **Skip** - no per-tool-call audit trail

**Valid answers:** Install, Skip (or 1, 2)
**Default:** Install (paid for itself within hours of install during our own v29 dogfooding).
**Affects:** `.claude/hooks/audit-log-hook.sh` creation, PostToolUse hook entry in settings.json, `data/audit/` gitignore entry.

---

### Q19: E5 - Hardened safety gate

Ask:
> The Core safety gate (installed by default) blocks `rm`, `DROP TABLE`, `git push --force`, `sudo`, etc. The Hardened gate adds:
>
> - **Hard-blocks on force-push to `main`/`master`/`production`/`prod`/`release`/`develop`** - cannot be approved through the hook even with your confirmation. Requires manual Terminal if you really need it.
> - **Hard-blocks on history-rewriting ops:** `git filter-branch`, `filter-repo`, `reflog expire`, `gc --prune=now`, `update-ref -d`.
> - **Word-boundary regex on `rm`** - fixes false-positives where the Core gate blocks harmless commands like `echo "format..."` because "format" contains "rm" substring.
> - **Wider git coverage:** blocks `rebase -i`, `--onto`, `commit --amend`, `checkout -- .`, `restore .`, `stash drop`, `stash clear`, `worktree remove --force`, `branch -D`.
>
> **What you get:** protection against the force-push-instead-of-commit class of incident that destroys shared git history. Specifically this blueprint was hardened after a real-world incident where the orchestrator force-pushed by mistake and overwrote commits.
>
> **What it costs:** £0. Same Bash hook, tighter rules. Zero token usage.
>
> **Install time:** ~5 minutes.
>
> **Test suite:** 48 cases in `/tmp/safety_test.sh` (regex false-positives + every destructive git op). Validated on install.
>
> 1. **Install now** - replaces the Core safety gate with the hardened version (backup is kept at `.claude/hooks/safety-gate.sh.core-backup`)
> 2. **Skip** - keep the Core gate

**Valid answers:** Install, Skip (or 1, 2)
**Default:** Install in Advanced mode (the Core gate will not catch a determined mistake - hardened is what you want for any real repo).
**Affects:** `.claude/hooks/safety-gate.sh` overwrite (with backup), same for the global gate at `~/.claude/hooks/safety-gate.sh`.

---

After Q16-Q19, echo back the extension choices and update `.{{orchestrator_lower}}-blueprint-version` accordingly:

```yaml
blueprint_version: v31
installed: <now>
mode: <simple|advanced>
extensions:
  E1_sqlite_vec: <true|false>
  E2_graphiti: false   # deprecated as of v30 - never set to true on a fresh install
  E3_agent_teams: <true|false>
  E4_observability: <true|false>
  E5_hardened_safety: <true|false>
  E6_amazing_memory: <true|false>
```

---

## Generation Order

After all questions are answered, generate files in this order. Each file comes from a template in `blueprints/xantham-templates-v31.md`. **Track success of every step.** If any numbered step below fails, capture the error, do NOT continue to the next numbered step, and emit `DIAGNOSTIC-CHECKLIST.md` instead of `SETUP-CHECKLIST.md` at the end (see Step 18).

1. **Create directory structure:**
   ```
   {{project_path}}/
   ├── .claude/
   │   ├── settings.json
   │   ├── hooks/
   │   │   ├── safety-gate.sh
   │   │   ├── log-telegram-hook.sh      (only if messaging=telegram)
   │   │   └── audit-log-hook.sh         (only if security=enterprise OR install_mode=advanced+E4)
   │   ├── skills/                       (skill bodies generated in Step 6)
   │   └── agents/
   │       └── <agent-name>.md           (one per selected agent)
   ├── scripts/
   │   ├── preflight.sh                  (already generated by Q0)
   │   ├── maintain.sh
   │   ├── healthcheck.sh
   │   ├── load-context.sh
   │   ├── commit-watcher.sh
   │   ├── log-correction.sh
   │   ├── history.sh
   │   ├── register-project.sh
   │   ├── uninstall.sh
   │   ├── check-blueprint-drift.sh
   │   ├── blueprint-drift-check.sh
   │   ├── sync-project-memories.sh
   │   ├── pre-compaction-sync.sh
   │   ├── post-compaction-reload.sh
   │   ├── session-end-sync.sh
   │   ├── log-telegram.sh              (only if messaging=telegram)
   │   └── batch-sync.sh
   ├── data/
   │   ├── help-text.md
   │   ├── team-text.md
   │   ├── runtime/install-mode.json    (already written by Q0.5)
   │   └── telegram-history/            (only if messaging=telegram)
   ├── docs/
   │   └── projects.md
   ├── memory/                           (starter seeds populated in Step 7)
   ├── Library/                          (only if library=yes)
   │   └── CLAUDE.md
   └── CLAUDE.md
   ```

   **Step 1.5 -- write `.gitignore` BEFORE any other generation step.** Use the body in **`blueprints/xantham-templates-v31.md` § Template: .gitignore**. This file must exist at `{{project_path}}/.gitignore` before Step 2 creates the sqlite DB or any subsequent step touches `data/approved.txt`, `data/runtime/`, `data/vector-memory.db`, or `logs/safety-gate.log`. Writing the gitignore here closes a real first-push leak window: the safety-gate template comment at line 497 in the templates file (`# NOTE: this file MUST be in .gitignore`) had no companion gitignore until now. Fixes Marco audit CS3.

2. **Create the SQLite database:** run `setup-db.sh` which creates `data/{{db_name}}` with the full schema (memories table with FTS5, corrections table, patterns table).

3. **Generate CLAUDE.md** from the master template in **`blueprints/xantham-templates-v31.md` § Template: CLAUDE.md**. This is the largest file - it defines the orchestrator's identity, core loop, routing table, commands, agent spawning rules, safety rules, and everything else. Substitute every `{{placeholder}}` (orchestrator name, agent roster, plan, security tier, mode, etc.). Honour both kinds of conditional in the template: `<!-- IF plan=... -->` blocks (driven by `{{plan}}` for the plan-label header) AND `<!-- IF spawn_aggressiveness=... -->` blocks (driven by `{{spawn_aggressiveness}}` from Q7.5 for the agent-spawning-rules section). The two conditionals are intentionally independent so a Max-20x user who picked Conservative gets the right rules (sequential dispatch) instead of inheriting plan-derived aggressive defaults. Also substitute the derived `{{spawn_aggressiveness_block}}` literal text inside whichever spawn-rules block ends up active, and the derived `{{context_warning_threshold}}` + `{{plan_name}}` values in the pre-compaction sync section.

4. **Generate .claude/settings.json** from **`blueprints/xantham-templates-v31.md` § Template: .claude/settings.json (Standard Security)** OR **`blueprints/xantham-templates-v31.md` § Template: .claude/settings.json (Enterprise Security)** depending on `{{security}}`.

   **Step 4 backup + sidecar (sentinel-gating, fixes Marco audit CG5).** If `~/.claude/settings.json` ALREADY EXISTS on the host (another Claude Code project on the same machine), copy it to `~/.claude/settings.json.pre-install` BEFORE writing the new one. Do NOT overwrite an existing `.pre-install` (preserve any older install's backup). Then `touch ~/.claude/.settings.json.xantham-managed` (mode `0644`) AFTER writing the new settings.json. The sidecar marker is what `scripts/uninstall.sh` reads to know it can safely jq-strip the `statusLine` block when the .pre-install backup is missing. Without the sidecar, uninstall refuses to touch settings.json. Mac/Linux: standard `cp` + `touch`. Windows (PowerShell): `Copy-Item "$env:USERPROFILE\.claude\settings.json" "$env:USERPROFILE\.claude\settings.json.pre-install"` + `New-Item -Path "$env:USERPROFILE\.claude\.settings.json.xantham-managed" -ItemType File`.

5. **Generate hook scripts.** For each hook listed below, look up the matching **`## Template: .claude/hooks/<name>.sh`** section in `blueprints/xantham-templates-v31.md` and write the literal body to `.claude/hooks/<name>.sh`, substituting placeholders. Hook list: `safety-gate.sh` (always), `log-telegram-hook.sh` (only if `{{messaging}}`=telegram), `audit-log-hook.sh` (only if `{{security}}`=enterprise OR Advanced mode with E4 selected at Q18), `voice-lint.sh` (always; the de-personalised reply-quality lint), `stop-composer.sh` (always), `stop-verify-contract.sh` (always). After writing, `chmod +x` each. Mac/Linux: `chmod +x .claude/hooks/*.sh`. Windows (Git Bash): `chmod +x .claude/hooks/*.sh` works the same; on plain PowerShell the chmod is unnecessary because Git Bash interprets the shebang directly.

6. **Generate skill bodies.** For each skill in **`blueprints/xantham-templates-v31.md` § Skill Templates**, write the literal body to `.claude/skills/<skill-name>/SKILL.md`. Substitute `{{orchestrator_name}}` / `{{orchestrator_lower}}` placeholders. Skills to generate: `<orchestrator_lower>-sync`, `<orchestrator_lower>-maintenance`, `<orchestrator_lower>-orchestration`, `<orchestrator_lower>-brain`, `<orchestrator_lower>-safety`, `<orchestrator_lower>-observability`, `<orchestrator_lower>-blueprint-updates`, plus any others in the Skill Templates section. <!-- TODO: cross-reference Kai-1's skill template section once it lands - skill list above is the contract; bodies come from blueprints/xantham-templates-v31.md. -->

7. **Generate script bodies.** Walk every script-bearing section in `blueprints/xantham-templates-v31.md` and write each literal body to its indicated path under `scripts/`. Script bodies live in FOUR distinct sections of the templates appendix and the wizard MUST pull from all four, not just the first one:

   1. **`## Script Templates`** (the always-installed core: healthcheck, verify-runtime-perms, load-context, commit-watcher, log-correction, history, register-project, pre-compaction-sync, post-compaction-reload, recent-telegram, redact-secrets, memory-search, embed-memories.py, check-memory-freshness, session-end-sync, update-handoff, reflect, promote-correction, log-telegram, batch-sync, sync-project-memories, check-blueprint-drift, telegram-signal, uninstall).
   2. **`## Common Templates (referenced earlier in this blueprint)`** (setup-db.sh, sync-safety-gates.sh, restore-memory-symlinks.sh). Always installed.
   3. **`## E1 - sqlite-vec + Nomic-embed`** (embed-memories.sh, memory-search.sh, install-git-hooks.sh, scripts/hooks/post-commit). Install only if `{{install_mode}}=advanced` AND E1 was selected at Q18.
   4. **`## E4 - Observability`** ({{orchestrator_lower}}-live.sh, audit-archive.sh). Install only if `{{install_mode}}=advanced` AND E4 was selected at Q18.

   Additional cognitive-memory + auth scripts live as their own top-level `## Template: scripts/<name>.sh` headings further down (active-recall, active-recall-entities, dream, dream/phase1-orient, dream/phase2-gather, dream/phase3-consolidate, dream/phase4-prune, update-profile, roll-episodic, weekly-memory-compile, monthly-memory-retrospective, auth-fallback, check-auth-status, export-blueprint, install-launchd-wrappers, regenerate-setup-checklist). Walk those too.

   After writing, `chmod +x` shell scripts. Mac/Linux/Git Bash: `chmod +x scripts/*.sh scripts/**/*.sh`. Plain PowerShell: skip the chmod (Git Bash handles execution).

   Verification: after generating all scripts, list `scripts/` and confirm the four-section contract is honoured. A missing `setup-db.sh` means section 2 was skipped. A missing `install-git-hooks.sh` means section 3 was skipped. A missing `audit-archive.sh` (when E4 selected) means section 4 was skipped.

8. **Generate starter memory seeds.** For each seed in **`blueprints/xantham-templates-v31.md` § Starter Memory Seeds**, write the literal body to its indicated path under `memory/`. Then write `memory/MEMORY.md` as the index pointing at every seed. <!-- TODO: cross-reference Isabella's starter memory seeds section once it lands - seed list comes from blueprints/xantham-templates-v31.md. -->

9. **Generate agent configs** in `.claude/agents/` - one per selected agent, from **`blueprints/xantham-templates-v31.md` § Template: Agent Config**.

10. **Create agent + orchestrator memory directories INSIDE the repo**, then symlink Claude Code's expected paths to them. Canonical files live in the repo so `git commit` backs them up and cloud routines see them:
    ```bash
    # Mac / Linux / Git Bash on Windows
    mkdir -p {{project_root}}/memory
    mkdir -p {{project_root}}/agent-memory/<agent-name-lower>  # for each agent
    PROJECT_SLUG=$(echo "{{project_root}}" | sed 's|/|-|g')
    mkdir -p ~/.claude/projects/$PROJECT_SLUG
    ln -s {{project_root}}/memory ~/.claude/projects/$PROJECT_SLUG/memory
    ln -s {{project_root}}/agent-memory ~/.claude/agent-memory
    ```
    ```powershell
    # Windows PowerShell - native equivalent (only if user is NOT using Git Bash for the install)
    New-Item -ItemType Directory -Force -Path "{{project_root}}\memory" | Out-Null
    foreach ($agent in $agents) {
      New-Item -ItemType Directory -Force -Path "{{project_root}}\agent-memory\$agent" | Out-Null
    }
    $projectSlug = ("{{project_root}}" -replace '\\','-' -replace ':','')
    New-Item -ItemType Directory -Force -Path "$HOME\.claude\projects\$projectSlug" | Out-Null
    New-Item -ItemType SymbolicLink -Path "$HOME\.claude\projects\$projectSlug\memory" -Target "{{project_root}}\memory"
    New-Item -ItemType SymbolicLink -Path "$HOME\.claude\agent-memory" -Target "{{project_root}}\agent-memory"
    # Note: SymbolicLink requires Developer Mode enabled or running PowerShell as Administrator on Windows.
    ```
    Also generate `scripts/restore-memory-symlinks.sh` so a fresh clone on a new machine can rebuild the symlinks in one command. The orchestrator repo MUST stay private - memory files contain personal and project context.

11. **Generate .mcp.json** if Telegram or any MCP servers were selected.

12. **Add shell launch functions** to the user's shell profile. Mac/Linux: append the bash/zsh functions from **`blueprints/xantham-templates-v31.md` § Template: Shell Launch Functions (Mac/Linux)** to `~/.zshrc` or `~/.bashrc`. Windows: append the PowerShell function from **`blueprints/xantham-templates-v31.md` § Template: Shell Launch Functions (Windows)** to `$PROFILE`.

13. **Generate data/help-text.md and data/team-text.md** from the agent roster.

14. **Generate docs/projects.md** template.

15. **Generate Library scaffold** if library=yes.

16. **Install Telegram plugin** if messaging=telegram (two-step CLI flow - there is no `claude plugin add` subcommand). Mac/Linux/Windows all use the same `claude plugin` CLI, so the commands are identical:
    ```
    claude plugin marketplace add claude-plugins-official
    claude plugin install telegram@claude-plugins-official
    ```
    Then configure with the token. After install, walk the user through the `/telegram:access` skill: it manages who can DM the bot. The user runs `/telegram:access` from their terminal to approve pairings, edit the allowlist, and set DM/group policy. Approvals never come from chat messages.

17. **Install selected plugins** (superpowers, document-skills, etc.):
    ```
    claude plugin marketplace add <marketplace-name>
    claude plugin install <plugin-name>@<marketplace-name>
    ```

18. **Register first project** if one was provided - run register-project.sh with the project details.

19. **Emit verification checklist - GATED on success of all previous steps.**

    If every numbered step 1-18 above completed without errors, emit `SETUP-CHECKLIST.md` from the template (see "What the wizard generates" section earlier). Tell the user: "Setup complete. Read SETUP-CHECKLIST.md and verify each item before your first real session."

    If any step failed, instead emit `DIAGNOSTIC-CHECKLIST.md` listing every failed step with: the step number, what was being attempted, the error captured, and a one-line "how to retry" suggestion. Tell the user: "🔸🔴 Setup partially failed at step <N>. I wrote DIAGNOSTIC-CHECKLIST.md instead of SETUP-CHECKLIST.md. Read it for what to fix. Resume by re-running the wizard and answering 'resume from step <N>' when it asks; do not restart from step 1 unless the diagnostic explicitly says to."

    Template skeleton for `DIAGNOSTIC-CHECKLIST.md`:

    ```markdown
    # Diagnostic checklist for {{orchestrator_name}}

    Setup did not complete cleanly. Below are the steps that failed.

    ## Failed steps

    ### Step {{step_number}}: {{step_title}}
    - **What it tried to do:** {{step_description}}
    - **Error captured:** `{{error_text}}`
    - **How to retry:** {{retry_hint}}

    [...one block per failed step...]

    ## Resume

    Re-run the install wizard. It will detect what already succeeded (via the directory structure + `data/runtime/install-mode.json`) and resume from the first unfinished step.
    ```

20. **Run post-setup validation** (only if Step 19 emitted SETUP-CHECKLIST.md, not DIAGNOSTIC-CHECKLIST.md). Validation steps are listed in the next section.

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

Team ({{agent_count}} specialists + orchestrator):
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

One Claude Code session. One CLAUDE.md. That is the system.

Claude Code starts in the project root and reads CLAUDE.md. The file declares who the orchestrator is, the agent roster, the routing table, the core loop, the safety rules, and the active command list. Agents are not separate processes. They are personas inside the same session, sharing the same context window and the same model. Routing to the engineer agent is a voice shift, not a network call.

**Components.** CLAUDE.md (one file, ~150 lines, loaded every turn). Memory directory `memory/` (flat markdown, one file per fact, indexed by `MEMORY.md`). SQLite at `data/audit.db` (logs, history, optional sqlite-vec embeddings). A handful of bash hooks under `.claude/hooks/`. Optionally a Telegram bot polling for inbound messages.

**Cost per turn.** Reading CLAUDE.md plus `MEMORY.md` plus the active project's CLAUDE.md is the fixed cost on every turn, around 8-12k tokens depending on which extensions are installed. Each routed agent reply spends its own context window. A parallel fan-out of 5 agents costs ~5x a single reply, not more, because the windows are independent.

**State across sessions.** Three places. Markdown under `memory/` for behavioural rules and project facts. `HANDOFF.md` per project for last-known state. `data/audit.db` for searchable history. Cold-start a session, the orchestrator reads the first two and queries the third on demand.

**Parallelism.** Sub-agents spawn via the Task tool. The Balanced default (recommended for most installers) runs 2-3 in parallel. Aggressive mode on Max 20x fans out up to 16, gated by the 5-hour rolling rate limit. Max 5x is comfortable at 2-3. Pro runs sequentially. Background work never blocks the main loop. The orchestrator acknowledges inbound, dispatches, and pings back when results land.

**Scaling.** Adding agents means adding entries to the routing table and `.claude/agents/<name>.md` config files. No infrastructure changes. A three-agent setup and a twelve-agent setup run identically.

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

A sibling sqlite-vec database at `data/vector-memory.db` indexes every markdown memory into dense embeddings (Nomic-embed via Ollama). The post-commit hook re-embeds changed files automatically - agents never write to the DB directly. Search via `bash scripts/memory-search.sh "<query>"`.

**Why markdown + vector instead of operational SQLite:**
- Markdown is diffable, git-tracked, survives DB corruption.
- Vector search returns semantic matches across all memory without FTS5 quoting gotchas.
- No parallel write path means no drift between "markdown reality" and "DB reality".

### How agents save memories

Agents save by writing a new `memory/<type>_<topic>.md` file (or updating an existing one) and committing. The post-commit hook takes care of embedding. Agents never run a `save` command - the filesystem is the API.

### Maintenance

The maintenance script (`scripts/maintain.sh`) runs on Monday sessions:
1. Check-memory-freshness sweep - flag any file past its `last_verified + ttl_days`.
2. Report MEMORY.md index sizes and warn if any index is over 200 lines.
3. Trigger the SLO canary probes (if enabled).

High-importance memories persist indefinitely. No auto-deletion - memory pruning is an explicit human decision.

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
- `git filter-branch` / `git filter-repo` - unrecoverable history rewrites
- `git reflog expire`, `git gc --prune=now`, `git gc --aggressive` - orphans commits permanently
- `git update-ref -d` - deletes refs
- **Force push to protected branches** (`main` / `master` / `production` / `prod` / `release` / `develop`) - any form of `--force`, `-f`, or `--force-with-lease`

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

`scripts/healthcheck.sh` runs a full system check:
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
{"pattern": "always checks forward test first on this project", "project": "MyProject", "count": 7, "first_seen": "2026-03-01", "last_seen": "2026-04-13"}
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

The orchestrator writes to `${TMPDIR:-/tmp}/{{orchestrator_name_lower}}-working-context.md` on every milestone (Mac/Linux: `/tmp`. Windows Git Bash users - set `TMPDIR=$LOCALAPPDATA/Temp` in `~/.bashrc` for a writable temp dir; the default `/tmp` under Git Bash points at `C:\Program Files\Git\tmp` which is read-only without admin):

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

Every registered project carries three docs: `CLAUDE.md` (stack + scripts), `HANDOFF.md` (last-known state), `FEATURES.md` (product reference). Sync keeps those current.

### Auto-sync triggers

Four conditions fire a sync without the user asking:

1. **Session end.** "bye", "done", "goodnight", or a long quiet stretch after a work block. Updates `HANDOFF.md` for every project touched in the session.
2. **Post-milestone.** Ship, deploy, fix landed: sync that project immediately.
3. **Context switch.** Leaving project A for project B: sync A first, before B fills the window.
4. **Greeting.** New session opening message names a project: pull its `HANDOFF.md` into context.

### Manual triggers

`sync <project>`, `sync all`, and `wrapup` all run the same cycle. The full command list lives in section 13. On Max 20x, `sync all` fans out one agent per project in parallel worktrees; mechanics are in pattern A5.

### Project registration

```bash
bash scripts/register-project.sh "<folder_path>" "<description>" "<stack>"
```

Creates the three docs if missing, adds the project to `docs/projects.md`, inits git, makes a private GitHub repo. Healthcheck flags any project folder that skipped this step.

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

Optional folder of cross-project handbooks. Agents read from it and write to it. Skip if you only run one project; enable if you expect repeated domain work (auth, payments, market research, etc.).

### Structure

```
Library/
├── CLAUDE.md                    (rules for library usage)
├── software-engineering/
│   ├── authentication-patterns.md
│   └── database-optimization.md
├── market-research/
│   ├── fitness-app-pricing.md
│   └── saas-pricing-models.md
└── domain-knowledge/
    └── negotiation-frameworks.md
```

Topics organise by domain, not by agent. Multiple agents write into the same file. `Library/CLAUDE.md` sets rules for citations, confidence tags, and structure.

### Agent linking

Each agent's `.claude/agents/<name>.md` config declares which library folders it reads and writes. The researcher writes new entries after an analysis. The engineer pulls from `authentication-patterns.md` before building a login flow. The business agent reads `saas-pricing-models.md` before pricing a feature.

### Update over duplicate

If a handbook already covers the topic, the agent appends. New file only when no existing one fits. First version of a handbook is three paragraphs. After five projects touch the topic, it's a thorough reference.

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

> 📎 *Part 3 (Code Templates) lives in the companion file: `blueprints/xantham-templates-v31.md`. Every template body the install wizard copies verbatim (CLAUDE.md, settings.json, hooks, scripts, skills, agent configs, memory seeds, doc bodies) is stored there. The landing file you are reading now keeps the human-readable wizard, architecture reference, advanced patterns, and troubleshooting catalogue.*

---

## Sharing this blueprint

This file is the entire public blueprint. Hand it to anyone. They can install a clean Xantham System from scratch.

Your **personal** copy (if you keep one) typically lives in your private repo as `blueprints/<your-orchestrator>-system-v31.md` or similar. Personal copies contain your actual project list, agent names, bot token guidance, Telegram allowlist, NotebookLM notebook ID, and other personal state. Do NOT share personal copies.

`scripts/export-blueprint.sh` strips a personal blueprint down to this public shape (replaces filled-in values with `{{template_vars}}`) if you ever update both and want to re-export.

---

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

The PreCompact hook grabs whatever is in `${TMPDIR:-/tmp}/{{orchestrator_name_lower}}-working-context.md` and copies it to `data/recovery/`. It keeps the last 5 snapshots so you can recover from any recent compaction.

The PostCompact hook reads the saved checkpoint back into context and also loads recent conversation history from the Telegram/terminal log. It re-reads the active project's HANDOFF.md so the session can continue without losing track of where it was.

**Checkpoint format**

Write to `${TMPDIR:-/tmp}/{{orchestrator_name_lower}}-working-context.md` regularly:

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
From any Bash shell (the CLI form works from a terminal, not just a Claude Code session):
```
claude plugin marketplace add claude-plugins-official
claude plugin install telegram@claude-plugins-official
```
Then start a fresh Claude Code session in your project directory, paste your bot token when the plugin asks for it, and it will store it under `data/runtime/telegram.json`.

**Step 4: Enable the plugin in `.claude/settings.json`**
Plugin enablement is a settings file entry, not a launch flag. There is no `--plugin telegram` flag on the `claude` binary. Add `"telegram"` to the `enabledPlugins` array in your project's `.claude/settings.json`:

```json
{
  "enabledPlugins": ["telegram"]
}
```

Your launch functions stay unchanged - they just `cd` into the project and run `claude --dangerously-skip-permissions`. The settings file controls which plugins load.

**Step 5: Update CLAUDE.md**

Add to the core loop:
- Logging inbound messages: `bash scripts/log-telegram.sh "{{user_name}}" "<message>" "<project>" <has_image>`
- Logging outbound replies: `bash scripts/log-telegram.sh "{{orchestrator_name_lower}}" "<reply>" "<project>" false`
- The reply-first rule (always reply on Telegram within seconds, never leave the user waiting)

Add `scripts/log-telegram.sh` if it was not generated during initial setup (terminal-only setups skip this script). Use the template from `blueprints/xantham-templates-v31.md` § Template: scripts/log-telegram.sh.

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
Fix: install via `claude plugin marketplace add claude-plugins-official && claude plugin install telegram@claude-plugins-official`. If already installed, check `.claude/settings.json` has `"telegram"` in `enabledPlugins`. There is no `--plugin telegram` launch flag - plugin enablement is settings-file based.

**Cause 4: Pairing not approved.**
If you are messaging from a new account or device, the plugin's access control may be blocking you.
Fix: Check the plugin's access configuration. Run `/telegram:access` from your terminal to review and approve pairings.

**Cause 5: Another session is consuming messages.**
Telegram's `getUpdates` API is single-consumer. If another Claude Code session has the same bot token, it will steal messages.
Fix: Close all other Claude Code sessions using the same bot token. Only one session per token.

---

### B2. "SQLite database is locked"

**Symptom:** Memory queries or saves fail with "database is locked" errors.

**Cause:** Another process has the SQLite database file open. The two known triggers are: (a) two Claude Code sessions running against the same project directory, or (b) an orphaned process from a crashed session still holding the lock. Run `lsof <db-path>` (Mac/Linux) to confirm which one.

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
| Pro | Smallest | One task per session. Sync after every task. Keep agent count low (1-2). |
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
Hooks failing with `\r: command not found` or `bad interpreter` mean your shell scripts have CRLF line endings. Prevention is in the Windows install section near the top of this blueprint - run `git config --global core.autocrlf input` ONCE before cloning, not `true`. The `true` setting (older docs) commits LF but checks out CRLF, which still breaks scripts when invoked through Git Bash. Use `input`. To fix scripts that are already wrong, re-clone or run `dos2unix` on every file under `.claude/hooks/` and `scripts/`.

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

---

### B13. Background scheduled tasks not firing on macOS

**Symptom:** You set up a routine that should fire on a schedule (morning digest at 8am, weekly Monday maintenance, monthly retrospective, auth-failover canary). Your Mac was on. The schedule did not run. No log entry, no Telegram ping.

**Cause: macOS Transparency, Consent, and Control (TCC) blocks launchd from running scripts under your `~/Documents/` folder.**

This started in late April 2026 with a macOS update. Apple's privacy layer began refusing requests where launchd (the system task scheduler) tries to execute scripts that live in your Documents directory. It is not a bug, it is the new default. The system never tells you. The script just silently fails to run, last_exit=126, "Operation not permitted."

You won't see this until you wonder why a scheduled routine never fired. Day-to-day chat with your agent is unaffected: anything you type into your terminal or send via Telegram still works.

**Fix (the established pattern).** Each scheduled routine ships with a tiny AppleScript `.app` wrapper at `~/Applications/<routine-name>.app`. macOS lets you grant Full Disk Access (FDA) to a `.app` bundle. Once granted, that `.app` can run the underlying script. The wrapper does nothing else, just runs the script and exits.

The AppleScript wrapper looks like this. Save as a `.applescript` file, open in Script Editor, then File > Export > File Format: Application:

```applescript
-- routine-wrapper.applescript
-- Compile to ~/Applications/<routine-name>.app
do shell script "cd " & quoted form of "/Users/<you>/Documents/MyAgent" & " && bash scripts/<routine>.sh"
```

To grant FDA:

1. Open System Settings (the gear icon in your menu bar).
2. Go to Privacy & Security, then Full Disk Access.
3. Click the `+` button.
4. Navigate to `~/Applications/`. Select each `<routine>.app` you want to grant.
5. Toggle each one on.

Then ask your agent: "reload the launchd plists." It runs `launchctl unload` then `launchctl load` for each scheduled routine. The next scheduled fire works.

**New-mac re-enable steps.** When you migrate to a new Mac, the FDA grants do not transfer. After cloning your project repo and re-installing the launchd plists, you have to manually grant FDA on each `.app` again. Allow about 5 minutes.

**Alternative: relocate scripts outside `~/Documents/`.** If you want to skip the FDA dance entirely, move the project to `~/Library/Application Support/<orchestrator>/` or another path TCC does not gate. Most users find FDA on a few `.app` wrappers easier than relocating the whole project.

**If you don't run any scheduled routines, you can skip this entirely.** This only affects users who set up the morning digest, weekly Monday maintenance, monthly retrospective, or the auth-failover canary. Telegram, terminal use, and ad-hoc agent work are not affected.

**Windows note:** macOS launchd has no direct Windows equivalent. The closest analogues are **Windows Task Scheduler** (built-in, GUI) and **NSSM** (`winget install NSSM.NSSM` for service-style daemons). The TCC issue does not exist on Windows. Schedule a Bash script via Task Scheduler with the action `C:\Program Files\Git\bin\bash.exe -c "cd C:/Users/<you>/Documents/MyAgent && bash scripts/<routine>.sh"` and grant the running user full file-system access via the Action's "Run as" account. Windows users see no equivalent of the TCC block.

---

### B14. Auth failover - Anthropic OAuth degraded or suspended

**Symptom:** Claude Code starts failing on every tool call with auth errors. Or your Anthropic Max subscription gets suspended (it happens, even briefly, even when nothing is wrong on your side). The orchestrator becomes unreachable until OAuth comes back.

**Why this matters.** Without a fallback, an OAuth outage takes the entire orchestrator down for as long as the outage lasts. A separately-billed API key flipped in fixes the outage in seconds.

**Cause: Anthropic's OAuth flow is unavailable, or your Max account is suspended pending review.**

**Fix.** The auth failover system lets you flip Claude Code between Max OAuth and a separately-billed API key. The API key is provisioned ahead of time, kept in `~/.config/claude/api-key` at mode 0600, and never lives in the repo.

Mac and Linux:

```bash
# One-time setup (do this BEFORE you ever need it)
mkdir -p ~/.config/claude

# If an api-key file ALREADY exists, it was provisioned by another tool.
# Leave it in place AND skip the sidecar write — uninstall keys off the
# sidecar to know whether to prompt for removal. No sidecar = leave alone.
if [ ! -f ~/.config/claude/api-key ]; then
  echo "<your-anthropic-api-key>" > ~/.config/claude/api-key
  chmod 0600 ~/.config/claude/api-key
  # Sidecar marker so scripts/uninstall.sh knows THIS install provisioned it
  # (fixes Marco audit CG5 — sentinel-gating on the api-key cleanup step).
  touch ~/.config/claude/.api-key-installed-by-xantham
  chmod 0600 ~/.config/claude/.api-key-installed-by-xantham
else
  echo "api-key already exists at ~/.config/claude/api-key (NOT provisioned by this wizard)"
fi

# Flip to API key when OAuth is degraded
bash scripts/auth-fallback.sh use-api-key

# Flip back to OAuth when the outage clears
bash scripts/auth-fallback.sh use-oauth

# Status check
bash scripts/auth-fallback.sh status

# Test a candidate key without committing to it
bash scripts/auth-fallback.sh test-key sk-ant-...
```

Windows (PowerShell):

```powershell
# One-time setup
New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\claude" | Out-Null
if (-not (Test-Path "$env:USERPROFILE\.config\claude\api-key")) {
  Set-Content -Path "$env:USERPROFILE\.config\claude\api-key" -Value "<your-anthropic-api-key>"
  icacls "$env:USERPROFILE\.config\claude\api-key" /inheritance:r /grant:r "$($env:USERNAME):(R)"
  # Sidecar marker so uninstall.sh knows THIS install provisioned the key
  New-Item -ItemType File -Path "$env:USERPROFILE\.config\claude\.api-key-installed-by-xantham" -Force | Out-Null
  icacls "$env:USERPROFILE\.config\claude\.api-key-installed-by-xantham" /inheritance:r /grant:r "$($env:USERNAME):(R)"
} else {
  Write-Host "api-key already exists at ~/.config/claude/api-key (NOT provisioned by this wizard)"
}

# Flip via Git Bash (the script is bash, runs identically on Windows)
bash scripts/auth-fallback.sh use-api-key
bash scripts/auth-fallback.sh use-oauth
bash scripts/auth-fallback.sh status
```

The Windows API key location is `%USERPROFILE%\.config\claude\api-key`. The Mac and Linux location is `~/.config/claude/api-key`. The script reads whichever path matches the running OS.

**Auth canary.** A 4th SLO canary at `scripts/check-auth-status.sh` pings Anthropic's `/v1/messages` endpoint every 5 minutes. After 3 consecutive failures it writes `data/runtime/auth-degraded.flag` and fires `auth canary degraded` via `scripts/telegram-signal.sh`. The canary path is what the telegram-signal.sh script primarily exists for in v31.

Mac launchd schedule for the canary. Save the plist below as `~/Library/LaunchAgents/com.{{orchestrator_name_lower}}.auth-canary.plist`, wrap via the AppleScript .app pattern per B13 above (so launchd's bash invocation can read under `~/Documents/`), grant Full Disk Access to ONLY that .app bundle in System Settings > Privacy & Security > Full Disk Access, then `launchctl load` it.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- XANTHAM-SENTINEL: launchd-plist-v31
         This XML comment is content-grep'd by scripts/uninstall.sh before
         removing the plist. Keeps uninstall from touching plists that just
         happen to share the com.{{orchestrator_lower}}. filename prefix. -->
    <key>Label</key>
    <string>com.{{orchestrator_name_lower}}.auth-canary</string>

    <!-- AppleScript .app wrapper invoked here instead of /bin/bash directly.
         Full Disk Access is granted to ONLY this .app bundle (not bash
         system-wide), so reading/writing under {{project_path}} works without
         leaking FDA to every other bash invocation on the machine.
         Build via: bash scripts/install-launchd-wrappers.sh
         Pattern: https://me.micahrl.com/blog/applescript-app-launchd/ -->
    <key>Program</key>
    <string>{{project_path}}/Applications/{{orchestrator_name}}-AuthCanary.app/Contents/MacOS/applet</string>

    <!-- The wrapper checks RUN_FROM_LAUNCHD=true to refuse manual double-clicks
         from Finder. Without this env var, the .app shows a dialog and exits. -->
    <key>EnvironmentVariables</key>
    <dict>
        <key>RUN_FROM_LAUNCHD</key>
        <string>true</string>
    </dict>

    <!-- Fire every 5 minutes (300 seconds). macOS skips fires when asleep. -->
    <key>StartInterval</key>
    <integer>300</integer>

    <!-- Log stdout and stderr separately for operator visibility. The script
         appends one line per run; rotate manually or via logrotate if growth
         becomes a concern. -->
    <key>StandardOutPath</key>
    <string>{{project_path}}/logs/auth-canary.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>{{project_path}}/logs/auth-canary.stderr.log</string>

    <!-- Working directory so relative paths in check-auth-status.sh resolve. -->
    <key>WorkingDirectory</key>
    <string>{{project_path}}</string>

    <!-- Don't run at load time. Wait for the first 5-minute tick so we observe
         steady-state behaviour, not a startup spike. -->
    <key>RunAtLoad</key>
    <false/>

    <!-- Throttle: if a run takes longer than 300s, wait until it's done before
         starting another. Prevents stacking under degraded API conditions. -->
    <key>ThrottleInterval</key>
    <integer>300</integer>
</dict>
</plist>
```

```bash
launchctl load ~/Library/LaunchAgents/com.{{orchestrator_name_lower}}.auth-canary.plist
```

The script `scripts/check-auth-status.sh` pings `/v1/messages` and tracks consecutive failures in `data/runtime/auth-canary-state.json`. After 3 consecutive fails it writes `data/runtime/auth-degraded.flag` and fires `auth canary degraded` via `scripts/telegram-signal.sh`. Reset the flag manually once auth recovers: `rm data/runtime/auth-degraded.flag`.

Windows Task Scheduler equivalent:

```powershell
schtasks /Create /SC MINUTE /MO 5 /TN "{{orchestrator_lower}}-auth-canary" /TR "\"C:\Program Files\Git\bin\bash.exe\" -c \"cd C:/Users/<you>/Documents/{{orchestrator_name}} && bash scripts/check-auth-status.sh\""
```

The healthcheck script surfaces the auth posture (OAuth or API key, last canary result, degraded flag state) so you know which mode is live without inspecting files.

### B15. Disaster recovery

Three recovery procedures for common failure modes that are mechanical to fix once you know the path. Each has a clean rollback if you stop part-way.

#### B15.1 vector-memory.db corruption recovery

**Symptom:** `bash scripts/memory-search.sh "<query>"` returns errors (e.g. `database disk image is malformed`, `no such table`, `vec0 module not loaded`), or returns zero results for queries that previously worked. Healthcheck flags the chunk count as 0 or wildly off.

**Cause.** The sqlite-vec virtual table at `data/vector-memory.db` got corrupted. Common triggers: disk full mid-write, abrupt power loss while the post-commit hook was running, sqlite-vec extension version mismatch after a Python upgrade.

**Recovery (Mac / Linux / Windows-Git-Bash, identical commands):**

```bash
# 1. Confirm Ollama is running and Nomic-embed is pulled
ollama list | grep nomic-embed-text

# 2. Move the corrupt index aside (do NOT delete yet, in case re-embed fails)
mv data/vector-memory.db data/vector-memory.db.corrupt-$(date +%s)

# 3. Full rebuild from markdown source of truth
bash scripts/embed-memories.sh --rebuild

# 4. Verify
bash scripts/memory-search.sh "test query" | head -10
ls -la data/vector-memory.db                 # file exists, > 1MB after first embed
```

**Time:** ~5 min on a 200-memory corpus. Scales roughly linearly with chunk count.

**If the rebuild also fails:** the source markdown is fine (it lives in git). The fault is environmental (Ollama not running, sqlite-vec extension missing, Python interpreter swapped). Run the E1 install verify steps in order. Once those pass, re-run step 3.

**Once the rebuild succeeds:** delete the `.corrupt-*` file. Keep nothing.

#### B15.2 MEMORY.md desync recovery

**Symptom:** `memory/MEMORY.md` (the index) shows entries pointing at files that no longer exist, OR is missing entries for memory files that DO exist on disk. The orchestrator references stale memories or fails to recall fresh ones.

**Cause.** The post-commit hook that auto-regenerates the index failed to fire (commit-skip flag set, hook not executable, hook silently errored). The on-disk index drifted from the source-of-truth set of `memory/**/*.md` files.

**Recovery (Mac / Linux / Windows-Git-Bash, identical commands):**

```bash
# 1. Snapshot the current index for diff after rebuild
cp memory/MEMORY.md memory/MEMORY.md.pre-regen

# 2. Trigger the post-commit hook's index-regeneration path manually
#    The hook lives at .git/hooks/post-commit (installed by E1's
#    install-git-hooks.sh). Re-running it with no commit-skip flag
#    rebuilds memory/MEMORY.md from the on-disk file list.
bash .git/hooks/post-commit --regen-index-only

# 3. If your install does NOT have the --regen-index-only flag (older
#    hook), force a regen by touching every memory file and committing:
find memory/ -name "*.md" -not -path "*/.*" -not -name "MEMORY.md" -exec touch {} +
git add memory/ && git commit -m "chore: trigger memory index regen" --allow-empty

# 4. Diff to confirm the regen produced changes
diff memory/MEMORY.md.pre-regen memory/MEMORY.md | head -50

# 5. Once happy
rm memory/MEMORY.md.pre-regen
```

**Time:** under 1 minute regardless of corpus size. The index regen reads frontmatter only, not bodies.

**If the regenerated index still misses files:** confirm the iterator is honoring subdir-recursion + dot-prune (`find memory/ -name "*.md" -not -path "*/.*"`). Files under gitignored subdirs (e.g. dot-dir carveouts) are correctly excluded. Files under `memory/episodic/` and `memory/semantic/<type>/` SHOULD be included.

#### B15.3 Partial-wizard-install reset

**Symptom:** The install wizard was interrupted mid-flow (terminal closed, network drop during a `brew install`, Ctrl-C). Re-running the wizard fails with "config already partially written" or behaves inconsistently. Hooks are half-installed, env vars half-set, scripts present but not chmod'd.

**Why this matters.** Half-installed state is worse than no install. The orchestrator may load a hook that references a missing script and crash on every tool call.

**Prevention (the wizard does this for you).** Before any destructive step (writing CLAUDE.md, installing hooks, running git mv), the wizard prints the pre-install commit hash to the terminal AND writes it to `data/runtime/install-rollback.txt`. Do NOT close the terminal until the wizard says "Setup complete." If you must close, the rollback hash is on disk.

**Recovery (Mac / Linux / Windows-Git-Bash, identical commands):**

```bash
# 1. Find the pre-install commit hash
cat data/runtime/install-rollback.txt
# OR scroll back the wizard transcript for "Pre-install commit: <hash>"
# OR if neither exists, find it by recency:
git log --oneline --all | head -20

# 2. Hard-reset to before the install (DESTROYS uncommitted wizard state)
git reset --hard <pre-install-hash>

# 3. Clean any partially-created files the wizard wrote outside git
#    (the rollback file itself + any data/ scaffolding committed-as-empty)
rm -f data/runtime/install-rollback.txt
find data/runtime -type f -newer data/runtime/install-rollback.txt 2>/dev/null

# 4. Confirm you are at a known-good state by listing what should NOT exist
ls -la .claude/hooks/        # expect: empty or only pre-install hooks
ls -la scripts/              # expect: empty or only pre-install scripts
cat CLAUDE.md 2>/dev/null    # expect: file does not exist OR is your pre-install version

# 5. Inventory check - the install-clean state should match this skeleton:
#    - no .claude/hooks/{audit-log-hook,safety-gate,session-end-verify}.sh
#    - no scripts/{embed-memories,memory-search,active-recall,dream}.sh
#    - no .{{orchestrator_lower}}-blueprint-version file
#    - no memory/MEMORY.md (the wizard creates it)
#    - no data/audit/, data/dream-runs/, data/runtime/

# 6. Re-run the install command from scratch
```

**Time:** under 2 minutes. The git reset is fast; the inventory check is what takes the time.

**If `git reset --hard` is blocked by the safety gate** (the gate hard-blocks it on protected branches in some configs): you are on a fresh install on a fresh branch, so a hard reset is safe. Approve via the gate's approval-file path (write `yes` to `data/approved.txt` and re-run), OR delete `.git` entirely and re-clone if this is a brand-new project folder with no other history.

--- END OF PART 4: ADVANCED PATTERNS & TROUBLESHOOTING ---

--- END OF BLUEPRINT ---

