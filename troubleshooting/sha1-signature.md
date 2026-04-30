# Troubleshooting — Kali rejects the Raspberry Pi archive signature

## Symptom

```
$ sudo apt update
W: GPG error: http://archive.raspberrypi.com/debian trixie InRelease:
   The following signatures were invalid: SHA1
E: The repository 'http://archive.raspberrypi.com/debian trixie InRelease'
   is not signed.
```

Or:

```
$ sudo apt install h10-hailort
E: There were unauthenticated packages and -y was used without
   --allow-unauthenticated
```

## Diagnosis

The Raspberry Pi apt archive signs its `Release` file with a **SHA1**-based signature. SHA1 has been considered cryptographically weak for years, and modern `apt` (which Kali uses) refuses SHA1 signatures by default.

This is a Kali-vs-RPi-archive policy mismatch, not a security issue per se — the RPi archive is legitimate and the SHA1 signature is technically valid, just considered insufficient by modern apt.

## Fix

Tell apt to trust this specific source:

```bash
sudo nano /etc/apt/sources.list.d/raspberrypi.list
```

Edit the line so it reads:

```
deb [arch=arm64 trusted=yes] http://archive.raspberrypi.com/debian trixie main
```

The key addition is `trusted=yes`. Save (`Ctrl+X` → `Y` → `Enter`).

Then:

```bash
sudo apt update
```

You'll still see warnings about the source being unsigned, but it'll work.

For individual installs, add `--allow-unauthenticated`:

```bash
sudo apt install --allow-unauthenticated h10-hailort
```

## Is this safe?

Reasonable caution applies. You're trusting that the bytes you receive over HTTP from `archive.raspberrypi.com` are authentic. Mitigations:

- The domain itself is the actual Raspberry Pi Foundation's archive.
- The packages you're pulling (`h10-hailort` and similar) are narrowly scoped to Hailo userspace tools — not full system packages.
- If you're paranoid, download the .deb manually, verify the SHA256 against the archive's `Packages` file, and install with `dpkg -i`.

For a security-research workstation this is a calculated risk. For a production deployment, you'd want a stronger trust chain.

## Long-term fix

Once Kali ships a configuration option to accept SHA1 from named archives, or once the RPi archive switches to SHA256 signatures, you can switch from `trusted=yes` to a proper `signed-by` keyring. Until then, `trusted=yes` is the answer.

## Verification

```bash
sudo apt update 2>&1 | grep -i error
# Should show no errors (warnings are OK)

apt-cache policy h10-hailort
# Should show 5.1.1 available from archive.raspberrypi.com
```

## See also

- [`docs/04-rpi-apt-source.md`](../docs/04-rpi-apt-source.md)
