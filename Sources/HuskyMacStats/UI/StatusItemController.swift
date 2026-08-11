import AppKit
import SwiftUI

/// Owns the menu bar item: its SwiftUI content, the hover popover, and the right-click menu.
@MainActor
final class StatusItemController: NSObject {
    private let store: StatsStore
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var hoverView: HoverTrackingView?
    private var closeWorkItem: DispatchWorkItem?
    private var isOverDisk = false

    init(store: StatsStore) {
        self.store = store
        statusItem = NSStatusBar.system.statusItem(
            withLength: BarStyle.statusItemWidth(coreCount: store.coreCount)
        )
        super.init()

        configureButton()
        configurePopover()
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }

        let hosting = NSHostingView(rootView: MenuBarView(store: store))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(hosting)

        let hover = HoverTrackingView()
        hover.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(hover)
        hover.onHover = { [weak self] point in
            self?.handleHover(at: point)
        }
        hoverView = hover

        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: button.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            hover.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            hover.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            hover.topAnchor.constraint(equalTo: button.topAnchor),
            hover.bottomAnchor.constraint(equalTo: button.bottomAnchor),
        ])

        button.target = self
        button.action = #selector(buttonClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func configurePopover() {
        popover.contentSize = NSSize(width: 220, height: 150)
        popover.contentViewController = NSHostingController(rootView: DiskPopoverView(store: store))
        popover.animates = false
        // Not `.transient`: the app is usually inactive, and transient dismissal behaves
        // unpredictably then. Hover exit closes it explicitly instead.
        popover.behavior = .applicationDefined
    }

    // MARK: - Hover

    private func handleHover(at point: CGPoint?) {
        guard let point else {
            isOverDisk = false
            scheduleClose()
            return
        }

        let overDisk = BarStyle.diskRange(coreCount: store.coreCount).contains(point.x)
        guard overDisk != isOverDisk else { return }
        isOverDisk = overDisk

        if overDisk {
            showPopover()
        } else {
            scheduleClose()
        }
    }

    private func showPopover() {
        closeWorkItem?.cancel()
        closeWorkItem = nil

        guard let button = statusItem.button, !popover.isShown else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    /// Debounced so a pointer jittering across the widget's edge doesn't flicker the popover.
    private func scheduleClose() {
        closeWorkItem?.cancel()

        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.isOverDisk else { return }
            self.popover.performClose(nil)
        }
        closeWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }

    // MARK: - Clicks

    @objc private func buttonClicked() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showMenu()
        } else {
            popover.isShown ? popover.performClose(nil) : showPopover()
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = LaunchAtLogin.isEnabled ? .on : .off
        if LaunchAtLogin.needsApproval {
            launchItem.title = "Launch at Login (approve in System Settings)"
        }
        menu.addItem(launchItem)
        menu.addItem(.separator())

        menu.addItem(
            withTitle: "Quit Husky Mac Stats",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        // Attaching the menu only for this click keeps left-clicks free for the popover.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleLaunchAtLogin() {
        guard let error = LaunchAtLogin.setEnabled(!LaunchAtLogin.isEnabled) else { return }

        let alert = NSAlert()
        alert.messageText = "Couldn't change the login item"
        alert.informativeText = """
            \(error.localizedDescription)

            macOS only launches login items from a stable, trusted location. Move \
            HuskyMacStats.app into /Applications and try again.
            """
        alert.alertStyle = .warning
        // A background agent has no key window to attach a sheet to.
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
