import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: StatsStore?
    private var settings: SettingsStore?
    private var controller: StatusItemController?
    private var settingsWindow: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = StatsStore()
        let settings = SettingsStore()

        let controller = StatusItemController(store: store, settings: settings)
        controller.onOpenSettings = { [weak self] in self?.showSettings() }

        store.start()
        self.store = store
        self.settings = settings
        self.controller = controller
    }

    func applicationWillTerminate(_ notification: Notification) {
        store?.stop()
    }

    /// Built lazily and kept afterwards, so reopening returns to the same window.
    private func showSettings() {
        guard let settings else { return }

        let window = settingsWindow ?? SettingsWindowController(settings: settings)
        settingsWindow = window
        window.show()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Background agent: no Dock icon, no app menu of its own.
app.setActivationPolicy(.accessory)
app.run()
