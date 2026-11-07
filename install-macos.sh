#!/usr/bin/env bash
# install-macos.sh — install resolve-sync on macOS (client only)

set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"
BIN_DIR="${PREFIX}/bin"
SHARE_DIR="${PREFIX}/share/resolve-sync"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This installer is for macOS. On Linux use the .deb package." >&2
  exit 1
fi

echo "Installing resolve-sync to ${PREFIX}"

# Need write access to PREFIX
if [[ ! -w "$PREFIX" ]]; then
  echo "No write access to $PREFIX. Re-run with sudo or set PREFIX to a user directory." >&2
  exit 1
fi

mkdir -p "$BIN_DIR" "$SHARE_DIR"

# Script
install -m 755 resolve-sync "$BIN_DIR/resolve-sync"

# Bank template
rm -rf "$SHARE_DIR/bank"
cp -a bank "$SHARE_DIR/bank"

echo "Installed:"
echo "  $BIN_DIR/resolve-sync"
echo "  $SHARE_DIR/bank/"
echo
echo "Make sure $BIN_DIR is on your PATH."
echo "Then run: resolve-sync setup"
