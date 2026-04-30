# Troubleshooting — Zombie hailo_pci driver

## Symptom

`lsmod | grep hailo` shows two drivers loaded:

```
hailo1x_pci    147456  0   ← your good driver
hailo_pci      131072  0   ← THE ZOMBIE
```

Or `dmesg` shows:

```
hailo: Init module. driver version 4.20.0
```

You did not install 4.20.0. You did not build 4.20.0. But there it is.

## Diagnosis

Kali ships its own ancient `hailo_pci` v4.20.0 driver as part of the kernel package. It lives at:

```
/lib/modules/$(uname -r)/kernel/drivers/media/pci/hailo/hailo_pci.ko.xz
```

When the kernel sees a Hailo PCIe device on boot, it loads **whatever Hailo driver it finds first** — and the Kali-shipped one is in `drivers/media/pci`, while your built-from-source one is in `drivers/misc`. The kernel doesn't know which is correct.

Both load simultaneously. They fight for control of the device. The Hailo-10H ends up in a broken state where `/dev/hailo0` either doesn't appear or returns `Failed reading device BARs`.

## Fix

Permanent blacklist:

```bash
sudo mkdir -p /etc/modprobe.d
echo "blacklist hailo_pci" | sudo tee /etc/modprobe.d/hailo-blacklist.conf
sudo depmod -a
```

Unload it from the running kernel:

```bash
sudo modprobe -r hailo_pci
```

If that fails with "Module hailo_pci is in use," reboot — the blacklist will prevent it from loading again.

## Verification

```bash
lsmod | grep hailo
```

Must show **only** `hailo1x_pci`. The 4.20.0 zombie must not appear.

```bash
cat /etc/modprobe.d/hailo-blacklist.conf
```

Must contain `blacklist hailo_pci`.

## Why this isn't documented anywhere else

The Raspberry Pi OS doesn't ship the conflicting driver, so nobody on RPi OS hits this. The Hailo official docs assume RPi OS. The Kali ARM team doesn't (yet) document Hailo support because it isn't officially supported.

That leaves you. And now me. And now this repo.

## See also

- [`docs/03-blacklist-zombie-driver.md`](../docs/03-blacklist-zombie-driver.md) — full walkthrough
