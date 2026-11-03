// Window actions through the Accessibility API.
import AppKit
import ApplicationServices

func attribute<T>(_ element: AXUIElement, _ name: String) -> T? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
    return value as? T
}

/// Standard, not minimized windows of every process of the app, front first.
func windows(of app: NSRunningApplication) -> [(pid: pid_t, window: AXUIElement)] {
    let processes = app.bundleIdentifier.map { NSRunningApplication.runningApplications(withBundleIdentifier: $0) } ?? [app]
    let ordered = [app] + processes.filter { $0.processIdentifier != app.processIdentifier }
    return ordered.flatMap { process -> [(pid: pid_t, window: AXUIElement)] in
        let element = AXUIElementCreateApplication(process.processIdentifier)
        let list: [AXUIElement] = attribute(element, kAXWindowsAttribute) ?? []
        return list
            .filter { (attribute($0, kAXSubroleAttribute) as String?) == kAXStandardWindowSubrole }
            .filter { (attribute($0, kAXMinimizedAttribute) as Bool?) != true }
            .map { (process.processIdentifier, $0) }
    }
}

/// Raises the last window of the frontmost app, so repeated calls go through all its windows.
func nextWindow() {
    guard let app = NSWorkspace.shared.frontmostApplication else { return }
    let list = windows(of: app)
    guard list.count > 1, let target = list.last else { return }
    AXUIElementSetAttributeValue(target.window, kAXMainAttribute as CFString, kCFBooleanTrue)
    AXUIElementPerformAction(target.window, kAXRaiseAction as CFString)
    NSRunningApplication(processIdentifier: target.pid)?.activate()
}
