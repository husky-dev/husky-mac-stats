import Combine
import Foundation

/// Live machine statistics, republished on every tick.
@MainActor
final class StatsStore: ObservableObject {
    @Published private(set) var cpuLoads: [Double]
    @Published private(set) var disk: DiskUsage = .unknown

    let coreCount: Int

    private let cpu = CPUSampler()
    private var timer: Timer?
    private var tick = 0

    private static let cpuInterval: TimeInterval = 1
    private static let diskTickInterval = 30

    init() {
        coreCount = cpu.coreCount
        cpuLoads = Array(repeating: 0, count: cpu.coreCount)
    }

    func start() {
        guard timer == nil else { return }

        refreshDisk()

        let timer = Timer(timeInterval: Self.cpuInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickNow() }
        }
        // `.common` keeps the widget live while a menu or popover holds a tracking run loop.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tickNow() {
        // Reading the Mach counters is a microsecond-scale syscall, so it stays on the main actor —
        // that keeps the sampler's tick history free of cross-actor state.
        cpuLoads = cpu.sample()

        tick += 1
        if tick % Self.diskTickInterval == 0 {
            refreshDisk()
        }
    }

    /// Capacity lookups touch the filesystem, so they run off the main actor.
    private func refreshDisk() {
        Task.detached(priority: .utility) {
            let usage = DiskSampler.sample()
            await MainActor.run { [weak self] in
                self?.disk = usage
            }
        }
    }
}
