# Backlog

---

## Active

### Immediate

- **Verify refactor on live VM** — the shared script architecture (setup.sh, startup.sh,
  shutdown.sh, install-game-units.sh) has not been tested on a live VM. Build and smoke test
  both existing games before adding new ones:
  1. `make build-game-VRising` + `make smoke-test-VRising`
  2. `make build-game-Barotrauma` + `make smoke-test-Barotrauma`

- **Create RCON password secret** — `make update-rcon-password` (VRising needs this before boot).

### Near-term

- **Terraform state for multi-VM** — single state file means one `terraform apply` clobbers the
  other game's VM. Evaluate: workspaces, `for_each`, or separate root modules.
- **Project rename** — "baroboys" → something generic. Image/tag prefixes already stripped as prep.
- [Games](todo/games.md) — Zomboid, Valheim, template-based onboarding
- [Testing](todo/testing.md) — smoke tests, CI tiers, manual QA
- [Admin & UX](todo/admin.md) — Cloud Run URL, multi-game awareness, game manifest

### Medium-term

- **Save files to GCS** — reduce repo bloat. `gsutil cp` instead of git commit. Trade-off:
  loses "Git as backup" simplicity.

- **Refactor games into subdir** — move `Barotrauma/` and `VRising/` under `games/`.
  GAME_DIR change cascades automatically (all paths derive from it). Low risk.

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
