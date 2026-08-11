import Foundation
import ServiceManagement

/// Registers the app as a login item via `SMAppService`, the modern replacement for
/// `LSSharedFileList` and hand-written LaunchAgent plists. The user can always override the choice
/// in System Settings → General → Login Items.
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// True once the user has approved the item, or when approval is still pending in System
    /// Settings — the registration succeeded either way.
    static var needsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    /// Returns the error on failure so the caller can surface it; registration can legitimately fail
    /// when the bundle lives somewhere the system won't launch from.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Error? {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return nil
        } catch {
            return error
        }
    }
}
