# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```sh
swift build                 # fast syntax/type check
./scripts/build-app.sh      # release build + assemble & ad-hoc sign HuskyMacStats.app
```

The plain `swift build` binary is only useful as a compile check. A menu bar app needs the
`LSUIElement` bundle, so anything you actually want to *see* requires `build-app.sh`.

Restart cycle after a change:

```sh
pkill HuskyMacStats; ./scripts/build-app.sh && open HuskyMacStats.app
```

`pkill` first — `open` on an already-running app is a no-op and you will be looking at the old build.

## Verification

There is no test target. Two things make verification unusual here:

**The metrics are testable, the UI is not.** `Metrics/` has no AppKit dependency, so compile the real
source files into a throwaway harness rather than reasoning about the math:

```sh
swiftc -O -o verify main.swift \
  Sources/HuskyMacStats/Metrics/CPUSampler.swift \
  Sources/HuskyMacStats/Metrics/DiskSampler.swift
```

The driver file must be named `main.swift` — Swift only allows top-level statements there. Load-test
CPU with `for i in 1 2 3 4; do yes > /dev/null & done`; exactly four cores should reach 1.00.

**You cannot see the menu bar.** This terminal lacks Screen Recording permission, so `screencapture`
fails with "could not create image from display". Anything visual — bar rendering, popover appearance,
menu item behaviour — must be reported as unverified and handed to the user to check. Do not claim a
layout change looks right.

Leak check for the Mach sampling loop: `ps -o rss= -p $(pgrep HuskyMacStats)` over several minutes.
RSS should sit flat around 22–28 MB.

## Architecture

`StatsStore` (`@MainActor`, `ObservableObject`) is the only clock: one 1 s `Timer`, with slower
metrics taken on a tick divisor (disk every 30th). `StatusItemController` hosts SwiftUI in the status
item via `NSHostingView` and owns the hover popover and right-click menu.

CPU sampling deliberately stays on the main actor — it is a microsecond syscall, and keeping it there
avoids making `CPUSampler`'s tick history cross-actor state. Filesystem work goes to a detached task.

### BarStyle is the layout source of truth

`UI/BarStyle.swift` holds all geometry, and the hover hit-test depends on it: `diskRange` computes
where the disk widget sits by summing the widths to its left. **Adding or resizing any widget means
updating `statusItemWidth` and the range functions together**, or hovering will open the popover over
the wrong glyph. Widths are derived from `coreCount`, never hardcoded.

### Constraints worth knowing before you "fix" something

These look like odd choices and are not:

- **`CPUSampler` must `vm_deallocate`.** `host_processor_info` maps a fresh region per call; skipping
  it leaks a page per second. The first sample returns zeros on purpose — the counters are cumulative
  since boot, so one reading alone is a lifetime average.
- **Disk capacity never reads `/`.** Under APFS the root is a sealed read-only snapshot reporting ~4%
  used regardless of the real state. Read the home directory's volume, and use
  `volumeAvailableCapacityForImportantUsage` so the number matches Finder.
- **`HoverTrackingView.hitTest` returns nil deliberately.** `NSStatusItem` has no hover callback, so
  the view exists only to own an `NSTrackingArea`; returning nil lets clicks fall through to the
  status button. Tracking areas fire regardless of hit-testing, and need `.activeAlways` because the
  app is almost never frontmost.
- **The popover is `.applicationDefined`, not `.transient`.** Transient dismissal is unreliable for a
  background agent; hover exit closes it on a 150 ms debounce instead.
- **The `Timer` runs in `.common` mode** so the widget stays live while a menu tracking loop is up.
- **Menu bar colours come from `NSColor.labelColor` / `.tertiaryLabelColor`**, which resolve against
  the menu bar's own appearance. Hardcoded SwiftUI colours break in light mode; the load ramp
  (green/amber/red) stays fixed because it carries meaning.

On this M1, kernel core order is efficiency cores at indices 0–3 and performance cores at 4–7, so the
four leftmost bars are E-cores.

Adding a metric: sampler returning a `Sendable` value type in `Metrics/`, publish from `StatsStore`,
view in `UI/`, compose into `MenuBarView`, extend `BarStyle`.

## Conventions

The global TypeScript/React rules in `~/.claude/rules/` do not apply to this repository — it is pure
Swift. Follow ordinary Swift conventions (lowerCamelCase constants, not the PascalCase rule from the
TS guide).
