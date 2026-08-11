import SwiftUI

/// Shared geometry and colour ramp so every widget reads as one system.
enum BarStyle {
    static let barWidth: CGFloat = 3
    static let barSpacing: CGFloat = 2
    static let barHeight: CGFloat = 14
    static let cornerRadius: CGFloat = 1.5

    /// Gap between adjacent widgets.
    static let groupSpacing: CGFloat = 7
    static let iconWidth: CGFloat = 13
    /// Gap between a widget's glyph and its bars.
    static let iconGap: CGFloat = 3
    static let statusHeight: CGFloat = 22
    static let horizontalPadding: CGFloat = 5

    /// Width of `count` bars laid out side by side.
    static func clusterWidth(bars count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        return CGFloat(count) * barWidth + CGFloat(count - 1) * barSpacing
    }

    /// Every widget's width lives here, so the status item's total width and the hover hit-test
    /// ranges are derived from one definition and cannot drift apart.
    static func width(of widget: Widget, coreCount: Int) -> CGFloat {
        let bars = switch widget {
        case .cpu: coreCount          // one bar per logical core
        case .memory, .disk: 1        // a single fill bar
        case .network: 2              // down and up
        }
        return iconWidth + iconGap + clusterWidth(bars: bars)
    }

    static func statusItemWidth(_ widgets: [Widget], coreCount: Int) -> CGFloat {
        guard !widgets.isEmpty else { return horizontalPadding * 2 }

        let content = widgets.reduce(0) { $0 + width(of: $1, coreCount: coreCount) }
        let gaps = CGFloat(widgets.count - 1) * groupSpacing
        return horizontalPadding * 2 + content + gaps
    }

    /// X range `widget` occupies inside the status item, or nil when it isn't shown.
    static func range(
        of widget: Widget,
        in widgets: [Widget],
        coreCount: Int
    ) -> ClosedRange<CGFloat>? {
        var start = horizontalPadding

        for candidate in widgets {
            let end = start + width(of: candidate, coreCount: coreCount)
            if candidate == widget { return start...end }
            start = end + groupSpacing
        }

        return nil
    }

    /// Hover hit-test: which widget sits under `x`, if any. Points in the gaps between widgets and
    /// in the outer padding belong to no widget.
    static func widget(at x: CGFloat, in widgets: [Widget], coreCount: Int) -> Widget? {
        widgets.first { range(of: $0, in: widgets, coreCount: coreCount)?.contains(x) == true }
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
