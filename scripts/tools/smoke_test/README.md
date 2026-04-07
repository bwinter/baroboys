# Smoke Test

E2E probe of a freshly provisioned game VM. Provisions infrastructure, boots the VM,
runs checks from both outside and inside, then tears down.

## Usage

```bash
./scripts/tools/smoke_test/run.sh [--game VRising|Barotrauma] [--skip-destroy]
```

`--skip-destroy` leaves the VM running after tests for manual inspection.

## What It Tests

**External** (from local machine):
- Terraform provisions cleanly and VM reaches RUNNING
- Boot sequence completes in correct service order (via serial console)
- Admin panel reachable: nginx + auth + Flask proxy all working
- `VRisingServer.log` served via admin panel (exercises symlink + log_map end-to-end)

**Internal** (`vm_checks.sh` runs on the VM, sources `config.sh`):
- Self-identifies game from `/etc/baroboys/active-game` (written by `setup.sh` at boot)
- All required systemd services active
- VRisingServer.log symlink points to correct target (VRising only)
- Game process running with sane RAM usage (500MB–5.5GB)
- Game log has real content (not just boot stub)
- Flask responding on :5000 directly

`run.sh` cross-checks that the server's reported game matches what was provisioned.

## Notes

- `run.sh` calls `terraform apply/destroy -auto-approve` directly — `make apply/destroy`
  are interactive and not scriptable.
- `vm_checks.sh` takes no arguments — it self-identifies via `/etc/baroboys/active-game`,
  which also feeds the admin panel multi-game awareness feature.