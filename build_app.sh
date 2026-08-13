#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="MouseTrails"
BUILD_CONFIG="release"

echo "Building ${APP_NAME} (${BUILD_CONFIG})..."
swift build -c "${BUILD_CONFIG}"

BIN_PATH="$(swift build -c "${BUILD_CONFIG}" --show-bin-path)/${APP_NAME}"
APP_BUNDLE="${APP_NAME}.app"

echo "Assembling ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BIN_PATH}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

echo "Done: ${APP_BUNDLE}"
