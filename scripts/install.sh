#!/usr/bin/env bash
#
# install.sh — Hailo-10H AI HAT+ on Kali Linux ARM64
#
# Sequence:
#   1. Pre-flight checks (Pi 5, ARM64, root)
#   2. Enable PCIe Gen 3 in /boot/firmware/config.txt
#   3. Blacklist the Kali-shipped zombie hailo_pci v4.20.0 driver
#   4. Add Raspberry Pi apt source with trusted=yes
#   5. Clone hailort-drivers at v5.1.1 branch and build
#   6. Download and install matching firmware
#   7. Install h10-hailort userspace library
#   8. Auto-load module at boot
#   9. Prompt for COLD power cycle (not reboot — PCIe needs cold reset)
#
# Reference: github.com/Gnosisone/hailo-kali-setup
#

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED=$'\033[0;31m'
GRN=$'\033[0;32m'
YLW=$'\033[1;33m'
BLU=$'\033[0;34m'
RST=$'\033[0m'

step()  { echo -e "${BLU}▶${RST} $*"; }
ok()    { echo -e "${GRN}✓${RST} $*"; }
warn()  { echo -e "${YLW}⚠${RST} $*"; }
fail()  { echo -e "${RED}✗${RST} $*" >&2; exit 1; }

# ── 1. Pre-flight ─────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || fail "Run with sudo."

step "Pre-flight checks"

[[ "$(uname -m)" == "aarch64" ]] || fail "ARM64 (aarch64) required. Got: $(uname -m)"
ok "Architecture: aarch64"

if grep -qi "raspberry pi 5" /proc/cpuinfo /proc/device-tree/model 2>/dev/null; then
  ok "Hardware: Raspberry Pi 5"
else
  warn "Could not confirm Pi 5 — proceeding anyway"
fi

if [[ ! -f /boot/firmware/config.txt ]]; then
  fail "/boot/firmware/config.txt not found — is this Kali on a Pi?"
fi
ok "Found /boot/firmware/config.txt"

# ── 2. Enable PCIe Gen 3 ──────────────────────────────────────────────────────
step "Enabling PCIe Gen 3 in /boot/firmware/config.txt"

if ! grep -q "^dtparam=pciex1$" /boot/firmware/config.txt; then
  echo "dtparam=pciex1" >> /boot/firmware/config.txt
  ok "Added dtparam=pciex1"
else
  ok "dtparam=pciex1 already set"
fi

if ! grep -q "^dtparam=pciex1_gen=3$" /boot/firmware/config.txt; then
  echo "dtparam=pciex1_gen=3" >> /boot/firmware/config.txt
  ok "Added dtparam=pciex1_gen=3"
else
  ok "dtparam=pciex1_gen=3 already set"
fi

# ── 3. Blacklist zombie driver ────────────────────────────────────────────────
step "Blacklisting Kali-shipped hailo_pci v4.20.0 (zombie driver)"

mkdir -p /etc/modprobe.d
cat > /etc/modprobe.d/hailo-blacklist.conf <<'EOF'
# Block Kali's ancient hailo_pci v4.20.0 from loading.
# We use the modern hailo1x_pci built from source instead.
blacklist hailo_pci
EOF
ok "Wrote /etc/modprobe.d/hailo-blacklist.conf"

# Unload it now if it's currently loaded
if lsmod | grep -q "^hailo_pci "; then
  modprobe -r hailo_pci 2>/dev/null || true
  ok "Unloaded currently-running hailo_pci"
fi

# ── 4. Raspberry Pi apt source ────────────────────────────────────────────────
step "Adding Raspberry Pi apt source (trusted=yes for SHA1 signature)"

if [[ ! -f /usr/share/keyrings/raspberrypi-archive-keyring.gpg ]]; then
  curl -fsSL https://archive.raspberrypi.com/debian/raspberrypi.gpg.key | \
    gpg --dearmor -o /usr/share/keyrings/raspberrypi-archive-keyring.gpg
  ok "Imported Raspberry Pi GPG key"
else
  ok "Raspberry Pi GPG key already present"
fi

cat > /etc/apt/sources.list.d/raspberrypi.list <<'EOF'
deb [arch=arm64 trusted=yes] http://archive.raspberrypi.com/debian trixie main
EOF
ok "Wrote /etc/apt/sources.list.d/raspberrypi.list"

apt update
ok "apt sources refreshed"

# ── 5. Build kernel driver from v5.1.1 branch ─────────────────────────────────
step "Building hailo1x_pci kernel driver from v5.1.1 branch"

# Install build deps
apt install -y --allow-unauthenticated \
  git build-essential dkms linux-headers-$(uname -r) || \
  warn "Header package may not exactly match — continuing"

DRIVER_DIR="${SUDO_USER:+/home/$SUDO_USER}/hailort-51"
DRIVER_DIR="${DRIVER_DIR:-/root/hailort-51}"

if [[ -d "$DRIVER_DIR" ]]; then
  warn "$DRIVER_DIR exists — removing for clean build"
  rm -rf "$DRIVER_DIR"
fi

git clone --branch v5.1.1 https://github.com/hailo-ai/hailort-drivers.git "$DRIVER_DIR"
ok "Cloned hailort-drivers @ v5.1.1"

cd "$DRIVER_DIR/linux/pcie"
make all
make install
depmod -a
ok "Built and installed hailo1x_pci"

# ── 6. Firmware ───────────────────────────────────────────────────────────────
step "Downloading and installing matched firmware (5.1.1)"

cd "$DRIVER_DIR"
./download_firmware_hailo10h.sh
ok "Firmware downloaded"

mkdir -p /lib/firmware/hailo/hailo10h
cp "$DRIVER_DIR"/hailo10h_fw_5.1.1/* /lib/firmware/hailo/hailo10h/
ok "Firmware copied to /lib/firmware/hailo/hailo10h/"

# Required renames — boot won't find firmware without these exact names
cd /lib/firmware/hailo/hailo10h
install -m 644 u-boot-default.dtb.signed u-boot.dtb.signed
install -m 644 fitImage u-boot-tfa.itb
ok "u-boot.dtb.signed and u-boot-tfa.itb in place"

# ── 7. Userspace library ──────────────────────────────────────────────────────
step "Installing h10-hailort userspace library (5.1.1)"

apt install -y --allow-unauthenticated h10-hailort
ok "h10-hailort installed"

# ── 8. Persist module load at boot ────────────────────────────────────────────
step "Configuring hailo1x_pci to load at boot"

mkdir -p /etc/modules-load.d
echo "hailo1x_pci" > /etc/modules-load.d/hailo.conf
ok "Wrote /etc/modules-load.d/hailo.conf"

# ── 9. Done — instruct cold boot ──────────────────────────────────────────────
echo
echo "════════════════════════════════════════════════════════════════"
echo " Install complete. NOW DO THIS:"
echo "════════════════════════════════════════════════════════════════"
echo
echo "  1. Run:  sudo poweroff"
echo "  2. WAIT 30 SECONDS with power physically OFF"
echo "  3. Power the Pi back on"
echo "  4. Run:  hailortcli fw-control identify"
echo
echo " You should see: Device Architecture: HAILO10H"
echo "                 Firmware Version: 5.1.1 (release,app)"
echo
echo " ⚠  DO NOT use 'sudo reboot' — PCIe must cold-reset to clear"
echo "    any prior D3cold power state. Only a real poweroff works."
echo
echo "════════════════════════════════════════════════════════════════"
