# Comparison

How Xantham stacks up against the most-cited public agent frameworks and orchestrators as of May 2026. Honest read, including where Xantham is behind.

## At a glance

| Dimension | Xantham | claude-financial-services | factory.ai (Droid) | AutoGen (Microsoft) | CrewAI | LangGraph | karpathy/llm-council |
|---|---|---|---|---|---|---|---|
| Installation effort | Paste one prompt, 20-60 min wizard | `claude plugin install` per agent | Install Droid CLI, sign in | `pip install autogen-agentchat` | `pip install crewai` | `pip install langgraph` | `git clone` + OpenRouter key |
| Runs on a Claude.ai subscription (no extra API keys) | Yes | Yes (Claude Code) | No, separate paid plan | No, BYO LLM keys | No, BYO LLM keys | No, BYO LLM keys | No, OpenRouter key |
| Persistent memory | Flat markdown + sqlite-vec + cognitive overlay + NotebookLM Brain | Per-agent skill bundles, no operator-level memory layer | Session-scoped, no built-in persistence | None native, you wire your own | Short-term + long-term + entity + contextual, SqliteProvider checkpoints | Checkpointer abstraction, you pick the backend | None |
| Parallel agents | Yes, 2-3 default, up to 16 in Aggressive mode on Max 20x, in isolated worktrees | Yes, Managed Agents primitive | Yes, droid swarms | Yes, group chat patterns | Yes, hierarchical or parallel crews | Yes, supervisor / fork-at-checkpoint | No, sequential council |
| Safety hooks | PreToolUse gate, hard-block / approval / audit buckets | Inherits Claude Code permissions | Inherits Claude Code permissions | None native | None native | None native | None |
| Telegram interface | First-class, default install | No | No | DIY | DIY | DIY | No |
| Observability layer | Per-tool-call JSONL audit log, telegram-tail digest | Inherits Claude Code logs, no dedicated layer | Built-in dashboard (paid) | DIY | Native event stream + telemetry | LangSmith (paid SaaS) | None |
| Self-installing blueprint | Yes, single paste runs full wizard | No, manual `/plugin install` per agent | No | No | No | No | No |
| License | MIT | Apache-2.0 | Proprietary (free trial month) | MIT | MIT | MIT | Not declared in repo |
| Primary use case | Solo operator running multiple projects from a phone | Vertical finance reference impl (Anthropic) | Commercial coding agent for engineering teams | General multi-agent research, .NET / Python apps | Role-playing autonomous crews for ops | Production agent graphs with state machines | Side-by-side multi-LLM evaluation |

Cost lines worth surfacing: Xantham is $0/month plus your existing Claude.ai plan (Pro $20, Max 5x $100, Max 20x $200). factory.ai Droid starts at $20/month and goes up. AutoGen / CrewAI / LangGraph are free frameworks but the LLM bill is on you and scales with token use. claude-financial-services is free but runs on Claude Code, same subscription posture as Xantham. llm-council needs an OpenRouter key (pay-per-token).

## Where Xantham is behind

**No marketplace plugin path.** The Claude Code ecosystem has converged on `claude plugin marketplace add <repo>` + `claude plugin install` as the install verb. 9,000+ plugins use it. Xantham still installs by paste-prompt + wizard. For someone browsing claudepluginhub.com or claudemarketplaces.com, Xantham is invisible. The wizard is the bet (deeper integration, lossless install), the marketplace plugin is what gets you passive discovery. Roadmap item, not shipped yet.

**No demo GIF in the README until this week.** Competitors with visual proof (ruvnet/ruflo, pedramamini/Maestro, simonstrumse/claude-code-manager) convert Reddit landings at a higher rate. Fix lane is open separately to this doc.

**Smaller test footprint than AgentShield.** affaan-m/everything-claude-code ships 1282 tests across 102 secret-pattern rules. Xantham's safety gate is one consolidated hook with broad coverage but a smaller verified test surface (verification flow is documented in `xantham-system-v31.md`, not a 1000-test suite). Architecturally equivalent, marketing-wise outclassed.

**Single maintainer, no community Discord or Slack.** AutoGen has Microsoft Research backing. LangGraph has LangChain Inc. CrewAI has a funded company. Xantham is one operator publishing infrastructure that is useful to others. Reasonable expectation: response times are days, not hours.

## Where Xantham is at parity

**Agent crew depth.** 9 specialists is in the same range as CrewAI's typical crew sizes and AutoGen's group-chat patterns. Different positioning (curated single-operator crew vs framework-for-arbitrary-crews) but functionally comparable.

**Per-agent scoping.** Xantham's YAML `mcps:` frontmatter pattern is lifted from anthropics/financial-services (Apache-2.0). The novel piece is using it for context-budget reduction (~6-8k tokens per dispatch) via `scripts/sync_agent_skills.py` validation. At parity with the canonical reference.

**Memory layer architecture.** CrewAI ships short-term / long-term / entity / contextual buckets. LangGraph ships checkpointer-backed thread state. Xantham ships flat markdown + sqlite-vec + Karpathy three-bucket cognitive overlay. Different shapes, comparable depth.

## Where Xantham is strictly ahead

**Self-installing wizard from a single paste.** No competitor in this table installs by handing one prompt to a fresh Claude Code session and watching a wizard run. CrewAI / LangGraph / AutoGen require Python project setup. factory.ai requires sign-in and a paid plan. llm-council is `git clone` + manual config. claude-financial-services is `/plugin install` per agent. Xantham's "paste this single line" install is the most differentiated piece of the system.

**Runs entirely on a Claude.ai subscription.** No new API keys, no separate billing relationship. Pro at $20/month works for solo use; Max 20x at $200 flat covers heavy parallel agent work. Compared to CrewAI / LangGraph / AutoGen, where the LLM bill is per-token and scales with use, Xantham's cost story is predictable.

**Operationalized council pattern.** karpathy/llm-council is the source pattern (Chairman LLM ranks anonymous responses). Xantham wires it as habit-17 of the orchestrator's orchestration skill (`<orchestrator_lower>-orchestration` after install) with a mandatory Lens D competitive-scan slot for product decisions, and archives outputs to `Library/decisions/council/`. llm-council is a side project; Xantham operationalizes it.

**Memory + safety + Telegram together.** Each of these exists elsewhere as a piece. Praktor ships Telegram. CrewAI ships memory. AgentShield ships safety. No competitor in this table ships all three integrated, with a single-paste install and a $0/month cost on top of your existing Claude plan.

**AI-SEO on ship.** Auto-generated llm.txt + sitemap.xml + robots.txt with explicit LLM-bot allowlist (GPTBot, ClaudeBot, PerplexityBot, Google-Extended, Applebot-Extended) + JSON-LD schema on every `ship <project>`. Zero competitors in this table ship this. Whether AI-SEO matters for your projects is a separate question; if it does, this is a moat.

## How to choose

- **You want a personal AI command centre run from your phone.** Xantham. The wizard, the Telegram interface, and the predictable cost are the differentiators.
- **You want a vertical reference implementation in finance.** anthropics/financial-services. It is Anthropic's official pattern for the domain.
- **You are an engineering team and want a paid commercial coding agent.** factory.ai Droid. Top of the terminal-bench leaderboards, enterprise support.
- **You want a framework to build custom multi-agent apps in Python.** CrewAI or LangGraph. CrewAI is the higher-level role-playing abstraction; LangGraph is the lower-level graph + checkpointer primitive.
- **You want Microsoft's enterprise multi-agent stack.** Microsoft Agent Framework (the AutoGen successor). AutoGen itself is in maintenance mode.
- **You want a Saturday hack to compare LLMs side by side.** karpathy/llm-council. That is exactly what it is.

## Sources

- [microsoft/agent-framework](https://github.com/microsoft/agent-framework) and [AutoGen maintenance-mode notice](https://microsoft.github.io/autogen/stable//index.html)
- [crewAIInc/crewAI](https://github.com/crewaiinc/crewai) and [CrewAI documentation](https://docs.crewai.com/)
- [langchain-ai/langgraph](https://github.com/langchain-ai/langgraph) and [LangGraph memory docs](https://docs.langchain.com/oss/python/langgraph/add-memory)
- [anthropics/financial-services](https://github.com/anthropics/financial-services) (Apache-2.0, per-agent skill bundle pattern)
- [karpathy/llm-council](https://github.com/karpathy/llm-council) (council pattern source, 16.9k stars)
- [factory.ai pricing](https://factory.ai/pricing) ($20/month entry, proprietary)
- [claudepluginhub.com](https://www.claudepluginhub.com/) and [claudemarketplaces.com](https://claudemarketplaces.com/) for marketplace discoverability context
