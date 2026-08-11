import SwiftUI

/// A "MEM" label stacked over the share of physical memory in use.
struct MemoryWidgetView: View {
    let usage: MemoryUsage
    let coreCount: Int

    var body: some View {
        VStack(spacing: 0) {
            Text("MEM")
                .font(.system(size: 8, weight: .semibold))

            Text("\(Int((usage.fractionUsed * 100).rounded()))%")
                .font(.system(size: 9))
                .monospacedDigit()
        }
        .foregroundStyle(BarStyle.glyphColor)
        .frame(
            width: BarStyle.width(of: .memory, coreCount: coreCount),
            height: BarStyle.statusHeight
        )
    }
}
