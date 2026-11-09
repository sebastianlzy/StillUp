#!/bin/sh
set -eu
cd "$(dirname "$0")"

app="StillUp.app"
module_cache=$(mktemp -d "${TMPDIR:-/tmp}/stillup.XXXXXX")
trap 'rm -rf "$module_cache"' EXIT

mkdir -p "$app/Contents/MacOS"
swiftc -O -target "$(uname -m)-apple-macos13.0" -module-cache-path "$module_cache" \
    StillUp.swift -o "$app/Contents/MacOS/StillUp"
cp Info.plist "$app/Contents/Info.plist"
xattr -dr com.apple.FinderInfo "$app" 2>/dev/null || true
codesign --force --sign - "$app"
