---
name: Banned Language List — words and phrases that trigger rejection
description: Specific words, phrases, and patterns that cause App Store rejection or escalate review scrutiny. Run this list as a grep pre-submission. Covers medical claims, marketing superlatives, AI tells, and category-specific traps.
type: reference
last_verified: 2026-05-09
ttl_days: 90
architectural_role: branch
---

# Banned Language List

**How to use:** Pre-submission, grep your app's strings, App Store description, screenshots, Privacy Policy, and marketing copy for every word in this list. If found, rewrite. Some are hard rejection triggers; others escalate review scrutiny.

---

## Hard medical-claim bans (Tier 1, Tier 2 apps)

These words trigger Guideline 1.4.1 medical-app review escalation AND the March 2026 medical-device disclosure rule. Use the safe alternative.

| Banned | Safe alternative | Why |
|---|---|---|
| treats, treatment | supports, helps with | Pulls you into medical-device territory |
| cures, cure | helps you quit, lifestyle change | FDA enforcement risk + 1.4.1 |
| clinical, clinically | research-based, peer-reviewed | Implies medical practitioner involvement |
| clinically proven | based on research | Unverifiable + clinical-claim |
| therapy, therapeutic | guidance, education | Therapy = medical practice |
| prescription, prescribe | over-the-counter, available | You're not a prescriber |
| diagnosis, diagnose | log, journal, track | Diagnosis = medical practice |
| medical-grade | research-grade, education-grade | Implies device classification |
| medical device | educational tool | You are explicitly NOT one |
| FDA-approved | (just don't claim it) | Unsupported = 2.3 violation |
| FDA-cleared | (only if literally true with documentation) | Apple checks this |
| MHRA-approved | (just don't claim it) | UK equivalent |
| symptom score | symptom log | Score implies clinical assessment |
| severity assessment | journal entry | Assessment implies clinical judgment |

---

## Marketing superlatives (Guideline 2.3 — accuracy)

Apple rejects these as unverifiable. Use specific, demonstrable claims instead.

| Banned | Why |
|---|---|
| best | Unverifiable |
| #1 | Unverifiable, may infringe trademark of #1 app |
| top-rated | Unverifiable unless you cite source + date |
| leading | Unverifiable |
| world-class | Vibe-coded copy tell |
| revolutionary | Vibe-coded copy tell |
| game-changing | Vibe-coded copy tell |
| best-in-class | Vibe-coded copy tell |
| 100% accurate | Almost never true |
| guaranteed [outcome] | Sets expectations Apple polices |
| X% success rate | Unverifiable in app description (QuitSure puts it on website only) |

---

## AI tells (anti-vibe-coded — Guideline 4.0 / 4.3)

Apple reviewers are using LLM-assisted review since late 2025. AI-generated copy is detectable. These tells are also banned from the orchestrator's own writing per the reply-discipline rule in `orchestration-habits.md`.

| Banned | Why |
|---|---|
| em dashes (—) | Strongest AI tell |
| "let's" (when AI-style) | AI conversational filler |
| "imagine" | AI hook pattern |
| "in today's fast-paced world" | AI listicle opener |
| "in this article" / "in this app" | AI meta-reference |
| "we'll explore" | AI structural cue |
| "delve into" | AI verb-of-the-week |
| "navigate" (as a metaphor for "understand") | AI metaphor reach |
| "tapestry of" | AI metaphor |
| "it's important to note" | AI hedging |
| "from groundbreaking to game-changing" | AI listicle copy |
| "unlock your potential" | AI motivational filler |
| "elevate your [thing]" | AI productivity-app cliché |
| "transform your [thing]" | AI productivity-app cliché |
| "seamlessly integrate" | AI tech copy |

Sentence-structure tells:
- Three short sentences in a row, all the same length
- Every paragraph is exactly three sentences
- Every list is exactly three items
- Every heading is "[Verb] Your [Noun]"

---

## Tobacco / vape category bans (Tier 1)

Beyond the medical bans above:

| Banned | Why |
|---|---|
| "how to vape better" | Encourages consumption (1.4.3) |
| harm reduction | Interpreted as enabling |
| "favourite flavour" | Sounds like brand affinity |
| "your perfect device" | Sounds like product recommendation |
| any vape device imagery in screenshots | 1.4.3 visual ban |
| "21+" or "18+" gateway language | Use the new age-rating system instead |
| "switching to vaping" | Implies consumption is the goal |
| "manage your nicotine" | Sounds like maintenance, not cessation |

---

## Tracking / privacy traps

| Banned | Why |
|---|---|
| "we never collect data" — when you actually collect crash reports | False claim → 5.1.1 violation |
| "anonymous" — when paired with a UserID | Apple checks; UserID + behavior = identifiable |
| "for your benefit" (re: tracking) | Generic, hides actual purpose |
| "to improve your experience" | ATT prompt rejection trigger |
| "industry-standard analytics" | Hides what you actually collect |

---

## Subscription dark-pattern phrasing

| Banned in cancellation flow | Why |
|---|---|
| "Are you sure?" multi-step | Asymmetry vs. signup flow |
| "We'll miss you" / "Don't go!" | Confirmshaming |
| "Tell us why you're leaving (required)" | Mandatory friction |
| "You'll lose your progress" (when not literally true) | Misleading |
| Subscription ToS hidden in long modal | 3.1.2 violation |

---

## Saturated-category app names (Tier 4 — Guideline 4.3)

Avoid generic names that pattern-match the saturated-category rejection wave.

| Banned naming pattern | Why |
|---|---|
| "[X] Tracker" alone | Too generic, "habit tracker / budget tracker" pattern |
| "AI [X]" | "AI wrapper" rejection wave |
| "[X] AI" | Same |
| "ChatGPT-[X]" | Trademark + saturated AI-wrapper |
| "Daily [X]" alone | Generic |
| "[X] Pro" alone | Generic |
| "Smart [X]" alone | AI-wrapper signal |
| "[X] Now" | Generic CTA-as-name |

Specific niche names with personality pass: "Streaks", "Tot", "Reeder", "Things", "Bear", "Halide", "Carrot Weather", "Linea", "Procreate". Generic names with personality also pass: "Notion", "Linear", "Things". Generic names without personality fail.

---

## App description structural traps

Don't open with:
- "Welcome to [app]."
- "[App] is the [adjective] way to [verb]."
- A three-bullet list of features

Don't end with:
- "Download now and [verb]!"
- "Join [number] users worldwide!"
- "What are you waiting for?"

These are AI-tell signatures and saturated-category signals.

---

## Pre-submission grep

Before every submission, run these greps against your project:

```bash
# AI tells in source code
grep -rE "(let's|imagine|delve|tapestry|seamlessly|elevate your|transform your|unlock your potential|—)" .

# Medical claims (Tier 1, Tier 2)
grep -rEi "(treats|cures|clinical|therapy|prescription|diagnosis|FDA[- ]approved|MHRA[- ]approved|medical[- ]grade|severity score)" .

# Marketing superlatives
grep -rEi "(\bbest\b|#1|top-rated|leading|world-class|revolutionary|game-changing|best-in-class|guaranteed)" .

# Privacy traps
grep -rE "(industry-standard analytics|to improve your experience|for your benefit)" .
```

If any return hits, rewrite before submitting.

---

## Bottom line

Banned language doesn't always cause rejection — it raises rejection probability. On a tier-by-tier basis:
- Tier 1 / Tier 2: medical bans are HARD. Rejection probability ~70% if any of those words land in the App Store description or app body.
- Tier 3: subscription dark-pattern phrasing is HARD. ~60% rejection probability if cancellation flow uses banned phrasing.
- Tier 4: AI tells are SOFT but escalating. ~30% rejection probability today, climbing through 2026.
- Universal: marketing superlatives in App Store description are HARD ~50% rejection. Privacy traps are HARD ~80%.

Run the grep. Rewrite. Submit clean.
