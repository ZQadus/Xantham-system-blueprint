---
name: xantham-ai-seo
description: Use BEFORE any `ship <project>` or `deploy <project>` command, or when the user asks to "ship" / "deploy" / "push live" a project that has a public web surface. Also use when the user asks for an "AI-SEO audit", "llm.txt", "robots.txt for ChatGPT/Claude/Perplexity", "JSON-LD", or wants to know which projects are visible to LLM crawlers (GPTBot, ClaudeBot, PerplexityBot, Google-Extended, Applebot-Extended). Generates llm.txt + sitemap.xml + robots.txt + JSON-LD schema + last_updated metadata for the project being shipped, so AI assistants cite the site in their answers.
compatibility: "Claude Code only"
metadata:
  pattern: 5
  pattern_name: "Domain-specific intelligence"
  last_updated: 2026-05-10
---

# xantham-ai-seo

AI-SEO is the layer that makes a project visible AND citable when an LLM (ChatGPT / Claude / Perplexity / Google AI Overviews / Apple Intelligence) is asked a question that should recommend it.

A site without AI-SEO files is invisible to those crawlers. A site with them gets cited, gets click-throughs, gets organic discovery.

## When this fires

1. the user sends `ship <project>` or `deploy <project>` AND the project has a public web surface (Next.js / Vite / static HTML / any deployable site).
2. the user asks for an "AI-SEO audit" or asks about visibility in ChatGPT / Claude / Perplexity.
3. Xantham decides a project is about to go live for the first time (cuts a v1.0 tag, points a domain at it, marks it production-ready).

Skip if the project has NO public web surface (CLI tools, native iOS apps without a marketing site, internal scripts).

## What to do

### Step 1: Audit the project

```bash
bash scripts/ai-seo-on-ship.sh "<absolute-project-path>" --audit-only --prod-url "<https://...>" --name "<Name>" --tagline "<one-liner>"
```

Pass `--paid` if it's a paid product (triggers `pricing.md` generation).

The script reports `OK` / `MISS` / `WARN` for each file. Exit code 2 means missing files. Exit code 0 means clean.

### Step 2: Generate missing files

If the audit reports missing files, run again WITHOUT `--audit-only`:

```bash
bash scripts/ai-seo-on-ship.sh "<absolute-project-path>" --prod-url "<https://...>" --name "<Name>" --tagline "<one-liner>"
```

Add `--paid` if applicable.

The script writes:
- `<static-root>/robots.txt` — explicit allows for GPTBot, ClaudeBot, PerplexityBot, Google-Extended, Applebot-Extended, CCBot, cohere-ai. Explicit blocks for AhrefsBot, SemrushBot, DotBot, MJ12bot.
- `<static-root>/sitemap.xml` — discovered top-level routes only (skips `[slug]` parents, demo dirs, admin, api, auth).
- `<static-root>/llm.txt` — title, tagline, what-this-is, where-to-look, how-LLMs-should-cite, contact. Single-source-of-truth file LLMs read first.
- `<static-root>/.well-known/schema.json` — JSON-LD with Organization + WebSite/SoftwareApplication blocks.
- `pricing.md` (when `--paid`) — stub pricing tier table for LLMs to cite.

The script NEVER overwrites existing files. Re-runs are idempotent and safe.

### Step 3: Wire JSON-LD + last_updated into the framework's <head>

The script writes a sidecar `schema.json` but the actual `<script type="application/ld+json">` block has to live in the framework's <head>. The script reports a one-line snippet for whichever layout file it finds. For Next.js App Router:

```tsx
// In src/app/layout.tsx (next to your existing metadata export):
const LAST_UPDATED = "YYYY-MM-DD";

export const metadata: Metadata = {
  // ... existing fields
  other: {
    last_updated: LAST_UPDATED,
    "article:modified_time": `${LAST_UPDATED}T00:00:00Z`,
  },
};

// And inside <head>:
<script
  type="application/ld+json"
  dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }}
/>
```

For static HTML, paste the meta tags + `<script type="application/ld+json">{...}</script>` directly into `<head>`.

Do this once per project. The `last_updated` constant gets bumped on every ship — that's the only AI-SEO field that goes stale.

### Step 4: Verify the files would be served

For Next.js with `public/`, files in `public/robots.txt` are served at the URL root. No config needed.

For Vite, same convention — `public/` maps to URL root.

For raw static sites, the files need to live next to `index.html`.

The script auto-detects the right static root: `public/` for Next/Vite, project root for static. If the project has neither, the script creates `public/`.

### Step 5: Commit + ship

After generating + wiring, commit with the project's normal `ship` flow. Files are tiny (1-3 KB total), no build impact, no runtime impact.

## Verification (after the deploy lands)

After Vercel / Netlify / hosting deploys, verify the files are live:

```bash
PROD_URL="https://your-project.com"
for f in robots.txt sitemap.xml llm.txt .well-known/schema.json; do
    code=$(curl -s -o /dev/null -w "%{http_code}" "$PROD_URL/$f")
    echo "$code  $PROD_URL/$f"
done
```

All should be 200. If 404, the static-root detection picked the wrong dir — re-run with files moved to the actual public/ folder.

Then verify a tagged crawler can see the site:

```bash
curl -A "ClaudeBot/1.0 (+claude-web)" -s "$PROD_URL/llm.txt" | head -10
```

Should return the llm.txt content, not a paywall / login redirect.

## Why the file list is what it is

- **llm.txt** — emerging standard ([llmstxt.org](https://llmstxt.org)) for "the one file LLMs should read first". GPTBot + ClaudeBot fetch it preferentially when scoring relevance.
- **robots.txt with explicit allows** — GPTBot defaults to `Disallow` if a site's robots.txt only mentions `User-agent: *` with restrictive rules. Explicit `User-agent: GPTBot Allow: /` overrides that.
- **sitemap.xml** — still the standard for crawler discovery. LLM crawlers cross-reference it against the URLs in llm.txt.
- **JSON-LD (schema.org)** — Organization + WebSite/SoftwareApplication blocks let LLMs build a structured understanding of who-publishes-what. Used by Google's AI Overviews directly.
- **last_updated metadata** — LLMs prefer fresh content. Without a date, they assume stale.
- **pricing.md** — when an LLM is asked "how much does X cost?", it cites the cheapest authoritative source. A markdown pricing file at `/pricing.md` is more reliably parsed than HTML pricing tables.

## What this skill does NOT do

- Doesn't write project-specific copy. The auto-generated llm.txt pulls the first paragraph of CLAUDE.md as the description; that may need a human edit to be punchy.
- Doesn't add `HowTo` or `FAQPage` JSON-LD blocks. Those are page-specific and need real content. Generate them per-page when the page exists.
- Doesn't submit the sitemap to Google Search Console or Bing Webmaster Tools. Do that once per project, not per ship.
- Doesn't auto-bump `LAST_UPDATED` in layout.tsx — that's a project-level edit, not a Xantham-level edit. Add a manual bump to the ship checklist OR write a project-level pre-commit hook that runs `sed -i '' "s/LAST_UPDATED = \"[0-9-]*\"/LAST_UPDATED = \"$(date -u +%Y-%m-%d)\"/" src/app/layout.tsx`.

## Pilot status (2026-05-10)

- Acme: shipped. All 5 files live in `public/` + JSON-LD wired into `src/app/layout.tsx`.
- Other projects: audit-only run pending. See `data/research/2026-05-10-ai-seo-audit-across-projects.md`.
