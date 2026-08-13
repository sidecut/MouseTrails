#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="MouseTrails"
SOURCE_APP="${APP_NAME}.app"
INSTALL_DIR="/Applications"
INSTALLED_APP="${INSTALL_DIR}/${APP_NAME}.app"
BINARY_PATH="${INSTALLED_APP}/Contents/MacOS/${APP_NAME}"

echo "Building ${APP_NAME}..."
./build_app.sh

if pgrep -f "${BINARY_PATH}" >/dev/null 2>&1; then
    echo "Quitting the running installed copy..."
    osascript -e "tell application \"${APP_NAME}\" to quit" >/dev/null 2>&1 || true
    sleep 1
    pkill -f "${BINARY_PATH}" 2>/dev/null || true
fi

echo "Installing to ${INSTALLED_APP}..."
rm -rf "${INSTALLED_APP}"
if [ -w "${INSTALL_DIR}" ]; then
    cp -R "${SOURCE_APP}" "${INSTALL_DIR}/"
else
    echo "${INSTALL_DIR} isn't writable, retrying with sudo..."
    sudo cp -R "${SOURCE_APP}" "${INSTALL_DIR}/"
fi

echo "Launching ${INSTALLED_APP}..."
open "${INSTALLED_APP}"

cat <<EOF

Installed ${APP_NAME} to ${INSTALLED_APP}.

If "Launch at Login" was enabled from a previous location (e.g. this
project directory), it's now pointing at a stale path. Toggle it off
and back on from the menu bar icon so macOS registers the new
/Applications copy.
EOF
