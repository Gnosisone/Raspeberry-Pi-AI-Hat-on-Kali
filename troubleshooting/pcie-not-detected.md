# Troubleshooting — PCIe device not detected (lspci empty)

## Symptom

```bash
$ lspci
# (no output, or no hailo entry)

$ lspci -nn | grep 1e60
# (empty)
```

The kernel doesn't see the Hailo-10H on PCIe at all. From software's perspective, the HAT might as well not be plugged in.

## Diagnosis

Three possibilities, in order of likelihood:

1. **FFC ribbon cable is backwards.** This is the #1 cause. The cable's metal contacts must face **down** on the HAT side and **up** on the Pi 5 side — they are mirrored.
2. **PCIe is not enabled in `/boot/firmware/config.txt`.** Pi 5 ships with the external PCIe lane disabled by default.
3. **PSU is undersized.** The Pi 5 + AI HAT+ + active cooler can pull more than a generic 5V/3A supply provides. PCIe link drops out under load and `lspci` flickers.

## Fix — FFC cable

```bash
sudo poweroff
```

Disconnect the power. Open both FFC connectors (pull the latches out gently). Look at the cable contacts — only one side has metal traces. On the **HAT** side, contacts face **down toward the PCB**. On the **Pi 5** side, contacts face **up away from the PCB**.

Reseat firmly, push both latches back in until they click. Power on.

## Fix — config.txt

```bash
sudo nano /boot/firmware/config.txt
```

Add at the bottom:

```
dtparam=pciex1
dtparam=pciex1_gen=3
```

Save (`Ctrl+X` → `Y` → `Enter`). Reboot.

## Fix — PSU

If you're using a generic USB-C PSU, swap to the **official Raspberry Pi 27W USB-C PSU**. Symptoms of an undersized PSU include:

- `lspci` sometimes shows the device, sometimes doesn't
- Random PCIe link errors in dmesg
- The Pi 5 throttling lightning bolt icon
- The HAT's status LED flickering

## Verification

After fixing whichever cause applied:

```bash
lspci -nn | grep -i hailo
# Should show: 0001:01:00.0 ... [1e60:45c4]

dmesg | grep -i pci | grep -i link
# Should show: PCI/LINK: link up @ 8 GT/s
```

`8 GT/s` confirms PCIe Gen 3. If you see `5 GT/s` (Gen 2), the `dtparam=pciex1_gen=3` line wasn't saved or didn't take effect — re-check `config.txt` and reboot again.

## What `lspci` should look like fully working

```
0000:00:00.0 PCI bridge: Broadcom Inc. and subsidiaries Device 2712 (rev 21)
0000:01:00.0 Ethernet controller: Raspberry Pi Ltd RP1 PCIe 2.0 South Bridge
0001:00:00.0 PCI bridge: Broadcom Inc. and subsidiaries Device 2712 (rev 21)
0001:01:00.0 Co-processor: Hailo Technologies Ltd. Hailo-10 AI Processor [1e60:45c4]
```

The last line is the one you need.

## See also

- [`docs/01-prerequisites.md`](../docs/01-prerequisites.md)
- [`docs/02-pcie-config.md`](../docs/02-pcie-config.md)
