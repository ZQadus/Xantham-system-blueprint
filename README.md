# Xantham System

> Self-installing personal AI orchestrator. Hand the blueprint to a fresh Claude Code session and it builds you a full multi-agent system. Built for someone managing multiple projects who wants to drive everything (research, code, deploys, writing, planning) from their phone via Telegram, with a team of AI specialists handling the actual work.

## What you get

- A master orchestrator (your AI) plus a crew of 9 specialist agents (engineering, research, growth, deploy, writing, trading, business, human dynamics, plus the orchestrator)
- Telegram interface so you can run the system from your phone
- Persistent memory that survives across sessions, with semantic search
- Live shared whiteboard so multiple agents coordinate cleanly when running in parallel
- Per-tool-call audit log + safety gate that prevents destructive accidents
- A self-installing wizard that walks you through setup in 20-60 minutes

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

## Before you start

You'll need:
- **Mac or Windows** (Linux works too, treated like Mac)
- **Claude Code** installed (claude.com/claude-code)
- **An active Claude.ai paid plan**: Pro ($20/mo), Max 5x ($100/mo), or Max 20x ($200/mo). The system uses your existing subscription - no additional API charges. Pro works; Max is recommended for parallel agent work.
- **About 90 minutes** of your time (60 min if you have Node/Git/Homebrew already installed; 30 min more if starting from a fresh laptop)

The wizard will check for Node 18, Git, jq, sqlite3, and bun on first run, and tell you exactly how to install any that are missing.

**Accounts you'll need:**
- Claude.ai paid plan (required, see above)
- Telegram (free, ~2 min to create the bot via @BotFather)
- Google (free, optional - for the NotebookLM AI Brain. Skip if uncomfortable)
- GitHub (free, optional - for auto-creating private repos for your projects)

**Cost summary:** £0/month for the system itself. Just your Claude.ai subscription.

## Data and privacy

- Your conversations + memory files live on your laptop only. Not synced anywhere.
- Telegram traffic flows: phone → Telegram servers → your bot → your laptop. Same posture as any Telegram bot.
- NotebookLM session summaries push to Google's servers IF you enable the Brain. Skip the Brain if uncomfortable.
- Claude API traffic flows to Anthropic via your existing Claude Code subscription. No new keys.
- Audit logs are local-only and gitignored. Zero analytics or telemetry to the maintainer.

## A note on the maintainer

If you see references to `your orchestrator` or `cortana` inside the blueprint - that's the maintainer's literal name. Yours will be whatever you pick during the install wizard. The blueprint is system-agnostic.

## How to install

1. Open a fresh Claude Code session pointed at an empty directory you want to become your AI command centre.

   **If you've never run Claude Code from a terminal before:**
   - **Mac:** Open Terminal (⌘+space, type Terminal). Type `mkdir ~/Documents/MyAgent && cd ~/Documents/MyAgent && claude`. Press enter.
   - **Windows:** Open PowerShell. Type `mkdir $env:USERPROFILE\Documents\MyAgent ; cd $env:USERPROFILE\Documents\MyAgent ; claude`. Press enter.
   - **Linux:** Same as Mac.

   You'll see a screen that says **"Welcome to Claude Code"** with a `>` prompt. NOT the regular terminal prompt (`$` or `%`). If you see `$` or `%` after running `claude`, the command didn't launch the TUI - check that Claude Code is installed (claude.com/claude-code).

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

   You don't need ANY values up front. The wizard asks one question at a time, in plain English, and tells you exactly how to get any external value (bot token, notebook ID) as it reaches that step. Total time: 20-45 minutes including bot setup.

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

- **`xantham-system-v31.md`** (~4900 lines). The landing file. Install wizard, day-1 user experience docs, architecture reference, advanced patterns, troubleshooting catalogue. The human-readable half.
- **`xantham-templates-v31.md`** (~9100 lines). The templates appendix. Every script body, hook template, settings.json variant, agent config, skill body, memory seed that the wizard generates. The wizard's install steps reference these by name; the user's Claude reads both files in sequence.
- **`archive/xantham-system-v30.md`** is the previous monolithic version (kept for upgrade-from-v30 reference).

Versions ship cumulatively. The latest pair on `main` is what the wizard install command points at.

## Modes

- **Simple mode.** Orchestrator + 9 agents + Telegram + NotebookLM Brain + basic safety gate. Set up in ~20 minutes. £0/month plus your Claude.ai subscription.
- **Advanced mode.** Simple plus the v31 power-user stack: E1 semantic memory (sqlite-vec + Ollama), E3 Agent Teams (live shared whiteboard), E4 Observability (per-tool-call audit JSONL + live viewer), E5 Hardened safety gate, plus the Amazing Memory layer (cognitive overlay with episodic + semantic + procedural memory, Profile bucket, dream consolidation pass, active-recall pre-turn entity lookup), plus auth failover (the canary that flips your Claude Code over to a paid API key if your Max OAuth ever suspends). ~45-60 minutes setup. £0/month for the local stack. ~$4/month if you enable the optional `dream` consolidation pass (~$1 per weekly run on Anthropic API).

## Both Mac and Windows are supported

Every install command in the blueprint has both Mac and Windows versions side by side. Windows users use Git Bash or WSL2 for the `.sh` scripts.

## Versioning

The repo name doesn't include a version. The files inside do. Commit history shows version progression. If you forked at v30 and v31 ships, run `bash scripts/upgrade-xantham.sh` from your installed orchestrator. The customisation-preserving merge walkthrough applies upstream changes without overwriting your additions.

## What's new in v31

- **Amazing Memory layer.** Cognitive overlay (episodic / semantic / procedural buckets, Karpathy three-bucket pattern with the Profile bucket as a first-class third leg), dream consolidation pass with hard $1 cost cap and dry-run default, pre-turn active-recall entity lookup with sub-50ms warm cache.
- **Auth failover.** A 4th SLO canary watches your Claude Code OAuth health. If it degrades 3 times running, the system flips you over to a separately-billed API key without losing the session. Caps any future Anthropic OAuth outage from days to minutes.
- **Wizard split.** v31 ships as two files. Landing (what humans read) plus templates appendix (what the install consumes). The single-monolith pattern is archived at `archive/xantham-system-v30.md`.
- **Pre-hoc reflection skill.** Cortana now runs a 6-stage chain-pattern-interrupt before dispatching agents on fuzzy briefs or first-time multi-agent fan-outs. Catches wrong-direction dispatches before tokens are spent.
- **Hardened safety gate.** Force-push to protected branches becomes physically impossible, no approval can unlock it. CLI-rm whitelist covers npm rm, yarn remove, pnpm rm, brew uninstall, vercel env rm, etc.

## Sharing

This repo is public. Fork it, share the URL, hand the blueprint file to anyone with Claude Code. They'll have their own AI command centre running by the end of the afternoon.

The personal-state version (with bot tokens, project names, agent personalities, etc.) lives in your private repo. This public file is the universal template.

## Don't like it? Uninstall in 2 minutes

```bash
rm -rf ~/Documents/MyAgent
claude plugin uninstall telegram@claude-plugins-official
```

That removes everything. Your Claude.ai subscription, Telegram bot, and NotebookLM notebook stay where they are - delete those manually if desired.

## Contributing

Currently a single-maintainer project. If you find bugs or have suggestions, open an issue. PRs welcome but please discuss first to avoid wasted work.

## License

Add your own license here. The maintainer ships personal AI infrastructure publicly because it's useful to others, not because it's a product.

## Contact

Open a GitHub issue. The maintainer reads them.
