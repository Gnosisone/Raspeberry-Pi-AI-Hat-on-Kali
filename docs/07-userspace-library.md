# 07 — Install the userspace library (h10-hailort)

Now that the kernel driver is built and the firmware is in place, you need the userspace library — `libhailort` plus the `hailortcli` command-line tool. This is the piece that talks to `/dev/hailo0` from user processes (your Python apps, ERR0RS, Ollama-Hailo, etc.).

## Install

With the Raspberry Pi apt source added (step [04](04-rpi-apt-source.md)), this is a one-liner:

```bash
sudo apt install -y --allow-unauthenticated h10-hailort
```

The `--allow-unauthenticated` flag tells apt to install despite the SHA1 signature warning. (Even with `trusted=yes` on the source, individual install commands sometimes still want this flag.)

## What you got

| Component | Path | Purpose |
|---|---|---|
| `libhailort.so` | `/usr/lib/aarch64-linux-gnu/libhailort.so.5.1.1` | The shared library Python bindings and apps link against. |
| `hailortcli` | `/usr/bin/hailortcli` | Command-line tool for device control, firmware queries, scheduler info. |
| Python bindings (optional) | available via `pip install hailort` | If you want Python integration. |

## Don't install `hailort` from Kali's repos

Kali has a package called just `hailort` (without the `h10-` prefix). That's the **older 4.x line for Hailo-8**. Installing it will overwrite your `hailortcli` with a version that can't talk to the Hailo-10H.

```bash
# DO NOT DO THIS:
sudo apt install hailort   # ← wrong — installs 4.x for Hailo-8
```

If you accidentally installed it earlier, remove it:

```bash
sudo apt remove hailort
sudo apt install --reinstall h10-hailort
```

## Verify the version match

```bash
hailortcli --version
```

You should see `5.1.1`. If you see anything else, something went wrong and you'll get the version-mismatch error at runtime.

Also check the library version:

```bash
strings /usr/lib/aarch64-linux-gnu/libhailort.so* | grep -E "^5\.[0-9]+\.[0-9]+$" | head -1
```

Should also be `5.1.1`. **Driver, library, and firmware all need to match this exact version** — that's the entire game on Kali.

## Don't run hailortcli yet

It might be tempting to run `hailortcli fw-control identify` right now to test. Don't — the kernel module hasn't been loaded yet (we're saving that for the cold boot in step 08), and trying to talk to the device before the firmware loads will leave it in a confused PCIe power state.

→ Next: [`08-cold-boot-verify.md`](08-cold-boot-verify.md)
