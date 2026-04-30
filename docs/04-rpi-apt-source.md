# 04 — Add the Raspberry Pi apt source

The Hailo-10H userspace library (`h10-hailort`) is **not in any Kali repo**. It is only distributed through the official Raspberry Pi apt archive at `archive.raspberrypi.com`.

Adding that archive on Kali has two complications:

1. The RPi archive signs packages with **SHA1**, which Kali's modern apt rejects by default.
2. The RPi archive's distribution name (`trixie`) doesn't line up with anything Kali tracks.

Both are solved by marking the source as `trusted=yes`.

## Add the GPG key (defensive — even though we'll use trusted=yes)

```bash
curl -fsSL https://archive.raspberrypi.com/debian/raspberrypi.gpg.key | \
  sudo gpg --dearmor -o /usr/share/keyrings/raspberrypi-archive-keyring.gpg
```

This won't actually be used because we're going to set `trusted=yes`, but it's good hygiene to have the key available — you can flip it to a `signed-by` setup later if Kali ever accepts SHA1 again.

## Add the apt source

```bash
echo "deb [arch=arm64 trusted=yes] http://archive.raspberrypi.com/debian trixie main" | \
  sudo tee /etc/apt/sources.list.d/raspberrypi.list
```

Breakdown of the source line:

| Part | Why |
|---|---|
| `[arch=arm64]` | The RPi archive has both armhf and arm64 packages; we only want arm64. |
| `[trusted=yes]` | Bypasses the SHA1 signature rejection. Acceptable here because we're pulling from the official RPi domain over HTTPS-redirected HTTP. |
| `trixie` | The Debian release name the RPi archive currently tracks. Kali is rolling and doesn't have a matching release name, but apt only uses this string as an index key. |
| `main` | The component. |

## Refresh and verify

```bash
sudo apt update
```

You'll see warnings about missing `Release.gpg` signatures — those are expected and harmless given `trusted=yes`. The line you want to see is:

```
Get:N http://archive.raspberrypi.com/debian trixie InRelease
```

Confirm the `h10-hailort` package is now visible:

```bash
apt-cache policy h10-hailort
```

You should see version `5.1.1-1` (or similar) available from `archive.raspberrypi.com`.

## Why not just download the .deb directly?

You can — `wget http://archive.raspberrypi.com/debian/pool/main/h/hailort/hailort_5.1.1_arm64.deb` and `dpkg -i` would work. But the apt-source approach lets you `apt upgrade` later if Hailo updates the package, and it pulls in dependencies automatically.

→ Next: [`05-build-driver.md`](05-build-driver.md)
