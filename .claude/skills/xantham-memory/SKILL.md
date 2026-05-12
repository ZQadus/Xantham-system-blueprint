---
name: xantham-memory
description: Use BEFORE generating any non-trivial reply on Telegram (i.e., a reply that references a project, URL, person, or named entity the user cares about). Surfaces relevant project / feedback / profile / reference memory from `memory/` so the reply is grounded in current state, not assumptions. Also handles manual `/dream` invocations + scheduled 24h+5-session consolidation passes.
architectural_role: trunk
compatibility: "Claude Code only"
metadata:
  pattern: 3
  pattern_name: "Iterative refinement"
  last_updated: 2026-05-10
---

# xantham-memory

Two modes:

1. **Active recall (session-start + per-turn).** Extract entities from the inbound message + Xantham's current task, search `memory/` semantically, inject the top-N hits into Xantham's working context BEFORE the first reply.
2. **Dream consolidation (manual or scheduled).** Run a 4-phase pass over `memory/` to merge contradictions, drop stale, normalize dates, rebuild MEMORY.md index.

## Skip conditions

DO NOT invoke active recall for: greetings (`hi`, `hey`, `gm`, `sup`), one-word confirmations (`yes`, `ok`, `go`), commands (`sync`, `wrapup`, `healthcheck`, `help`, `team`, `projects`, `status`, `monitor`, `deploy`, `history`, `brain`, `notes`).

## Mode A: Active recall

When triggered, the orchestrator should:

1. Read inbound text (from `data/runtime/inbound.txt` if Stop hook captured it, otherwise from the latest user message).
2. Run `bash scripts/active-recall-entities.sh` (Task 16) — emits entities one per line. Person names match the watch-list in `memory/profile/*.md` (currently nigel, danielle, hannah, olena, rhys, hosa).
3. For each entity (cap 2), run `bash scripts/memory-search.sh "<entity>"` and dedup hits. Person matches surface the corresponding `memory/profile/<person>.md` first because file basename strongly signals.
4. Inject the formatted `<memory>` block into Xantham's context BEFORE generating the reply.

Implementation in `scripts/active-recall.sh` (Task 17). Within-session cache at `data/runtime/active-recall-cache.tsv` (Task 18). Wired into Xantham's session-start by `CLAUDE.md` directive (Task 19).

### Per-person profile files (shipped 2026-05-10)

`memory/profile/<person>.md` is the per-person sibling of `memory/profile_zaki.md`. One file per regularly-mentioned external person (clients, collaborators, reviewers). Each carries `type: profile-person` frontmatter + a structured shape (Who they are / How to address / Active threads / Past patterns / Sensitivities / Evidence trail).

These files surface automatically via active recall when the person's name appears in inbound text. To populate after a new interaction:

- Manual: `bash scripts/profile-person-update.sh <person> "<fact>"` — appends a timestamped fact under a "Pending review" section; bumps `last_verified`.
- Automatic at session-end: `scripts/session-end-sync.sh` runs `scripts/profile-person-update.sh --scan-tail 4` which writes candidate facts (one section per mentioned person) to `data/runtime/profile-person-pending.md`. Xantham reviews + applies on next session start.

Privacy guardrail: the appender refuses facts containing phone / email / postcode patterns. Use the structured profile sections for verified contact details, or rephrase.

To add a new tracked person: create `memory/profile/<name>.md` with the standard frontmatter + shape, then add the name to the hardcoded list in `scripts/active-recall-entities.sh` (lines ~120, "for name in ..."). The active-recall path will pick it up immediately; memory-search semantic hits land after the next post-commit embed.

## Mode B: Dream consolidation

Triggered by:
- Manual: the user sends `dream` / `/dream` / "consolidate memory"
- Scheduled: Stop hook on session end if 24h + 5 sessions elapsed since last run

Four phases (per Anthropic Auto Dream pattern, since native is still feature-flagged in our tier as of May 2026):

1. **Orient** (`scripts/dream/phase1-orient.sh`, Task 20) — read MEMORY.md + profile_zaki.md + corrections-promoted.jsonl + last 5 reflections; emit JSON map of current state
2. **Gather signal** (`scripts/dream/phase2-gather.sh`, Task 21) — scan last N sessions' telegram + audit for repeated patterns / contradictions / decisions
3. **Consolidate** (`scripts/dream/phase3-consolidate.sh`, Task 22) — convert relative dates, drop contradicted entries, merge overlapping; promote cross-cutting items to procedural/; compress episodic > 30d into semantic summaries
4. **Prune & index** (`scripts/dream/phase4-prune.sh`, Task 23) — rebuild MEMORY.md (cap 200 lines), re-embed via post-commit, write `data/dream-runs/<ts>/changes.md`

Cost cap: $1/run, never re-run within 23h. Orchestrator at `scripts/dream.sh` (extended in Task 24).

## File layout this skill operates over (post Phase 2)

```
memory/
├── MEMORY.md              (auto-regenerated index, capped at 200 lines)
├── profile_zaki.md        (top-level Profile bucket, mutable narrative)
├── agent-memory/          (9 agent dirs)
├── episodic/<date>.md     (daily rolled telegram + reflection + commits)
├── semantic/
│   ├── feedback/          (89 files: feedback rules)
│   ├── project/           (27 files: per-project state)
│   ├── reference/         (12 files: external references)
│   ├── note/              (20 files: ad-hoc notes)
│   └── user/              (3 files: user atomic facts)
├── procedural/README.md   (pointers to CLAUDE.md + skills + hooks)
└── .amy/                  (gitignored Amy persona memory; ALL iterators dot-prune)
```

The `.amy/` carveout invariant MUST hold in both modes. Active recall + dream both use the centralised walker at `embed-memories.py walk_markdown` which dot-prunes by default since 2026-05-04.

## Status

Task 15 scaffolds this file. Tasks 16-19 build Mode A. Tasks 20-24 build Mode B. Task 19 wires Mode A into CLAUDE.md.

Until Tasks 16-19 land, this skill description triggers but the orchestrator has no `scripts/active-recall.sh` to call. That's expected mid-build.
