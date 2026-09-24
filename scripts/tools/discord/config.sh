#!/usr/bin/env bash

# Public Discord application settings. Override these environment variables for
# another Discord application or server; the bot token stays in Secret Manager.
DISCORD_APPLICATION_ID="${DISCORD_APPLICATION_ID:-1552444135376425010}"
DISCORD_PUBLIC_KEY="${DISCORD_PUBLIC_KEY:-19fcc04f19c646459ce07aa876988a15208ed25edf2fc256b7b55874bb0e70cb}"
# Semicolon-separated guild:channel pairs. Add another pair when the bot has
# been installed in that server, for example:
# guild-a:channel-a;guild-b:channel-b
DISCORD_ALLOWED_LOCATIONS="${DISCORD_ALLOWED_LOCATIONS:-691814072483840071:1552460843092938842}"
