import Foundation

struct DiskUsage: Equatable, Sendable {
    var volumeName: String
    var totalBytes: Int64
    var freeBytes: Int64

    var usedBytes: Int64 { max(totalBytes - freeBytes, 0) }

    var fractionUsed: Double {
        guard totalBytes > 0 else { return 0 }
        return min(max(Double(usedBytes) / Double(totalBytes), 0), 1)
    }

    static let unknown = DiskUsage(volumeName: "Disk", totalBytes: 0, freeBytes: 0)
}

/// Reads capacity for the volume holding the user's home directory.
///
/// Deliberately not `/`: under APFS the root is a sealed, read-only system snapshot and reports a
/// few percent used regardless of how full the machine actually is.
enum DiskSampler {
    private static let url = URL(fileURLWithPath: NSHomeDirectory())

    static func sample() -> DiskUsage {
        let keys: Set<URLResourceKey> = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
        ]

        guard let values = try? url.resourceValues(forKeys: keys),
              let total = values.volumeTotalCapacity
        else {
            return .unknown
        }

        // `forImportantUsage` counts space macOS can reclaim from purgeable caches, which is the
        // figure Finder shows. Fall back to the raw free count if it is unavailable.
        let free = values.volumeAvailableCapacityForImportantUsage
            ?? Int64(values.volumeAvailableCapacity ?? 0)

        return DiskUsage(
            volumeName: values.volumeName ?? "Disk",
            totalBytes: Int64(total),
            freeBytes: free
        )
    }
}
