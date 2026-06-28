#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Ace Link Podman"
DERIVED_DATA="${DERIVED_DATA:-/tmp/acelink-podman-derived}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILT_APP="${DERIVED_DATA}/Build/Products/Debug/${APP_NAME}.app"
DEST_APP="${HOME}/Desktop/${APP_NAME}.app"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_podman_if_missing() {
    if command_exists podman; then
        return
    fi

    if ! command_exists brew; then
        echo "Podman is not installed and Homebrew was not found."
        echo "Install Homebrew or Podman, then run this script again."
        exit 1
    fi

    echo "Podman is not installed. Installing with Homebrew..."
    brew install podman
}

ensure_podman_running() {
    if podman info >/dev/null 2>&1; then
        return
    fi

    if podman machine list >/dev/null 2>&1; then
        if ! podman machine list --format '{{.Name}}' 2>/dev/null | grep -q .; then
            echo "Creating the default Podman machine..."
            podman machine init
        fi

        echo "Starting the Podman machine..."
        podman machine start || true
    fi

    if ! podman info >/dev/null 2>&1; then
        echo "Podman is installed but is not running."
        echo "Try running: podman machine start"
        exit 1
    fi
}

ensure_xcodebuild() {
    if command_exists xcodebuild; then
        return
    fi

    echo "xcodebuild was not found."
    echo "Install Xcode or the Xcode command line tools, then run this script again."
    exit 1
}

copy_app_to_desktop() {
    if [ ! -d "${BUILT_APP}" ]; then
        echo "Build completed, but ${BUILT_APP} was not found."
        exit 1
    fi

    rm -rf "${DEST_APP}"
    cp -R "${BUILT_APP}" "${DEST_APP}"
}

install_podman_if_missing
ensure_podman_running
ensure_xcodebuild

cd "${ROOT_DIR}"

echo "Building the Ace Stream Podman image..."
make podman

echo "Building ${APP_NAME}.app..."
xcodebuild -scheme 'Ace Link' -configuration Debug -derivedDataPath "${DERIVED_DATA}" build

echo "Copying ${APP_NAME}.app to your Desktop..."
copy_app_to_desktop

echo "Installed ${DEST_APP}"
