# Husky Mac Stats

A native macOS menu bar app showing live machine statistics as compact vertical-bar widgets.

```
 ⌗ ▁▃█▂▅▁▇▃  ▤ ▐     🔋  12:04
 └───cpu───┘ └ssd┘
```

- **CPU** — a chip glyph and one thin bar per logical core, filling bottom-up with that core's load,
  sampled once a second. Green under 50%, amber to 80%, red above.
- **Disk** — an SSD glyph plus a fill bar for the boot volume. Hover it for total, used, and free
  space.

Runs as a background agent: no Dock icon, no window. Right-click the widget to quit.

## Build and run

```sh
./scripts/build-app.sh
open HuskyMacStats.app
```

Right-click the widget and tick **Launch at Login** to start it automatically. That registers the
bundle with `SMAppService`, so it also shows up under System Settings → General → Login Items, where
it can be turned off again.

The registration records the bundle's current path. Moving or renaming `HuskyMacStats.app` afterwards
breaks it — move the app where you want it first (`/Applications` is the natural home), then enable
the toggle. Rebuilding in place is fine, since the path doesn't change.

For a plain debug build without the bundle, `swift build` works, but the executable must run from an
`LSUIElement` bundle to stay out of the Dock.

## Design notes

**CPU.** `host_processor_info(PROCESSOR_CPU_LOAD_INFO)` returns tick counters accumulated since boot,
so instantaneous load requires differencing two samples — the first reading after launch is published
as zeros rather than a misleading lifetime average. The kernel maps a fresh region on every call, so
`CPUSampler` `vm_deallocate`s it each time; without that the process leaks a page per second.

Core order is whatever the kernel reports and is stable across samples, so bar *n* always means the
same core. On this M1 the efficiency cores occupy indices 0–3 and the performance cores 4–7.

**Disk.** Capacity is read from the volume holding the home directory, not from `/`. Under APFS the
root is a sealed read-only system snapshot and reports single-digit percent used no matter how full
the machine is. Free space uses `volumeAvailableCapacityForImportantUsage`, which counts space macOS
can reclaim from purgeable caches — the figure Finder's Get Info shows — falling back to the raw
available count if unavailable.

**Hover.** `NSStatusItem` gives no hover callback, so `HoverTrackingView` sits transparently above the
SwiftUI content owning an `NSTrackingArea` with `.activeAlways` (the app is almost never frontmost).
Its `hitTest` returns nil so clicks still reach the status button underneath; tracking areas deliver
enter/exit/moved regardless of hit-testing. The popover opens only when the pointer is within the
disk widget's x-range and closes on a 150 ms debounce so edge jitter doesn't flicker it.

## Adding a metric

1. Add a sampler under `Sources/HuskyMacStats/Metrics/` returning a `Sendable` value type.
2. Publish it from `StatsStore`, choosing a tick divisor if it needs a slower cadence than 1 s.
3. Add a view under `UI/`, compose it into `MenuBarView`, and extend `BarStyle.statusItemWidth` so
   the status item reserves room for it.
