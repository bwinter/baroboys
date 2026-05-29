# Wrap Targets — baroboys

Files, indexes, and gotchas `session:wrap` should pay attention to in this repo. Per `session:wrap/references/wrap-targets.md`.

Grow the table when a wrap touches something not yet listed. Use the Notes section for one-offs that don't fit a row yet.

## Targets

| File / target | Shape | Triggers attention when... |
|---|---|---|
| GCP orphan check (pre-commit gate) | `gcloud compute instances list` | every wrap — must confirm `Listed 0 items.` before commit |
| `docs/known-issues.md` | open issues registry | any code fix lands — verify closed issue's entry is removed |
| `docs/architecture.md` | technical reference | infrastructure decision, new systemd pattern, new file path, or build behavior changes |
| `docs/adding-a-game.md` | onboarding guide | per-game file schema changes or shared script layout shifts |
| `memory/scripts-reference.md` | script index | any script added, renamed, or meaningfully changed (Step 4 new-script obligation) |
| `memory/systemd-reference.md` | systemd patterns | unit file added/changed or unit dependency pattern updated |
| `todo/*.md` (three files) | per-area backlogs | game/testing/admin scope changes; wrap's Step 9 hits root `TODO.md` only by default |
| `plugins/fleet/skills/repos-baroboys/SKILL.md` | repo identity skill | repo address, dispatch constraints, or domain summary changes |

## Notes

- **GCP orphan check is a hard gate, not a soft check.** Run `gcloud compute instances list` and confirm `Listed 0 items.` before every commit. A Packer build VM orphaned 2026-03-09 ran 60 days silently and cost $96. If a VM is intentional (active play session, in-progress build), confirm with user explicitly before committing. Distinct from `make clean` (which checks stale build artifacts — images, disks, IPs — not running VMs).
- **Pending Verification annotation.** Step 5 entries that need image rebuild should be annotated `(needs: image rebuild + live boot)` or `(needs: smoke test run)`. Don't close a Pending Verification entry until the annotated condition is met — a smoke test or live boot confirmation.
- **Partial TODO completions.** Step 8: mark completed steps with ✅ + commit hash in `todo/*.md`; move an item to Done only when ALL steps complete. Partial ✅ marks inline are the signal to the next agent that a multi-step item is in progress.
- **After wrap: compact.** Memory is current and commit is pushed — right moment to `/compact`. Not a wrap obligation but a natural cadence point for this repo.
- **`memory/wrap-protocol.md` is a dead reference.** CLAUDE.md "Working Style" references it but the file doesn't exist; the wrap protocol IS `session:wrap`. The CLAUDE.md pointer is cleaned up — this note exists until a future session confirms no other references remain.
