# 05 — Build the kernel driver from v5.1.1 branch

This is where most online guides go wrong. They tell you to clone `https://github.com/hailo-ai/hailort-drivers.git` and run `make`. That gives you the **master branch**, which currently builds a **5.2.0** driver. The Raspberry Pi apt archive (your only source for the userspace library on Kali) only has **5.1.1**.

A 5.2.0 driver against a 5.1.1 library produces:

```
Driver version (5.2.0) is different from library version (5.1.1)
```

— and `hailortcli` refuses to talk to the device.

The fix: clone the `v5.1.1` branch explicitly so driver, library, and firmware all match.

## Install build dependencies

```bash
sudo apt install -y --allow-unauthenticated \
  git build-essential dkms linux-headers-$(uname -r)
```

The `linux-headers-$(uname -r)` package needs to **exactly match your running kernel**. If `apt` tells you the package isn't found:

```bash
uname -r
# 6.12.34+rpt-rpi-2712
apt search linux-headers | grep $(uname -r | cut -d. -f1-2)
```

…and install the closest matching variant. On Kali Pi the package is usually `kalipi-kernel-headers`. You may need to first run `sudo apt update && sudo apt full-upgrade` to align kernel and headers.

## Clone the v5.1.1 branch

```bash
cd ~
git clone --branch v5.1.1 https://github.com/hailo-ai/hailort-drivers.git hailort-51
```

The directory name `hailort-51` is just a convention — it makes it clear at a glance which version this is, since you might also have an older `hailort-drivers` directory from a previous attempt. Delete any old ones first.

## Build and install

```bash
cd ~/hailort-51/linux/pcie
make all
sudo make install
sudo depmod -a
```

`make all` produces `hailo1x_pci.ko`. `make install` copies it into `/lib/modules/$(uname -r)/kernel/drivers/misc/`. `depmod -a` rebuilds the module dependency database so the kernel can find it.

## Verify the build

```bash
find /lib/modules/$(uname -r) -name "hailo1x*"
```

You should see exactly one file: `/lib/modules/$(uname -r)/kernel/drivers/misc/hailo1x_pci.ko.xz`.

If you also see a `hailo_pci.ko.xz` somewhere — that's the zombie. Confirm your blacklist from [step 03](03-blacklist-zombie-driver.md) is in place.

## Don't load it yet

It might be tempting to run `sudo modprobe hailo1x_pci` right now. Don't — without the firmware in place (next step), it will fail to initialize the device and may leave the PCIe device in D3cold power state, which only a full power-off recovers from.

→ Next: [`06-firmware-install.md`](06-firmware-install.md)
