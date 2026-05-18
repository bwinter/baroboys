#!/usr/bin/env bash
# PreToolUse hook for Bash — block long-running build commands without explicit timeout.
#
# Why: Claude Code's Bash tool default timeout is 120000ms (2 min). Packer image builds
# and Terraform applies take 10–30 min. Without an explicit timeout, the harness SIGKILLs
# the local process at 2 min and the GCP-side resource (build VM, ongoing terraform run)
# is left orphaned — silent billing for days/weeks.
#
# Motivating incident: 2026-03-09 → 2026-05-08 Packer build VM ran 60 days, $96 cost.
#
# Behavior: if any command segment matches a long-running pattern AND timeout is
# unset or <1,800,000ms, block with exit 2 (Claude sees stderr + retries).
#
# String-literal handling: heredoc bodies, single-quoted, and double-quoted strings
# are stripped before pattern-matching, so the hook doesn't false-positive on commit
# messages or echo'd text that happens to mention `make build-*`.

set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')
timeout=$(echo "$input" | jq -r '.tool_input.timeout // 0')

# Strip strings + heredocs, then split on shell separators and check each piece's start.
is_build=$(printf '%s' "$command" | perl -0777 -ne '
  s/<<-?["\x27]?(\w+)["\x27]?\b.*?\n\1\b//gs;   # heredoc bodies
  s/\x27[^\x27]*\x27//g;                         # single-quoted strings
  s/"[^"]*"//g;                                  # double-quoted strings
  for my $piece (split /(?:&&|\|\||;|\|)/) {
    $piece =~ s/^\s+|\s+$//g;
    if ($piece =~ /^(make\s+(build|smoke-test|terraform-apply|terraform-destroy)-|packer\s+build\b|terraform\s+(apply|destroy)\b)/) {
      print "yes"; last;
    }
  }
')

if [[ "$is_build" == "yes" ]] && (( timeout < 1800000 )); then
  cat >&2 <<EOF
⚠️  Long-running build/deploy command detected:
    $command

Claude Code's default Bash timeout is 120000ms (2 min). This command typically takes
10–30 min. Without an explicit timeout, the harness will SIGKILL the local process and
leave GCP-side resources (Packer build VM, Terraform-managed VM) orphaned and billing.

Real incident: 2026-03-09 → 2026-05-08 orphan VM cost \$96 (60 days continuous runtime).

Fix: re-invoke this Bash call with an explicit timeout. Recommended:
    timeout: 1800000   (30 min, in milliseconds)

For longer operations (full \`make build\` of all layers), use 3600000 (60 min) or
run_in_background: true with periodic BashOutput polling instead of timeout.
EOF
  exit 2
fi

exit 0
