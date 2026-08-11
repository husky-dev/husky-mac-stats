import Darwin
import Foundation

struct MemoryUsage: Equatable, Sendable {
    var totalBytes: Int64
    var usedBytes: Int64

    var freeBytes: Int64 { max(totalBytes - usedBytes, 0) }

    var fractionUsed: Double {
        guard totalBytes > 0 else { return 0 }
        return min(max(Double(usedBytes) / Double(totalBytes), 0), 1)
    }

    static let unknown = MemoryUsage(totalBytes: 0, usedBytes: 0)
}

/// Reads physical memory usage from the Mach VM statistics.
///
/// "Used" is active + wired + compressed pages, which is what Activity Monitor calls Memory Used.
/// Inactive pages are deliberately excluded: they hold evictable file-backed data and counting them
/// would show the machine as permanently near full.
///
/// Unlike `host_processor_info`, `host_statistics64` fills a caller-owned struct, so there is no
/// mapped region to `vm_deallocate` here.
enum MemorySampler {
    private static let totalBytes = Int64(ProcessInfo.processInfo.physicalMemory)

    /// Asked of the kernel rather than read from `vm_kernel_page_size`: that global is a mutable
    /// `var` as far as Swift 6 is concerned, so touching it is a concurrency error.
    private static let pageSize: Int64 = {
        var size: vm_size_t = 0
        guard host_page_size(mach_host_self(), &size) == KERN_SUCCESS else { return 16384 }
        return Int64(size)
    }()

    static func sample() -> MemoryUsage {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return .unknown }

        let usedPages = Int64(stats.active_count)
            + Int64(stats.wire_count)
            + Int64(stats.compressor_page_count)

        return MemoryUsage(
            totalBytes: totalBytes,
            usedBytes: min(usedPages * pageSize, totalBytes)  // clamped: page counts race the total
        )
    }
}
