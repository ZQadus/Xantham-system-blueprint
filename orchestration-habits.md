---
version: 1.0.0
last_updated: 2026-05-12
source: github.com/ZQadus/Xantham-system-blueprint/blob/main/orchestration-habits.md
license: MIT
---

# Orchestration habits

Operational rules baked into how Xantham (and any Cortana-style multi-agent system) works. These are general, apply to all installs, and travel as a single drop-in file.

## How to install

Tell your orchestrator `sync habits` (or `install habits` / `update habits`). The orchestrator's `<orchestrator>-sync-habits` skill picks up the request, fetches the latest version of this file, runs everything in the manifest section below, and reports back on the messaging channel. The user does not run install commands. If you want the manual fallback, see `install-xantham-habits.sh` at the repo root.

The user-facing flow:

1. **Fresh install**: `git clone https://github.com/ZQadus/Xantham-system-blueprint && cd Xantham-system-blueprint && claude`, then say `sync habits` in the first session.
2. **Existing install, add habits**: open your orchestrator session, say `sync habits`.
3. **Update habits**: same trigger. Re-running is idempotent; only new manifest entries fire.
4. **Upgrade a friend's install**: friend opens their existing orchestrator session, says `sync habits`. Agent pulls upstream + installs whatever is new.

---

## Reply discipline

Anchor: `#reply-discipline`

- Always reply on the user's primary channel (Telegram, Slack, whatever the install configured) immediately. Never leave the user waiting in silence while an agent runs.
- The reply must go through the messaging tool (e.g. `mcp__plugin_telegram_telegram__reply`). Plain stdout / terminal text is invisible on the user's phone.
- This applies even when a skill is driving the turn. Skill instructions shape the CONTENT of the reply, not the CHANNEL.
- No em-dashes, no signoff, no AI tells (no "I'd be happy to", "Certainly!", "Great question"), no marketing superlatives.
- Plain questions in plain language. Never label them D1 / D2 / A / B — the user reads on a phone, codes are confusing.
- When dispatching a specialist, name them with `@` (e.g. "@kai is on this") so the user knows who is on the work.
- Always announce who does the work — either the agent name or "doing this myself with skill X loaded". The user cannot see Bash calls; the reply is their only visibility.

### Enforcement stack (the rule is load-bearing, the stack matters more than the habit text)

Five mechanisms back this rule:

1. **UserPromptSubmit reminder injection** — `.claude/hooks/telegram-reply-reminder.sh`. Detects when the inbound prompt has a Telegram channel tag, prepends a loud `TELEGRAM TURN — REPLY DISCIPLINE` context block to the prompt. Costs about 60 tokens per turn.
2. **Per-turn contract** — `data/runtime/turn-contract.json` (0600 perms). Same hook writes a JSON contract recording guarantees expected for this turn. Cleared on every non-Telegram turn so it cannot go stale.
3. **Stop-side verification** — `.claude/hooks/stop-verify-contract.sh`. Reads the contract, scans the audit log, auto-logs a correction with category `forgot-telegram-reply` if zero reply-tool calls fired after a Telegram turn started.
4. **Correction promotion at threshold** — `scripts/promote-correction.sh`. When `forgot-telegram-reply` crosses 3x, the system auto-drafts a rule promotion into CLAUDE.md.
5. **Audit stream as substrate** — `data/audit/*.jsonl`. Every tool call logged. Stop-verify-contract reads this to introspect what fired.

### Optional hard-block (opt-in)

A sixth mechanism — a PreToolUse hook that BLOCKS plain-text output when the current turn originated from Telegram and no reply tool call has fired — ships as opt-in. Set `XANTHAM_REPLY_HARD_BLOCK=1` in `.claude/settings.json` env block to enable. Disabled by default in v1; toggle on if your install keeps missing replies despite mechanisms 1-5.

---

## Aggressive parallelism

Anchor: `#aggressive-parallelism`

- On Max 20x plans, single-agent dispatch is the wrong default. Default to 5-8 parallel dispatches when the work is decomposable.
- Use Agent Teams (a shared `data/agent-channels/<sprint>.md` whiteboard file) for sprints with 5+ lanes that cross-talk.
- Dispatch agents for any 3+ minute task so the main loop stays responsive to follow-up messages.
- Watch the 5-hour rolling rate limit when running 8+ heavy-research or build agents at once.
- On Pro plans, agents run sequentially regardless — the reply-first rule is optional because there is no parallel surface to lose responsiveness on.

---

## Install skills yourself, never punt commands at the user

Anchor: `#install-skills`

When the user asks for a Claude Code skill, plugin, or habits sync: the agent runs the install. The user never types `claude plugin install` or `git clone` or `curl` themselves. The agent picks up the trigger (`sync habits`, `install <skill>`, `add <plugin>`) and runs the commands via the Bash tool.

This rule is why `orchestration-habits.md` has a machine-readable manifest at the bottom — so the agent can parse and execute, not lecture the user.

---

## Council pattern

Anchor: `#council-pattern`

For high-stakes ambiguous decisions, invoke a 3-agent or 4-agent anonymised peer-ranked debate:

- **3-member**: internal decisions. Three lenses (A/B/C), anonymised, peer-rank each other, Chairman synthesises.
- **4-member**: product / market / customer-facing questions. Slots A/B/C are opinion lenses; slot D is a mandatory competitive-scan evidence base. D is not ranked, it is the ground truth A/B/C must reconcile against.
- Always orchestrator-invoked. Never exposed as a slash command.
- Every council output lands in `Library/decisions/council/<date>-<turn-id>.md`.

---

## Verification before completion

Anchor: `#verification-before-completion`

- Never claim work is complete, fixed, or passing without running a verification command.
- For shipped code: tests pass, build succeeds, deploy URL probes 200.
- For deploys behind GitHub-auto wiring (Vercel / Netlify / Cloudflare Pages / Railway / Render / Fly / GitHub Pages): `git push` success does NOT mean deploy success. Confirm via CLI (`vercel ls --prod`, `gh run list`) or a marker probe.
- For Cloudflare Workers without GitHub-auto: `git push` does NOT trigger a deploy. Run `npx wrangler deploy` after the push.
- Evidence before assertions.

---

## Spec-kit bridge for greenfield builds

Anchor: `#spec-kit-bridge`

For greenfield builds (no existing code) with budget > 4 hours, fire the spec-kit pipeline BEFORE engineering-agent dispatch. Pinned to `v0.8.8.dev0`. Walks: constitution -> spec -> clarify -> plan -> tasks -> analyze. Skip for bug fixes, ops work, refactors, brownfield, < 4h tasks.

---

## Plan before code

Anchor: `#plan-before-code`

- Any task touching 3+ files needs a written plan first.
- Any new feature or new dependency needs a plan.
- Multi-agent fan-out needs a plan.
- Plans go in `data/plans/<YYYY-MM-DD>-<slug>.md`.
- Skip for one-file edits, bug fixes with obvious root cause, ops work, tasks under an hour.

---

## Pre-hoc reflection on fuzzy briefs

Anchor: `#pre-hoc-reflection`

When a brief is fuzzy, run the 6-stage chain BEFORE dispatching: PERSONALITY, ROLE, TASK, OUTCOME, PERSISTENCE, RISK-INFLECTION-CHECK. Cheap, catches expensive misdispatches.

---

## Built-to-scale, never break existing users

Anchor: `#built-to-scale`

Every change preserves current user behaviour (back-compat-first) and is designed for 100x current load from day one. Zero silent breaking changes.

---

## Published-repo-first

Anchor: `#published-repo-first`

Before framing any upgrade as "build custom X", search GitHub + npm + PyPI for X first. Default to install / wrap / fork-and-adapt. Only build custom when no published fit exists.

---

## Complete sweep

Anchor: `#complete-sweep`

When building a feature, apply it everywhere it should go. Grep for every usage of any constant or pattern you touch. Update the router, navigation, docs, tests in the same pass.

---

## Fix at the root cause

Anchor: `#fix-properly`

Never apply band-aid fixes. Diagnose root cause, fix at the source, add a guard so it cannot recur, verify. Bug-fix protocol: reproduce -> isolate -> root cause -> fix at source -> verify -> prevent (test / type / constraint) -> document.

---

## Memory hygiene

Anchor: `#memory-hygiene`

- Every memory file carries `last_verified` + `ttl_days` frontmatter.
- Per-type TTL defaults: feedback 365d, project 2d, user 180d, reference 180d, note 30d, agent 90d.
- Do not commit secrets to memory files. Use `data/runtime/` (gitignored) for tokens.

---

## Safety (short form)

Anchor: `#safety`

**Never without explicit user confirmation**: destructive SQL, `rm -rf`, force push, schema migrations, DNS / SSL changes, API key revocation, `sudo` anything.

**Hard-blocked even with user approval**: force push to `main` / `master` / `production` / `release`, `filter-branch`, `reflog expire`, `gc --prune=now`, `update-ref -d`.

The safety-gate PreToolUse hook is the real enforcement. CLAUDE.md text alone is not sufficient.

---

## Banned language

Anchor: `#banned-language`

The banned-language gate hook blocks medical-claim words, marketing superlatives, and AI-tells from leaking into messaging-tool replies AND files written under `Library/`, `docs/`, app strings dirs. Sources: `Library/app-store-compliance/banned-language-list.md` (the list) + `banned-language-allowlist.md` (exceptions). Performance target under 50ms per fire.

---

## Always live searches

Anchor: `#live-searches`

Never rely on training data alone for current information. Always run a live WebSearch / WebFetch for time-sensitive queries. If a YouTube summary or research scan mentions a tool / repo / package, verify it exists before propagating into a brief.

---

## Keep project scripts in their own repos

Anchor: `#project-scripts-in-project`

Never put project-specific scripts in the orchestrator's repo. Each project's scripts live in that project's repo.

---

## HANDOFF.md on session end

Anchor: `#handoff-on-session-end`

When a session ends, the orchestrator writes HANDOFF.md to every project touched during the session. Auto-generated from git diff + telegram tail + reflection notes via `scripts/update-handoff.sh`.

---

## Cross-references

These habits link to skills shipped in this repo:

- `<orchestrator>-orchestration` loads `#aggressive-parallelism`, `#plan-before-code`, `#council-pattern`
- `<orchestrator>-reflection` loads `#pre-hoc-reflection`
- `<orchestrator>-spec-kit-bridge` loads `#spec-kit-bridge`
- `<orchestrator>-safety` loads `#safety`
- `<orchestrator>-memory` loads `#memory-hygiene`
- `<orchestrator>-sync-habits` loads `#install-skills` (it IS the implementation of this rule)

Skills reference habit anchors directly (e.g. `[[orchestration-habits#reply-discipline]]`).

---

## Manifest

The orchestrator's `<orchestrator>-sync-habits` skill parses this YAML block and runs every step via the Bash tool. Re-running is idempotent — already-installed items no-op.

```yaml
manifest_version: 1
habits_version: 1.0.0

# Skills to install (clone or marketplace).
# Each skill lands at .claude/skills/<name>/SKILL.md.
skills:
  - name: "{{orchestrator_lower}}-orchestration"
    install: blueprint-generated
    desc: 18+ orchestration habits, council pattern, plan-first dispatch
  - name: "{{orchestrator_lower}}-reflection"
    install: blueprint-generated
    desc: pre-hoc 6-stage chain-pattern-interrupt on fuzzy briefs
  - name: "{{orchestrator_lower}}-spec-kit-bridge"
    install: blueprint-generated
    desc: greenfield > 4h builds route through github/spec-kit pipeline first
  - name: "{{orchestrator_lower}}-safety"
    install: blueprint-generated
    desc: git + DB + deploy-verify hard rules
  - name: "{{orchestrator_lower}}-memory"
    install: blueprint-generated
    desc: Mode A active recall + Mode B dream consolidation
  - name: "{{orchestrator_lower}}-ai-seo"
    install: blueprint-generated
    desc: auto-fires on ship / deploy; generates llm.txt + sitemap + robots + JSON-LD
  - name: "{{orchestrator_lower}}-21st-bridge"
    install: blueprint-generated
    desc: routes generic React UI generation to 21st.dev/magic-chat
  - name: "{{orchestrator_lower}}-sync-habits"
    install: blueprint-generated
    desc: handles 'sync habits' / 'install habits' / 'update habits' (this rule self-installing)

# Hooks to copy + chmod +x.
# Each entry: download src -> dest, then chmod +x.
hooks:
  - name: telegram-reply-reminder.sh
    src: "https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/.claude/hooks/telegram-reply-reminder.sh"
    dest: ".claude/hooks/telegram-reply-reminder.sh"
    wire_to:
      event: UserPromptSubmit
      matcher: ""
  - name: banned-language-gate.sh
    src: "https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/.claude/hooks/banned-language-gate.sh"
    dest: ".claude/hooks/banned-language-gate.sh"
    wire_to:
      event: PreToolUse
      matcher: "mcp__plugin_telegram_telegram__reply|Write|Edit"
    requires:
      - ".claude/hooks/banned-language-gate.pl"
      - "Library/app-store-compliance/banned-language-list.md"
      - "Library/app-store-compliance/banned-language-allowlist.md"
  - name: banned-language-gate.pl
    src: "https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/.claude/hooks/banned-language-gate.pl"
    dest: ".claude/hooks/banned-language-gate.pl"
    wire_to: helper
  - name: stop-verify-contract.sh
    src: "https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/.claude/hooks/stop-verify-contract.sh"
    dest: ".claude/hooks/stop-verify-contract.sh"
    wire_to: called-by-stop-composer
  - name: stop-composer.sh
    src: "https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/.claude/hooks/stop-composer.sh"
    dest: ".claude/hooks/stop-composer.sh"
    wire_to:
      event: Stop
      matcher: ""
  - name: agent-dispatch-pre.sh
    src: "https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/.claude/hooks/agent-dispatch-pre.sh"
    dest: ".claude/hooks/agent-dispatch-pre.sh"
    wire_to:
      event: PreToolUse
      matcher: "Agent|Task"
    optional: true
  - name: agent-dispatch-post.sh
    src: "https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/.claude/hooks/agent-dispatch-post.sh"
    dest: ".claude/hooks/agent-dispatch-post.sh"
    wire_to:
      event: PostToolUse
      matcher: "Agent|Task"
    optional: true

# Plugins to install via claude plugin marketplace add + plugin install.
plugins:
  - marketplace_repo: "anthropics/claude-code-plugins"
    plugins:
      - telegram
    note: "Required if your install uses Telegram as the primary channel."

# Library files (required by hooks above).
library:
  - src: "https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/Library/app-store-compliance/banned-language-list.md"
    dest: "Library/app-store-compliance/banned-language-list.md"
  - src: "https://raw.githubusercontent.com/ZQadus/Xantham-system-blueprint/main/Library/app-store-compliance/banned-language-allowlist.md"
    dest: "Library/app-store-compliance/banned-language-allowlist.md"

# Settings.json patches (jq-applied; idempotent).
settings_patches:
  - jq: |
      .hooks.UserPromptSubmit //= [] |
      .hooks.UserPromptSubmit |= (
        if any(.hooks[]?.command == ".claude/hooks/telegram-reply-reminder.sh") then .
        else . + [{hooks: [{type: "command", command: ".claude/hooks/telegram-reply-reminder.sh"}]}]
        end
      )
  - jq: |
      .hooks.PreToolUse //= [] |
      .hooks.PreToolUse |= (
        if any(.matcher == "mcp__plugin_telegram_telegram__reply|Write|Edit") then .
        else . + [{matcher: "mcp__plugin_telegram_telegram__reply|Write|Edit", hooks: [{type: "command", command: ".claude/hooks/banned-language-gate.sh"}]}]
        end
      )
  - jq: |
      .hooks.Stop //= [] |
      .hooks.Stop |= (
        if any(.hooks[]?.command == ".claude/hooks/stop-composer.sh") then .
        else . + [{hooks: [{type: "command", command: ".claude/hooks/stop-composer.sh"}]}]
        end
      )

# Verification steps the skill MUST run after install.
verify:
  - "test -x .claude/hooks/telegram-reply-reminder.sh"
  - "test -x .claude/hooks/banned-language-gate.sh"
  - "test -x .claude/hooks/stop-verify-contract.sh"
  - "test -x .claude/hooks/stop-composer.sh"
  - "test -f Library/app-store-compliance/banned-language-list.md"
  - "grep -q telegram-reply-reminder .claude/settings.json"
  - "grep -q banned-language-gate .claude/settings.json"

# Reporting template the skill emits back on the messaging channel.
report_template: |
  Habits synced. v{{habits_version}}.
  Installed: {{n_skills}} skills, {{n_plugins}} plugins, {{n_hooks}} hooks, {{n_library}} library files.
  Settings patches applied: {{n_settings_patches}}.
  Verification: {{verify_pass}}/{{verify_total}} passed.
  Restart the session to load new hooks.
```

---

## Changelog

- **1.0.0 — 2026-05-12** — Initial consolidated drop-in file. Replaces the 30+ separate feedback memories that used to encode these rules. Manifest section added so the `<orchestrator>-sync-habits` skill can install everything autonomously from a single trigger ("sync habits").
