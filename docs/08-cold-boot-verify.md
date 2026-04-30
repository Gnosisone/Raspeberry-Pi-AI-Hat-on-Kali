# 08 — Cold boot and verify

You've built the driver, blacklisted the zombie, placed the firmware, installed the library. Now you have to bring the device up — and there's exactly one right way to do it.

## Persist the module load

So the driver loads automatically on every future boot:

```bash
echo "hailo1x_pci" | sudo tee /etc/modules-load.d/hailo.conf
```

This file is read by `systemd-modules-load.service` very early in boot, before any userspace process tries to talk to the device.

## The cold boot

Now the critical part. **Do not run `sudo reboot`.** Run:

```bash
sudo poweroff
```

Then **wait at least 30 seconds with the power physically off**. Then power the Pi back on.

## Why poweroff and not reboot?

The Hailo-10H supports PCIe power management states D0 (operating), D3hot (idle, link up), and **D3cold** (idle, link down, requires re-init).

If during your install attempts the kernel module loaded and then failed (say, because of a version mismatch or the zombie driver fight), the chip can wedge in D3cold. From D3cold, the chip cannot be woken back up by the OS — it requires a full PCIe link re-training, which only happens when the entire bus is power-cycled.

`reboot` keeps the PCIe bus powered (it's a CPU-level reset, not a power-rail reset). `poweroff` actually drops the 3.3V and 5V rails to the HAT, which gives the Hailo PMIC time to reset.

The 30-second wait matters: PCIe rails take a few seconds to fully discharge through the bypass capacitors on the HAT. Cutting it short occasionally leaves the chip in a half-power state where it appears in `lspci` but won't accept firmware.

Symptom of skipping the cold boot: dmesg shows `D3cold to D0 transition failed` or `Failed reading device BARs, device may be disconnected`.

## After the cold boot

Once the Pi is back up, run:

```bash
hailortcli fw-control identify
```

You should see something like:

```
Executing on device: 0001:01:00.0
Identifying board
Control Protocol Version: 2
Firmware Version: 5.1.1 (release,app)
Logger Version: 0
Board Name: Hailo-10
Device Architecture: HAILO10H
Serial Number: <serial>
Part Number: <part>
Product Name: HAILO10H AI ACC M.2 MODULE
```

That's the complete win condition. The chip is alive, the firmware is loaded, and the userspace library is talking to it.

## Full verification script

For a more thorough check that all layers are healthy:

```bash
sudo bash scripts/verify.sh
```

This runs through:

- Module loaded? (`hailo1x_pci`)
- Zombie not loaded? (`hailo_pci`)
- PCIe device visible? (`lspci` shows `1e60:45c4`)
- Device node present? (`/dev/hailo0`)
- Firmware files in place?
- `hailortcli fw-control identify` succeeds?

All checks should pass.

## What's next

The Hailo-10H is now usable as a generic NPU. Real workloads usually want one of:

- **HailoRT Python bindings** — `pip install hailort` for direct Python inference
- **Hailo Model Zoo** — pre-compiled `.hef` files for object detection, classification, etc.
- **hailo-ollama** — runs Ollama LLMs with NPU acceleration (the path used by ERR0RS)
- **GenAI Model Zoo** — `wget https://dev-public.hailo.ai/2025_12/Hailo10/hailo_gen_ai_model_zoo_5.1.1_arm64.deb` and install for LLM-specific compiled models

Those are out of scope for this repo — this guide stops at "device operational." From here, the rest is just normal Hailo userspace development.

## You're done

Four days of debugging compressed into one repo. Use it. Ship it.
