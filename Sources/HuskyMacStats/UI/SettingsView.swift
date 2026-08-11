import AppKit
import SwiftUI

/// Settings content: the reorderable widget list, and general app preferences.
struct SettingsView: View {
    @ObservedObject var settings: SettingsStore

    /// `SMAppService` exposes no change notification, so the toggle mirrors it in local state and
    /// re-reads on `refreshLaunchAtLogin()` — the user can flip it in System Settings behind us.
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var needsApproval = LaunchAtLogin.needsApproval

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Widgets")
                    .font(.system(size: 13, weight: .semibold))

                Text("Drag to reorder how they appear in the menu bar.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            List {
                ForEach(settings.order) { widget in
                    row(for: widget)
                }
                .onMove { source, destination in
                    settings.move(fromOffsets: source, toOffset: destination)
                }
            }
            .listStyle(.bordered)
            .frame(minHeight: 180)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Launch at Login", isOn: launchAtLoginBinding)

                if needsApproval {
                    Text("Approve Husky Mac Stats in System Settings → General → Login Items.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .frame(width: 380)
        .onAppear(perform: refreshLaunchAtLogin)
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in
            refreshLaunchAtLogin()
        }
    }

    private func row(for widget: Widget) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)

            Image(systemName: widget.symbolName)
                .font(.system(size: 13))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(widget.title)
                    .font(.system(size: 12, weight: .medium))
                Text(widget.summary)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: binding(for: widget))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                // The last enabled widget can't be turned off: a zero-width status item can't be
                // right-clicked, so there would be no way back into this window.
                .disabled(isOn(widget) && !settings.canDisable(widget))
        }
        .padding(.vertical, 3)
        // Disabled widgets keep their slot in the order, but read as inactive.
        .opacity(isOn(widget) ? 1 : 0.5)
    }

    private func isOn(_ widget: Widget) -> Bool {
        settings.enabled.contains(widget)
    }

    private func binding(for widget: Widget) -> Binding<Bool> {
        Binding(
            get: { isOn(widget) },
            set: { settings.setEnabled($0, for: widget) }
        )
    }

    // MARK: - Launch at login

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin },
            set: { setLaunchAtLogin($0) }
        )
    }

    private func refreshLaunchAtLogin() {
        launchAtLogin = LaunchAtLogin.isEnabled
        needsApproval = LaunchAtLogin.needsApproval
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled

        guard let error = LaunchAtLogin.setEnabled(enabled) else {
            needsApproval = LaunchAtLogin.needsApproval
            return
        }

        // Registration failed, so the switch must not keep claiming it succeeded.
        refreshLaunchAtLogin()

        let alert = NSAlert()
        alert.messageText = "Couldn't change the login item"
        alert.informativeText = """
            \(error.localizedDescription)

            macOS only launches login items from a stable, trusted location. Move \
            HuskyMacStats.app into /Applications and try again.
            """
        alert.alertStyle = .warning
        alert.runModal()
    }
}
