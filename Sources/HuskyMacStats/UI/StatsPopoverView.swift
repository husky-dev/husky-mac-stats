import SwiftUI

/// The hover popover: one section per visible widget, stacked in the status item's own order.
///
/// There is a single panel rather than one per widget — reading two metrics shouldn't mean aiming at
/// two glyphs — so hovering anywhere on the status item shows all of this.
struct StatsPopoverView: View {
    let widgets: [Widget]
    @ObservedObject var store: StatsStore

    var body: some View {
        PopoverPanel {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(widgets.enumerated()), id: \.element) { index, widget in
                    if index > 0 { Divider() }
                    section(for: widget)
                }
            }
        }
    }

    /// A new widget registers its popover content here, and nowhere else.
    @ViewBuilder
    private func section(for widget: Widget) -> some View {
        switch widget {
        case .cpu: CPUSection(store: store)
        case .memory: MemorySection(store: store)
        case .network: NetworkSection(store: store)
        case .disk: DiskSection(store: store)
        }
    }
}

/// Per-core load, plus the average across all cores.
struct CPUSection: View {
    @ObservedObject var store: StatsStore

    var body: some View {
        let loads = store.cpuLoads
        let average = loads.isEmpty ? 0 : loads.reduce(0, +) / Double(loads.count)

        PopoverSection(title: "CPU") {
            CapacityBar(fraction: average)

            Text("\(PopoverStyle.percent(average)) average across \(loads.count) cores")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                ForEach(Array(loads.enumerated()), id: \.offset) { index, load in
                    HStack(spacing: 8) {
                        Text("Core \(index)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(width: 46, alignment: .leading)

                        CapacityBar(fraction: load, height: 4)

                        Text(PopoverStyle.percent(load))
                            .font(.system(size: 11))
                            .monospacedDigit()
                            .frame(width: 34, alignment: .trailing)
                    }
                }
            }
        }
    }
}

/// Physical memory in use, matching Activity Monitor's "Memory Used".
struct MemorySection: View {
    @ObservedObject var store: StatsStore

    var body: some View {
        let usage = store.memory

        PopoverSection(title: "Memory") {
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

/// Current throughput across all non-loopback interfaces.
struct NetworkSection: View {
    @ObservedObject var store: StatsStore

    var body: some View {
        let throughput = store.network

        PopoverSection(title: "Network") {
            VStack(spacing: 4) {
                StatRow(
                    label: "Download",
                    value: PopoverStyle.rate(throughput.downBytesPerSecond)
                )
                StatRow(
                    label: "Upload",
                    value: PopoverStyle.rate(throughput.upBytesPerSecond)
                )
            }

            Text("Across all active interfaces")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}
