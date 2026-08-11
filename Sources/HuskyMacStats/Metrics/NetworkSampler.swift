import Darwin
import Foundation

struct NetworkThroughput: Equatable, Sendable {
    var downBytesPerSecond: Double
    var upBytesPerSecond: Double

    static let zero = NetworkThroughput(downBytesPerSecond: 0, upBytesPerSecond: 0)
}

/// Samples interface throughput by differencing the kernel's per-interface byte counters.
///
/// Two constraints mirror `CPUSampler`:
/// - `getifaddrs` allocates the list on the heap, so every call must `freeifaddrs` it.
/// - The counters are cumulative since boot, so the first sample returns zero — a single reading
///   alone would be a lifetime average, not a rate.
final class NetworkSampler {
    private var previous: (down: UInt64, up: UInt64)?
    private var previousTime: TimeInterval?

    /// Returns bytes per second since the previous call.
    func sample() -> NetworkThroughput {
        let totals = interfaceTotals()
        let now = ProcessInfo.processInfo.systemUptime

        defer {
            previous = totals
            previousTime = now
        }

        guard let previous, let previousTime, now > previousTime else { return .zero }

        let elapsed = now - previousTime
        return NetworkThroughput(
            downBytesPerSecond: rate(totals.down, previous.down, over: elapsed),
            upBytesPerSecond: rate(totals.up, previous.up, over: elapsed)
        )
    }

    /// Counters are 32-bit on some interfaces and reset when one is torn down, so a decrease means
    /// a wrap or a reset rather than negative traffic. Report zero instead of a bogus spike.
    private func rate(_ current: UInt64, _ previous: UInt64, over elapsed: TimeInterval) -> Double {
        guard current >= previous else { return 0 }
        return Double(current - previous) / elapsed
    }

    /// Sums the link-layer byte counters across every non-loopback interface.
    private func interfaceTotals() -> (down: UInt64, up: UInt64) {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let head else { return (0, 0) }
        // The list is heap-allocated per call; skipping this leaks on every tick.
        defer { freeifaddrs(head) }

        var down: UInt64 = 0
        var up: UInt64 = 0

        for pointer in sequence(first: head, next: { $0.pointee.ifa_next }) {
            let interface = pointer.pointee

            // Only the AF_LINK entry carries `if_data`; the AF_INET/AF_INET6 aliases for the same
            // interface would otherwise double-count.
            guard interface.ifa_addr?.pointee.sa_family == UInt8(AF_LINK),
                  interface.ifa_flags & UInt32(IFF_LOOPBACK) == 0,
                  let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self)
            else { continue }

            down += UInt64(data.pointee.ifi_ibytes)
            up += UInt64(data.pointee.ifi_obytes)
        }

        return (down, up)
    }
}
