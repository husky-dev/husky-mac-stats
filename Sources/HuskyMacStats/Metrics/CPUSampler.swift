import Darwin
import Foundation

/// Samples per-core CPU load from the Mach host by differencing tick counters.
///
/// `host_processor_info` reports cumulative ticks since boot, so a single reading only tells us the
/// lifetime average. Instantaneous load requires the delta between two consecutive samples.
final class CPUSampler {
    /// Number of logical cores, fixed for the lifetime of the process.
    let coreCount: Int

    /// Flat `coreCount * CPU_STATE_MAX` array of ticks from the previous sample.
    private var previousTicks: [natural_t] = []

    /// Last published loads, reused when a core reports no elapsed ticks.
    private var lastLoads: [Double]

    init() {
        var count: natural_t = 0
        var size = MemoryLayout<natural_t>.size
        if sysctlbyname("hw.logicalcpu", &count, &size, nil, 0) != 0 || count == 0 {
            count = natural_t(ProcessInfo.processInfo.activeProcessorCount)
        }
        coreCount = Int(count)
        lastLoads = Array(repeating: 0, count: Int(count))
    }

    /// Returns per-core load in `0...1`. The first call after launch returns zeros, since there is
    /// no earlier sample to difference against.
    func sample() -> [Double] {
        guard let ticks = readTicks() else { return lastLoads }

        defer { previousTicks = ticks }
        guard previousTicks.count == ticks.count else { return lastLoads }

        let states = Int(CPU_STATE_MAX)
        var loads = lastLoads

        for core in 0..<min(coreCount, ticks.count / states) {
            let base = core * states
            let user = delta(ticks, previousTicks, base + Int(CPU_STATE_USER))
            let system = delta(ticks, previousTicks, base + Int(CPU_STATE_SYSTEM))
            let nice = delta(ticks, previousTicks, base + Int(CPU_STATE_NICE))
            let idle = delta(ticks, previousTicks, base + Int(CPU_STATE_IDLE))

            let busy = user + system + nice
            let total = busy + idle
            // A parked core can report no elapsed ticks; holding the prior value beats dividing by zero.
            guard total > 0 else { continue }

            loads[core] = min(max(busy / total, 0), 1)
        }

        lastLoads = loads
        return loads
    }

    private func delta(_ current: [natural_t], _ previous: [natural_t], _ index: Int) -> Double {
        // Counters are monotonic, but guard the subtraction anyway — natural_t is unsigned and an
        // underflow would trap.
        let now = current[index]
        let before = previous[index]
        return now >= before ? Double(now - before) : 0
    }

    private func readTicks() -> [natural_t]? {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &cpuCount,
            &info,
            &infoCount
        )
        guard result == KERN_SUCCESS, let info else { return nil }

        // The kernel hands back a freshly mapped region on every call. Without this the process
        // leaks a page per sample.
        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(UInt(bitPattern: info)),
                vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.size)
            )
        }

        return info.withMemoryRebound(to: natural_t.self, capacity: Int(infoCount)) { pointer in
            Array(UnsafeBufferPointer(start: pointer, count: Int(infoCount)))
        }
    }
}
