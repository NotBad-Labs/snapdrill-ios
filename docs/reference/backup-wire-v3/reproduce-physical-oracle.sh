#!/bin/sh

set -eu

if [ "$#" -ne 2 ]; then
    echo "usage: $0 SIMULATOR_UDID ABSOLUTE_OUTPUT_PATH" >&2
    exit 2
fi

case "$2" in
    /*) ;;
    *)
        echo "output path must be absolute" >&2
        exit 2
        ;;
esac

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
build_root="${TMPDIR:-/tmp}/snapdrill-v3-physical-oracle"
initializer="$build_root/iossim-init"
output=$2

mkdir -p "$build_root"
xcrun --sdk iphonesimulator clang \
    -target arm64-apple-ios26.0-simulator \
    "$root/iossim-init.c" \
    -lsqlite3 \
    -o "$initializer"

xcrun simctl spawn "$1" "$initializer" "$output"
(
    cd "$root"
    sqlite3 -batch -bail "$output" < schema.sql
    sqlite3 -batch -bail "$output" < full-fixture.sql
)

if ! cmp -s "$output" "$root/iOS-26.5-full-v3.sqlite"; then
    echo "FAIL physical oracle bytes differ from retained fixture" >&2
    shasum -a 256 "$output" "$root/iOS-26.5-full-v3.sqlite" >&2
    exit 1
fi

echo "PASS physical oracle byte identity"
shasum -a 256 "$output"
