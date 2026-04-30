# Xantham System

> Self-installing personal AI orchestrator. Hand the blueprint to a fresh Claude Code session and it builds you a full multi-agent system. Built for someone managing multiple projects who wants to drive everything (research, code, deploys, writing, planning) from their phone via Telegram, with a team of AI specialists handling the actual work.

## What you get

- A master orchestrator (your AI) plus a crew of 9 specialist agents (engineering, research, growth, deploy, writing, trading, business, human dynamics, plus the orchestrator)
- Telegram interface so you can run the system from your phone
- Persistent memory that survives across sessions, with semantic search
- Live shared whiteboard so multiple agents coordinate cleanly when running in parallel
- Per-tool-call audit log + safety gate that prevents destructive accidents
- A self-installing wizard that walks you through setup in 20-60 minutes

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
   Read the Xantham System v30 blueprint at https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/xantham-system-v30.md and run the full setup wizard. Walk me through every step, ask me one question at a time, and don't assume any values. Guide me through getting whatever you need (Telegram bot token, NotebookLM notebook, agent name, etc.) as the wizard reaches each one.
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

## Files in this repo

- **`xantham-system-v30.md`** — the canonical blueprint (~5800 lines). Includes the install wizard, every template file, day-1 user experience docs, customisation-preserving upgrade walkthrough, and the architecture reference.

Future versions ship as `xantham-system-v31.md`, `v32.md`, etc. — never overwrite an existing version. The latest is whatever has the highest version number on `main`.

## Modes

- **Simple mode** — orchestrator + 9 agents + Telegram + NotebookLM Brain + basic safety gate. Set up in ~20 minutes. £0/month plus your Claude Max subscription.
- **Advanced mode** — Simple plus four extensions: E1 semantic memory (sqlite-vec), E3 Agent Teams, E4 Observability audit, E5 Hardened safety gate. ~45-60 minutes. Still £0/month — all extensions are local + free.

## Both Mac and Windows are supported

Every install command in the blueprint has both Mac and Windows versions side by side. Windows users use Git Bash or WSL2 for the `.sh` scripts.

## Versioning

The repo name doesn't include a version. The file inside does. Commit history shows version progression. If you forked at v30 and v31 ships, run `bash scripts/upgrade-xantham.sh` from your repo and the customisation-preserving merge walkthrough applies upstream changes without overwriting your additions.

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
