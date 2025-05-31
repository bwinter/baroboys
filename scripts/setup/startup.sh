#!/bin/bash
set -eux

# Refreshes Repositories.
source "/root/baroboys/scripts/setup/root/setup_users.sh"

# Refreshes Nginx & config (Get latest Admin Server routes.)
source "/root/baroboys/scripts/setup/install/apt_nginx.sh"

# Refreshes & Enables & Starts Admin Server (Startup Admin Server immediately.)
source "/root/baroboys/scripts/setup/install/service/admin_server.sh"

# Refreshes Shutdown Service (Want to use latest lave logic.)
source "/root/baroboys/scripts/setup/install/service/shutdown.sh"

# Refreshes & Enables Startup Service (Want to install self to ensure refresh occurs after restart.)
source "/root/baroboys/scripts/setup/install/service/startup.sh"

# Refreshes game (Dependencies refreshed, game updated & started.)
source "/root/baroboys/scripts/setup/root/setup_game.sh"