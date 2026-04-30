# 01 — Prerequisites

Before you touch any software, confirm your hardware is right. Most failures in this guide trace back to a backwards FFC cable or an underpowered PSU.

## Required hardware

| Item | Why it matters |
|---|---|
| Raspberry Pi 5 (8GB) | Pi 5 is the only model with the PCIe Gen 3 lane the Hailo-10H needs. The Hailo will not work on a Pi 4. 8GB is recommended for running an LLM alongside ERR0RS or similar workloads. |
| Raspberry Pi AI HAT+ (Hailo-10H, 26 TOPS) | Sometimes labeled "AI HAT+ 2". The 13 TOPS variant uses Hailo-8L, which uses different drivers — this guide is for **Hailo-10H** specifically. |
| FFC ribbon cable | Ships with the HAT. Connects the HAT's PCIe FFC connector to the Pi 5's PCIe header. |
| Active cooler | The HAT runs hot. Without active cooling the Pi will throttle and the HAT may PCIe-link-drop under load. |
| Official 27W USB-C PSU | Cheap PSUs cause intermittent PCIe link drops that look like driver bugs. |
| NVMe storage (recommended) | An NVMe SSD via Geekworm X1004 or similar dramatically improves boot time and LLM model loading. MicroSD works but is slow. |

## FFC cable orientation — read this twice

The FFC cable has metal contacts only on **one side**. The orientation is **mirrored** between the HAT and the Pi:

- **HAT side:** contacts face **down** (toward the PCB)
- **Pi 5 side:** contacts face **up** (away from the PCB)

If you put it in the same orientation on both ends, the link will not come up and `lspci` will show nothing. This burned multiple hours in the original install. **Pull both connector latches out, seat the cable, push the latches back in firmly.**

If, after running the full install, `lspci -nn | grep 1e60` shows nothing, the cable is the most likely cause. Power off and reseat both ends.

## Software prerequisites

| Item | Notes |
|---|---|
| Kali Linux ARM64, freshly imaged | A fresh image avoids cruft from prior driver experiments. The original install only succeeded after a clean Kali re-image. |
| Internet connection | The install pulls from GitHub and the Raspberry Pi apt archive. |
| Time and patience | The first build takes ~5 minutes; the firmware download ~2 minutes; first boot probing ~5 seconds. |

## Sanity checks before you start

```bash
# Are you on a Pi 5?
cat /proc/device-tree/model
# Expected: Raspberry Pi 5 Model B Rev 1.0 (or similar)

# Are you on ARM64?
uname -m
# Expected: aarch64

# Is the AI HAT+ physically connected and powered?
# (You won't see it in lspci yet — that's the next step.)
ls /boot/firmware/config.txt
# Expected: file exists
```

If any of those fail, fix that before continuing. There is no point installing drivers for a device the Pi can't see.

→ Next: [`02-pcie-config.md`](02-pcie-config.md)
