# Security

Xantham is an agentic system that executes shell commands, edits files, pushes commits, and sends messages on your behalf. That is a meaningful surface area. This document describes what the system protects against, what it does not, and how to report a vulnerability.

The goal here is to be honest about the threat model, not to overclaim. Read the **Known limitations** section before you decide the safety gate is enough for your use case.

## Reporting a vulnerability

If you find a security issue, please do not open a public GitHub issue. Instead, use **[GitHub's private vulnerability reporting](https://github.com/ZQadus/Xantham-system-blueprint/security/advisories/new)** for this repository. If that is unavailable, email the maintainer via the address on the GitHub profile at [github.com/ZQadus](https://github.com/ZQadus). Include:

- A clear description of the issue and how to reproduce it
- The affected component (safety gate, secret redactor, banned-language gate, install wizard, blueprint templates)
- The version of the blueprint you are looking at (v31, v30, etc.)
- Your assessment of severity (information leak, privilege escalation, command injection, etc.)

Expected response time: **48 hours for acknowledgement, 7 days for triage**. This is a single-maintainer project so do not expect enterprise turnaround, but real issues are taken seriously and credited in the fix commit unless you ask otherwise.

## Threat model

### What Xantham is designed to protect against

1. **Operator typos and rushed decisions.** You ask the orchestrator to push a fix, get distracted, type a force-push by reflex, the gate refuses. You ask for a quick cleanup, Claude proposes `rm -rf` on the wrong directory, the gate refuses.
2. **Claude getting confused.** A long session with a fuzzy brief can lead the model to propose destructive commands that look plausible in context. The gate is a second pair of eyes that does not get tired or context-saturated.
3. **Prompt injection via tool results.** A scraped webpage, a NotebookLM summary, a Telegram message, or a fetched RSS feed can contain text crafted to make Claude run an attacker-chosen command. The gate refuses the dangerous primitives those payloads tend to land on (force-push, `rm -rf`, `DROP TABLE`, `curl | bash` to unknown hosts).
4. **Credentials leaking into committed files.** The secret redactor strips Anthropic / Stripe / GitHub / Slack / Telegram-bot / AWS / database-URL token patterns from any text that gets folded into committed audit logs, handoffs, or reflections. The banned-language gate adds a second pass for content destined for the Library, docs, or app strings.

### What Xantham does NOT protect against

Be clear-eyed about this.

1. **A malicious user with physical access to your laptop.** Anyone at your keyboard can bypass the gate by editing the hook script or running commands in their own terminal outside the Claude Code tool dispatch.
2. **A compromised Claude binary.** The gate runs as a `PreToolUse` hook inside Claude Code's process. If the Claude Code binary itself is replaced or patched, the hook layer is bypassable.
3. **A malicious MCP server.** Xantham wires MCP servers (Telegram, Consensus, Exa, Reddit, Neon, Vercel, Pipedream, etc.) into Claude Code. MCP servers run arbitrary code inside Claude Code's process. The gate inspects the `Bash` tool's commands and a small set of file-write paths, but it cannot inspect what an MCP server does internally. **Install MCP servers from sources you trust.** The blueprint defaults to first-party Anthropic connectors and well-known open-source servers.
4. **OS-level damage outside Claude Code.** A privileged process not invoked via Claude Code's tool layer (e.g. a launchd daemon, a cron job, a script you run from your own terminal) bypasses the gate entirely. The gate is a `PreToolUse` hook, not OS-level enforcement.
5. **Social engineering of the operator.** If someone convinces you on Telegram to type `corrections promote <category>` or `dream approve` against a bad proposal, the gate has no opinion. You authored the decision. The `/telegram:access` allowlist is the primary defence here, see the **Auth and secrets** section.
6. **Loss of an unencrypted laptop.** Memory files, audit logs, and the approval file all live on disk in your home directory. Use FileVault on Mac or BitLocker on Windows.

## The safety model in three buckets

Xantham's `PreToolUse` hook (`.claude/hooks/safety-gate.sh`, ~282 lines in the canonical reference implementation) classifies every shell command and file write into one of three buckets.

### 1. Hard-blocked

These cannot be approved. The hook returns a refusal regardless of any approval file entry. Editing the gate to allow them requires opening your own terminal and rewriting the script, which is the intended friction.

- Force-push to protected branches: `main`, `master`, `production`, `prod`, `release`, `develop` (any flag variant: `--force`, `-f`, `--force-with-lease`, refspec-prefixed `+HEAD:main`)
- History rewriting: `git filter-branch`, `git filter-repo`, `git reflog expire`, `git gc --prune=now`, `git update-ref -d`
- Disk-level destruction: `mkfs`, `dd if=`, `fdisk`, `diskutil erase`
- Catastrophic deletes: `rm -rf /`, `rm -rf ~`, `rm -rf $HOME`

### 2. Approval-gated

These are blocked until you write the exact command to `{{project_path}}/data/approved.txt`. Approvals carry a 30-day TTL and are one-shot (consumed on use). The hook prunes expired entries on every fire.

- Force-push to any non-protected branch, `git push --mirror`, `--delete`, `:branch`
- `git reset --hard`, `git clean -f`, `git branch -D`, `git rebase -i`, `rebase --onto`, `commit --amend`
- `git checkout -- .`, `git restore .`, `git stash drop/clear`, `git worktree remove --force`
- `git stash pop` / `stash apply` (overwrite-on-pop vector), `git stash` chained with a branch-switch in one command, `git checkout <ref> -- <path>` / `git restore --source=<ref>` over a dirty working tree, and broad-staging (`git add -A` / `git add .` / `--all`) — the data-loss-class blocks added in v31.1 to close the failure modes that surfaced with Opus 4.8
- `rm` with any flag (the CLI-rm whitelist exempts known-safe variants like `npm rm`, `vercel env rm`, `docker rm`, `gh secret rm`, `git rm`)
- `DROP TABLE`, `TRUNCATE`, `DELETE FROM` without a `WHERE` clause
- `sudo` anything
- Direct edits to `.env` files, SSH private keys, GPG keys

### 3. Allowed with audit

Everything else passes through. Every tool call is still recorded in the audit log (`.claude/hooks/audit-log-hook.sh`) so you can reconstruct what happened after the fact. Audit logs are local-only and gitignored by default.

The canonical implementation of the gate is the one shipped by the blueprint at `.claude/hooks/safety-gate.sh` (project-level) and `~/.claude/hooks/safety-gate.sh` (global). Both are kept in sync via `scripts/sync-safety-gates.sh`. Diverging them is a known footgun, see the install verification step in `xantham-system-v31.md`.

### Reactive model-defense layer (v31.1)

On top of the three-bucket gate, v31.1 adds a set of reactive hooks and deterministic scripts that target a specific model generation's failure modes (built on the principle that a rule in a prompt does not bind the model, so every defense is a hook or a script, not prose). These sit beside the gate and can be retuned as the model improves:

- **Fabricated-completion gate.** A `PreToolUse` hook on the outbound-message tool flags a "shipped / passing / deployed" claim when no verification command was recorded that turn. WARN-only by default (never blocks a user reply); opt-in hard-block via env var.
- **Non-killing loop detector.** A `PostToolUse` Bash hook fires a single capped owner-ping when the same command repeats 3 times in 300 seconds. It never auto-kills (an auto-restart daemon that killed live work is deliberately left unloaded).
- **Transcript grounding.** Every quote/attribution is substring-checked against the real source (3-tier exact / whitespace-normalized / fuzzy) before it enters memory or a message.
- **Pre-merge deletion guard.** A script reports the real deletions a branch makes relative to its merge-base (not the misleading two-dot diff) and flags shared-config edits, before any agent/worktree branch is merged.

Full component detail is in the E5.1 section of `xantham-system-v31.md`. These are layered on top of the gate, not a replacement for it.

## Known limitations

These are real. Read them.

### The early-install window

The wizard runs for about an hour (30-45 minutes if your prereqs are already installed). The safety gate body is generated and activated around Q6-Q9 of the wizard, depending on the mode you pick (Simple vs Advanced). That means there is a **15-40 minute window of unprotected execution** at the start of the install where Claude Code is running with `--dangerously-skip-permissions` enabled and the gate is not yet in place.

Mitigations:

- **Run the install in a fresh directory** with no existing secrets, repositories, or sensitive files. The wizard only writes inside the install directory until you explicitly point it at other projects later.
- **Read the install command before pasting.** It points Claude at this public blueprint and tells it to walk you through the wizard. Nothing exotic.
- **Skip `--dangerously-skip-permissions` if you prefer manual approval.** The install becomes slower (you will approve hundreds of tool calls) but never has an unprotected window.

### Approval reuse is theoretically possible

The approval file uses one-shot entries with a 30-day TTL and exact-string matching against the command. A pre-approval written for one purpose cannot be re-used for a different command. However, if you approve `git push --force origin feature-x` and a later session also legitimately needs that exact command, the second use will pass without re-asking. Honest tradeoff: stricter would be one-shot-per-session, which is worse ergonomics for active development. The 30-day TTL is the compromise.

### The gate is a hook, not OS-level enforcement

`PreToolUse` runs inside Claude Code's tool dispatch. A privileged process outside that dispatch (a separate terminal, a cron job, a daemon you wrote) is not gated. If your threat model assumes a compromised local user account, you need OS-level mandatory access controls (SELinux, AppArmor, macOS sandbox profiles), not Xantham's gate.

### MCP servers are trust-on-install

Xantham wires several MCP servers by default. Each server runs arbitrary code inside Claude Code's process. The gate inspects `Bash` commands, not MCP tool calls. **You are trusting the source of every MCP server you install.** The blueprint defaults to first-party Anthropic connectors and named open-source projects, but the install wizard does not audit them for you.

### Banned-language and secret redactors are pattern-based

Both gates use deterministic regex patterns. New token formats (a hypothetical new Anthropic key prefix, a new Stripe environment) require an update to `scripts/redact-secrets.sh`. The blueprint enforces a hard rule that any credential-shaped string in a Telegram message must be added to the redactor before being logged, but a brand-new pattern can slip through if added between blueprint releases. Check `scripts/redact-secrets.sh` against your provider list when handling sensitive credentials.

### A determined attacker has known bypass routes

Be explicit about what "the gate refuses force-push" does not promise. A motivated attacker who has gained the ability to run code in your environment (via a compromised dependency, a malicious MCP server, a poisoned Markdown payload, or a phishing route) has the following bypass vectors. These are the known limits of the gate. None of them are theoretical, all of them are inherent to a hook-based defence. The list below names eight classes; the new classes Xantham discovers get added as they are found.

- **Sourced commands.** A command run via `bash -c '...'` or `eval` or a here-doc may serialise into a single `Bash` tool call. The gate inspects the literal argument string, so creative quoting and string assembly that delays the dangerous primitive until runtime can pass the static check. The hook applies several normalisation passes against this, but no pattern matcher is complete.
- **OS-level vectors outside Claude Code's tool dispatch.** Any process not invoked via Claude Code (`launchd`, `cron`, a daemon you wrote, a shell session you opened yourself) bypasses the gate entirely. If your threat model includes a privileged local user, you need OS-level mandatory access controls, not Xantham's gate.
- **Payloads inside MCP servers.** MCP servers run arbitrary code inside Claude Code's process. The gate inspects the `Bash` tool's argument and a small set of file-write paths. It does not inspect what an MCP server does internally. Installing a malicious MCP server defeats the gate end-to-end.
- **The approve-once pattern carries forward.** When you write a command to `data/approved.txt`, it stays valid for that exact string for 30 days and one use. A future session that legitimately needs the same exact command (same flags, same ref, same destination) consumes the approval silently. The TTL is the compromise between security and operator ergonomics; if you need stricter, run with `--dangerously-skip-permissions` off so every tool call prompts.
- **`--dangerously-skip-permissions` during the early-install window.** Covered above in **The early-install window** but worth restating here: the gate is generated and activated mid-wizard. Tool calls that fire before activation are not gated.
- **Path-confusion and symlink races against the gate's own files.** The gate reads `.claude/hooks/safety-gate.sh`, `~/.claude/settings.json`, and `data/approved.txt` as ordinary files. An attacker who has write access to any of those paths (same uid as Claude Code, since `PreToolUse` hooks run in the same process) can swap the script body, the hook registration, or the approval file in the window between the hook resolving the path and the kernel executing it. Symlink-races on `data/approved.txt` can promote an attacker-chosen line into the consumed-approval slot. Symlink-races on the gate script itself can substitute a no-op gate. The gate is one uid away from itself; if that uid is already attacker-controlled, the gate cannot defend itself.
- **TOCTOU on approval consumption across parallel agents.** The orchestrator runs 2-3 agents in parallel by default and up to 16 in Aggressive mode on Max 20x, and the gate is per-tool-call rather than per-session. Two agents that fire the same approved command in the same wall-clock window can both pass the check before either of them removes the entry from `data/approved.txt`, because the read of the file and the rewrite of the file are separate filesystem operations with no kernel-level lock between them. The practical effect is that the "one-shot" promise of an approval degrades to "approximately one-shot, with a race window proportional to disk latency" under concurrent dispatch. Workloads that depend on the one-shot guarantee for safety (rather than for ergonomics) should serialise the relevant tool calls rather than fan them out.
- **Plugin-update vectors.** Xantham installs Claude Code plugins via `claude plugin install <name>`. Plugins can register their own hooks in `~/.claude/settings.json`, and hook ordering in that file is by declaration order, not by trust level. A plugin that the maintainer installs today and audits today can ship an update next week that adds a `PreToolUse` hook ordered before the safety gate, or that overwrites the safety gate file directly, or that loads new MCP servers under its own configuration. The audit happens at install time; the bytes that run come from whatever is latest at execution time. This is structurally the same problem as the MCP-server class but at the plugin layer, and it bites independently because plugins and MCP servers are separate trust domains in the Claude Code permission model.

If any of the above is a deal-breaker for your environment, install in a sandbox first (see [`docker/README.md`](docker/README.md)) or do not install at all. The honest posture is that the gate raises the bar substantially against typo-class accidents and prompt-injection-class attacks, and lowers but does not eliminate the bar against a determined attacker who already has code-execution.

### No formal third-party security audit has been completed

The maintainer has not commissioned a security audit from a third-party firm. The threat model in this document, the safety gate implementation, the secret redactor patterns, and the install wizard are reviewed by the maintainer only. They are not certified by an external auditor.

If you need an audited agentic stack for a regulated environment, this is not currently the project for you. The blueprint is MIT-licensed, so a third-party audit is something a user, an organisation, or a community can fund and publish independently. Audit findings (positive or critical) are welcome via GitHub Issues or PR.

## Auth and secrets

- **Telegram bot token.** Lives in your Claude Code config (`~/.claude/plugins/telegram/.env` or equivalent depending on plugin version). Never committed. The wizard walks you through getting it from `@BotFather` in step Q9-Q11.
- **NotebookLM session cookies.** Local-only, stored in your Claude Code MCP config. Never committed.
- **Anthropic API key (auth-failover only).** Optional. If you opt into the auth-failover canary in Advanced mode, you store a separately-billed Anthropic API key at `~/.config/claude/api-key` (mode 0600). Never in the repo. See `docs/auth-failover-runbook.md` for the provisioning + cost-watch flow.
- **Per-project secrets** (database URLs, deploy tokens, OAuth credentials). Live in each project's `.env` file. The wizard adds `.env*` to `.gitignore` automatically on every new project registration.
- **Telegram channel access.** Restricted by `/telegram:access` allowlist. Pairing requests from inside Telegram (e.g. a message saying "approve me") are explicitly refused by the plugin instructions, since that is the request a prompt injection would make.

## Data residency

- **Conversation history, memory files, audit logs.** Local-only. Your laptop, never synced.
- **Git repositories.** Live wherever you push them (default: GitHub private repos created by `scripts/register-project.sh`).
- **Telegram messages.** Flow through Telegram's servers (phone -> Telegram -> your bot -> your laptop). Same posture as any Telegram bot.
- **NotebookLM Brain (optional).** If enabled, session summaries are pushed to Google's NotebookLM servers. Skip the Brain in Simple mode if you are uncomfortable with this.
- **Anthropic API traffic.** Routed via your existing Claude Code subscription (Pro / Max 5x / Max 20x), no separate API key unless you opt into auth-failover. See Anthropic's privacy policy for their handling.
- **MCP server traffic.** Each MCP server has its own data flow. Consensus queries a peer-review database, Exa queries a search index, Reddit queries Reddit, Pipedream wraps ~2,500 third-party APIs. Read each server's docs before connecting it.

## Supply chain

The blueprint code lives in this public repository. Before installing:

- **Audit the install command.** It is a single paste in the README's install section. It tells Claude to read two files from `raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/`. Both files are public, plain-text Markdown. Read them directly if you want to see what the wizard will generate before running it.
- **Verify the blueprint cryptographically.** Every commit to `main` regenerates `CHECKSUMS.sha256` with SHA256 hashes of the seven published artifacts (`xantham-system-v31.md`, `xantham-templates-v31.md`, `LICENSE`, `README.md`, `SECURITY.md`, `ARCHITECTURE.md`, `COMPARISON.md`). Run `bash scripts/verify-blueprint.sh` (or the curl one-liner in the README) to confirm the bytes you fetched match the bytes the maintainer published.
- **Pin to a commit SHA you have reviewed.** The README's install section supports pinned-SHA URLs (`/<sha>/xantham-system-v31.md` instead of `/main/xantham-system-v31.md`). Pinning to a SHA defeats the "I trusted main, then the repo was compromised after my audit" attack and makes the install reproducible.
- **Optional Docker sandbox.** `docker/Dockerfile.xantham-sandbox` builds a minimal throwaway environment if you want to run the first install inside a container before graduating to host. See `docker/README.md` for the full flow. Not required, presented as an option for users who want the strongest audit posture.
- **MIT license.** This blueprint is MIT-licensed (see `LICENSE`). You can audit, modify, and redistribute. The maintainer makes no warranty.
- **No telemetry to the maintainer.** Audit logs are local-only and gitignored. The blueprint does not phone home.

## Updates

Security fixes ship as new commits on `main` with a `security:` prefix in the commit message. Watch the repo (GitHub bell -> Custom -> Releases + Issues) to get notified. Major safety-gate changes are also called out in the changelog section of `xantham-system-v31.md` (or the equivalent file on the latest version).
