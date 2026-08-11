#!/bin/bash
# Builds HuskyMacStats.app — an LSUIElement bundle, ad-hoc signed so it launches locally.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

app="$root/HuskyMacStats.app"

swift build -c release

rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/HuskyMacStats" "$app/Contents/MacOS/HuskyMacStats"
cp "$root/Resources/Info.plist" "$app/Contents/Info.plist"

codesign --force --sign - "$app"

echo "Built $app"
