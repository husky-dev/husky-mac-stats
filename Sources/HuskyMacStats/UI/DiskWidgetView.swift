import SwiftUI

/// SSD glyph plus a vertical bar whose fill is the fraction of the volume in use.
struct DiskWidgetView: View {
    let usage: DiskUsage

    var body: some View {
        HStack(spacing: BarStyle.iconGap) {
            Image(systemName: "internaldrive")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(BarStyle.glyphColor)
                .frame(width: BarStyle.iconWidth)

            LoadBar(fraction: usage.fractionUsed)
        }
        .frame(width: BarStyle.diskWidth, height: BarStyle.barHeight)
    }
}
