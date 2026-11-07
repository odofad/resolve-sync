#!/usr/bin/env bash
# install.sh — install resolve-sync
# On Ubuntu: adds the PPA and installs the deb.
# Otherwise: installs the script and bank template to /usr/local.

set -euo pipefail

if [[ -f /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
fi

if [[ "${ID:-}" == "ubuntu" ]]; then
  echo "Ubuntu detected. Adding PPA and installing package..."
  sudo add-apt-repository -y ppa:odofad/stable
  sudo apt update
  sudo apt install -y resolve-sync
  echo "Installed via apt."
  exit 0
fi

# Non-Ubuntu (macOS or other Linux)
PREFIX="${PREFIX:-/usr/local}"
BIN_DIR="${PREFIX}/bin"
SHARE_DIR="${PREFIX}/share/resolve-sync"

echo "Installing resolve-sync to ${PREFIX}"

if [[ ! -w "$PREFIX" ]]; then
  echo "No write access to $PREFIX. Re-run with sudo or set PREFIX to a user directory." >&2
  exit 1
fi

mkdir -p "$BIN_DIR" "$SHARE_DIR"

# Locate the script and bank (works when run from the extracted zip)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install -m 755 "$SCRIPT_DIR/resolve-sync" "$BIN_DIR/resolve-sync"
rm -rf "$SHARE_DIR/bank"
cp -a "$SCRIPT_DIR/bank" "$SHARE_DIR/bank"

echo "Installed:"
echo "  $BIN_DIR/resolve-sync"
echo "  $SHARE_DIR/bank/"
echo
echo "Make sure $BIN_DIR is on your PATH."
echo "Then run: resolve-sync setup"
