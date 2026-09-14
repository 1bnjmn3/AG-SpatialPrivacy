#!/bin/bash
set -e

APP_NAME="AG-SpatialPrivacy"
BUNDLE_DIR="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "🔨 Building ${APP_NAME} in Release mode..."
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/${APP_NAME}"

echo "📦 Assembling ${BUNDLE_DIR}..."
rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy binary
cp "${BIN_PATH}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Copy Info.plist
cp Resources/Info.plist "${CONTENTS_DIR}/Info.plist"

# Copy AppIcon if available
if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns "${RESOURCES_DIR}/AppIcon.icns"
fi

# Code sign (ad-hoc)
echo "🔐 Ad-hoc code signing..."
codesign --force --deep --sign - "${BUNDLE_DIR}"

echo "✅ Successfully built ${BUNDLE_DIR}!"
echo "To run the app:"
echo "  open ${BUNDLE_DIR}"
