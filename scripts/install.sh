#!/bin/sh
# Builds gshortcuts, installs it for the current user and starts it as a LaunchAgent.
# Run it again after an update. It needs Accessibility (System Settings → Privacy & Security).
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
LABEL=cz.gabo.gshortcuts
BIN="$HOME/Library/Application Support/gshortcuts/bin"
LOGS="$HOME/Library/Logs/gshortcuts"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"
UID_=$(id -u)
cd "$ROOT"
swift build -c release
mkdir -p "$BIN" "$LOGS" "$(dirname "$AGENT")"
cp .build/release/gshortcuts "$BIN/gshortcuts"
chmod 755 "$BIN/gshortcuts"
codesign --force --sign - --identifier "$LABEL" "$BIN/gshortcuts"
"$BIN/gshortcuts" selftest
PLIST=$(mktemp "$(dirname "$AGENT")/.gshortcuts.XXXXXX")
trap 'rm -f "$PLIST"' EXIT HUP INT TERM
/usr/bin/plutil -create xml1 "$PLIST"
/usr/libexec/PlistBuddy -c "Add :Label string $LABEL" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :ProgramArguments array" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :ProgramArguments:0 string $BIN/gshortcuts" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :RunAtLoad bool true" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :KeepAlive bool true" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :ProcessType string Interactive" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :StandardOutPath string $LOGS/stdout.log" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :StandardErrorPath string $LOGS/stderr.log" "$PLIST"
mv "$PLIST" "$AGENT"
trap - EXIT HUP INT TERM
launchctl bootout "gui/$UID_/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID_" "$AGENT"
echo "gshortcuts is running."
echo "Allow it in System Settings → Privacy & Security → Accessibility ($BIN/gshortcuts),"
echo "then restart it: launchctl kickstart -k gui/$UID_/$LABEL"
