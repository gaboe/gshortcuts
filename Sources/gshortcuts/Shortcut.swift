// A shortcut sees every event the tap listens to and acts on its own.
import CoreGraphics

protocol Shortcut: AnyObject {
    var name: String { get }
    /// Called on the event tap's thread. Do the action on the main queue.
    func handle(_ type: CGEventType, _ event: CGEvent)
    /// Called when macOS turned the tap off and on again.
    func reset()
}

/// A self test case: a name and a check that returns true when it passes.
typealias Check = (name: String, run: () -> Bool)
