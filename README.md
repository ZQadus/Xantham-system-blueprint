# Xantham System

> Self-installing personal AI orchestrator. Hand the blueprint to a fresh Claude Code session and it builds you a full multi-agent system in about an hour.
>
> Built for operators running multiple projects who want to drive research, code, deploys, and writing from their phone. Telegram is the front door, a crew of specialist agents does the actual work.

## Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)**: system map with Mermaid diagram, component descriptions, data flow, memory and safety cross-sections.
- **[SECURITY.md](SECURITY.md)**: threat model, the three-bucket safety gate (hard-block / approval-gated / allowed), known limitations, vulnerability disclosure.
- **[COMPARISON.md](COMPARISON.md)**: honest benchmark vs claude-financial-services, factory.ai, AutoGen, CrewAI, LangGraph, karpathy/llm-council. Where Xantham is behind, at parity, and ahead.

## What you get

- A master orchestrator (your AI) plus a crew of 9 specialist agents (engineering, research, growth, social, infra, writing, trading, business, human dynamics)
- Telegram interface so you can run the system from your phone
- Persistent memory that survives across sessions, with semantic search
- Live shared whiteboard so multiple agents coordinate cleanly when running in parallel
- Per-tool-call audit log + safety gate that prevents destructive accidents
- A self-installing wizard that walks you through setup in about an hour (30-45 minutes if you already have Node 18, Git, jq, sqlite3, and bun installed)

## What you can do with it

The system is general-purpose. Anything Claude Code can do, your specialist crew can be asked to do via Telegram. A non-exhaustive list of what operators actually use it for:

### Coding and shipping software

- **Build a new iOS app from a spec.** Tell the engineer to scaffold, build features in long sessions, run tests, ship to TestFlight. Real apps shipped to the App Store with this exact pattern.
- **Maintain multiple projects in parallel.** Work on 4-5 projects in one session. Each one lives in its own working tree so agents don't trample each other. The orchestrator coordinates merges.
- **Code review on a branch.** `review <project>` dispatches a reviewer agent that audits the diff against your codebase conventions + flags issues.
- **Fix a production bug from your phone.** Telegram in, fix out. Verified via deploy check before the orchestrator says "done".
- **Refactor across a large repo.** Multi-agent dispatch handles independent files in parallel. Sync writes the result back.

### Research and analysis

- **Frontier scans on a topic.** Ask the research agent for a survey of recent papers, repos, and posts on something specific (e.g. "what's the state of agent orchestration in 2026?"). It searches the web, peer-reviewed sources via the Consensus integration, and writes a structured brief.
- **Competitive intelligence.** "Who else is building X? What do they charge, what do they ship, what's the gap?" Gets you a comparison matrix you can act on.
- **Technical deep-dives.** Read a 30-page paper, summarise the load-bearing claims, link to verifiable sources, flag anything that didn't replicate.
- **Market sizing + feasibility.** Hand the research agent a product idea, get a defensible TAM/SAM/SOM back with the assumptions visible.

### Writing and content

- **Long-form blog posts.** Built-in anti-AI-tell style guide, no em-dashes, varied sentence cadence. Output reads like a real person wrote it.
- **Pitch decks and investor materials.** Structured outline + per-slide copy.
- **Reddit posts, X threads, LinkedIn updates.** Platform-tactical content from the social agent. Title + body + cadence + which subreddit, all defensible.
- **Cold-email and outreach drafts.** The human-dynamics agent writes intros calibrated to the recipient.
- **Documentation.** PRDs, README files, technical specs, internal handover docs.

### Operations and admin

- **Morning digest.** Every morning, the orchestrator fires a catch-up on Telegram. What's pending, what shipped overnight, what needs your input today.
- **Calendar suggestions.** "Find me 90 minutes this week to focus on X." Looks at your real calendar via the Google integration, suggests slots.
- **Email triage.** Drafts replies, flags the ones that need your attention, archives the rest. You approve before anything sends.
- **Reading queue.** Paste a YouTube link, get a structured summary with timestamps + key claims + a "should I actually watch this" verdict.
- **Knowledge library.** Auto-promoted research notes, decisions, handbooks. Searchable across every session.

### Trading and market research

- **Strategy ideation and backtesting.** Walk-forward tests, portfolio analysis, risk-management work. Local execution, no broker API in the loop unless you wire one yourself.
- **Market-data analysis.** Pull live data via the database integrations, run analysis, write a brief.
- **Position sizing models.** Kelly criterion calculators, drawdown analysis, regime detection.

### Growth and launch

- **Launch playbooks.** ASO, paid + organic strategy, week-by-week rollout cadence.
- **Subreddit + community strategy.** Where to post, when, with what voice. The social agent reads sub-specific norms before recommending.
- **Cross-posting + repurposing.** One asset, multiple platforms, calibrated copy per channel.
- **Conversion optimisation.** Landing page audit, CTA placement, copy A/B suggestions.

### Personal stuff

- **Project ideation.** "Help me think through X". Brainstorming agent walks the design space before any code gets written.
- **Decision support.** Hard call you keep avoiding? The system has a council pattern for it (3 agents debate anonymously, a chairman ranks).
- **Pattern detection on yourself.** After enough sessions, the system notices what you keep doing wrong + flags it. Auto-promoted to rules after the same correction lands 3 times.

The bigger principle: anything you'd type into a Claude conversation, you can route through this system, with the difference that it remembers across sessions, runs specialist agents in parallel, and ships safely.

## New to agentic AI? Read this first

If you've used ChatGPT or the Claude.ai web chat, you already know what an AI conversation looks like. You type, it answers. Useful, but you have to drive every step.

**Agentic** is the upgrade. Instead of just answering, the AI takes actions: runs commands, reads files, edits code, searches the web, pushes deploys, sends Telegram messages. It uses tools the way you would. You give it a goal in plain English, it figures out the steps and executes them. You stay in the loop on the important calls, but you don't have to drive every keystroke.

Xantham is **multi-agent on top of that.** Instead of one AI doing everything, you get a master (the "orchestrator") plus a crew of 9 specialists, each pointed at a different domain.

### Who's on the crew

- **Engineer**: writes and reviews code, ships builds, fixes bugs
- **Research**: competitive analysis, paper deep-dives, market intel
- **Growth**: ASO, launch playbooks, paid + organic strategy
- **Social**: platform-tactical content for Reddit, X, LinkedIn, TikTok
- **Infra**: deploys, CI/CD, DNS, monitoring, hosting
- **Writing**: long-form, decks, docs, emails, no AI tells
- **Business**: pricing, partnerships, contracts, legal
- **Trading**: strategy research, backtests, portfolio analysis (no live capital unless you wire it yourself)
- **Human dynamics**: negotiation, networking, cold outreach, presence

The orchestrator is the boss. You talk to it. It routes work to the right specialist (or several at once), then reports back. Most tasks need one specialist. Bigger sprints get 3-5 specialists running in parallel in their own isolated working trees so they don't trample each other.

### Three things you get from this setup

1. **Persistent memory across sessions.** Every session writes structured notes to disk, plus an optional snapshot to an AI Brain (NotebookLM). When you open a fresh terminal next Tuesday, the orchestrator reads back yesterday's state in under 5 seconds. Days, weeks, months of work stay continuous.
2. **2-3 specialists in parallel by default, up to 16 in Aggressive mode on Max 20x.** The Balanced default (recommended for most installers) fans out 2-3 specialists when work decomposes cleanly. Aggressive mode runs 5-16 in their own git worktrees on big sprints, gated by the 5-hour Max 20x rolling rate limit. A 4-hour solo build collapses to roughly 45 minutes of wall-clock time when the work splits cleanly.
3. **Hard-blocked destructive commands.** The safety gate refuses force-push to main, `rm -rf` against your home directory, and `DROP TABLE` against a database, regardless of approval. Approval-gated commands (database migrations and similar) still pause for your call. The hard-blocks are not configurable on purpose.

### One thing worth knowing before you install

You're not using an AI assistant. You're running a small operation that happens to be entirely AI-driven, with you as the operator. The orchestrator is the one you talk to. It routes work to specialists, holds context across sessions, and pings you when something needs your call.

In practice this looks different from a regular chat after about a week. You stop typing long prompts. You start typing short directions: "fix the bug on the login screen of NearbyMe", "draft a Reddit post for r/ClaudeAI about the wizard install", "summarise yesterday's research on agent orchestration". The orchestrator already knows the codebase, the project, your voice. It dispatches a specialist, the specialist works in background, you get a result on your phone.

That is the shape of the thing.

## Before you start

You'll need:
- **Mac or Windows** (Linux works too, treated like Mac)
- **Claude Code** installed (claude.com/claude-code)
- **An active Claude.ai paid plan**: Pro ($20/mo), Max 5x ($100/mo), or Max 20x ($200/mo). The system uses your existing subscription - no additional API charges. Pro works; Max is recommended for parallel agent work.
- **About an hour** of your time (30-45 minutes if you already have Node 18, Git, jq, sqlite3, and bun installed; closer to a full hour if starting from a fresh laptop and the wizard installs the prereqs first)

The wizard will check for Node 18, Git, jq, sqlite3, and bun on first run, and tell you exactly how to install any that are missing.

**Accounts you'll need:**
- Claude.ai paid plan (required, see above)
- Telegram (free, ~2 min to create the bot via @BotFather)
- Google (free, optional - for the NotebookLM AI Brain. Skip if uncomfortable)
- GitHub (free, optional - for auto-creating private repos for your projects)

**Cost summary:** $0/month (£0) for the system itself. Just your Claude.ai subscription.

## Data and privacy

- Your conversations + memory files live on your laptop only. Not synced anywhere.
- Telegram traffic flows: phone → Telegram servers → your bot → your laptop. Same posture as any Telegram bot.
- NotebookLM session summaries push to Google's servers IF you enable the Brain. Skip the Brain if uncomfortable.
- Claude API traffic flows to Anthropic via your existing Claude Code subscription. No new keys.
- Audit logs are local-only and gitignored. Zero analytics or telemetry to the maintainer.

## A note on the maintainer

If you see references to `your orchestrator` or `cortana` anywhere in this repo (blueprint, ARCHITECTURE, SECURITY, COMPARISON, docker) - that is the maintainer's literal orchestrator name. Yours will be whatever you pick during the install wizard. Every doc here is system-agnostic; the install wizard substitutes your chosen name into every generated file.

## How to proceed safely

This system runs shell commands, edits files, and pushes commits on your behalf. Meaningful surface area, treat it like any other piece of foreign code. Three checks before you install:

1. **Clone the repo locally first.** Read the blueprint Markdown and the wizard scripts at your own pace before you hand them to Claude Code.

   ```bash
   git clone https://github.com/ZQadus/Xantham-system-blueprint.git
   cd Xantham-system-blueprint
   ```

2. **Pick Simple mode for the first install.** Roughly a third of the surface area of Advanced and still a fully usable system. Upgrade later with `bash scripts/upgrade-<your-orchestrator-name>.sh` once you have audited what's actually running on your machine.

3. **Do not hand the orchestrator credentials you can't rotate fast.** Telegram bot tokens are revocable from `@BotFather` in seconds. Treat anything else with care. Project-level deploy keys, database passwords, OAuth credentials should be ones you can rotate in minutes if something goes wrong.

## Maintainer track record

This is a single-maintainer open-source project. The most useful security signal you have is the maintainer's prior public work. Verify it directly rather than taking the README's word for it.

- **GitHub:** [github.com/ZQadus](https://github.com/ZQadus). Commit history on this repo and other repos shows operating posture (commit cadence, prior projects, response to issues).
- **Portfolio:** [zakiqadus.co.uk](https://zakiqadus.co.uk). Public artifacts, shipped projects, current focus.
- **LinkedIn:** [linkedin.com/in/zaki-qadus](https://linkedin.com/in/zaki-qadus). Professional history, current role, prior work.
- **Community activity:** open GitHub Issues + Discussions are the public record. Read the maintainer's responses there to calibrate.

If anything looks off in the above, do not install. Open an issue or send a question first.

## How to install

Two paths, pick the one that fits your trust level. The wizard is identical in both; the only difference is whether you run it inside a throwaway container or directly on your host.

| Path | Best for | Trade-off |
|---|---|---|
| **Recommended: Docker sandbox** | First-time installers, security-conscious users, anyone auditing before committing | Need Docker installed. Extra ~5 min to build the container. Highest audit posture. |
| **Fast path: direct host install** | Users who have already audited the blueprint, or who already trust the maintainer | Less friction, no Docker needed. Lower audit posture by design. |

Both paths use the same install command. The wizard generates the same files. After a successful sandbox install you can repeat the steps on your host and the result is identical.

### Recommended path: install in a Docker sandbox

The full wizard runs inside an isolated container. Filesystem writes stay inside the container. You can audit what got generated before bringing any of it to your real machine.

**Step 1, verify the blueprint files cryptographically.**

A SHA256 manifest at `CHECKSUMS.sha256` tracks every published file. Run the verifier first:

```bash
git clone https://github.com/ZQadus/Xantham-system-blueprint.git
cd Xantham-system-blueprint
bash scripts/verify-blueprint.sh
```

The script exits `0` on match, `1` on mismatch (do not install), `2` on fetch errors. macOS uses `shasum -a 256`, Linux uses `sha256sum`, both supported.

**Step 2, build and enter the sandbox container.**

```bash
docker build -f docker/Dockerfile.xantham-sandbox -t xantham-sandbox docker/
docker run --rm -it xantham-sandbox
```

Inside the container, run the standard install command from the Fast path below (the same single-paste prompt). The wizard walks Q0 through Q19 identically, but everything it writes lives inside the container.

**Step 3, audit what got generated.**

Read the generated files inside the container:

- `.claude/hooks/safety-gate.sh` for the safety gate body
- `.claude/hooks/banned-language-gate.sh` for the banned-language gate body
- `scripts/` directory for all wizard-generated scripts
- `CLAUDE.md` for the orchestrator's operational config

If anything looks off, type `exit` (the `--rm` flag wipes the container) and either fix the issue locally or report it as a GitHub issue.

**Step 4, graduate to host install when ready.**

If the audit looks good, repeat the Fast-path install on your host filesystem now that you know what to expect. The container can stay around for future test installs or you can discard it.

Full reference + commit-pinning options at [`docker/README.md`](docker/README.md).

### Fast path: install directly on host

1. Open a fresh Claude Code session pointed at an empty directory you want to become your AI command centre.

   **If you've never run Claude Code from a terminal before:**
   - **Mac:** Open Terminal (⌘+space, type Terminal). Type `mkdir ~/Documents/MyAgent && cd ~/Documents/MyAgent && claude --dangerously-skip-permissions`. Press enter.
   - **Windows:** Open PowerShell. Type `mkdir $env:USERPROFILE\Documents\MyAgent ; cd $env:USERPROFILE\Documents\MyAgent ; claude --dangerously-skip-permissions`. Press enter.
   - **Linux:** Same as Mac.

   You'll see a screen that says **"Welcome to Claude Code"** with a `>` prompt. NOT the regular terminal prompt (`$` or `%`). If you see `$` or `%` after running `claude`, the command didn't launch the TUI - check that Claude Code is installed (claude.com/claude-code).

   > **About `--dangerously-skip-permissions`**: the wizard runs hundreds of tool calls (file writes, Bash commands, hook installs) over the full hour of install. Without this flag you'd be hitting "Allow" every few seconds for the whole install, which is painful and error-prone.
   >
   > **Honest about the trade-off**: there is a window of unprotected execution during the early install steps. Q0 preflight runs Bash commands before the safety gate is generated. Q1 through Q5 collect answers but write minimal files. The safety gate gets generated and activated around Q6-Q9 depending on the mode you pick.
   >
   > Once the gate is active, it blocks destructive commands via Claude Code's PreToolUse hook layer (force-push to protected branches, recursive home-directory deletes, filter-branch, disk-format ops, etc) regardless of whether `--dangerously-skip-permissions` is on. Some commands (database drops, schema migrations) are approval-gated rather than hard-blocked, so you stay in the loop on those even after the gate is live.
   >
   > Two ways to minimise the early-window risk:
   > - **Read the install command before you paste it.** It just points Claude at this repo. Nothing exotic.
   > - **Run the install in a fresh directory** with no existing secrets, repos, or sensitive files. The wizard only writes inside the install directory until you explicitly point it at other projects later.
   >
   > After the install, you keep the `--dangerously-skip-permissions` flag on (or off) per your preference. The safety gate keeps working either way. Most operators run with it on for daily work because the orchestrator is fine-grained about what it dispatches to specialists, and the hard-blocks catch the truly dangerous stuff.

2. Paste this single line into the Claude prompt:

   ```
   Read the Xantham System v31 blueprint at https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/xantham-system-v31.md and the companion templates appendix at https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/xantham-templates-v31.md. Run the full setup wizard from the landing file, pulling template bodies from the appendix when generation steps reference them. Walk me through every step, ask me one question at a time, don't assume any values. Guide me through getting whatever you need (Telegram bot token, NotebookLM notebook, agent name, etc.) as the wizard reaches each one.
   ```

3. The wizard handles everything interactively from there. It will:
   - Detect your OS automatically (with confirmation).
   - Ask you to pick Simple or Advanced mode AFTER showing what each one includes.
   - Walk you through creating a Telegram bot via @BotFather (step-by-step) when it gets to the messaging step. (Telegram bot setup takes ~2 minutes - you message a bot called @BotFather, type `/newbot`, pick a name, paste the token back into the wizard. The wizard walks you through every tap.)
   - Walk you through creating a NotebookLM notebook (or skipping the AI Brain for now) when it gets to the memory step.
   - Ask you to name your orchestrator at the right point in the flow.
   - Pick sensible defaults for everything else and confirm before applying.

   You don't need ANY values up front. The wizard asks one question at a time, in plain English, and tells you exactly how to get any external value (bot token, notebook ID) as it reaches that step. Total time: about an hour including bot setup, 30-45 minutes if your prereqs (Node 18 / Git / jq / sqlite3 / bun) are already installed.

4. When done, the wizard generates eight files at the project root: `SETUP-CHECKLIST.md` (verify install), `USER-GUIDE.md` (your day-one cheat sheet), `BACKUP-AND-RECOVERY.md`, `FIRST-WEEK.md`, `PITFALLS.md`, `MEMORY-HYGIENE.md`, plus two helper scripts in `scripts/`.

5. Close the session, run your new agent's terminal alias (e.g. `myagent` if you named it MyAgent), and the first fresh session walks you through `SETUP-CHECKLIST.md` before any real work.

## How to use it

Day-to-day, you drive Xantham from Telegram. Plain English works for most things ("what's the status on project X", "ship the portfolio", "fix the bug in NearbyMe", "draft a Reddit post for r/ClaudeAI"). The orchestrator routes to the right specialist and reports back.

A handful of explicit commands are worth learning early. All of them are typed directly into Telegram.

### Daily commands

| Command | What it does |
|---|---|
| `help` | Lists the active commands. Always current, so re-check if you forget what's wired. |
| `team` | Lists your specialist crew (engineer, research, growth, infra, writing, etc) and what each one is for. |
| `projects` / `project list` | Shows every project the orchestrator knows about, grouped by category (mobile apps, web, SaaS, tools, etc). |
| `status <project>` | Reads HANDOFF.md for that project and summarises where you left off. |
| `healthcheck` | Runs a system check (Telegram plugin, AI Brain auth, memory database, safety hook, project doc coverage, MCP servers). Run it weekly or when something feels off. |
| `history <query>` | Unified search across Telegram, audit log, git log, and memory markdown. Useful for "when did we decide X" or "where did I save that note about Y". |
| `brain <question>` | Asks your NotebookLM AI Brain. Use for cross-project questions, old decisions, things you remember but don't know where they live. |

### Shipping work

| Command | What it does |
|---|---|
| `ship <project>` | Commits and pushes the project. Verification runs after to confirm the deploy landed (not just the push). |
| `review <project>` | Runs tests and dispatches a code-reviewer pass over the recent changes. |
| `deploy <project>` | Promotes to production on Vercel (or the project's configured target). |
| `nuke <project>` | Stash + clean the working tree. Requires explicit confirmation, never silent. |

### Context window management with `sync`

This is the command that lets one Claude session cover a full day of work without context exhaustion.

Claude Code sessions hold the conversation in a context window. As you work across projects, that window fills up. Older context gets compressed or dropped. Without help, a long session degrades into "what were we doing again" the further you get from where you started.

The fix is `sync`. At the end of a project block (or whenever you context-switch to a different project), you say `sync <project>` and the orchestrator runs a full cycle:

1. **Writes a HANDOFF.md** for the project so the next session knows the exact state.
2. **Folds the relevant new information into long-term memory** as markdown notes that survive across sessions.
3. **Updates the Profile bucket** if you signalled anything new about yourself or your priorities.
4. **Pushes a snapshot to your AI Brain** (NotebookLM) so the cross-session memory layer is current.
5. **Commits and pushes outstanding work** if the project has a clean state to ship.

Variants:

- `sync` (no project) syncs the current focus project.
- `sync all` runs the cycle for every project touched in the session, in parallel.
- `wrapup` or `/wrapup` is the end-of-session version. Runs sync across every touched project + writes a session reflection + closes out cleanly.

After a sync, you can either keep working in the same session (context window is now lighter because long-term state is on disk and in the Brain), or open a fresh terminal and start a clean Claude session. The fresh session will pick up exactly where you left off via HANDOFF.md and the memory layer, with zero context used.

The 1M context window on Max plans is generous. Most operators do 4-5 projects per session and `sync` between them or at the end, without hitting any wall.

### Picking back up in a new session

This is the fun bit. After a `sync` or `wrapup`, close the terminal entirely. Next time you sit down, run your orchestrator's launch alias (e.g. `myagent`), and the first message you type into Telegram can just be:

> hi

That single word triggers the maintenance + greeting digest protocol. The orchestrator runs through:

1. **Telegram tail check.** Pulls the last 30-50 messages so it knows what you were actually doing in the previous session, not just what's in HANDOFF.md.
2. **HANDOFF.md read** for the project (or projects) you were on.
3. **Unpushed commits scan** across active projects so it knows what's still local-only.
4. **Working-context recovery** via `bash scripts/load-context.sh`.
5. **Stale commit detection** via `bash scripts/commit-watcher.sh`.
6. **Open threads from the AI Brain** (NotebookLM) so anything you queried mid-session that you didn't act on resurfaces.

Then it sends you a single Telegram message: health status, open threads from last session, suggested priorities for today, unpushed commits if any. You can pick the priority and just say "yes" or "do that one first" and you're rolling again with full context, in a session that used zero tokens to get there.

Other greetings that fire the same protocol: `hey`, `hello`, `morning`, `yo`, `gm`, `good morning`, `sup`, `yes`.

If you want to skip the digest and jump straight to a specific project, just say `status <project>` instead. Same picking-back-up data, scoped to one project.

If something is on fire and you need to skip everything, lead with the actual request: "deploy the portfolio" or "fix the bug in NearbyMe" works. The orchestrator will recognise it as a task, not a greeting, and route immediately.

### Multi-project setup

The orchestrator lives in its own directory (e.g. `~/Documents/Xantham`). Projects can live anywhere on your machine. The orchestrator learns where each one lives from `docs/projects.md` (registered automatically the first time you create a new project, or by running `bash scripts/register-project.sh <folder> <description> [stack]`).

Working on multiple things in parallel is the default. Telling Telegram "work on NearbyMe and the portfolio in parallel" dispatches two agents in their own working trees so they don't trample each other. The orchestrator coordinates the merge back.

### Pattern that works for most operators

- Morning: open a fresh session, the orchestrator's morning digest fires automatically (if enabled) and tells you what's pending across all projects.
- Throughout the day: work in long focused blocks via Telegram, `sync` whenever you context-switch.
- End of day: `wrapup` runs sync across every touched project, writes a session reflection, closes cleanly.
- Next morning: fresh session, zero context, full state restored.

### When something goes wrong

- Read the `PITFALLS.md` file the wizard wrote during install. It catalogues the failure modes I've hit so you don't have to.
- `healthcheck` will tell you which subsystem is unhappy.
- `history "<keyword>"` finds anything I logged at the time.
- The safety hook blocks any destructive command (force push to main, `rm -rf`, `DROP TABLE`, etc) regardless of who asked. If you genuinely need to run one, you run it yourself in your own terminal, not via the orchestrator.

## Files in this repo

- **`README.md`**. This file. Start here.
- **`ARCHITECTURE.md`**. System map with Mermaid diagram, component descriptions, data flow, memory and safety cross-sections.
- **`SECURITY.md`**. Threat model, the three-bucket safety gate, known limitations, vulnerability disclosure.
- **`COMPARISON.md`**. Benchmark table vs the most-cited public agent frameworks and orchestrators.
- **`xantham-system-v31.md`** (~4900 lines). The landing file. Install wizard, day-1 user experience docs, architecture reference, advanced patterns, troubleshooting catalogue. The human-readable half.
- **`xantham-templates-v31.md`** (~9100 lines). The templates appendix. Every script body, hook template, settings.json variant, agent config, skill body, memory seed that the wizard generates. The wizard's install steps reference these by name; the user's Claude reads both files in sequence.
- **`archive/xantham-system-v30.md`** is the previous monolithic version (kept for upgrade-from-v30 reference).

Versions ship cumulatively. The latest pair on `main` is what the wizard install command points at.

## Modes

- **Simple mode.** Orchestrator + 9 specialists + Telegram + NotebookLM Brain + basic safety gate. Set up in roughly 30 minutes. $0/month (£0) plus your Claude.ai subscription.
- **Advanced mode.** Simple plus the v31 power-user stack: E1 semantic memory (sqlite-vec + Ollama), E3 Agent Teams (live shared whiteboard), E4 Observability (per-tool-call audit JSONL + live viewer), E5 Hardened safety gate, plus the Amazing Memory layer (cognitive overlay with episodic + semantic + procedural memory, Profile bucket, dream consolidation pass, active-recall pre-turn entity lookup), plus auth failover (the canary that flips your Claude Code over to a paid API key if your Max OAuth ever suspends). About an hour of setup. $0/month (£0) for the local stack. About $4/month (~£3) if you enable the optional `dream` consolidation pass (~$1 per weekly run on Anthropic API).

## Both Mac and Windows are supported

Every install command in the blueprint has both Mac and Windows versions side by side. Windows users use Git Bash or WSL2 for the `.sh` scripts.

## Versioning

The repo name doesn't include a version. The files inside do. Commit history shows version progression. If you forked at v30 and v31 ships, run `bash scripts/upgrade-<your-orchestrator-name>.sh` from your installed orchestrator (the wizard names the upgrade script after the orchestrator you picked at Q1, e.g. `upgrade-myagent.sh` if you named yours MyAgent, `upgrade-jarvis.sh` if you named yours Jarvis). The customisation-preserving merge walkthrough applies upstream changes without overwriting your additions.

## What's new in v31

- **Amazing Memory layer.** Cognitive overlay (episodic / semantic / procedural buckets, Karpathy three-bucket pattern with the Profile bucket as a first-class third leg), dream consolidation pass with hard $1 cost cap and dry-run default, pre-turn active-recall entity lookup with sub-50ms warm cache.
- **Auth failover.** A 4th SLO canary watches your Claude Code OAuth health. If it degrades 3 times running, the system flips you over to a separately-billed API key without losing the session. Caps any future Anthropic OAuth outage from days to minutes.
- **Wizard split.** v31 ships as two files. Landing (what humans read) plus templates appendix (what the install consumes). The single-monolith pattern is archived at `archive/xantham-system-v30.md`.
- **Pre-hoc reflection skill.** Your orchestrator now runs a 6-stage chain-pattern-interrupt before dispatching agents on fuzzy briefs or first-time multi-agent fan-outs. Catches wrong-direction dispatches before tokens are spent.
- **Hardened safety gate.** Force-push to protected branches becomes physically impossible, no approval can unlock it. CLI-rm whitelist covers npm rm, yarn remove, pnpm rm, brew uninstall, vercel env rm, etc.

## Sharing

This repo is public. Fork it, share the URL, hand the blueprint file to anyone with Claude Code. They'll have their own AI command centre running by the end of the afternoon.

The personal-state version (with bot tokens, project names, agent personalities, etc.) lives in your private repo. This public file is the universal template.

## Don't like it? Uninstall in 2 minutes

The wizard ships a real uninstall script that cleans up every side-effect location it wrote to (statusline, safety gate, shell profile launch functions, launchd plists, AppleScript wrappers, the project dir itself). Run it in two phases.

```bash
# Phase 1: dry-run -- prints the manifest, changes nothing
bash ~/Documents/MyAgent/scripts/uninstall.sh --dry-run

# Phase 2: apply -- prompts before touching paid assets (the auth-failover
# API key, the global safety gate that protects other Claude Code projects)
bash ~/Documents/MyAgent/scripts/uninstall.sh

# Then remove the Telegram plugin from Claude Code
claude plugin uninstall telegram@claude-plugins-official
```

The uninstall is **idempotent** (safe to run twice) and uses sentinel comments inside the files it owns, so it never touches a statusline or safety gate you wrote yourself. Default behaviour keeps the global safety gate (it protects other Claude Code projects on this machine) and the optional auth-failover API key (paid asset). Pass `--yes` if you want non-interactive defaults.

Things the script does NOT touch on purpose: your Claude.ai subscription, the Telegram bot on Telegram's servers (revoke via @BotFather for a clean break), the NotebookLM notebook on Google's servers.

## Contributing

Currently a single-maintainer project. If you find bugs or have suggestions, open an issue. PRs welcome but please discuss first to avoid wasted work.

## License

MIT. See [LICENSE](LICENSE). Fork it, hand it to teammates, ship it inside your own product. Attribution appreciated, not required.

## Contact

Open a GitHub issue. The maintainer reads them.

For security vulnerabilities, use GitHub's private vulnerability reporting (per [SECURITY.md](SECURITY.md)) rather than a public issue, so the disclosure stays out of the public timeline until a fix lands.
