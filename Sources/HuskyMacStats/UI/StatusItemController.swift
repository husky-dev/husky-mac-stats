import AppKit
import Combine
import SwiftUI

/// Owns the menu bar item: its SwiftUI content, the hover popover, and the right-click menu.
@MainActor
final class StatusItemController: NSObject {
    /// Invoked when the user picks Settings from the right-click menu.
    var onOpenSettings: (() -> Void)?

    private let store: StatsStore
    private let settings: SettingsStore
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var hoverView: HoverTrackingView?
    private var closeWorkItem: DispatchWorkItem?
    private var hoveredWidget: Widget?
    /// Which widget the popover is currently built for, so it is only rebuilt when that changes.
    private var popoverWidget: Widget?
    private var cancellables: Set<AnyCancellable> = []

    init(store: StatsStore, settings: SettingsStore) {
        self.store = store
        self.settings = settings
        statusItem = NSStatusBar.system.statusItem(
            withLength: BarStyle.statusItemWidth(settings.visible, coreCount: store.coreCount)
        )
        super.init()

        configureButton()
        configurePopover()
        observeSettings()
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }

        let hosting = NSHostingView(rootView: MenuBarView(store: store, settings: settings))
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
        popover.animates = false
        // Not `.transient`: the app is usually inactive, and transient dismissal behaves
        // unpredictably then. Hover exit closes it explicitly instead.
        popover.behavior = .applicationDefined
    }

    /// The status item's width is fixed at creation, so toggling or reordering widgets has to
    /// resize it explicitly. `MenuBarView` re-renders on its own through `@ObservedObject`.
    private func observeSettings() {
        settings.objectWillChange
            .receive(on: RunLoop.main)  // fires *before* the change lands; read it on the next turn
            .sink { [weak self] _ in
                self?.resizeStatusItem()
            }
            .store(in: &cancellables)
    }

    private func resizeStatusItem() {
        let visible = settings.visible
        statusItem.length = BarStyle.statusItemWidth(visible, coreCount: store.coreCount)

        // A widget can disappear from under the pointer; don't leave its popover on screen.
        if let hoveredWidget, !visible.contains(hoveredWidget) {
            self.hoveredWidget = nil
            popover.performClose(nil)
        }
    }

    // MARK: - Hover

    private func handleHover(at point: CGPoint?) {
        let widget = point.flatMap {
            BarStyle.widget(at: $0.x, in: settings.visible, coreCount: store.coreCount)
        }

        guard widget != hoveredWidget else { return }
        hoveredWidget = widget

        if let widget {
            showPopover(for: widget)
        } else {
            scheduleClose()
        }
    }

    private func showPopover(for widget: Widget) {
        closeWorkItem?.cancel()
        closeWorkItem = nil

        guard let button = statusItem.button else { return }

        // Moving between widgets keeps the popover up but swaps its contents.
        if popoverWidget != widget {
            let hosting = NSHostingController(
                rootView: WidgetPopoverView(widget: widget, store: store)
            )
            popover.contentViewController = hosting
            popover.contentSize = hosting.view.fittingSize
            popoverWidget = widget
        }

        guard !popover.isShown else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    /// Debounced so a pointer jittering across a widget's edge doesn't flicker the popover.
    private func scheduleClose() {
        closeWorkItem?.cancel()

        let work = DispatchWorkItem { [weak self] in
            guard let self, self.hoveredWidget == nil else { return }
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
        } else if popover.isShown {
            popover.performClose(nil)
        } else if let widget = hoveredWidget ?? settings.visible.first {
            showPopover(for: widget)
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
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

    @objc private func openSettings() {
        // The popover would otherwise hang over the window that is about to take focus.
        hoveredWidget = nil
        popover.performClose(nil)
        onOpenSettings?()
    }
}
