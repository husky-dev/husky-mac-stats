import SwiftUI

/// Popover section for the disk widget: capacity bar plus total / used / free.
struct DiskSection: View {
    @ObservedObject var store: StatsStore

    var body: some View {
        let usage = store.disk

        PopoverSection(title: usage.volumeName) {
            CapacityBar(fraction: usage.fractionUsed)

            VStack(spacing: 4) {
                StatRow(label: "Total", value: PopoverStyle.bytes(usage.totalBytes))
                StatRow(label: "Used", value: PopoverStyle.bytes(usage.usedBytes))
                StatRow(label: "Free", value: PopoverStyle.bytes(usage.freeBytes))
            }

            Text("\(PopoverStyle.percent(usage.fractionUsed)) used")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}
