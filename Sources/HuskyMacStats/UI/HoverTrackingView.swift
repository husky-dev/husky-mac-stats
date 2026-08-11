import AppKit

/// Transparent overlay that reports pointer position inside the status item.
///
/// It sits above the hosting view purely to own a tracking area; `hitTest` returns nil so clicks
/// still reach the underlying `NSStatusBarButton`. Tracking areas deliver enter/exit/moved
/// independently of hit-testing, so hover works even though the view is click-through.
final class HoverTrackingView: NSView {
    /// Pointer location in this view's coordinates, or nil once the pointer leaves.
    var onHover: ((CGPoint?) -> Void)?

    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        // The status item resizes with core count and menu bar layout, so rebuild rather than
        // trusting a rect captured at init.
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: bounds,
            // `.activeAlways` matters: the app is a background agent and is almost never frontmost.
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        report(event)
    }

    override func mouseMoved(with event: NSEvent) {
        report(event)
    }

    override func mouseExited(with event: NSEvent) {
        onHover?(nil)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    private func report(_ event: NSEvent) {
        onHover?(convert(event.locationInWindow, from: nil))
    }
}
