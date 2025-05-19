# This is designed to be manually run on the server.
# tl;dr it starts a screen session so terminal can die and server still stays up.
screen -S baro-server -d -m /home/bwinter_sc81/baroboys/Barotrauma/DedicatedServer

# TODO: get this into a systemd service.