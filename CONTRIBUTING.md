# Contributing

Thank you for considering a contribution. This repo exists because Hailo-on-Kali is poorly documented — every PR makes the next person's life easier.

## What's most useful

In rough priority order:

1. **New troubleshooting entries.** If you hit a failure mode not covered here, add a file under `troubleshooting/` using the format below. This is the highest-value contribution.
2. **Verification on different hardware.** This guide was written and tested on a Pi 5 (8GB) + AI HAT+ (Hailo-10H). If you confirm it works (or doesn't) on another configuration — Pi 5 4GB, AI HAT+ 13 TOPS variant (Hailo-8L), different cooler, different PSU — open an issue or PR noting the result.
3. **Confirmation on different Kali versions.** This was verified on Kali 2026.1. If you confirm on 2025.x, 2026.2, etc., update the OS-tested table in the README.
4. **Newer HailoRT versions.** When the Raspberry Pi archive starts shipping HailoRT 5.2.x or higher, this guide will need updating to match. PRs welcome.
5. **Typo fixes, link fixes, prose improvements.** Always welcome.

## What's not in scope

- **Hailo Model Zoo / inference examples.** This repo is exclusively about getting the device operational. Once `hailortcli fw-control identify` returns clean, you're done with what this repo covers.
- **Raspberry Pi OS instructions.** That's well-covered by Hailo's official docs.
- **Hailo-8 family devices.** Different drivers, different firmware. Out of scope.

## Troubleshooting entry format

Use this structure for `troubleshooting/<your-issue>.md`:

```markdown
# Troubleshooting — <short title>

## Symptom

What the user sees. Include exact error messages, dmesg lines, or command output.

## Diagnosis

What's actually going wrong, in plain terms. Why does this happen?

## Fix

Step-by-step commands. Real, tested, copy-paste-able.

## Verification

How to confirm the fix worked.

## See also

Links to relevant docs/ files.
```

Real failure modes only. No speculative "this might happen if..." — only things you actually hit.

## Pull request process

1. Fork the repo
2. Create a branch: `git checkout -b add-<short-description>`
3. Make your change
4. **Test your commands** on a real Kali Pi if you're modifying install steps. Don't trust transcription.
5. Commit with a clear message
6. Open a PR

For fixes to the install script, ideally test on a fresh Kali image. The script is supposed to be idempotent and safe to re-run; please don't break that.

## Code of conduct

Be useful, be accurate, don't be a jerk. That's it.

## License

Contributions are accepted under the same MIT license as the rest of the repo.
