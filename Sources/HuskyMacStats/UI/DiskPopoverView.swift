import SwiftUI

/// Hover content for the disk widget: capacity bar plus total / used / free.
struct DiskPopoverView: View {
    @ObservedObject var store: StatsStore

    private static let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        // `.file` matches Finder's decimal-GB convention, so the numbers agree with Get Info.
        formatter.countStyle = .file
        formatter.allowedUnits = [.useGB, .useTB]
        return formatter
    }()

    var body: some View {
        let usage = store.disk

        VStack(alignment: .leading, spacing: 10) {
            Text(usage.volumeName)
                .font(.system(size: 13, weight: .semibold))

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(BarStyle.trackColor.opacity(0.3))
                    Capsule()
                        .fill(BarStyle.loadColor(usage.fractionUsed))
                        .frame(width: geometry.size.width * usage.fractionUsed)
                }
            }
            .frame(height: 6)

            VStack(spacing: 4) {
                row("Total", usage.totalBytes)
                row("Used", usage.usedBytes)
                row("Free", usage.freeBytes)
            }

            Text("\(Int((usage.fractionUsed * 100).rounded()))% used")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 220)
    }

    private func row(_ label: String, _ bytes: Int64) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(Self.formatter.string(fromByteCount: bytes))
                .monospacedDigit()
        }
        .font(.system(size: 12))
    }
}
