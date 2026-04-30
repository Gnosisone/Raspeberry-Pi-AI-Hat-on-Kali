# 06 — Install the firmware (and the rename gotcha)

The Hailo-10H is a **firmware-loaded** NPU — every boot, the kernel driver pushes a firmware blob to the device before it can do anything. Without firmware, you'll get the device on PCIe but `/dev/hailo0` will not appear and the chip will sit there inert.

## Download the firmware

The drivers repo includes a helper script that pulls the matching firmware version. **Use the Hailo-10H specific script**, not the generic one:

```bash
cd ~/hailort-51
sudo ./download_firmware_hailo10h.sh
```

⚠ **Don't use `download_firmware.sh`** (no `_hailo10h` suffix) — that's for the Hailo-8 family and will pull the wrong blob.

After it finishes, you'll have a directory called `hailo10h_fw_5.1.1` in `~/hailort-51`. **Note the underscores, not dots.** Earlier attempts at this install failed because of `cp ~/hailort-51/hailo10h_fw_5.1.1/*` typos where the user put dots instead of underscores in the path.

## Place the firmware

The kernel driver expects firmware files at `/lib/firmware/hailo/hailo10h/`. Create the directory and copy:

```bash
sudo mkdir -p /lib/firmware/hailo/hailo10h
sudo cp ~/hailort-51/hailo10h_fw_5.1.1/* /lib/firmware/hailo/hailo10h/
```

After the copy, you should see something like:

```bash
ls /lib/firmware/hailo/hailo10h/
# fitImage
# u-boot-default.dtb.signed
# (other .bin files)
```

## The rename gotcha

The driver doesn't actually look for `u-boot-default.dtb.signed` or `fitImage` — it looks for files with **specific different names**: `u-boot.dtb.signed` and `u-boot-tfa.itb`. You have to copy them under those exact names:

```bash
cd /lib/firmware/hailo/hailo10h
sudo install -m 644 u-boot-default.dtb.signed u-boot.dtb.signed
sudo install -m 644 fitImage u-boot-tfa.itb
```

We use `install` rather than `cp` because it sets the file mode explicitly to 644 in one step. `cp` would work too — but read-only firmware files must be world-readable for the kernel firmware loader to find them.

## Why two names for the same file?

The firmware download script names files by their build artifact name (`u-boot-default.dtb.signed`, `fitImage`). The driver names them by their runtime role (`u-boot.dtb.signed`, `u-boot-tfa.itb`). The driver source has the runtime names hardcoded; the build artifacts have the artifact names. So you need both — the original (in case you want to reflash later) and the renamed copy (for the driver to actually find them).

## Verification

```bash
ls /lib/firmware/hailo/hailo10h/u-boot.dtb.signed
ls /lib/firmware/hailo/hailo10h/u-boot-tfa.itb
```

Both files must exist with non-zero size. If either is missing, the driver will fail at firmware load with `Failed to load firmware` in dmesg.

## Common typos to watch for

In the original install session a stiff keyboard caused real trouble at this step. Watch for:

- `u-boot-defualt` (transposed letters) — should be `u-boot-default`
- `u-boot-.dtb.signed` (missing word `dtb`) — should be `u-boot.dtb.signed`
- Smart curly quotes `"` `"` instead of straight quotes `"` if you're typing on a phone

If you find a wrongly-named file in the directory, just `sudo rm` it and redo the `install` command.

→ Next: [`07-userspace-library.md`](07-userspace-library.md)
