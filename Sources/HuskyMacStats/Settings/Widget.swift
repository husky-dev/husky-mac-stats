import Foundation

/// The set of widgets the status item can show, in their first-run order.
///
/// This is the single place a new widget registers itself: add a case here and a width in
/// `BarStyle.width(of:coreCount:)`, and the settings list, layout and hover hit-testing all pick it
/// up. Raw values are persisted, so renaming a case changes what stored preferences resolve to.
enum Widget: String, CaseIterable, Identifiable, Sendable {
    case cpu
    case memory
    case network
    case disk

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cpu: "CPU"
        case .memory: "Memory"
        case .network: "Network"
        case .disk: "Disk"
        }
    }

    var symbolName: String {
        switch self {
        case .cpu: "cpu"
        case .memory: "memorychip"
        case .network: "arrow.up.arrow.down"
        case .disk: "internaldrive"
        }
    }

    /// One-line explanation shown under the title in Settings.
    var summary: String {
        switch self {
        case .cpu: "One bar per logical core"
        case .memory: "Share of physical memory in use"
        case .network: "Upload and download speed"
        case .disk: "Space used on the home volume"
        }
    }
}
