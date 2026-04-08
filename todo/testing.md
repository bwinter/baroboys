# Testing & CI

Validation layers — from local smoke tests to automated CI. Ordered by what you can
do today vs. what needs infrastructure.

## Smoke tests (ready now)

- **Smoke test both games** — `make smoke-test-VRising` is exercised; `make smoke-test-Barotrauma`
  hasn't been run end-to-end. Verify it passes clean.

- **Smoke test: verify game is joinable** — extend `vm_checks.sh` to check that the game port
  is accepting connections, not just that the process is running. `nc -z -w5 <host> <port>`.

- **Manual QA: connect and play both games** — provision, launch game client, verify real
  connection. Port checks confirm listening; only a human client confirms playable.

## Self-reporting health (design ready, blocked on smoke test passing)

The VM should self-report health, not require external probing. Design:

1. **Fold vm_checks.sh logic into idle_check.sh** — health checks become additional fields in
   status.json. Boot-time seed runs all checks (static + runtime). Timer runs only runtime
   checks (process alive, services healthy, RAM). Static checks (Wine arch, WINEARCH) don't
   change after boot.

2. **`make game-status-<GAME>` already exists** — curls status.json from running VM. Once health
   fields are in status.json, this becomes the single "how's my server" command.

3. **Thin out run.sh** — replace SSH + vm_checks.sh stage with a curl to the health endpoint.
   External smoke test becomes: provision → poll health endpoint → verify external reachability
   (nginx + auth + Flask) → tear down. No SSH needed.

4. **Admin panel** — status.json is already served by nginx. HTML changes to display health
   fields are a separate step (see todo/admin.md).

## LLM-Executor-Test (document the pattern)

The LLM-in-conversation testing pattern that's emerged across sessions:
- **Call path trace**: walk Packer build → boot → runtime → shutdown, find bugs at context boundaries
- **Rename consistency**: grep every old name across scripts, units, docs, Makefile, memory
- **Permission model audit**: trace which user runs what, verify sudo/chown/chmod match
- **Ripple effect probe**: after any change, ask "what else references this?"

This is static analysis that runs in conversation — complementary to the automated smoke test
(which tests the running system). Worth documenting as a reusable pattern, especially for
the post-build nudge where the LLM naturally suggests verification.

## Makefile shortcuts

The full menu uses consistent `object-verb-<GAME>` naming. Consider adding short aliases
for the most-used commands. Candidates: `ssh-<GAME>` → `game-ssh-<GAME>`,
`status-<GAME>` → `game-status-<GAME>`. Decide which ones earn their keep based on
actual usage after the rename settles in.

## CI (needs GitHub Actions setup)

- **Tier 1: syntax/validate** — `packer validate` and `terraform validate` on every push.
  GitHub Actions on `push`/`pull_request`. No GCP credentials needed.

- **Tier 2: design/contract tests** — enforce design decisions:
  - `shellcheck` on all scripts in `scripts/`
  - Verify systemd unit template pairing (refresh/startup/shutdown)
  - Verify `Requires=` always accompanied by `After=` in unit templates
  - Verify all `.template` files contain only known `${VAR}` placeholders
  - Verify `SAVE_NAME` is exported in VRising/post-checkout.sh before `envsubst`
  - Verify `shared/shutdown.sh` contains the stash-pull-push-pop sequence
  - Verify every game dir has an `env-vars.sh` with all `SETUP: REQUIRED` vars set
  - Verify `.envrc` and `shared.tfvars` agree on project/zone/region

- **Tier 3: E2E smoke test on push** — full smoke test on every push to `main`.
  GitHub Actions with GCP SA credentials. Upload logs as job artifacts.
