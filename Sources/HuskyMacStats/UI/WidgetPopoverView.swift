import SwiftUI

/// Routes a hovered widget to its own hover panel.
struct WidgetPopoverView: View {
    let widget: Widget
    @ObservedObject var store: StatsStore

    var body: some View {
        switch widget {
        case .cpu: CPUPopoverView(store: store)
        case .memory: MemoryPopoverView(store: store)
        case .network: NetworkPopoverView(store: store)
        case .disk: DiskPopoverView(store: store)
        }
    }
}

/// Per-core load, plus the average across all cores.
struct CPUPopoverView: View {
    @ObservedObject var store: StatsStore

    var body: some View {
        let loads = store.cpuLoads
        let average = loads.isEmpty ? 0 : loads.reduce(0, +) / Double(loads.count)

        PopoverFrame(title: "CPU") {
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
struct MemoryPopoverView: View {
    @ObservedObject var store: StatsStore

    var body: some View {
        let usage = store.memory

        PopoverFrame(title: "Memory") {
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
struct NetworkPopoverView: View {
    @ObservedObject var store: StatsStore

    var body: some View {
        let throughput = store.network

        PopoverFrame(title: "Network") {
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
