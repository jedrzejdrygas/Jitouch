#!/bin/bash

set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$repo_dir/build"
deployment_target="${MACOSX_DEPLOYMENT_TARGET:-12.0}"
clean_build=true

usage() {
    echo "Usage: $0 [--no-clean]"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-clean) clean_build=false ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Jitouch can only be built on macOS." >&2
    exit 1
fi

if ! xcodebuild -version >/dev/null 2>&1; then
    echo "Full Xcode is required and must be selected with xcode-select." >&2
    exit 1
fi

if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
    echo "Complete Xcode first-launch setup and accept its license before building." >&2
    exit 1
fi

if ! xcrun --find ibtool >/dev/null 2>&1; then
    echo "Interface Builder tools are unavailable in the selected Xcode." >&2
    exit 1
fi

gesture_source="$repo_dir/jitouch/Jitouch/Gesture.m"
firefox_dispatch_count="$(grep -Fc 'if (![application isEqualToString:@"Safari"])' "$gesture_source" || true)"
if [[ "$firefox_dispatch_count" -lt 2 ]]; then
    echo "Firefox horizontal-swipe support is missing; refusing to build." >&2
    exit 1
fi

if "$clean_build"; then
    rm -rf "$build_dir"
fi
mkdir -p "$build_dir"

echo "Building Jitouch.app (Release, macOS $deployment_target+)..."
xcodebuild \
    -quiet \
    -project "$repo_dir/jitouch/Jitouch/Jitouch.xcodeproj" \
    -target Jitouch \
    -configuration Release \
    SYMROOT="$build_dir/app" \
    MACOSX_DEPLOYMENT_TARGET="$deployment_target" \
    CODE_SIGNING_ALLOWED=NO \
    build

app_product="$build_dir/app/Release/Jitouch.app"
if [[ ! -d "$app_product" ]]; then
    echo "Build did not produce $app_product" >&2
    exit 1
fi

rm -rf "$repo_dir/prefpane/Jitouch.app"
ditto "$app_product" "$repo_dir/prefpane/Jitouch.app"

echo "Building Jitouch.prefPane (Release, macOS $deployment_target+)..."
xcodebuild \
    -quiet \
    -project "$repo_dir/prefpane/Jitouch.xcodeproj" \
    -target Jitouch \
    -configuration Release \
    SYMROOT="$build_dir/prefpane" \
    MACOSX_DEPLOYMENT_TARGET="$deployment_target" \
    CODE_SIGNING_ALLOWED=NO \
    build

prefpane_product="$build_dir/prefpane/Release/Jitouch.prefPane"
if [[ ! -d "$prefpane_product" ]]; then
    echo "Build did not produce $prefpane_product" >&2
    exit 1
fi

entitlements_file="$repo_dir/jitouch/Jitouch/Jitouch.entitlements"
codesign --force --sign - --entitlements "$entitlements_file" "$app_product"
codesign --force --sign - --entitlements "$entitlements_file" \
    "$prefpane_product/Contents/Resources/Jitouch.app"
codesign --force --sign - "$prefpane_product"
codesign --verify --deep --strict --verbose=2 "$app_product"
codesign --verify --deep --strict --verbose=2 "$prefpane_product"

echo "Build complete:"
echo "  $app_product"
echo "  $prefpane_product"
