import SwiftUI

/// Chip glyph plus one thin vertical bar per logical core, filling bottom-up with that core's load.
struct CPUBarsView: View {
    let loads: [Double]

    var body: some View {
        HStack(spacing: BarStyle.iconGap) {
            Image(systemName: "cpu")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(BarStyle.glyphColor)
                .frame(width: BarStyle.iconWidth)

            HStack(alignment: .bottom, spacing: BarStyle.barSpacing) {
                ForEach(Array(loads.enumerated()), id: \.offset) { _, load in
                    LoadBar(fraction: load)
                }
            }
        }
        .frame(
            width: BarStyle.cpuWidth(coreCount: loads.count),
            height: BarStyle.barHeight
        )
    }
}

/// A single bottom-anchored bar: a dim track with a coloured fill on top.
struct LoadBar: View {
    let fraction: Double

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: BarStyle.cornerRadius, style: .continuous)
                .fill(BarStyle.trackColor.opacity(0.35))

            RoundedRectangle(cornerRadius: BarStyle.cornerRadius, style: .continuous)
                .fill(BarStyle.loadColor(fraction))
                // A minimum sliver keeps an idle core visible as a baseline rather than blank.
                .frame(height: max(BarStyle.barHeight * fraction, 1.5))
        }
        .frame(width: BarStyle.barWidth, height: BarStyle.barHeight)
        // Slightly under the 1 s sample interval, so each step glides into the next.
        .animation(.linear(duration: 0.9), value: fraction)
    }
}
