#!/bin/bash

#######################################
# Init volume at 60% for ear protection at startup
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   None
#######################################

mkdir -p ~/.config/autostart

cat > ~/.config/autostart/volume-cap.desktop << 'EOF'
[Desktop Entry]
Type=Application
Exec=bash -c "wpctl status | awk '/Sinks:/,/Sources:/' | grep -oP '[0-9]+(?=\.\s)' | while read id; do wpctl set-volume \"\$id\" 0.60; done"
Name=Volume Cap
X-GNOME-Autostart-enabled=true
EOF
