# Xantham System

> Self-installing personal AI orchestrator. Hand the blueprint to a fresh Claude Code session and it builds you a full multi-agent system.

## What you get

- A master orchestrator (your AI) plus a crew of 9 specialist agents (engineering, research, growth, deploy, writing, trading, business, human dynamics, plus the orchestrator)
- Telegram interface so you can run the system from your phone
- Persistent memory that survives across sessions, with semantic search
- Live shared whiteboard so multiple agents coordinate cleanly when running in parallel
- Per-tool-call audit log + safety gate that prevents destructive accidents
- A self-installing wizard that walks you through setup in 20-60 minutes

## How to install

1. Open a fresh Claude Code session pointed at an empty directory you want to become your AI command centre
2. Paste this prompt:

   ```
   Read the xantham-system-v30.md blueprint at https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/xantham-system-v30.md
   Install it in <simple|advanced> mode.
   My OS is <mac|windows|linux>.
   My name is <your name>. My Telegram bot token is <token>. My NotebookLM Brain notebook ID is <id> (or "create a new one").
   Walk me through it.
   At the end, generate SETUP-CHECKLIST.md per the "Post-install verification" section.
   ```

3. Walk through the questions
4. When done, the wizard generates eight files at the project root: `SETUP-CHECKLIST.md`, `USER-GUIDE.md`, `BACKUP-AND-RECOVERY.md`, `FIRST-WEEK.md`, `PITFALLS.md`, `MEMORY-HYGIENE.md`, plus two helper scripts in `scripts/`
5. Close the session, run your new agent's terminal alias (e.g. `myagent`), and the first session walks you through `SETUP-CHECKLIST.md` before any real work

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

## A note on the maintainer

If you see references to "your orchestrator" inside the blueprint or in commits — that's the maintainer's personal AI agent built from this same blueprint. Yours will have whatever name you pick during the install wizard. The blueprint is system-agnostic.

## Contributing

Currently a single-maintainer project. If you find bugs or have suggestions, open an issue. PRs welcome but please discuss first to avoid wasted work.

## License

Add your own license here. The maintainer ships personal AI infrastructure publicly because it's useful to others, not because it's a product.

## Contact

Open a GitHub issue. The maintainer reads them.
