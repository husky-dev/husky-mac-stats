import SwiftUI

/// Shared geometry and colour ramp so the CPU and disk widgets read as one system.
enum BarStyle {
    static let barWidth: CGFloat = 3
    static let barSpacing: CGFloat = 2
    static let barHeight: CGFloat = 14
    static let cornerRadius: CGFloat = 1.5

    /// Gap between the CPU widget and the disk widget.
    static let groupSpacing: CGFloat = 7
    static let iconWidth: CGFloat = 13
    /// Gap between a widget's glyph and its bars.
    static let iconGap: CGFloat = 3
    static let statusHeight: CGFloat = 22
    static let horizontalPadding: CGFloat = 5

    /// Width of the disk widget: glyph, a small gap, and its fill bar.
    static let diskWidth: CGFloat = iconWidth + iconGap + barWidth

    static func cpuClusterWidth(coreCount: Int) -> CGFloat {
        guard coreCount > 0 else { return 0 }
        return CGFloat(coreCount) * barWidth + CGFloat(coreCount - 1) * barSpacing
    }

    /// Width of the CPU widget: chip glyph, a small gap, and one bar per core.
    static func cpuWidth(coreCount: Int) -> CGFloat {
        iconWidth + iconGap + cpuClusterWidth(coreCount: coreCount)
    }

    static func statusItemWidth(coreCount: Int) -> CGFloat {
        horizontalPadding * 2 + cpuWidth(coreCount: coreCount) + groupSpacing + diskWidth
    }

    /// X range the disk widget occupies inside the status item, used for hover hit-testing.
    static func diskRange(coreCount: Int) -> ClosedRange<CGFloat> {
        let start = horizontalPadding + cpuWidth(coreCount: coreCount) + groupSpacing
        return start...(start + diskWidth)
    }

    /// Green below half, amber approaching full, red when saturated.
    static func loadColor(_ fraction: Double) -> Color {
        switch fraction {
        case ..<0.5: Color(red: 0.31, green: 0.78, blue: 0.47)
        case ..<0.8: Color(red: 0.95, green: 0.72, blue: 0.24)
        default: Color(red: 0.94, green: 0.36, blue: 0.33)
        }
    }

    /// Unfilled portion of a bar. Semantic so it inverts with the menu bar's appearance.
    static var trackColor: Color { Color(nsColor: .tertiaryLabelColor) }

    /// Glyph tint, matching neighbouring menu bar items.
    static var glyphColor: Color { Color(nsColor: .labelColor) }
}
