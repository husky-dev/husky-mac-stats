import Combine
import Foundation
// For `Array.move(fromOffsets:toOffset:)`. Worth the import rather than reimplementing it: the
// offsets come straight from SwiftUI's `.onMove`, whose semantics this must match exactly.
import SwiftUI

/// Which widgets the status item shows, and in what order. Persisted to `UserDefaults`.
///
/// `order` holds *every* widget including the disabled ones, so turning one off and back on returns
/// it to the same slot rather than to the end of the row.
@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var order: [Widget]
    @Published private(set) var enabled: Set<Widget>

    /// The status item's composition, left to right.
    var visible: [Widget] { order.filter(enabled.contains) }

    private let defaults: UserDefaults

    private enum Key {
        static let order = "widgetOrder"
        static let enabled = "enabledWidgets"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedOrder = defaults.stringArray(forKey: Key.order)
        order = Self.decodeOrder(storedOrder)
        enabled = Self.decodeEnabled(
            defaults.stringArray(forKey: Key.enabled),
            knownAtLastWrite: storedOrder
        )
    }

    // MARK: - Mutation

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        order.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    /// Ignores an attempt to disable the last enabled widget: a zero-width status item cannot be
    /// right-clicked, which would leave no way back into Settings.
    func setEnabled(_ isEnabled: Bool, for widget: Widget) {
        guard isEnabled || canDisable(widget) else { return }

        if isEnabled {
            enabled.insert(widget)
        } else {
            enabled.remove(widget)
        }
        persist()
    }

    /// False when `widget` is the only one left on, so the UI can show its toggle as disabled
    /// instead of appearing to ignore the click.
    func canDisable(_ widget: Widget) -> Bool {
        !(enabled.count == 1 && enabled.contains(widget))
    }

    private func persist() {
        defaults.set(order.map(\.rawValue), forKey: Key.order)
        defaults.set(enabled.map(\.rawValue), forKey: Key.enabled)
    }

    // MARK: - Decoding

    /// Drops raw values that no longer name a widget and appends any widget missing from the stored
    /// order, so adding a case later neither crashes nor discards the user's arrangement.
    private static func decodeOrder(_ raw: [String]?) -> [Widget] {
        guard let raw else { return Widget.allCases }

        var result = raw.compactMap(Widget.init(rawValue:))
        result.append(contentsOf: Widget.allCases.filter { !result.contains($0) })
        return result
    }

    /// A widget added in a later version is on by default, but one the user switched off must stay
    /// off. The two are only distinguishable via the stored *order*, which lists every widget that
    /// existed when the preferences were last written — the enabled set alone cannot tell "new" from
    /// "deliberately disabled".
    private static func decodeEnabled(
        _ raw: [String]?,
        knownAtLastWrite: [String]?
    ) -> Set<Widget> {
        guard let raw, let knownAtLastWrite else { return Set(Widget.allCases) }

        let stored = Set(raw.compactMap(Widget.init(rawValue:)))
        let known = Set(knownAtLastWrite)
        let addedSinceLastWrite = Widget.allCases.filter { !known.contains($0.rawValue) }

        let result = stored.union(addedSinceLastWrite)
        // Every widget disabled would strand the user with an unclickable status item.
        return result.isEmpty ? Set(Widget.allCases) : result
    }
}
