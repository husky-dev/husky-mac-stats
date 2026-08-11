import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: StatsStore?
    private var controller: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let store = StatsStore()
        controller = StatusItemController(store: store)
        store.start()
        self.store = store
    }

    func applicationWillTerminate(_ notification: Notification) {
        store?.stop()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Background agent: no Dock icon, no app menu of its own.
app.setActivationPolicy(.accessory)
app.run()
