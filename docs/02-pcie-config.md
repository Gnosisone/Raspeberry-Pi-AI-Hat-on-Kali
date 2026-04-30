# 02 — Enable PCIe Gen 3 in config.txt

The Pi 5's PCIe lane is **disabled by default** and runs at **Gen 2** even when enabled. The Hailo-10H needs both: the lane on, and Gen 3 speed for full throughput.

## What to add

Edit `/boot/firmware/config.txt`:

```bash
sudo nano /boot/firmware/config.txt
```

Scroll to the bottom and add:

```
dtparam=pciex1
dtparam=pciex1_gen=3
```

Save with `Ctrl+X` → `Y` → `Enter`.

## What these do

| Line | Effect |
|---|---|
| `dtparam=pciex1` | Enables the external PCIe x1 lane on the Pi 5. Without this, the AI HAT+ is electrically connected but the kernel never sees a PCIe device. `lspci` will return empty. |
| `dtparam=pciex1_gen=3` | Forces PCIe Gen 3. The Pi 5 firmware defaults to Gen 2 because Gen 3 is technically out of spec for the connector. In practice it works reliably for the Hailo-10H and gives 2x the bandwidth, which matters for inference workloads. |

## Verification

After adding these lines you need to **reboot** for them to take effect (a normal reboot is fine here — the cold-boot requirement only matters later, after a failed driver load):

```bash
sudo reboot
```

After reboot, confirm the lane is up:

```bash
sudo dmesg | grep -i "pci.*link"
```

You should see something like `PCI/LINK: link up @ 8 GT/s`. The 8 GT/s is the Gen 3 indicator (Gen 2 is 5 GT/s). If you see 5 GT/s, the `gen=3` line didn't take — double-check spelling.

If you see no PCIe link messages at all, either the cable orientation is wrong (see [01-prerequisites.md](01-prerequisites.md)) or the lines weren't saved correctly. Run `tail /boot/firmware/config.txt` to confirm they're at the end of the file.

## Why not enable PCIe Gen 3 globally for the whole boot?

You can — there's a `dtparam=pciex1_gen=3` in some Pi tutorials added to the `[all]` section. The version above is identical for our purposes; the parameter applies to the external x1 lane regardless of section.

→ Next: [`03-blacklist-zombie-driver.md`](03-blacklist-zombie-driver.md)
