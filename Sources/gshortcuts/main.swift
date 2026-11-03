// gshortcuts: our global keyboard shortcuts in one background process.
// Run: gshortcuts            (listens; needs Accessibility)
//      gshortcuts selftest   (runs every shortcut's checks, no permissions)
// Add a shortcut: write a class that conforms to Shortcut and add it to `shortcuts`.
import AppKit
import ApplicationServices

let shortcuts: [Shortcut] = [DoubleCommand()]
let allChecks: [Check] = DoubleCommand.checks

func log(_ text: String) { FileHandle.standardError.write("gshortcuts: \(text)\n".data(using: .utf8)!) }

var tap: CFMachPort?

func listen() {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    if !AXIsProcessTrustedWithOptions(options) { log("allow Accessibility in System Settings, then restart it") }
    let kinds: [CGEventType] = [.flagsChanged, .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown]
    let mask = kinds.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
    tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
                            eventsOfInterest: mask, callback: { _, type, event, _ in
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            shortcuts.forEach { $0.reset() }
        } else {
            shortcuts.forEach { $0.handle(type, event) }
        }
        return Unmanaged.passUnretained(event)
    }, userInfo: nil)
    guard let tap else { log("cannot create the event tap; allow Accessibility and restart"); exit(1) }
    CFRunLoopAddSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
    log("listening: \(shortcuts.map(\.name).joined(separator: ", "))")
    CFRunLoopRun()
}

func selftest() -> Never {
    let failed = allChecks.filter { check in
        let ok = check.run()
        print("\(ok ? "ok  " : "FAIL") \(check.name)")
        return !ok
    }
    exit(failed.isEmpty ? 0 : 1)
}

if CommandLine.arguments.dropFirst().first == "selftest" { selftest() } else { listen() }
