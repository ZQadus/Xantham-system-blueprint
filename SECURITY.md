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
- `rm` with any flag (the CLI-rm whitelist exempts known-safe variants like `npm rm`, `vercel env rm`, `docker rm`, `gh secret rm`, `git rm`)
- `DROP TABLE`, `TRUNCATE`, `DELETE FROM` without a `WHERE` clause
- `sudo` anything
- Direct edits to `.env` files, SSH private keys, GPG keys

### 3. Allowed with audit

Everything else passes through. Every tool call is still recorded in the audit log (`.claude/hooks/audit-log-hook.sh`) so you can reconstruct what happened after the fact. Audit logs are local-only and gitignored by default.

The canonical implementation of the gate is the one shipped by the blueprint at `.claude/hooks/safety-gate.sh` (project-level) and `~/.claude/hooks/safety-gate.sh` (global). Both are kept in sync via `scripts/sync-safety-gates.sh`. Diverging them is a known footgun, see the install verification step in `xantham-system-v31.md`.

## Known limitations

These are real. Read them.

### The early-install window

The wizard runs for 20-60 minutes. The safety gate body is generated and activated around Q6-Q9 of the wizard, depending on the mode you pick (Simple vs Advanced). That means there is a **15-40 minute window of unprotected execution** at the start of the install where Claude Code is running with `--dangerously-skip-permissions` enabled and the gate is not yet in place.

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
- **Pin to a known-good commit.** If you do not want bleeding-edge, fork this repo, pin to a commit you have reviewed, and change the install command's URL to point at your fork.
- **MIT license.** This blueprint is MIT-licensed (see `LICENSE`). You can audit, modify, and redistribute. The maintainer makes no warranty.
- **No telemetry to the maintainer.** Audit logs are local-only and gitignored. The blueprint does not phone home.

## Updates

Security fixes ship as new commits on `main` with a `security:` prefix in the commit message. Watch the repo (GitHub bell -> Custom -> Releases + Issues) to get notified. Major safety-gate changes are also called out in the changelog section of `xantham-system-v31.md` (or the equivalent file on the latest version).
