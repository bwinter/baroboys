# Baroboys AI Primer

sBaroboys is a GCP game server hosting platform for **V Rising** and **Barotrauma**. Packer builds
layered GCE images; Terraform provisions the VM; systemd + bash scripts manage the game lifecycle;
saves are committed to Git on every shutdown. Near-zero cost when idle.

**This file is intentionally brief. Full context lives in:**

- [`CLAUDE.md`](../CLAUDE.md) — working instructions, commands, key facts, architecture summary
- [`docs/architecture.md`](architecture.md) — deep technical reference (boot sequence, systemd
  graph, file paths, networking)
- [`docs/known-issues.md`](known-issues.md) — known bugs and gaps with fix status