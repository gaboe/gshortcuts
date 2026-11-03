# gshortcuts

Small global keyboard shortcuts for macOS, in one background process.

| Shortcut | What it does |
| --- | --- |
| Tap ⌘ twice | Moves to the next window of the frontmost app, for example between two Rider projects. Repeat it to go through all windows. ⌘ used with another key or modifier does not count. |

## Install

Needs macOS 13 or later and the Xcode command line tools (`xcode-select --install`).

```sh
git clone https://github.com/gaboe/gshortcuts.git
cd gshortcuts
sh scripts/install.sh
```

1. The script builds the tool, runs its self tests and starts it as a LaunchAgent.
2. Open System Settings → Privacy & Security → Accessibility and turn on `gshortcuts`. If it is not in the list, add `~/Library/Application Support/gshortcuts/bin/gshortcuts` with **+** (⇧⌘G opens the hidden folder).
3. Restart it: `launchctl kickstart -k gui/$(id -u)/cz.gabo.gshortcuts`.

After an update, run `git pull && sh scripts/install.sh`. A rebuild can make macOS ask for Accessibility again.

Remove it with `sh scripts/uninstall.sh`, then remove its Accessibility entry.

## Add a shortcut

Each shortcut is a class that conforms to `Shortcut` in `Sources/gshortcuts/Shortcut.swift`. Add it to `shortcuts` in `main.swift` and its checks to `allChecks`. `gshortcuts selftest` runs the checks without any permission.

Logs: `~/Library/Logs/gshortcuts/stderr.log`.
