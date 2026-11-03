// ⌘⌘: tap ⌘ twice to move to the next window of the frontmost app.
import Foundation
import CoreGraphics

/// Tells a double tap of ⌘ alone from ⌘ used as a modifier.
struct TapDetector {
    var maxHold: TimeInterval = 0.25   // ⌘ down to up, one tap
    var maxGap: TimeInterval = 0.35    // first tap up to second tap down

    private var downAt: TimeInterval?
    private var lastTapAt: TimeInterval?
    private var dirty = false          // another key during this press

    /// ⌘ state or other modifiers changed. Returns true on the second tap.
    mutating func flags(command: Bool, others: Bool, at t: TimeInterval) -> Bool {
        if others { reset(); return false }
        if command {
            if downAt == nil {
                if let last = lastTapAt, t - last > maxGap { lastTapAt = nil }
                downAt = t
                dirty = false
            }
            return false
        }
        guard let down = downAt else { return false }
        downAt = nil
        if dirty || t - down > maxHold { lastTapAt = nil; return false }
        if lastTapAt != nil { lastTapAt = nil; return true }
        lastTapAt = t
        return false
    }

    /// A key or a mouse button went down.
    mutating func other() {
        dirty = downAt != nil
        lastTapAt = nil
    }

    mutating func reset() { downAt = nil; lastTapAt = nil; dirty = false }
}

final class DoubleCommand: Shortcut {
    let name = "⌘⌘ next window"
    private var detector = TapDetector()
    private let others: CGEventFlags = [.maskShift, .maskControl, .maskAlternate, .maskSecondaryFn]

    func handle(_ type: CGEventType, _ event: CGEvent) {
        guard type == .flagsChanged else { detector.other(); return }
        let flags = event.flags
        let fired = detector.flags(command: flags.contains(.maskCommand),
                                   others: !flags.intersection(others).isEmpty,
                                   at: ProcessInfo.processInfo.systemUptime)
        if fired { DispatchQueue.main.async(execute: nextWindow) }
    }

    func reset() { detector.reset() }

    static let checks: [Check] = {
        typealias Step = (command: Bool, others: Bool, at: TimeInterval)
        func fires(_ steps: [Step], otherBefore: Set<Int> = []) -> Int {
            var d = TapDetector()
            var count = 0
            for (i, s) in steps.enumerated() {
                if otherBefore.contains(i) { d.other() }
                if d.flags(command: s.command, others: s.others, at: s.at) { count += 1 }
            }
            return count
        }
        let quick: [Step] = [(true, false, 0), (false, false, 0.08), (true, false, 0.2), (false, false, 0.28)]
        return [
            ("two quick taps fire", { fires(quick) == 1 }),
            ("one tap does not fire", { fires(Array(quick.prefix(2))) == 0 }),
            ("slow second tap does not fire", { fires([(true, false, 0), (false, false, 0.08), (true, false, 0.6), (false, false, 0.68)]) == 0 }),
            ("long hold does not fire", { fires([(true, false, 0), (false, false, 0.5), (true, false, 0.6), (false, false, 0.68)]) == 0 }),
            ("⌘C between taps does not fire", { fires(quick, otherBefore: [2]) == 0 }),
            ("⌘ with a key in the second press does not fire", { fires(quick, otherBefore: [3]) == 0 }),
            ("⇧⌘ does not fire", { fires([(true, false, 0), (false, false, 0.08), (true, true, 0.2), (false, false, 0.28)]) == 0 }),
            ("triple tap fires once", { fires(quick + [(true, false, 0.4), (false, false, 0.48)]) == 1 }),
        ]
    }()
}
