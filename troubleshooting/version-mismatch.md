# Troubleshooting — Driver/library version mismatch

## Symptom

```
$ hailortcli fw-control identify
[HailoRT] [error] Driver version (5.2.0) is different from library version (5.1.1)
[HailoRT] [error] CHECK failed - status=HAILO_DRIVER_FAIL(36)
```

Or any combination of mismatched version numbers — the specifics vary based on what you accidentally installed.

## Diagnosis

The Hailo stack has three independent version-carrying components:

| Component | Source | Version it expects |
|---|---|---|
| Kernel driver (`hailo1x_pci`) | Built from `hailort-drivers` git repo | Whatever branch you cloned |
| Userspace library (`libhailort`) | `h10-hailort` apt package | Whatever's in the RPi archive |
| Firmware blob | `download_firmware_hailo10h.sh` | Whatever the script defaults to |

All three must be the **same version**. Today, the only way to make that work on Kali is to align everything at **5.1.1** because that's the version the Raspberry Pi apt archive ships.

If you cloned `hailort-drivers` without specifying a branch, you got `master`, which currently builds 5.2.0. That's the most common cause of this error.

## Fix

Rebuild the driver from the `v5.1.1` branch:

```bash
# Remove the wrong-version driver
cd ~/hailort-drivers/linux/pcie 2>/dev/null && sudo make uninstall || true
sudo find /lib/modules -name "hailo1x*" -delete

# Clone the right version
cd ~
rm -rf hailort-51
git clone --branch v5.1.1 https://github.com/hailo-ai/hailort-drivers.git hailort-51

# Build
cd hailort-51/linux/pcie
make clean
make all
sudo make install
sudo depmod -a

# Re-download matching firmware
cd ~/hailort-51
sudo ./download_firmware_hailo10h.sh
sudo cp hailo10h_fw_5.1.1/* /lib/firmware/hailo/hailo10h/
cd /lib/firmware/hailo/hailo10h
sudo install -m 644 u-boot-default.dtb.signed u-boot.dtb.signed
sudo install -m 644 fitImage u-boot-tfa.itb

# Cold boot
sudo poweroff
# wait 30s, power back on

hailortcli fw-control identify
```

## Verification

All three commands should report `5.1.1`:

```bash
# Library version
hailortcli --version

# Driver version (from dmesg after module loads)
sudo dmesg | grep "hailo.*driver version"

# Firmware version (after device comes up)
hailortcli fw-control identify | grep "Firmware Version"
```

## Why not just upgrade the library to 5.2.0?

You can't on Kali — the Raspberry Pi archive doesn't ship 5.2.0. Hailo distributes it via their developer portal which requires a registered developer account, and the deb packages there are versioned for specific Debian releases that don't line up with Kali rolling. 5.1.1 from the public RPi archive is the path of least resistance.

## See also

- [`docs/05-build-driver.md`](../docs/05-build-driver.md)
- [`docs/07-userspace-library.md`](../docs/07-userspace-library.md)
