- **Smoke test both games** — `make smoke-test-VRising` is exercised; `make smoke-test-Barotrauma`
  hasn't been run end-to-end. Verify it passes clean.

- **Smoke test: verify game is joinable** — extend `vm_checks.sh` to check that the game port
  is accepting connections, not just that the process is running. `nc -z -w5 <host> <port>`.

- **Manual QA: connect and play both games** — provision, launch game client, verify real
  connection. Port checks confirm listening; only a human client confirms playable.

- **CI — Tier 1: syntax/validate** — `packer validate` and `terraform validate` on every push.
  GitHub Actions on `push`/`pull_request`. No GCP credentials needed.

- **CI — Tier 2: design/contract tests** — enforce design decisions:
  - `shellcheck` on all scripts in `scripts/`
  - Verify systemd unit template pairing (setup/startup/shutdown)
  - Verify `Requires=` always accompanied by `After=` in unit templates
  - Verify all `.template` files contain only known `${VAR}` placeholders
  - Verify `SAVE_NAME` is exported in VRising/post-checkout.sh before `envsubst`
  - Verify `shared/shutdown.sh` contains the stash-pull-push-pop sequence
  - Verify every game dir has an `env-vars.sh` with all `SETUP: REQUIRED` vars set
  - Verify `.envrc` and `shared.tfvars` agree on project/zone/region/machine_name

- **CI — Tier 3: E2E smoke test on push** — full smoke test on every push to `main`.
  GitHub Actions with GCP SA credentials. Upload logs as job artifacts.
