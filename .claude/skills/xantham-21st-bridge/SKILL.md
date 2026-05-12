---
name: xantham-21st-bridge
description: Use when generating a React UI component (pricing table, form, modal, dashboard tile, navbar, hero, AI-chat surface) and the goal is "novel functional component with sensible defaults". Routes to 21st.dev/magic-chat browser flow (free tier 100 credits/month, no API key needed) for the initial component, then hands the generated code back to Xantham for integration. Skip when the work is hand-styled premium taste, full-page design (use ui-ux-pro-max instead), animation-first work (use Motion or freshtechbro/claudedesignskills), or pure refactor of existing components (use frontend-design or redesign-skill).
compatibility: "Claude Code only"
metadata:
  pattern: 4
  pattern_name: "Context-aware tool selection"
  last_updated: 2026-05-10
---

# 21st.dev browser bridge

Xantham has a deep frontend skill stack. 21st.dev fills one specific slot: getting a battle-tested React component fast without hand-coding the structure.

## When this fires

**Trigger conditions (any one is enough)**:

- "Generate a [component-type]" where component-type is a generic pattern: pricing table, contact form, modal, navbar, hero, dashboard tile, settings panel, AI-chat surface, login form, sidebar, breadcrumb, accordion, etc.
- The user wants a starting point for a component, not a hand-tuned premium build.
- The component fits a known UI pattern that has been built thousands of times (no novel interaction model).

**Skip conditions (any one is enough)**:

- Hand-styled premium taste matters more than registry components -> use `frontend-design`, `taste-skill`, `soft-skill`, `minimalist-skill`, or `brutalist-skill` based on the desired feel.
- Full-page design (palette + typography + spacing + chart picks together) -> use `ui-ux-pro-max`.
- Animation-first work (page transitions, micro-interactions, scroll sequences) -> use Motion AI Kit if installed, otherwise `freshtechbro/claudedesignskills` bundle.
- Refactor of an existing component -> use `redesign-skill`.
- Quick fix to a single element -> just write the code.
- 21st.dev free-tier credits are exhausted (100/month).

## How to use 21st.dev (browser flow, free tier)

The 21st.dev/magic-chat interface is the no-API-key path. Free tier ships with 100 credits/month.

### Step-by-step

1. **Open Chrome** to https://21st.dev/magic-chat (Xantham can do this via `mcp__claude-in-chrome__navigate` or by handing the URL to the user).
2. **Describe the component** using `/ui` syntax. Example: `/ui pricing table for a quit-vape app, three tiers, monthly/annual toggle, primary CTA on the middle tier, dark theme optional`.
3. **Wait for variations**. The system generates multiple styles for the same component.
4. **Browse + pick**. Compare the variations side-by-side, pick the one whose layout best matches the brief.
5. **Copy the code**. Either copy the full TypeScript code directly, OR copy the integration prompt 21st.dev provides for use inside Claude Code.

### Where the generated code lands

If Xantham drives the browser:

- Use `mcp__claude-in-chrome__navigate` to open the URL.
- Use `mcp__claude-in-chrome__form_input` or `mcp__claude-in-chrome__type` to enter the `/ui` prompt.
- Use `mcp__claude-in-chrome__read_page` to read the generated code blocks.
- Paste the code into the target file via Write or Edit tools.

If the user drives the browser:

- Xantham writes a precise `/ui ...` prompt for the user to paste.
- the user picks a variation and pastes the code back to Xantham via Telegram or terminal.
- Xantham integrates it into the target project.

### Picking which mode

- **Xantham drives** when the component is part of a build kai is dispatched on, no taste judgment required, the prompt is precise enough that any of the variations is acceptable.
- **the user drives** when taste matters (the user has the visual eye for which variation reads best).

## Pick-and-choose policy across all frontend skills

Xantham's frontend stack as of 2026-05-10:

| Skill | When it wins |
|---|---|
| `21st.dev` (this bridge) | Novel component, sensible defaults, ship fast, registry pattern fits |
| `ui-ux-pro-max` (76k stars, installed) | Full-page design system selection, palette + typography + spacing + charts |
| `motion-framer` (freshtechbro/core-3d-animation, installed) | Framer Motion / Motion animation in React |
| `gsap-scrolltrigger` (installed) | GSAP scroll-driven sequences, complex timeline animations |
| `react-three-fiber` (installed) | React Three Fiber 3D scenes |
| `babylonjs-engine` (installed) | Babylon.js 3D engine work |
| `react-spring` (installed) | React Spring physics-based animations |
| `magic-ui` (installed) | Magic UI animated component primitives |
| `aos-scroll` (installed) | AOS Animate-On-Scroll library |
| `animejs` (installed) | anime.js fine-grained animations |
| `lottie-animations` (installed) | Lottie After Effects animations on web |
| `swiftui-animation` | SwiftUI native animations + matched geometry + Metal shaders |
| `swiftui-liquid-glass` | iOS 26+ Liquid Glass API |
| `frontend-design` | Distinctive premium hand-built layouts where opinionated taste beats registry |
| `taste-skill` | Senior UI/UX engineer mode: balanced design engineering + metric-based rules |
| `redesign-skill` | Audit + lift existing site without breakage |
| `soft-skill` | Designer-friendly high-end agency feel |
| `minimalist-skill` | Clean editorial monochrome |
| `brutalist-skill` | Raw mechanical, Swiss + military terminal aesthetic |
| `impeccable` | Frontend interface critique + polish + edge cases |
| `apple-hig-designer` | Native iOS + Apple Watch, HIG compliance |
| `swiftui-ui-patterns` | SwiftUI components + composition + tab architecture |
| `stitch-skill` | Google Stitch DESIGN.md generation, anti-generic UI standards |

The trigger conditions in each skill's `description` field are how Claude Code routes. Xantham picks the right skill for the job per the table above. ALL skills are kept; never delete one because a new one shipped.

## Cost discipline

- Free tier 100 credits/month on 21st.dev. One credit per `/ui` generation (multiple variations included). Treat the free tier as: ~100 components per month.
- If the same component pattern appears twice in one project, save the chosen variation locally (e.g. `Library/snippets/<component>.tsx`) so the second use doesn't burn another credit.
- Above the free tier, paid plans exist. Don't auto-upgrade without telling the user.

## Why this skill exists vs hand-rolling components

The 21st.dev registry has been built and validated by 1.4M devs / 200K MAU. A pricing-table component there has been A/B tested across thousands of sites. Xantham hand-rolling a pricing table from scratch every time is the kind of "build custom X" anti-pattern that perma-rule 9 (`feedback_check_published_repo_first.md`) explicitly fights. Use the registry, ship faster, save the taste judgment for the ~20 percent of components where premium feel actually matters.

## What this skill does NOT do

- Not a substitute for hand-styling. The 21st.dev variation is the starting point, not the final design.
- Not a substitute for taste. Xantham still picks variations, integrates copy, picks colour overrides, animates entry, makes responsive decisions. 21st.dev gives the structure; the polish is still Xantham's.
- Not a way around constitutional principles in any specific project (e.g. 90 Days no-medical-claims, banned-language gate, no analytics SDK). Always re-check the generated code against project constitution before integration.
