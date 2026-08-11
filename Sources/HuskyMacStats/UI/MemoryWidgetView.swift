import SwiftUI

/// Memory glyph plus a vertical bar whose fill is the fraction of physical memory in use.
struct MemoryWidgetView: View {
    let usage: MemoryUsage
    let coreCount: Int

    var body: some View {
        HStack(spacing: BarStyle.iconGap) {
            Image(systemName: Widget.memory.symbolName)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(BarStyle.glyphColor)
                .frame(width: BarStyle.iconWidth)

            LoadBar(fraction: usage.fractionUsed)
        }
        .frame(
            width: BarStyle.width(of: .memory, coreCount: coreCount),
            height: BarStyle.barHeight
        )
    }
}
