import SwiftUI

/// Transfer glyph plus two bars: download on the left, upload on the right.
struct NetworkWidgetView: View {
    let throughput: NetworkThroughput
    let coreCount: Int

    /// Full-scale rate for the bars, ~12 MB/s — roughly a saturated 100 Mbit link.
    private static let referenceBytesPerSecond: Double = 12_000_000

    var body: some View {
        HStack(spacing: BarStyle.iconGap) {
            Image(systemName: Widget.network.symbolName)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(BarStyle.glyphColor)
                .frame(width: BarStyle.iconWidth)

            HStack(alignment: .bottom, spacing: BarStyle.barSpacing) {
                LoadBar(fraction: Self.fraction(throughput.downBytesPerSecond))
                LoadBar(fraction: Self.fraction(throughput.upBytesPerSecond))
            }
        }
        .frame(
            width: BarStyle.width(of: .network, coreCount: coreCount),
            height: BarStyle.barHeight
        )
    }

    /// Logarithmic, because throughput spans several orders of magnitude: on a linear scale the
    /// everyday few-hundred-KB/s of traffic would sit invisibly close to zero.
    static func fraction(_ bytesPerSecond: Double) -> Double {
        guard bytesPerSecond > 0 else { return 0 }

        let scaled = log10(1 + bytesPerSecond) / log10(1 + referenceBytesPerSecond)
        return min(max(scaled, 0), 1)
    }
}
