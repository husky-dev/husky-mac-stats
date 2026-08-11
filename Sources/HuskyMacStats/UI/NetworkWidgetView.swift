import SwiftUI

/// Two stacked rates: upload on top, download below, each trailed by its own arrow.
struct NetworkWidgetView: View {
    let throughput: NetworkThroughput
    let coreCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            row(symbol: "arrow.up", rate: throughput.upBytesPerSecond)
            row(symbol: "arrow.down", rate: throughput.downBytesPerSecond)
        }
        .frame(
            width: BarStyle.width(of: .network, coreCount: coreCount),
            height: BarStyle.statusHeight
        )
    }

    private func row(symbol: String, rate bytesPerSecond: Double) -> some View {
        HStack(spacing: BarStyle.iconGap) {
            Text(Self.rate(bytesPerSecond))
                .font(.system(size: 9))
                .monospacedDigit()
                .frame(width: BarStyle.networkRateWidth, alignment: .trailing)

            Image(systemName: symbol)
                .font(.system(size: 8, weight: .semibold))
                .frame(width: BarStyle.networkArrowWidth)
        }
        .foregroundStyle(BarStyle.glyphColor)
    }

    /// Menu bar rates need a fixed shape: `ByteCountFormatter` prints "Zero KB" when idle and varies
    /// its digit count, which would make the rows jitter inside a fixed-width status item. Decimal
    /// units, matching the `.file` count style the popover uses, so the two agree.
    static func rate(_ bytesPerSecond: Double) -> String {
        switch bytesPerSecond {
        case ..<1_000:
            "0 KB/s"
        case ..<1_000_000:
            "\(Int((bytesPerSecond / 1_000).rounded())) KB/s"
        case ..<10_000_000:
            String(format: "%.1f MB/s", bytesPerSecond / 1_000_000)
        case ..<1_000_000_000:
            "\(Int((bytesPerSecond / 1_000_000).rounded())) MB/s"
        default:
            String(format: "%.1f GB/s", bytesPerSecond / 1_000_000_000)
        }
    }
}
