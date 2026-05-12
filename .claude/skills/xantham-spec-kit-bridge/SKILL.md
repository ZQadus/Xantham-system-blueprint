---
name: xantham-spec-kit-bridge
description: Use BEFORE dispatching @kai on a greenfield build (no existing code) with estimated budget >4 hours. Walks GitHub spec-kit's constitution -> spec -> plan -> tasks -> analyze pipeline first, so kai gets file-based artifacts with cross-artifact consistency checks rather than a fuzzy brief. Skip for bug fixes, ops work, refactors, brownfield modifications, or any task under 4 hours of estimated work. Pinned to spec-kit v0.8.8.dev0.
compatibility: "Claude Code only"
metadata:
  pattern: 1
  pattern_name: "Sequential workflow orchestration"
  last_updated: 2026-05-10
---

# Spec-kit bridge

This skill turns a Xantham brief into spec-kit artifacts before kai dispatch.

## When this fires

**Trigger conditions (all three must be true)**:

1. **Greenfield**: no existing code in the target repo. Empty repo, new Xcode project, fresh Next.js app, etc. NOT a feature on an existing codebase.
2. **Budget >4 hours** estimated total. Below 4h the spec-kit overhead (25 to 45 min) is more than the savings.
3. **Xantham-orchestrated**: triggered by `ship <project>` for a greenfield, OR explicit `spec-kit init <project>`, OR Xantham decides during brainstorming.

**Skip conditions (any one is enough)**:

- Bug fix, hotfix, or ops work
- Refactor of existing code
- Brownfield modification (existing codebase, new feature)
- Quick (<4h) build
- Task where the spec is expected to change mid-build (the pipeline is rigid)
- Followup work to an already-spec-kit'd project (work continues from existing artifacts; do not re-run the chain)

## Prerequisites

Spec-kit must be installed once on this machine:

```bash
uv tool install specify-cli==0.8.8.dev0 --from git+https://github.com/github/spec-kit.git
specify --version  # confirm 0.8.8.dev0
specify check      # confirm Claude Code, git, python 3.11+ all present
```

Pin to v0.8.8.dev0 to avoid silent breaking changes from upstream. Re-pin only when a new version has been pilot-tested through this same skill.

## Pipeline

For each greenfield build the skill walks 6 ordered phases. Xantham drives this in foreground (sub-agents do not have access to the speckit-* skills).

### Phase 1 - Init (~2 min)

1. Decide the project directory. For confirmed-name projects, this is the project repo root. For naming-still-open projects (like quit-vape was), pilot in `Library/projects/<slug>-spec-kit/` until the name is picked, then move artifacts into the real repo.
2. From the chosen dir: `specify init --here --integration claude --skip-tls`. This creates `.specify/` (templates + memory + scripts), `.claude/skills/speckit-*/` (14 skills), and `CLAUDE.md` stub. **Do NOT run `specify init --here` from the Xantham root** - it will create a `CLAUDE.md` in the wrong place. Confirm cwd before running.
3. Add `.specify/` and `.claude/skills/speckit-*/` to the project's `.gitignore` if they should not ship; alternatively commit them so they survive across sessions.

### Phase 2 - Constitution (~5 min)

Distill the brief's non-negotiables into 3 to 5 named principles. Each principle gets:

- A name
- A 1 to 2 paragraph statement
- Whether it is NON-NEGOTIABLE or guideline-strength
- A worked example of what compliance looks like

Write to `.specify/memory/constitution.md`. Examples in the quit-vape pilot at `Library/projects/quit-vape-spec-kit/constitution.md`:

- I. Honest Vocabulary (NON-NEGOTIABLE) - never claim cessation cures, distinguish active drug from metabolite
- II. Tracker, Not Therapy
- III. Single Surface = Lock Screen
- IV. Streak Is The Sunk-Cost Asset
- V. Privacy By Storage Locality

### Phase 3 - Spec (~10 min)

Read `.specify/templates/spec-template.md` to understand required sections. Then write `specs/001-<slug>/spec.md` containing:

- **User scenarios** as priority-ordered MVP slices. Each story (P1 / P2 / P3 etc) must be independently testable - if you ship only that one, you have a viable MVP.
- **Acceptance scenarios** in Given/When/Then form, 2 to 3 per user story.
- **Edge cases** named explicitly. Pull from the brief but also from analogous shipped products and known failure modes.
- **Functional requirements** numbered FR-001 through FR-NNN with MUST or MUST be able to verb discipline. Each FR must be testable.
- **Key entities** if the feature involves persisted data.
- **Success criteria** SC-001 through SC-NNN. Each MUST be measurable, technology-agnostic, and verifiable. Examples: "users complete onboarding in under 90s" (good); "API responds in 200ms" (bad - too technical, use "users see results instantly").
- **Assumptions** section listing reasonable defaults for anything underspecified.
- **NEEDS CLARIFICATION** markers capped at 3 maximum, prioritised scope > security > UX > tech.

### Phase 4 - Plan (~5 min)

Read `.specify/templates/plan-template.md`. Write `specs/001-<slug>/plan.md` containing:

- **Summary**: one-paragraph technical approach
- **Technical Context**: language version, primary deps, storage, testing framework, target platform, project type, performance goals, constraints, scale
- **Constitution Check**: a table mapping each constitution principle to plan compliance. Verdict: PASS / FAIL / PARTIAL with notes.
- **Project Structure**: documentation tree + source tree as concrete file paths (no placeholder names)
- **Cross-cutting decisions**: math model, persistence, notifications, etc. - whatever the project needs.
- **Phase plan**: Phase 0 research, Phase 1 design, Phase 2 tasks (deferred to next phase), Phase 3 implementation.
- **Complexity tracking**: only fill if there are constitution violations that must be justified.

### Phase 5 - Tasks (~10 min)

Break the plan into atomic tasks. Each task:

- Has a T-XYZ-NN identifier
- Names which user story and acceptance scenarios it serves
- Names which functional requirements it satisfies
- Names dependencies on other tasks
- Has a "Done when" exit criterion
- Has an estimate

Group by phase (Research, Design, Implementation P1, Implementation P2+, App Store / deploy readiness). Sum estimates and surface any mismatch with the brief budget.

### Phase 6 - Analyze (~5 min)

Cross-artifact consistency check. Walk:

1. **Constitution alignment**: every principle traces through spec, plan, tasks. Table of PASS / FAIL.
2. **FR coverage**: every FR-XXX has at least one task. Orphans are blockers.
3. **User story coverage**: every story has tasks satisfying every acceptance scenario.
4. **SC verifiability**: every SC is verifiable. Post-launch metrics are fine; un-verifiable claims are not.
5. **Issues**: list every gap, with HIGH / MEDIUM / LOW severity and a resolution proposal.
6. **Verdict**: READY FOR IMPLEMENTATION pending issue resolutions, OR BLOCKED with named blockers.

Write to `specs/001-<slug>/analyze.md`.

## After /analyze passes

Once the analyze pass returns READY FOR IMPLEMENTATION (or all blockers resolved):

1. Promote the artifacts to the project repo's source-of-truth location (move out of `Library/projects/<slug>-spec-kit/` into `<project-repo>/specs/`).
2. Xantham dispatches @kai with the artifacts as context. Brief becomes historical input; artifacts are authoritative.
3. Track which user stories @kai has implemented vs which remain open in tasks.md.

## Failure modes to avoid

- **Running `specify init --here` from the Xantham root.** This creates a `CLAUDE.md` stub at `<orchestrator-repo-root>/CLAUDE.md` and overwrites Xantham's actual CLAUDE.md. Always cd into the target dir first and confirm cwd.
- **Walking the chain on a brownfield task.** Spec-kit's constitution-first model assumes the project's rules can be written from scratch. On an existing codebase the constitution is already encoded in the code; spec-kit will produce a clean-room constitution that contradicts the actual code conventions.
- **Skipping /analyze.** The cross-artifact consistency gate is the single biggest value-add. Skipping it puts you in the same position as ad-hoc planning.
- **Mid-build spec changes.** Spec-kit is rigid. If the spec changes after /analyze, re-run /clarify -> /plan -> /tasks -> /analyze rather than ad-hoc patching artifacts.

## Pilot evidence

The quit-vape v1 pilot ran 2026-05-10 and surfaced 5 real issues the council-derived brief had missed: budget mismatch (24.5h vs 16-20h promised), naming as a hard blocker not a soft note, SC-008 non-verifiability under the privacy constitution, tip-jar with no acceptance scenario, brain-recovery citation hand-waving. Two of those (budget + naming) are blockers that would have hit mid-build. Full pilot report: `data/research/2026-05-10-spec-kit-pilot-evaluation.md`.

## Out of scope for this skill

- Bug fixes (use systematic-debugging skill).
- Brownfield feature work (use writing-plans + xantham-orchestration habit 1).
- Trivial builds <4h (use brainstorming + plan-first inline).
- Mid-build spec changes (re-run the chain rather than patching).
