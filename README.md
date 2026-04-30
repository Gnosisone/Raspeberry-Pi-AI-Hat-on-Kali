# Hailo-10H AI HAT+ on Kali Linux ARM64

> Getting the Raspberry Pi AI HAT+ (Hailo-10H NPU, 26 TOPS) running on Kali Linux ARM64 — the hard way, documented end-to-end.

The Raspberry Pi AI HAT+ ships with first-class support for Raspberry Pi OS. On Kali Linux ARM64, it is **completely unsupported** — and worse, Kali ships its own ancient `hailo_pci` driver (v4.20.0) that actively fights the modern one. This repo documents the exact, working steps to bring up the Hailo-10H NPU on a Pi 5 running Kali Linux, including every dead end I hit along the way.

If you are running offensive security tooling on a Pi 5 and want NPU-accelerated local inference (LLMs, on-device CV, ML-assisted recon) without giving up Kali, this is the guide.

## What you'll end up with

- HailoRT 5.1.1 driver, library, and firmware all matched and stable
- `hailo1x_pci` kernel module loaded at boot, zombie `hailo_pci` blacklisted
- Hailo-10H detected on PCIe Gen 3, firmware loaded, `/dev/hailo0` present
- `hailortcli fw-control identify` returning a clean device readout
- A reproducible install script you can run on a fresh Kali ARM64 image

## Why this is hard

Three problems compound on Kali ARM64:

1. **Kali ships an ancient zombie driver.** The `hailo_pci` v4.20.0 module lives at `/lib/modules/<kernel>/kernel/drivers/media/pci/hailo/hailo_pci.ko.xz` and auto-loads alongside any newer driver, causing PCIe BAR read failures.
2. **Driver, library, and firmware versions must match exactly.** The Raspberry Pi apt archive (which has the only available userspace library) only ships HailoRT **5.1.1**. The Hailo GitHub master branch builds **5.2.0** drivers. A 5.2.0 driver against a 5.1.1 library throws `Driver version is different from library version` and refuses to start.
3. **Kali rejects the Raspberry Pi archive's signing key.** The RPi archive uses SHA1, which Kali's apt considers insecure by default. You need `trusted=yes` and `--allow-unauthenticated`.

Plus the usual hardware foot-guns: backwards FFC ribbon cable, PCIe not enabled in `config.txt`, and the Hailo-10H wedging in PCIe D3cold power state after a failed driver load (only a true cold poweroff fixes that — `reboot` won't).

## Hardware tested

| Component | Notes |
|---|---|
| Raspberry Pi 5 (8GB) | Required — PCIe Gen 3 x1 is the data path |
| Raspberry Pi AI HAT+ (Hailo-10H, 26 TOPS) | Also marketed as "AI HAT+ 2" |
| FFC ribbon cable | **Check orientation** — HAT side and Pi side are mirrored |
| Active cooler | The HAT runs warm under load |
| Official 27W USB-C PSU | Underpowering causes PCIe link drops |
| NVMe boot | Strongly recommended over MicroSD |

## OS tested

- **Kali Linux 2026.1 ARM64** (rolling, kernel 6.12.x)
- Should also apply to **Kali 2025.3+** with minor adjustments

## Quick start

If you trust the recipe and just want it working:

```bash
git clone https://github.com/Gnosisone/hailo-kali-setup.git
cd hailo-kali-setup
chmod +x scripts/install.sh
sudo ./scripts/install.sh
sudo poweroff
# wait 30 seconds with power OFF, then power back on
hailortcli fw-control identify
```

You should see:

```
Device Architecture: HAILO10H
Firmware Version: 5.1.1 (release,app)
```

If you don't, see [troubleshooting/](troubleshooting/).

## The long version

If you want to understand what's happening (recommended — this is finicky):

1. [`docs/01-prerequisites.md`](docs/01-prerequisites.md) — Hardware checks, FFC cable orientation, PSU
2. [`docs/02-pcie-config.md`](docs/02-pcie-config.md) — `/boot/firmware/config.txt` PCIe Gen 3 overlay
3. [`docs/03-blacklist-zombie-driver.md`](docs/03-blacklist-zombie-driver.md) — Killing the Kali-shipped 4.20.0 driver permanently
4. [`docs/04-rpi-apt-source.md`](docs/04-rpi-apt-source.md) — Adding the Raspberry Pi archive with `trusted=yes`
5. [`docs/05-build-driver.md`](docs/05-build-driver.md) — Building `hailo1x_pci` from the v5.1.1 branch
6. [`docs/06-firmware-install.md`](docs/06-firmware-install.md) — Firmware placement and the u-boot rename gotcha
7. [`docs/07-userspace-library.md`](docs/07-userspace-library.md) — Installing `h10-hailort`
8. [`docs/08-cold-boot-verify.md`](docs/08-cold-boot-verify.md) — Why `poweroff` not `reboot`, and the verification step

## Troubleshooting

The bugs I hit, with fixes:

- [`troubleshooting/zombie-driver.md`](troubleshooting/zombie-driver.md) — `hailo_pci` v4.20.0 keeps loading alongside `hailo1x_pci`
- [`troubleshooting/version-mismatch.md`](troubleshooting/version-mismatch.md) — Driver version is different from library version
- [`troubleshooting/d3cold-pcie.md`](troubleshooting/d3cold-pcie.md) — `Failed reading device BARs, device may be disconnected`
- [`troubleshooting/pcie-not-detected.md`](troubleshooting/pcie-not-detected.md) — `lspci` shows nothing (FFC cable, config.txt)
- [`troubleshooting/sha1-signature.md`](troubleshooting/sha1-signature.md) — Kali rejects the Raspberry Pi archive

## Why this repo exists

I'm building [ERR0RS-clean](https://github.com/Gnosisone/ERR0RS-clean), a local AI-powered penetration testing platform that runs natively on Kali. The Hailo-10H gives me NPU-accelerated local inference for the agent's reasoning loop without sending data off-device. Getting it working on Kali instead of Raspberry Pi OS took four days. This repo is so the next person doesn't have to repeat them.

## Contributing

If you hit a different failure mode and figured it out, open a PR adding a file under `troubleshooting/`. Format your fix as: symptom → diagnosis → fix → verification.

## License

MIT. Use it, fork it, ship it.

## Credits

- Hailo for the hardware and HailoRT
- The Kali ARM team
- Everyone on the Hailo Community forum who posted dmesg logs at 2am
