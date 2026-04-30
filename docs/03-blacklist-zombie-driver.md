# 03 — Kill the zombie driver

This is the single most important step in the whole guide and the one that's not documented anywhere else. **Skipping or doing it wrong will silently break everything that follows.**

## The problem

Kali Linux ships its own ancient `hailo_pci` driver — version **4.20.0** — bundled with the kernel package. It lives at:

```
/lib/modules/$(uname -r)/kernel/drivers/media/pci/hailo/hailo_pci.ko.xz
```

This driver is for the older Hailo-8 family. It is **not compatible** with the Hailo-10H. But the kernel will load it automatically the moment a Hailo PCIe device appears, **even if you have a newer driver installed**, because the device IDs partially overlap.

Symptoms of the zombie running:

```bash
lsmod | grep hailo
# hailo1x_pci    147456  0   ← your good driver
# hailo_pci      131072  0   ← THE ZOMBIE
```

When both load, you'll see `Failed reading device BARs` in dmesg, and `/dev/hailo0` either won't appear or will return I/O errors. The newer driver loses the fight for control of the device.

## The fix

Blacklist `hailo_pci` permanently:

```bash
sudo mkdir -p /etc/modprobe.d
sudo nano /etc/modprobe.d/hailo-blacklist.conf
```

Inside the file, write:

```
# Block Kali's ancient hailo_pci v4.20.0 from loading.
# We use the modern hailo1x_pci built from source instead.
blacklist hailo_pci
```

Save with `Ctrl+X` → `Y` → `Enter`.

Then unload it from the running kernel and refresh module dependencies:

```bash
sudo modprobe -r hailo_pci 2>/dev/null || true
sudo depmod -a
```

The `|| true` is intentional — `modprobe -r` will fail harmlessly if the module isn't currently loaded, and we don't want that to break the script.

## Verification

After a reboot, confirm only the right driver loads:

```bash
lsmod | grep hailo
```

You should see **only** `hailo1x_pci`, never `hailo_pci`.

If `hailo_pci` keeps coming back even with the blacklist, check:

1. **Did the file save correctly?** `cat /etc/modprobe.d/hailo-blacklist.conf`
2. **Did you typo the module name?** It's `hailo_pci` (with an underscore), not `hailo-pci`.
3. **Is something else loading it?** `grep -r "hailo_pci" /etc/modules*` and `grep -r "hailo_pci" /etc/modules-load.d/` should return nothing.

## Why the original install almost died here

The first attempt at this install thought the zombie was gone after a `modprobe -r hailo_pci`. It came back on every reboot. The fix wasn't `modprobe -r` (that only unloads for the current session) — it was the persistent blacklist file.

This is also why the **fresh Kali install** ended up being necessary in the original session — too many corrupted module states layered on top of each other. With this blacklist in place from the start, you should not need to wipe.

→ Next: [`04-rpi-apt-source.md`](04-rpi-apt-source.md)
