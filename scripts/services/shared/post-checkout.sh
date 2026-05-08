#!/usr/bin/env bash
# Sourced by shared/refresh.sh after the manifest is written. Fetches runtime
# secrets, exposes manifest values that envsubst needs, and processes every
# (input, output) template pair declared in the manifest.
#
# Per-game data — which templates to render, what ports to splice — lives in
# the JSON tfvars and flows in via /etc/baroboys/manifest.json. This file is
# game-agnostic; adding a new game does not require touching it.

GAME_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"
export GAME_PASSWORD

# Game-listen ports for envsubst into config templates. Convention: the first
# UDP port is the game port, the second is the query port. Games that bind a
# single port get GAME_QUERY_PORT empty (templates that don't reference it
# render fine).
read -r GAME_PORT GAME_QUERY_PORT < <(
  jq -r '[.ports.udp[0] // "", .ports.udp[1] // ""] | @tsv' /etc/baroboys/manifest.json
)
export GAME_PORT GAME_QUERY_PORT

# Process every (input, output) pair declared in manifest.templates. Paths are
# relative to GAME_DIR. envsubst replaces `${VAR}` with the values currently
# in env (GAME_PASSWORD, GAME_PORT, SAVE_NAME, RCON_*, etc. — all already
# exported by env-vars.sh + the lines above).
while IFS=$'\t' read -r in_path out_path; do
  [[ -z "$in_path" ]] && continue
  envsubst < "$GAME_DIR/$in_path" > "$GAME_DIR/$out_path"
done < <(jq -r '.templates[] | @tsv' /etc/baroboys/manifest.json)
