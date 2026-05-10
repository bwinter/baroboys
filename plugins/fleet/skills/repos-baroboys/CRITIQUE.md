# repos-baroboys — Alignment + Critique (2026-05-09)

Sweep dispatched by fleet-mcp:claude. Aligning to canonical patterns from the
description-craft probe (cc6814f / 590c12a) + 18-skill canonical pass (775a06b),
then critiquing with fresh eyes against CLAUDE.md, MEMORY.md, and README.

## Alignment edits applied

| Pattern | Before | After |
|---------|--------|-------|
| Description voice | `Load when referencing baroboys:claude...` | `This skill should be used when referencing baroboys:claude...` |
| Frontmatter `version:` | `version: 0.3.0` present | removed |
| H1 version | `# baroboys:claude` (no version) | `# baroboys:claude v0.3.0` |
| `allowed-tools: []` | already present | unchanged |
| `plugin.json` description | `baroboys' self-registered fleet identity (fleet:repos-baroboys)` (meta-scoped) | `Repo-identity skill for the baroboys project — dispatch target for fleet cross-talk` (plugin-scoped) |

## Structural validation

`quick_validate.py /Users/bwinter/workspace/baroboys/plugins/fleet/skills/repos-baroboys/` → **Skill is valid!** (after both alignment + substantive edits)

## Critique findings (fresh eyes against CLAUDE.md / MEMORY.md / README)

### 1. Stale dispatch-list reference (post-checkout consolidation)

**Found:** "Game lifecycle scripts (refresh/startup/shutdown, per-game env-vars.sh, post-checkout.sh)" listed per-game `post-checkout.sh` as a dispatch target.

**Reality:** Per commit 38fbc6f and current MEMORY.md, per-game `post-checkout.sh` was DRY-consolidated into `shared/post-checkout.sh` which reads `manifest.templates`. Per-game is now exactly two files: `terraform/game/<Game>.tfvars.json` (cross-language SoT) + `scripts/services/<Game>/env-vars.sh`.

**Edit applied:** "Game lifecycle scripts (shared refresh/startup/shutdown/post-checkout; per-game is just `env-vars.sh` + `terraform/game/<Game>.tfvars.json`)"

This is the single most load-bearing edit — the card was implying a directory layout that no longer exists, which would mislead a sender about whether their task targets shared or per-game code.

### 2. "Not to Dispatch" conflated two distinct destinations

**Found:** "Changes to shared Claude Code infrastructure (skills, plugins, fleet config) — that's `claude-skills:claude`" bundled marketplace-skill work, plugin work, AND fleet harness work into one redirect.

**Reality:** Per ADR 0006 + recent fleet-mcp work, those are different routes. claude-skills:claude owns marketplace skills/plugins; fleet-mcp:claude owns the harness, MCP server code, and harness architecture. This very dispatch came from fleet-mcp:claude — the card was redirecting harness work to the wrong agent.

**Edit applied:** Split into two bullets:
- claude-skills marketplace skills/plugins → `claude-skills:claude`
- fleet harness / MCP server code / `fleet-mcp` architecture → `fleet-mcp:claude`

### 3. Description undercaptured natural triggers

**Found:** Description listed only `baroboys:claude` + "the baroboys engineer" + "the baroboys project agent."

**Reality:** Brendan and other agents also reference this repo as "the baroboys repo" and "the game-server platform." Sibling cards (e.g. fleet:repos-bastion) include richer alias lists in their descriptions for trigger reliability.

**Edit applied:** Added "the game-server platform agent" and shifted the dispatch phrasing to mirror the bastion card: "dispatching a task to an agent working in the baroboys repo."

### 4. Missing routing-relevant design principles

**Found:** Working Style covered process discipline (TDD, iterate, no rm -rf, wrap) but not the architectural principles that decide what BELONGS in this repo.

**Reality:** Two principles flagged in MEMORY.md / CLAUDE.md as load-bearing for routing decisions:
- **"systemd owns lifecycle — not scripts"** (MEMORY.md "Core Design Principle"). Senders who frame work in shell-loop terms ("add a polling loop", "sleep 5 then check") get a unit-file answer here. Worth surfacing so they can pre-frame.
- **Cost-constrained: near-zero idle.** A sender proposing always-on infra is already off-mission.

**Edit applied:** Added a "Design Principles (routing-relevant)" section between Working Style and References with three bullets: systemd-first, Terraform-once-systemd-runtime, cost-constrained. Kept tight — these are routing signals, not exhaustive architecture docs.

### 5. Minor: "Wine/Proton" → "Wine"

**Found:** "Wine/Proton troubleshooting for games other than VRising"

**Reality:** This repo doesn't run Proton anywhere. Mentioning it suggests there's Proton expertise here when there isn't.

**Edit applied:** "Wine troubleshooting for games other than VRising"

## Things checked and left alone (no edits warranted)

- **Stack line:** Matches MEMORY.md and CLAUDE.md exactly. No drift.
- **Identity block:** Address, role, aliases, install command all current per ADR 0006.
- **Connections:** All four sibling skills exist and are reachable. `fleet:agents-claude`, `fleet:dispatch`, `fleet:repos-fleet-mcp`, `fleet:repos-claude-skills`, `fleet:manage` — verified by spot-check.
- **`references/insights.md`:** Empty placeholder (`<!-- fill in from experience -->`). Not stale, just unfilled. Will populate organically as cross-agent observations accumulate.
- **Working Style — TDD / iterate / fix-in-place / no rm -rf / wrap:** All present in CLAUDE.md, all valid.

## Files touched (uncommitted, per dispatch)

- `plugins/fleet/skills/repos-baroboys/SKILL.md` — alignment + 5 substantive edits
- `plugins/fleet/.claude-plugin/plugin.json` — plugin-scoped description
- `plugins/fleet/skills/repos-baroboys/CRITIQUE.md` — this file (new)

## Discipline check

No concerns to raise. Dispatch was clear; canonical patterns were unambiguous; substantive critique surfaced real drift (post-checkout consolidation hadn't been backported into the identity card). Brendan batches the commit at end of session.
