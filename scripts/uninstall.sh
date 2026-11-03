#!/bin/sh
# Stops gshortcuts and removes it. Remove its Accessibility entry in System Settings by hand.
set -u
LABEL=cz.gabo.gshortcuts
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -rf "$HOME/Library/LaunchAgents/$LABEL.plist" "$HOME/Library/Application Support/gshortcuts" "$HOME/Library/Logs/gshortcuts"
echo "gshortcuts is removed."
