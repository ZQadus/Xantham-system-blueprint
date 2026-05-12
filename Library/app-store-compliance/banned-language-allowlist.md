---
name: Banned Language Allowlist — exception phrases the gate will not block
description: Phrases / contexts that look like banned language but are legitimate uses (project names, technical terms, meta-talk). The banned-language-gate hook reads this file and skips matches.
type: reference
last_verified: 2026-05-10
ttl_days: 90
---

# Banned Language Allowlist

The hook at `.claude/hooks/banned-language-gate.sh` reads this file and adds these to its skip set. One pattern per line. Lines starting with `#` are comments. Empty lines ignored.

Two pattern types:

1. **`literal:<phrase>`** — case-insensitive substring match. If the phrase appears anywhere in the text, the entire match for that banned word is skipped. Use for technical terms / project names that legitimately contain a banned word.

2. **`regex:<pattern>`** — perl-compatible regex (case-insensitive). Matched against the text. If the regex hits, any banned word that overlaps with the regex match is whitelisted.

Default skips already baked into the hook itself (no need to repeat here):

- Code blocks (triple-backtick)
- Inline code (single-backtick)
- Quoted strings ("..." and '...')
- Markdown links and file paths
- URLs (http://..., https://...)
- File paths under `data/research/` and `Library/` when the banned word appears inside a markdown table cell that's documenting it
- Words preceded by "no ", "not ", "non-", "never " (negation)
- Words inside angle brackets like `<example>` or block-quote markers `>`

---

## Project-specific exceptions

```
# 90 Days app — talking about cessation context, not making medical claims
literal:not clinical
literal:non-clinical
literal:talking about clinical
literal:clinical-claim
literal:clinical evidence
literal:clinical source

# Meta-discussion of the ban list itself, banned words appear when discussing the ban
literal:banned-language
literal:banned language
literal:ban list
literal:banned list

# Standard tech / build phrases that shouldn't trip
literal:best practice
literal:best practices
literal:code-best-practice
literal:claude-code-best
literal:bcherny-claude
literal:claude-best
literal:docs/en/best
regex:bcherny.*best
regex:best-practice
literal:fits best
literal:works best
literal:best fit
literal:at best
literal:do my best
literal:best, no
literal:best case
literal:worst case scenario
literal:treats it as
literal:treats them as
literal:treats the
literal:treats that
literal:transformer
literal:transformers
literal:transform function
literal:transform method
literal:imagine.app
literal:imagine the
literal:let's see
literal:let's check
literal:let's go

# Casual telegram speech (orchestrator's style is conversational with the user)
literal:imagine if
```

## Path-context exceptions

These regexes describe TEXT contexts (not file paths) where matches should be ignored.

```
# Documenting banned words inside the compliance handbook itself
regex:banned[\s-]+(words?|language|list|phrases?)
regex:safe alternative
regex:rejection (probability|risk)

# Markdown table rows that show banned/safe pairs (e.g. "| treats | supports |")
regex:^\s*\|.*\|.*\|.*\|\s*$

# YAML frontmatter
regex:^---$
```

## When to add to this file

If the banned-language-gate hook blocks something legitimate, run:

```bash
bash scripts/banned-language-allowlist-add.sh "<phrase>"
```

Or edit this file directly + commit. The hook re-reads on every fire (cached for 60s within a single Claude session via `data/runtime/banned-lang-allowlist.cache`).

## What NOT to add here

- Don't whitelist actual banned-word usage in marketing copy or app descriptions. The hook exists because that lands you in App Store rejection territory. Rewrite the copy instead.
- Don't whitelist "let's" / "imagine" / "delve" in customer-facing app strings. They are AI-tells regardless of intent.
- Don't add catch-alls like `regex:.*` — that defeats the gate.
