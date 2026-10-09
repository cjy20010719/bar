#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
install_dir="$HOME/Library/Application Support/bar"
agent_path="$HOME/Library/LaunchAgents/com.bar.app.display-switcher.plist"
service="gui/$(id -u)/com.bar.app.display-switcher"

mkdir -p "$install_dir" "$HOME/Library/LaunchAgents"

clang \
    -fobjc-arc \
    -Wall \
    -Wextra \
    -Werror \
    -framework Foundation \
    -framework CoreGraphics \
    "$script_dir/main.m" \
    -o "$install_dir/BarDisplaySwitcher"

install -m 644 \
    "$script_dir/com.bar.app.display-switcher.plist" \
    "$agent_path"

launchctl bootout "$service" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$agent_path"

echo "Installed and started BarDisplaySwitcher."
