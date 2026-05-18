# Backlog

---

## Active

### Near-term
- **Project rename** — "baroboys" → something generic. Image/tag prefixes already stripped as prep.
- [Games](todo/games.md) — Zomboid, Valheim, template-based onboarding
- [Testing](todo/testing.md) — smoke tests, CI tiers, manual QA
- [Admin & UX](todo/admin.md) — Cloud Run URL, multi-game awareness, game manifest

### Medium-term

- **Save files to GCS** — reduce repo bloat. `gsutil cp` instead of git commit. Trade-off:
  loses "Git as backup" simplicity.

- **Refactor games into subdir** — move `Barotrauma/` and `VRising/` under `games/`.
  GAME_DIR change cascades automatically (all paths derive from it). Low risk.

- **Tech-specific plugins / skills audit** — investigate whether installable plugins or skills
  exist that codify best practices for the techs this repo uses. Would help ensure form is good
  (e.g. catch the Packer-timeout gotcha structurally rather than via memory entry). Three-step
  approach:
  1. Build the tech list — Packer, Terraform, GCE/gcloud, systemd, Bash, Flask, Nginx, SteamCMD,
     Wine/Xvfb, direnv, Debian. (Plus our own: Make, Python.)
  2. For each: check Anthropic marketplaces + Claude Code plugin directory + web search for
     existing plugins/skills. Where one exists, evaluate fit + cost (token weight, scope) per
     project-scope curation rules in CLAUDE.md.
  3. Where none exists but the gotchas are real (Packer timeouts, Terraform state lock recovery,
     gcloud auth quirks, systemd unit ordering), draft a local skill from training data + repo
     experience — then refine via search as a correction pass rather than building from scratch.

---

## Future / Big Ideas

These are interesting but not current priority.

- **devbox dev environment** — pins terraform, packer, gcloud, python3 via Nix-backed devbox.
  Learning/demo item — not a current pain point.
- Nix for environment management (replace/augment direnv)
- Claude API integration — AI-assisted ops from admin console
- Productize game management — web UI for picking/loading games; metadata-driven setup pipeline
- React frontend for admin panel
- Go for backend services
- Additional games beyond Zomboid/Valheim

---

## Done

Completed work lives in `git log`, `docs/architecture.md`, and inline comments.
Near-term items are removed from this list once their rationale is captured in docs.
