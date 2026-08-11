import SwiftUI

/// The full status item: per-core CPU bars, then the disk widget.
struct MenuBarView: View {
    @ObservedObject var store: StatsStore

    var body: some View {
        HStack(spacing: BarStyle.groupSpacing) {
            CPUBarsView(loads: store.cpuLoads)
            DiskWidgetView(usage: store.disk)
        }
        .padding(.horizontal, BarStyle.horizontalPadding)
        .frame(
            width: BarStyle.statusItemWidth(coreCount: store.coreCount),
            height: BarStyle.statusHeight
        )
    }
}
