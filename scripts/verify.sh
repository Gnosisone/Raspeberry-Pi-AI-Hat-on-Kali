#!/usr/bin/env bash
#
# verify.sh — Confirm Hailo-10H is fully operational
#
# Run AFTER the cold boot. Checks every layer of the stack.
#

set -uo pipefail

GRN=$'\033[0;32m'
RED=$'\033[0;31m'
YLW=$'\033[1;33m'
RST=$'\033[0m'

pass=0
fail=0

check() {
  local label="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo -e "${GRN}✓${RST} $label"
    pass=$((pass+1))
  else
    echo -e "${RED}✗${RST} $label"
    fail=$((fail+1))
  fi
}

echo
echo "═══ Hailo-10H Verification ═══"
echo

# 1. Module loaded?
check "hailo1x_pci kernel module loaded" "lsmod | grep -q '^hailo1x_pci '"

# 2. Zombie driver NOT loaded?
if lsmod | grep -q "^hailo_pci "; then
  echo -e "${RED}✗${RST} Zombie hailo_pci driver IS loaded — blacklist failed!"
  fail=$((fail+1))
else
  echo -e "${GRN}✓${RST} Zombie hailo_pci driver NOT loaded"
  pass=$((pass+1))
fi

# 3. PCIe device visible?
check "Hailo-10H visible on PCIe (vendor 1e60, device 45c4)" \
      "lspci -nn | grep -qi '1e60:45c4'"

# 4. Device node exists?
check "/dev/hailo0 device node exists" "[[ -e /dev/hailo0 ]]"

# 5. Firmware files in place?
check "u-boot.dtb.signed firmware present" \
      "[[ -f /lib/firmware/hailo/hailo10h/u-boot.dtb.signed ]]"
check "u-boot-tfa.itb firmware present" \
      "[[ -f /lib/firmware/hailo/hailo10h/u-boot-tfa.itb ]]"

# 6. hailortcli installed?
check "hailortcli binary installed" "command -v hailortcli"

# 7. The big one — full identify
echo
echo "── hailortcli fw-control identify ──"
if hailortcli fw-control identify 2>&1; then
  pass=$((pass+1))
  echo -e "${GRN}✓${RST} Firmware identify succeeded"
else
  fail=$((fail+1))
  echo -e "${RED}✗${RST} Firmware identify failed"
fi

# 8. dmesg sanity
echo
echo "── Recent hailo dmesg lines ──"
dmesg | grep -i hailo | tail -10

# Summary
echo
echo "═══ Summary ═══"
echo -e "  ${GRN}Pass:${RST} $pass"
echo -e "  ${RED}Fail:${RST} $fail"
echo

if [[ $fail -eq 0 ]]; then
  echo -e "${GRN}All checks passed. Hailo-10H is fully operational.${RST}"
  exit 0
else
  echo -e "${YLW}Some checks failed. See troubleshooting/ for fixes.${RST}"
  exit 1
fi
