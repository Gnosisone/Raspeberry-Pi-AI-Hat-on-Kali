# Troubleshooting — D3cold PCIe power state

## Symptom

`dmesg` shows:

```
hailo1x_pci: Failed reading device BARs, device may be disconnected
hailo1x_pci: D3cold to D0 transition failed
```

`/dev/hailo0` doesn't appear, even though `lspci` shows the device. `hailortcli fw-control identify` fails with `Device not found` or hangs.

## Diagnosis

The Hailo-10H supports PCIe power management states D0 (operating), D3hot (idle but link up), and **D3cold** (idle, link down).

Once the chip is in D3cold, it cannot be woken up by software alone — the PCIe link must be re-trained from a power-off condition. A normal `reboot` keeps the PCIe rails powered, so D3cold persists across reboots.

This typically happens after:

- A version-mismatched driver tried to load and failed
- The zombie `hailo_pci` v4.20.0 conflicted with `hailo1x_pci`
- A firmware load attempt timed out
- A previous run of this install left the chip in a bad state

## Fix

Full power cycle:

```bash
sudo poweroff
```

Then **physically wait at least 30 seconds with the power off**. Unplug the USB-C if you're paranoid — the goal is to fully discharge the bypass capacitors on the HAT.

Then power back on. The PCIe link will re-train from cold, the chip will come up in D0, and the driver should load cleanly.

## Why `sudo reboot` doesn't fix this

`reboot` is a CPU-level reset. It re-runs the boot ROM, restarts the kernel, and re-initializes drivers — but it **does not power-cycle the PCIe rails**. From the HAT's perspective, the Pi just rebooted while the HAT stayed powered. So the chip stays in whatever state it was in.

`poweroff` actually drops the rails. That's the difference.

## Verification

After the cold boot:

```bash
sudo dmesg | grep -i hailo | head -20
```

You should see clean initialization:

```
hailo1x_pci: Probing: Added board 1e60-45c4, /dev/hailo0
hailo1x_pci: SOC Firmware Batch loaded successfully
hailo1x_pci: Firmware loaded in 5510 ms
```

No `D3cold`, no `Failed reading device BARs`.

## Avoiding it next time

Don't `modprobe hailo1x_pci` manually until everything is in place — the firmware files, the blacklist, the userspace library. The original install hit D3cold three separate times because the module got loaded prematurely during debugging.

The clean sequence is: build driver → place firmware → install library → persist module load → cold boot. Don't manually load the module before that final cold boot.

## See also

- [`docs/08-cold-boot-verify.md`](../docs/08-cold-boot-verify.md)
