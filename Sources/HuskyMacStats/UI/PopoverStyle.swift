import SwiftUI

/// Shared building blocks for the hover popovers, so the disk, memory, CPU and network panels stay
/// visually identical rather than drifting apart as each grows its own copy.
/// `@MainActor` because `ByteCountFormatter` is not `Sendable`; the popovers are all main-actor
/// views, so pinning the shared formatters there is free.
@MainActor
enum PopoverStyle {
    /// Every popover is this wide; the status item's own width varies, but the panels shouldn't.
    static let width: CGFloat = 220
    static let padding: CGFloat = 14

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        // `.file` matches Finder's decimal-GB convention, so the numbers agree with Get Info.
        formatter.countStyle = .file
        formatter.allowedUnits = [.useGB, .useTB]
        return formatter
    }()

    private static let rateFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        // Rates span idle to saturated, so let the formatter pick the unit per reading.
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.zeroPadsFractionDigits = true
        return formatter
    }()

    static func bytes(_ count: Int64) -> String {
        byteFormatter.string(fromByteCount: count)
    }

    static func rate(_ bytesPerSecond: Double) -> String {
        "\(rateFormatter.string(fromByteCount: Int64(bytesPerSecond.rounded())))/s"
    }

    static func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }
}

/// Title on the left, monospaced value on the right.
struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
        .font(.system(size: 12))
    }
}

/// Horizontal capacity bar using the same load ramp as the menu bar widgets.
struct CapacityBar: View {
    let fraction: Double
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(BarStyle.trackColor.opacity(0.3))
                Capsule()
                    .fill(BarStyle.loadColor(fraction))
                    .frame(width: geometry.size.width * fraction)
            }
        }
        .frame(height: height)
    }
}

/// Shared chrome: heading, then whatever the individual popover puts below it.
struct PopoverFrame<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))

            content
        }
        .padding(PopoverStyle.padding)
        .frame(width: PopoverStyle.width)
    }
}
