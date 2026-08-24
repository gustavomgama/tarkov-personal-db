# Skills Reference

How to use the 27 AI skills installed in `~/.opencode/skills/` (plus the pre-existing
`cursor-api-key-management`).

## How activation works

- Skills load **at session start** — after installing/removing one, restart opencode.
- They trigger **automatically** when your request matches the skill's description
  ("review this controller for Clean Code violations" → `clean-code`).
- You can also invoke **explicitly** by naming them: *"use ponytail-review on this diff"*,
  *"apply refactoring-guru rules here"*.
- Each skill is a folder with a `SKILL.md`; open one anytime to read its full instructions.

---

## 1. Task Observer — `one-skill-to-rule-them-all`

| Skill | Purpose |
|---|---|
| `task-observer` | Watches any multi-step session, captures patterns/corrections, and proposes new reusable skills. |

**Use:** leave it running during substantive work; afterwards ask *"what skill opportunities
did you notice?"* Best paired with a session-start habit — just mention "task observer" when
a session begins.

## 2. UI/UX pack — ui-ux-pro-max (6)

| Skill | Purpose |
|---|---|
| `design` | Umbrella skill: brand, tokens, logos, CIP deliverables, banners, icons, social images |
| `design-system` | Token architecture (primitive→semantic→component), component specs |
| `ui-styling` | Build/repair UI with shadcn/ui + Tailwind patterns, accessible components |
| `brand` | Brand voice, identity, messaging frameworks, consistency review |
| `banner-design` | Banners/heroes for web, ads, social (22 art directions) |
| `slides` | HTML presentations w/ Chart.js + copywriting formulas |

**Use:** *"style the items table using ui-styling"*, *"create a design-system spec for our
badges"*. Image-generation features optionally use your own `GEMINI_API_KEY`.

## 3. Engineering books — agent-rules-books (14)

Distilled rule sets; each triggers when you name its book or its principles:

`clean-code` · `refactoring` · `refactoring-guru` · `clean-architecture` ·
`domain-driven-design` (+ `-distilled`, `implementing-`) ·
`working-effectively-with-legacy-code` · `the-pragmatic-programmer` ·
`code-complete` · `release-it` · `patterns-of-enterprise-application-architecture` ·
`designing-data-intensive-applications` · `a-philosophy-of-software-design`

**Use:** *"refactor ItemsController following clean-code"*, *"review this migration against
DDIA principles"*. Full rule files live inside each skill folder.

## 4. Ponytail — anti-over-engineering (6)

| Skill | Purpose |
|---|---|
| `ponytail` | Persistent mode: forces the laziest solution that actually works |
| `ponytail-review` | Reviews a diff only for what to DELETE (reinvented stdlib, speculative abstractions) |
| `ponytail-audit` | Whole-repo over-engineering audit, ranked deletion list |
| `ponytail-debt` | Harvests `ponytail:` comments into a debt ledger |
| `ponytail-gain` | Scoreboard of code/cost/speed savings |
| `ponytail-help` | Quick reference card |

**Use:** *"ponytail-review my last diff"* before pushing; *"run ponytail-audit on app/services"*.

---

## Suggested habits for this project

1. **Before committing**: `ponytail-review` the diff → then commit.
2. **While writing Rails code**: name the relevant book (`clean-code`, `refactoring`) so rules apply as we type.
3. **Frontend changes**: `ui-styling` / `design-system` keep Bootstrap markup consistent.
4. **Monthly**: `ponytail-debt` to revisit deferred shortcuts; `task-observer` to bank new skills.
5. **Schema/data questions**: none of these replace `HANDOFF.md` — check it first.

*Note: ponytail's repo also targets a "Hermes" chat harness (slash commands) — only the skill
bundles above are installed here.*

## 5. Rails audit — nuke-on-rails (1)

| Skill | Purpose |
|---|---|
| `nuke-on-rails` | Principal-engineer Rails audit: rubycritic + Brakeman + bundler-audit + ruby_audit, OWASP arsenal, impact-ranked action plan. Explicit invocation only (model auto-invocation disabled). |

**Use:** *"run nuke on rails on this project"* — expect it to shell out to the scanners.

## 6. Ruby pack — rubyn-code (14) + ruby-skills (3)

`rubyn-ruby` · `rubyn-ruby_project` · `rubyn-rails` · `rubyn-sinatra` · `rubyn-solid` ·
`rubyn-minitest` · `rubyn-rspec` · `rubyn-refactoring` · `rubyn-code_quality` ·
`rubyn-design_patterns` · `rubyn-gems` · `rubyn-megaplan` · `rubyn-self_test`

Reference libraries distilled from the rubyn-code project; trigger by topic
(*"apply rubyn-solid to this service"*, *"check rubyn-rails conventions here"*).

`ruby-resource-map` · `ruby-test-frameworks` · `ruby-version-manager` — st0012's Ruby
navigation/testing/version-manager guidance.

---

Total: **45 skills installed** (28 documented above + the 17 added from these three packs).
