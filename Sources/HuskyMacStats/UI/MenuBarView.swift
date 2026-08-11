import SwiftUI

/// The full status item: the enabled widgets, in the order the user arranged them in Settings.
struct MenuBarView: View {
    @ObservedObject var store: StatsStore
    @ObservedObject var settings: SettingsStore

    var body: some View {
        let widgets = settings.visible

        HStack(spacing: BarStyle.groupSpacing) {
            ForEach(widgets) { widget in
                view(for: widget)
            }
        }
        .padding(.horizontal, BarStyle.horizontalPadding)
        .frame(
            width: BarStyle.statusItemWidth(widgets, coreCount: store.coreCount),
            height: BarStyle.statusHeight
        )
    }

    @ViewBuilder
    private func view(for widget: Widget) -> some View {
        switch widget {
        case .cpu:
            CPUBarsView(loads: store.cpuLoads)
        case .memory:
            MemoryWidgetView(usage: store.memory, coreCount: store.coreCount)
        case .network:
            NetworkWidgetView(throughput: store.network, coreCount: store.coreCount)
        case .disk:
            DiskWidgetView(usage: store.disk, coreCount: store.coreCount)
        }
    }
}
