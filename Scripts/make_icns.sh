#!/bin/bash
# Generates Resources/AppIcon.icns from Scripts/generate_app_icon.swift.
# Requires only tools that ship with macOS and Xcode: swift, sips, iconutil.
set -euo pipefail

cd "$(dirname "$0")/.."

TMPDIR=$(mktemp -d)
MASTER="$TMPDIR/master.png"
ICONSET="$TMPDIR/AppIcon.iconset"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Rendering icon master (1024×1024)…"
swift Scripts/generate_app_icon.swift "$MASTER"

echo "Building iconset…"
mkdir -p "$ICONSET"

for s in 16 32 128 256 512; do
    sips -z $s $s             "$MASTER" --out "$ICONSET/icon_${s}x${s}.png"       > /dev/null
    sips -z $((s*2)) $((s*2)) "$MASTER" --out "$ICONSET/icon_${s}x${s}@2x.png"   > /dev/null
done

iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
echo "Created Resources/AppIcon.icns"
