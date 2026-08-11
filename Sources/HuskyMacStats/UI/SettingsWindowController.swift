import AppKit
import SwiftUI

/// Hosts `SettingsView` in a real window.
///
/// A plain `NSWindow` rather than SwiftUI's `Settings` scene: this is an `.accessory` app with no
/// app menu, so there is no Settings command to hang that scene off, and opening it programmatically
/// is unreliable. Showing a window we own is predictable.
@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    convenience init(settings: SettingsStore) {
        let hosting = NSHostingController(rootView: SettingsView(settings: settings))

        let window = NSWindow(contentViewController: hosting)
        window.title = "Husky Mac Stats Settings"
        window.styleMask = [.titled, .closable]
        // The controller is retained across openings so the window can be shown again after close.
        window.isReleasedWhenClosed = false
        window.center()

        self.init(window: window)
        window.delegate = self
    }

    /// Brings the window forward. The app is a background agent and is never frontmost, so an
    /// explicit `activate` is required or the window appears behind whatever the user is using.
    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
